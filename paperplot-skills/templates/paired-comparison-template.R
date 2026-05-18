#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) {
  stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from the repository root.", call. = FALSE)
}
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
paired_id_col <- "TODO_sample"
condition_col <- "TODO_group"
value_col <- "TODO_value"
figure_id <- "paired_comparison"
figure_role <- "main"
scientific_message <- "Show within-sample changes across paired conditions without treating observations as independent."
y_label <- "TODO value"

if (!file.exists(input_csv)) {
  stop("Input CSV not found: ", input_csv, call. = FALSE)
}
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(paired_id_col, condition_col, value_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[condition_col]] <- factor(df[[condition_col]])
df[[paired_id_col]] <- factor(df[[paired_id_col]])
df[[value_col]] <- as.numeric(df[[value_col]])
df <- df[!is.na(df[[paired_id_col]]) & !is.na(df[[condition_col]]) & !is.na(df[[value_col]]), , drop = FALSE]
if (nlevels(df[[condition_col]]) < 2) stop("Paired comparison requires at least two conditions.", call. = FALSE)

counts_by_pair <- table(df[[paired_id_col]])
if (any(counts_by_pair < 2)) {
  warning("Some paired IDs have fewer than two observations; they remain visible but weaken paired interpretation.")
}

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "paired-comparison-template",
  task_type = "new",
  figure_role = figure_role,
  scientific_message = scientific_message,
  plot_type = "paired_comparison",
  sample_id = paired_id_col,
  group_var = condition_col,
  output_preset = "nature_half"
)
metric_spec <- pp_metric_spec(metric = value_col, label = y_label, unit = "a.u.", direction = "neutral", transform = "none", role = "primary")
data_profile <- pp_data_profile(df, sample_col = paired_id_col, group_col = condition_col, value_col = value_col)
statistical_plan <- pp_statistical_plan(df, group_col = condition_col, value_col = value_col, paired_id_col = paired_id_col)
stat_annotation_plan <- pp_stat_annotation_plan(statistical_plan, figure_role = figure_role)

label_strategy <- pp_label_strategy_v2(levels(df[[condition_col]]), figure_role = figure_role, available_width_cm = 8.9, sample_identity_role = "core")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = length(levels(df[[condition_col]])), n_legend_entries = length(levels(df[[condition_col]])))

design_brief <- pp_design_brief(
  scientific_message = scientific_message,
  figure_role = figure_role,
  main_comparison = list(paired_id = paired_id_col, condition = condition_col, value = value_col),
  data_roles = list(pairing = "within-sample identity", condition = "paired condition", value = "quantitative response"),
  metric_semantics = list(value = metric_spec),
  label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score),
  acceptable_simplifications = c("Individual paired identities are encoded by lines rather than labeled individually."),
  must_show = c("paired trajectories", "raw observations"),
  may_move_to_metadata = c("full paired sample IDs", "group summaries")
)

design_plan <- pp_design_plan(
  chart_family = "paired_points_lines",
  layout_plan = list(type = "single_panel", nrow = 1, ncol = 1),
  label_strategy = label_strategy,
  palette_plan = list(color_role = condition_col, consistent_across_panels = TRUE),
  statistical_plan = stat_annotation_plan,
  visible_simplifications = c("Pair IDs are not printed unless they are the scientific message."),
  risks = statistical_plan$warnings
)

plot <- ggplot(df, aes(x = .data[[condition_col]], y = .data[[value_col]], group = .data[[paired_id_col]])) +
  geom_line(color = "#7A7A76", linewidth = 0.28, alpha = 0.45) +
  geom_point(aes(color = .data[[condition_col]]), size = 1.9, alpha = 0.9) +
  pp_scale_color(levels(df[[condition_col]])) +
  labs(x = NULL, y = y_label, color = "Condition") +
  pp_theme(base_size = 7) +
  theme(legend.position = "bottom")

qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role),
  pp_validate_statistical_expression("paired_comparison", statistical_plan, data_profile)
)
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)

outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))

pp_write_notes(
  notes_path,
  figure_id = figure_id,
  input_path = input_csv,
  output_files = outputs,
  preset = figure_spec$output_preset,
  design_decisions = c(
    "Connecting lines are used only because a paired ID column is present.",
    "Pair IDs are not printed in the main figure unless identity is the scientific message.",
    "Raw paired observations remain visible."
  ),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Lines are used because a paired ID column is present; do not use this template for independent samples.",
  figure_spec = figure_spec,
  metric_spec = metric_spec,
  design_brief = design_brief,
  design_plan = design_plan,
  layout = design_plan$layout_plan,
  palette = design_plan$palette_plan,
  label_strategy = label_strategy,
  data_summary = data_profile
)
pp_write_metadata(
  metadata_path,
  figure_spec = figure_spec,
  metric_spec = metric_spec,
  output_files = c(outputs, notes = notes_path, qa = qa_path),
  layout = design_plan$layout_plan,
  palette = design_plan$palette_plan,
  qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness),
  data_summary = data_profile,
  design_brief = design_brief,
  design_plan = design_plan,
  data_profile = data_profile,
  visual_budget = visual_budget,
  label_strategy = label_strategy,
  statistical_plan = statistical_plan
)
pp_write_qa_report(qa_path, qa_results)
