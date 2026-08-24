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
group_col <- "TODO_group"
value_col <- "TODO_value"
figure_id <- "grouped_boxplot_jitter"
figure_role <- "main"
scientific_message <- "Compare a quantitative measurement across groups while keeping raw observations visible."
y_label <- "TODO value"

if (!file.exists(input_csv)) {
  stop("Input CSV not found: ", input_csv, call. = FALSE)
}
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(group_col, value_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[group_col]] <- factor(df[[group_col]])
df[[value_col]] <- as.numeric(df[[value_col]])
df <- df[!is.na(df[[group_col]]) & !is.na(df[[value_col]]), , drop = FALSE]
if (nrow(df) == 0) stop("No non-missing rows remain after filtering group/value columns.", call. = FALSE)

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "grouped-boxplot-jitter-template",
  task_type = "new",
  figure_role = figure_role,
  scientific_message = scientific_message,
  plot_type = "grouped_boxplot_jitter",
  group_var = group_col,
  output_preset = "nature_half"
)
metric_spec <- pp_metric_spec(
  metric = value_col,
  label = y_label,
  unit = "a.u.",
  direction = "neutral",
  transform = "none",
  role = "primary"
)
data_profile <- pp_data_profile(df, group_col = group_col, value_col = value_col)
statistical_plan <- pp_statistical_plan(df, group_col = group_col, value_col = value_col)
stat_annotation_plan <- pp_stat_annotation_plan(statistical_plan, figure_role = figure_role)

label_strategy <- pp_label_strategy_v2(levels(df[[group_col]]), figure_role = figure_role, available_width_cm = 8.9, sample_identity_role = "core")
visual_budget <- pp_visual_budget(
  figure_role = figure_role,
  n_panels = 1,
  n_labels = length(levels(df[[group_col]])),
  n_legend_entries = length(levels(df[[group_col]]))
)

design_brief <- pp_design_brief(
  scientific_message = scientific_message,
  figure_role = figure_role,
  main_comparison = list(group = group_col, value = value_col),
  data_roles = list(group = "primary visual grouping", value = "quantitative response"),
  metric_semantics = list(value = metric_spec),
  label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score),
  legend_burden = list(entries = length(levels(df[[group_col]]))),
  acceptable_simplifications = c("Raw observations remain visible; statistical details are recorded in metadata."),
  must_show = c("raw observations", "group summaries"),
  may_move_to_metadata = c("group sample sizes", "effect-size details")
)

design_plan <- pp_design_plan(
  chart_family = if (isTRUE(statistical_plan$min_n < 5)) "raw_points_with_median" else "boxplot_jitter",
  layout_plan = list(type = "single_panel", nrow = 1, ncol = 1),
  label_strategy = label_strategy,
  palette_plan = list(color_role = group_col, consistent_across_panels = TRUE),
  statistical_plan = stat_annotation_plan,
  visible_simplifications = c("Do not use p-value stars as the primary statistical expression."),
  risks = statistical_plan$warnings
)

base_plot <- ggplot(df, aes(x = .data[[group_col]], y = .data[[value_col]], color = .data[[group_col]]))
if (isTRUE(statistical_plan$min_n >= 5)) {
  base_plot <- base_plot + geom_boxplot(width = 0.52, outlier.shape = NA, linewidth = 0.35, alpha = 0.18)
}
plot <- base_plot +
  geom_jitter(width = 0.1, height = 0, size = pp_point_size("normal"), alpha = 0.78, stroke = 0) +
  stat_summary(fun = median, geom = "crossbar", width = 0.45, linewidth = 0.35, color = "#1D1D1B") +
  pp_scale_color(levels(df[[group_col]])) +
  labs(x = NULL, y = y_label, color = "Group") +
  pp_theme(base_size = 7) +
  theme(legend.position = "none")

qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role),
  pp_validate_statistical_expression(if (statistical_plan$min_n >= 5) "boxplot_jitter" else "raw_points", statistical_plan, data_profile)
)
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)

outputs <- pp_save_all_with_qa_loop(plot, output_stem, preset = figure_spec$output_preset, qa_context = list(family = figure_spec$plot_type), overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))

pp_write_notes(
  notes_path,
  figure_id = figure_id,
  input_path = input_csv,
  output_files = outputs,
  preset = figure_spec$output_preset,
  design_decisions = c(
    "Raw observations remain visible as primary evidence.",
    "Pattern reference: raincloud-violin-jitter.",
    if (statistical_plan$min_n < 5) "Boxplot suppressed for small group size." else "Boxplot used only as compact summary context.",
    "P-value stars are not used as the primary statistical expression."
  ),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = if (statistical_plan$min_n < 5) "Boxplot was suppressed because at least one group has fewer than five observations." else "Boxplot is used as summary context; raw observations remain primary.",
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
  output_files = pp_extend_output_files(outputs, notes = notes_path, qa = qa_path),
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
