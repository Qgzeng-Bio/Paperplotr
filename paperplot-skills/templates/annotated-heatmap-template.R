#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })
helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)
recipe_path <- Sys.getenv("PAPERPLOT_RECIPE_ENGINE")
if (!nzchar(recipe_path)) recipe_path <- "paperplot-skills/recipes/paperplot_code_recipes.R"
if (!file.exists(recipe_path)) stop("Missing recipe engine: ", recipe_path, call. = FALSE)
source(recipe_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
row_col <- "TODO_row"
column_col <- "TODO_column"
value_col <- "TODO_value"
row_group_col <- "TODO_group"
figure_id <- "annotated_heatmap"
figure_role <- "main"
scientific_message <- "Show matrix-level quantitative structure with compact row annotation and one continuous color scale."
recipe_id <- "annotated_heatmap"

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(row_col, column_col, value_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
if (!row_group_col %in% names(df)) df[[row_group_col]] <- "Row group"
df[[value_col]] <- as.numeric(df[[value_col]])
df <- df[!is.na(df[[row_col]]) & !is.na(df[[column_col]]) & !is.na(df[[value_col]]), , drop = FALSE]
if (nrow(df) < 9) stop("Annotated heatmap template needs at least nine matrix cells.", call. = FALSE)

base <- pp_recipe_mock_data(recipe_id)
recipe_df <- base[rep(seq_len(nrow(base)), length.out = nrow(df)), ]
recipe_df$metric <- factor(df[[row_col]], levels = unique(df[[row_col]]))
recipe_df$category <- factor(df[[column_col]], levels = unique(df[[column_col]]))
recipe_df$value <- df[[value_col]]
recipe_df$group <- factor(df[[row_group_col]], levels = unique(df[[row_group_col]]))

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
label_key_path <- paste0(output_stem, "_label_key.csv")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path, label_key_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "annotated-heatmap-template", task_type = "new", figure_role = figure_role, scientific_message = scientific_message, plot_type = "annotated_heatmap", output_preset = "nature_half")
metric_spec <- pp_metric_spec(metric = value_col, label = "Matrix value", unit = "a.u.", direction = "neutral", transform = "none", role = "primary")
label_strategy <- pp_label_strategy_v2(unique(c(as.character(recipe_df$metric), as.character(recipe_df$category))), figure_role = figure_role, available_width_cm = 8.9, sample_identity_role = "core")
if (isTRUE(label_strategy$needs_label_key)) {
  label_map <- pp_rank_index_map(unique(c(as.character(recipe_df$metric), as.character(recipe_df$category))))
  pp_write_label_key(label_key_path, label_map)
}
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = length(levels(recipe_df$group)), n_labels = length(unique(recipe_df$metric)) + length(unique(recipe_df$category)), n_legend_entries = 1)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(rows = row_col, columns = column_col, annotation = row_group_col), data_roles = list(row = row_col, column = column_col, value = value_col, row_group = row_group_col), metric_semantics = list(metrics = metric_spec), label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score), acceptable_simplifications = c("Use annotation facets instead of heavy sidebars when dependencies are restricted."), must_show = c("row identity", "column identity", "continuous color scale", "row annotation"), may_move_to_metadata = c("cluster dendrogram", "complete annotation table"))
design_plan <- pp_design_plan(chart_family = "annotated_heatmap", figure_role = figure_role, layout_plan = list(type = "faceted_annotation_heatmap", width_cm = 8.9, height_cm = 7.2), label_strategy = label_strategy, palette_plan = list(type = "continuous", name = "graphpad_heatmap"), statistical_plan = list(recipe_id = recipe_id), visible_simplifications = design_brief$acceptable_simplifications, risks = c("Confirm matrix normalization and whether clustering is required."), pattern_reference = pp_pattern_reference("heatmap", template_id = "annotated-heatmap-template"))

plot <- pp_recipe_plot(recipe_id, recipe_df)
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec, label_strategy), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("heatmap_semantics", "warn", "Confirm normalization, transformation, and row/column order."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, width = 8.9, height = 7.2, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id, input_csv, outputs, figure_spec$output_preset, design_decisions = c("Pattern reference: correlation-heatmap.", "Row annotation is encoded through facets to avoid extra package dependency.", "Cell borders are thin white separators only when annotation facets need separation."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm normalization, transform, color scale midpoint, and clustering requirements.", figure_spec = figure_spec, metric_spec = metric_spec, design_brief = design_brief, design_plan = design_plan, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = pp_data_profile(recipe_df, group_col = "group", metric_col = "metric", value_col = "value"))
pp_write_metadata(metadata_path, figure_spec, metric_spec, c(outputs, notes = notes_path, qa = qa_path), layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness), data_summary = pp_data_summary(recipe_df), design_brief = design_brief, design_plan = design_plan, data_profile = pp_data_profile(recipe_df, group_col = "group", metric_col = "metric", value_col = "value"), visual_budget = visual_budget, label_strategy = label_strategy, statistical_plan = design_plan$statistical_plan, sidecars = list(label_key = if (file.exists(label_key_path)) label_key_path else NULL))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
