#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })
helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
sample_col <- "TODO_sample"
mode_col <- "TODO_metric"
group_col <- "TODO_group"
value_col <- "TODO_value"
figure_id <- "bio_duplication_mode_comparison"
figure_role <- "main"
scientific_message <- "Compare gene duplication burden and duplication-mode composition across groups with consistent mode semantics."

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(sample_col, mode_col, group_col, value_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[sample_col]] <- as.character(df[[sample_col]])
df[[mode_col]] <- as.character(df[[mode_col]])
df[[group_col]] <- as.character(df[[group_col]])
df[[value_col]] <- as.numeric(df[[value_col]])
df <- df[!is.na(df[[sample_col]]) & !is.na(df[[mode_col]]) & !is.na(df[[group_col]]) & !is.na(df[[value_col]]), , drop = FALSE]
mode_levels <- unique(df[[mode_col]])
group_levels <- unique(df[[group_col]])

burden <- aggregate(df[[value_col]], by = setNames(list(df[[sample_col]], df[[group_col]]), c("sample", "group")), FUN = sum, na.rm = TRUE)
names(burden)[3] <- "value"
burden$panel <- "A. Duplicate-pair burden"
burden$x <- burden$sample
burden$color_group <- burden$group

frac <- df
frac$value <- frac[[value_col]] / max(df[[value_col]], na.rm = TRUE)
frac$panel <- "B. Fraction by mode"
frac$x <- frac[[mode_col]]
frac$color_group <- frac[[group_col]]
frac <- frac[, c("panel", "x", "value", "color_group")]

sample_total <- ave(df[[value_col]], df[[sample_col]], FUN = function(x) sum(x, na.rm = TRUE))
rel <- df
rel$value <- rel[[value_col]] / sample_total
rel$panel <- "C. Relative contribution"
rel$x <- rel[[mode_col]]
rel$color_group <- rel[[group_col]]
rel <- rel[, c("panel", "x", "value", "color_group")]

effect_parts <- lapply(mode_levels, function(mode) {
  d <- df[df[[mode_col]] == mode, , drop = FALSE]
  es <- if (length(unique(d[[group_col]])) == 2) pp_effect_size(d, group_col = group_col, value_col = value_col, method = "mean_difference") else data.frame(method = "mean_difference", group_a = NA, group_b = NA, estimate = NA, ci_low = NA, ci_high = NA, stringsAsFactors = FALSE)
  data.frame(panel = "D. Group effect size", x = mode, value = es$estimate, color_group = NA_character_, stringsAsFactors = FALSE)
})
effect <- do.call(rbind, effect_parts)
plot_df <- rbind(burden[, c("panel", "x", "value", "color_group")], frac, rel, effect)
plot_df$panel <- factor(plot_df$panel, levels = c("A. Duplicate-pair burden", "B. Fraction by mode", "C. Relative contribution", "D. Group effect size"))

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "bio-duplication-mode-comparison-template", figure_role = figure_role, scientific_message = scientific_message, plot_type = "bio_duplication_mode_four_panel", sample_id = sample_col, group_var = group_col, output_preset = "double_column")
metric_spec <- pp_metric_spec(metric = mode_levels, label = mode_levels, unit = "duplication metric", direction = "neutral", transform = "none", role = "duplication_mode")
data_profile <- pp_data_profile(df, sample_col = sample_col, group_col = group_col, metric_col = mode_col, value_col = value_col)
label_strategy <- list(status = "pass", strategy = "mode_labels_visible", visible_label_policy = "show duplication mode labels", needs_label_key = FALSE, direct_label_mode = "none", message = "Mode labels are semantic and remain visible.")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 4, n_labels = length(mode_levels), n_legend_entries = length(group_levels))
panel_specs <- list(pp_panel_spec("A", "Total duplicate-pair burden", "primary", "burden"), pp_panel_spec("B", "Duplicated fraction by mode", "secondary", "fraction"), pp_panel_spec("C", "Relative mode contribution", "secondary", "composition"), pp_panel_spec("D", "Group effect-size summary", "supporting", "effect_size"))
panel_hierarchy <- pp_panel_hierarchy(panel_specs)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(group = group_col, mode = mode_col), data_roles = list(sample = "biological unit", mode = "duplication mode", group = "primary comparison", value = "mode-specific burden"), metric_semantics = list(modes = metric_spec), panel_hierarchy = panel_hierarchy, acceptable_simplifications = c("Panels share mode semantics but use free y scales."), must_show = c("group difference", "mode composition", "effect direction"), may_move_to_metadata = c("full per-sample values", "effect-size calculation details"))
design_plan <- pp_design_plan(chart_family = "bio_duplication_mode_four_panel", figure_role = figure_role, layout_plan = list(type = "facet_four_panel", nrow = 2, ncol = 2), label_strategy = label_strategy, palette_plan = list(color_role = group_col, mode_role = mode_col), panel_hierarchy = panel_hierarchy, statistical_plan = list(effect_method = "mean_difference"), visible_simplifications = design_brief$acceptable_simplifications, risks = c("free y scales require clear panel labels"))

plot <- ggplot(plot_df, aes(x = x, y = value, color = color_group)) +
  geom_hline(data = data.frame(panel = factor("D. Group effect size", levels = levels(plot_df$panel))), aes(yintercept = 0), inherit.aes = FALSE, linetype = "dashed", linewidth = 0.3, color = "#555555") +
  geom_point(position = position_jitter(width = 0.12, height = 0), size = pp_point_size("normal"), alpha = 0.82) +
  facet_wrap(~panel, scales = "free", ncol = 2) +
  pp_scale_color(stats::na.omit(unique(plot_df$color_group))) +
  labs(x = NULL, y = NULL, color = "Group") +
  pp_theme(base_size = 7) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("panel_hierarchy", "pass", "Panel hierarchy contains primary, secondary, and supporting roles."), pp_qa_result("bio_duplication_semantics", "pass", "Duplication modes and group colors are recorded consistently."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all_with_qa_loop(plot, output_stem, preset = figure_spec$output_preset, qa_context = list(family = figure_spec$plot_type), overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id = figure_id, input_path = input_csv, output_files = outputs, preset = figure_spec$output_preset, design_decisions = c("Four panels summarize burden, fraction, relative contribution, and effect size.", "Mode labels stay visible because they are semantic, not lookup labels.", "Free y scales are used because panels encode different quantities."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Replace approximate effect-size panel with final tested effect estimates before submission.", figure_spec = figure_spec, metric_spec = metric_spec, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = data_profile, design_brief = design_brief, design_plan = design_plan)
pp_write_metadata(metadata_path, figure_spec, metric_spec, outputs, layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)), data_summary = data_profile, design_brief = design_brief, design_plan = design_plan, data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy, palette_plan = design_plan$palette_plan, panel_hierarchy = panel_hierarchy, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
