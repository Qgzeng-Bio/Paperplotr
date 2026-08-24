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
pc1_col <- "TODO_PC1"
pc2_col <- "TODO_PC2"
group_col <- "TODO_group"
sample_col <- "TODO_sample"
figure_id <- "pcoa_marginal"
figure_role <- "main"
scientific_message <- "Show ordination separation with marginal distribution cues and restrained group encoding."
recipe_id <- "pcoa_marginal_box"
pc1_label <- "PCoA1 (TODO%)"
pc2_label <- "PCoA2 (TODO%)"

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(pc1_col, pc2_col, group_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
if (!sample_col %in% names(df)) df[[sample_col]] <- paste0("S", seq_len(nrow(df)))
df[[pc1_col]] <- as.numeric(df[[pc1_col]]); df[[pc2_col]] <- as.numeric(df[[pc2_col]])
df <- df[!is.na(df[[pc1_col]]) & !is.na(df[[pc2_col]]) & !is.na(df[[group_col]]), , drop = FALSE]
if (nrow(df) < 8) stop("PCoA marginal template needs at least eight complete samples.", call. = FALSE)

base <- pp_recipe_mock_data(recipe_id)
recipe_df <- base[rep(seq_len(nrow(base)), length.out = nrow(df)), ]
recipe_df$pc1 <- df[[pc1_col]]
recipe_df$pc2 <- df[[pc2_col]]
recipe_df$group <- factor(df[[group_col]])
recipe_df$sample <- as.character(df[[sample_col]])

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "pcoa-marginal-template", task_type = "new", figure_role = figure_role, scientific_message = scientific_message, plot_type = "pcoa_marginal", group_var = group_col, output_preset = "nature_half")
metric_spec <- pp_metric_spec(metric = c(pc1_col, pc2_col), label = c(pc1_label, pc2_label), unit = "ordination axis", direction = "neutral", transform = "none", role = "primary")
label_strategy <- pp_label_strategy_v2(levels(recipe_df$group), figure_role = figure_role, available_width_cm = 8.9, sample_identity_role = "supporting")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = 0, n_legend_entries = length(levels(recipe_df$group)))
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(groups = levels(recipe_df$group)), data_roles = list(pc1 = pc1_col, pc2 = pc2_col, group = group_col, sample = sample_col), metric_semantics = list(metrics = metric_spec), label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score), acceptable_simplifications = c("Marginal cues are rugs rather than full extra panels to preserve equal data region."), must_show = c("ordination axes", "group separation", "axis variance semantics"), may_move_to_metadata = c("PERMANOVA table", "sample coordinates"))
design_plan <- pp_design_plan(chart_family = "pca_pcoa_ordination", figure_role = figure_role, layout_plan = list(type = "single_panel_ordination_with_marginal_cues", width_cm = 8.9, height_cm = 6.2), label_strategy = label_strategy, palette_plan = list(type = "group", name = "graphpad_discrete"), statistical_plan = list(recipe_id = recipe_id), visible_simplifications = design_brief$acceptable_simplifications, risks = c("Confirm axis percentages and ordination method."), pattern_reference = pp_pattern_reference("pca_pcoa_ordination", template_id = "pcoa-marginal-template"))

plot <- pp_recipe_plot(recipe_id, recipe_df) + labs(x = pc1_label, y = pc2_label)
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("ordination_semantics", "warn", "Confirm ordination method, distance metric, and axis percentages."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all_with_qa_loop(plot, output_stem, preset = figure_spec$output_preset, qa_context = list(family = figure_spec$plot_type), width = 8.9, height = 6.2, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id, input_csv, outputs, figure_spec$output_preset, design_decisions = c("Pattern reference: pca-pcoa-ordination.", "Marginal cues are restrained rugs, not unequal stitched panels.", "Ellipses are low-weight support, not the primary data."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm ordination method, distance metric, and PERMANOVA if shown.", figure_spec = figure_spec, metric_spec = metric_spec, design_brief = design_brief, design_plan = design_plan, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = pp_data_profile(recipe_df, sample_col = "sample", group_col = "group"))
pp_write_metadata(metadata_path, figure_spec, metric_spec, pp_extend_output_files(outputs, notes = notes_path, qa = qa_path), layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness), data_summary = pp_data_summary(recipe_df), design_brief = design_brief, design_plan = design_plan, data_profile = pp_data_profile(recipe_df, sample_col = "sample", group_col = "group"), visual_budget = visual_budget, label_strategy = label_strategy, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
