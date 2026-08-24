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
item_col <- "TODO_item"
set_col <- "TODO_set"
present_col <- "TODO_present"
figure_id <- "upset_summary"
figure_role <- "main"
scientific_message <- "Summarize set membership with readable set sizes and a compact membership matrix."
recipe_id <- "upset_summary"

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(item_col, set_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
if (!present_col %in% names(df)) df[[present_col]] <- 1
df[[present_col]] <- as.integer(as.numeric(df[[present_col]]) > 0)
df <- df[!is.na(df[[item_col]]) & !is.na(df[[set_col]]), , drop = FALSE]
if (nrow(df) < 6) stop("UpSet summary template needs at least six membership records.", call. = FALSE)

base <- pp_recipe_mock_data(recipe_id)
recipe_df <- base[rep(seq_len(nrow(base)), length.out = nrow(df)), ]
recipe_df$item <- as.character(df[[item_col]])
recipe_df$set <- factor(df[[set_col]], levels = unique(df[[set_col]]))
recipe_df$present <- df[[present_col]]

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "upset-summary-template", task_type = "new", figure_role = figure_role, scientific_message = scientific_message, plot_type = "upset_set_summary", output_preset = "nature_half")
metric_spec <- pp_metric_spec(metric = "set_size", label = "Set size", unit = "count", direction = "neutral", transform = "none", role = "primary")
label_strategy <- pp_label_strategy_v2(levels(recipe_df$set), figure_role = figure_role, available_width_cm = 8.9, sample_identity_role = "supporting")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = length(levels(recipe_df$set)), n_legend_entries = 0)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(sets = levels(recipe_df$set)), data_roles = list(item = item_col, set = set_col, present = present_col), metric_semantics = list(metrics = metric_spec), label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score), acceptable_simplifications = c("Show set sizes and membership cues; move full intersections to metadata if too dense."), must_show = c("set identity", "membership", "set size"), may_move_to_metadata = c("full intersection table", "rare set combinations"))
design_plan <- pp_design_plan(chart_family = "upset_set_plot", figure_role = figure_role, layout_plan = list(type = "compact_set_summary", width_cm = 8.9, height_cm = 7), label_strategy = label_strategy, palette_plan = list(type = "single accent", name = "graphpad blue"), statistical_plan = list(recipe_id = recipe_id), visible_simplifications = design_brief$acceptable_simplifications, risks = c("For complex intersections, use optional ComplexUpset backend and maintain this compact summary as overview."), pattern_reference = pp_pattern_reference("upset_set_plot", template_id = "upset-summary-template"))

plot <- pp_recipe_plot(recipe_id, recipe_df)
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("set_semantics", "warn", "Confirm whether visible bars represent set sizes or intersections."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, width = 8.9, height = 7, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id, input_csv, outputs, figure_spec$output_preset, design_decisions = c("Pattern reference: upset-set-plot.", "Set-size bars are prioritized; dense intersections should move to a table or optional backend.", "Membership dots remain small to limit label burden."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm whether the manuscript needs exact intersection sizes or overview set sizes.", figure_spec = figure_spec, metric_spec = metric_spec, design_brief = design_brief, design_plan = design_plan, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = pp_data_summary(recipe_df))
pp_write_metadata(metadata_path, figure_spec, metric_spec, c(outputs, notes = notes_path, qa = qa_path), layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness), data_summary = pp_data_summary(recipe_df), design_brief = design_brief, design_plan = design_plan, data_profile = pp_data_summary(recipe_df), visual_budget = visual_budget, label_strategy = label_strategy, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
