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
metric_col <- "TODO_metric"
group_col <- "TODO_group"
value_col <- "TODO_value"
figure_id <- "effect_size_forest"
figure_role <- "main"
scientific_message <- "Compare the direction and magnitude of group effects across metrics with intervals visible."
effect_method <- "mean_difference"
effect_label <- "Mean difference"

if (!file.exists(input_csv)) {
  stop("Input CSV not found: ", input_csv, call. = FALSE)
}
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(metric_col, group_col, value_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[metric_col]] <- factor(df[[metric_col]])
df[[group_col]] <- factor(df[[group_col]])
df[[value_col]] <- as.numeric(df[[value_col]])
df <- df[!is.na(df[[metric_col]]) & !is.na(df[[group_col]]) & !is.na(df[[value_col]]), , drop = FALSE]
if (nlevels(df[[group_col]]) != 2) stop("Effect-size forest template requires exactly two groups.", call. = FALSE)

metric_levels <- levels(df[[metric_col]])
effect_parts <- lapply(metric_levels, function(m) {
  d <- df[df[[metric_col]] == m, , drop = FALSE]
  es <- pp_effect_size(d, group_col = group_col, value_col = value_col, method = effect_method)
  data.frame(metric = m, es, stringsAsFactors = FALSE)
})
effect_df <- do.call(rbind, effect_parts)
effect_df$metric <- factor(effect_df$metric, levels = effect_df$metric[order(effect_df$estimate)])
effect_df$direction <- ifelse(effect_df$estimate >= 0, "positive", "negative")

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "effect-size-forest-template",
  task_type = "new",
  figure_role = figure_role,
  scientific_message = scientific_message,
  plot_type = "effect_size_forest",
  group_var = group_col,
  output_preset = "nature_half"
)
metric_spec <- pp_metric_spec(metric = metric_levels, label = metric_levels, unit = "effect", direction = "neutral", transform = "none", role = "primary")
data_profile <- pp_data_profile(df, group_col = group_col, metric_col = metric_col, value_col = value_col)
statistical_plan <- list(
  plot_type = "effect_size_forest",
  method = effect_method,
  comparison = levels(df[[group_col]]),
  show_effect_size = TRUE,
  show_ci = TRUE,
  effect_table = effect_df
)

label_strategy <- pp_label_strategy_v2(metric_levels, figure_role = figure_role, available_width_cm = 9, sample_identity_role = "core")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = length(metric_levels), n_legend_entries = 2)

# Truthful 9 cm canvas moves dense metric sets onto the rank-index contract:
# when the strategy demands a key, write the label-key sidecar and reference it
# in notes/metadata instead of silently keeping full labels.
label_key_path <- paste0(output_stem, "_label_key.csv")
rank_map <- if (isTRUE(label_strategy$needs_label_key)) pp_rank_index_map(metric_levels) else NULL
if (!is.null(rank_map)) pp_write_label_key(label_key_path, rank_map)

design_brief <- pp_design_brief(
  scientific_message = scientific_message,
  figure_role = figure_role,
  main_comparison = list(groups = levels(df[[group_col]]), metrics = metric_levels),
  data_roles = list(group = "comparison groups", metric = "forest rows", value = "measurement used for effect size"),
  metric_semantics = list(metrics = metric_spec),
  label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score),
  acceptable_simplifications = c("Raw observations are summarized into effect sizes; group-level details are recorded in metadata."),
  must_show = c("effect direction", "effect interval"),
  may_move_to_metadata = c("group summaries", "raw value distribution")
)

design_plan <- pp_design_plan(
  chart_family = "effect_size_forest",
  layout_plan = list(type = "single_panel_forest", nrow = 1, ncol = 1),
  label_strategy = label_strategy,
  palette_plan = list(color_role = "effect direction", positive = "#2F6DB3", negative = "#B54A47"),
  statistical_plan = statistical_plan,
  visible_simplifications = c("Display effect sizes and intervals instead of p-value stars."),
  risks = c("Confirm interval method and reference group before final manuscript use."),
  pattern_reference = pp_pattern_reference("effect_size_forest", template_id = "effect-size-forest-template", source = "code-recipe-library")
)

plot <- ggplot(effect_df, aes(y = metric, x = estimate)) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.35, color = "#555555") +
  geom_segment(aes(x = ci_low, xend = ci_high, y = metric, yend = metric), linewidth = 0.45, color = "#2F2F2D", na.rm = TRUE) +
  geom_point(aes(color = direction), size = 2.3) +
  scale_color_manual(values = c(positive = "#2F6DB3", negative = "#B54A47"), guide = "none") +
  labs(x = effect_label, y = NULL) +
  pp_theme(base_size = 7)

qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role),
  pp_qa_result("statistical_expression", "pass", "Effect size and interval are the primary visual expression.")
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
    "Code recipe link: forest_effect_size.",
    "Effect size and interval are the primary visual expression.",
    "P-value stars are avoided in the main forest plot.",
    "Raw group distributions are moved to metadata or supporting figures.",
    if (!is.null(rank_map)) "Metric names moved to a label-key sidecar; main axis shows rank indices." else NULL
  ),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Intervals are simple approximate confidence intervals from available group values; confirm method before final submission.",
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
  statistical_plan = statistical_plan,
  sidecars = if (!is.null(rank_map)) list(label_key = basename(label_key_path)) else list()
)
pp_write_qa_report(qa_path, qa_results)
