# Standalone rank plus key metrics template with design-aware visible-vs-metadata split

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "rank_plus_key_metrics_todo"
preset <- "nature"

sample_col <- "TODO_sample"
score_col <- "TODO_score"
metric_col <- "TODO_metric"
value_col <- "TODO_value"
unit_col <- "TODO_unit"
group_col <- NULL
max_key_metrics <- 3
figure_role <- "main"

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
label_key_path <- paste0(output_stem, "_label_key.csv")
pp_stop_if_outputs_exist(c(paste0(output_stem, c(".pdf", ".png")), notes_path, metadata_path, qa_path, label_key_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "rank-plus-key-metrics-template",
  task_type = "new",
  figure_role = figure_role,
  scientific_message = "Show an integrated ranking plus a small number of interpretable key metrics without overloading the visible figure.",
  plot_type = "rank_plus_key_metrics_rank_index",
  sample_id = sample_col,
  group_var = group_col,
  output_preset = preset
)

if (!file.exists(input_path)) stop("Set input_path to an existing CSV file.", call. = FALSE)
df <- read.csv(input_path, check.names = FALSE)

required_cols <- c(sample_col, score_col, metric_col, value_col, unit_col, group_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

score_cols <- c(sample_col, score_col, group_col)
score_cols <- score_cols[!is.na(score_cols) & nzchar(score_cols)]
score_df <- unique(df[, score_cols, drop = FALSE])
score_df <- score_df[order(score_df[[score_col]], decreasing = TRUE), , drop = FALSE]
sample_levels <- as.character(score_df[[sample_col]])
rank_map <- pp_rank_index_map(sample_levels)
pp_write_label_key(label_key_path, rank_map)

key_metrics <- head(unique(as.character(df[[metric_col]])), max_key_metrics)
metric_df <- df[df[[metric_col]] %in% key_metrics, , drop = FALSE]
metric_df$facet_label <- paste0(metric_df[[metric_col]], " (", metric_df[[unit_col]], ")")
metric_df$plot_value <- metric_df[[value_col]]

score_plot_df <- score_df
score_plot_df$facet_label <- "Integrated score"
score_plot_df$plot_value <- score_plot_df[[score_col]]
score_plot_df[[metric_col]] <- "Integrated score"

plot_cols <- c(sample_col, group_col, metric_col, "facet_label", "plot_value")
plot_cols <- plot_cols[!is.na(plot_cols) & nzchar(plot_cols)]
plot_df <- rbind(score_plot_df[, plot_cols, drop = FALSE], metric_df[, plot_cols, drop = FALSE])
plot_df <- pp_prepare_rank_axis(plot_df, sample_col = sample_col, sample_order = sample_levels, index_col = "rank_index")
plot_df$facet_label <- factor(plot_df$facet_label, levels = unique(plot_df$facet_label))
layout <- pp_recommend_facet_grid(length(unique(plot_df$facet_label)), plot_type = "small_multiples", complex = TRUE)
layout$width_cm <- max(layout$width_cm, pp_output_preset(preset)$width_cm)
label_strategy <- pp_label_strategy_v2(sample_levels, figure_role = figure_role, available_width_cm = layout$width_cm / max(1, layout$ncol), sample_identity_role = "lookup")

key_metric_info <- unique(metric_df[, c(metric_col, unit_col), drop = FALSE])
key_metric_info <- key_metric_info[!duplicated(key_metric_info[[metric_col]]), , drop = FALSE]
metric_spec <- rbind(
  pp_metric_spec(score_col, label = "Integrated score", unit = "score", direction = "higher_better", role = "ranking"),
  pp_metric_spec(key_metric_info[[metric_col]], label = key_metric_info[[metric_col]], unit = key_metric_info[[unit_col]], direction = "neutral", role = "key")
)

key_samples <- pp_select_key_labels(score_df, sample_col = sample_col, value_col = score_col, group_col = group_col, max_labels = 8)
key_label_df <- plot_df[plot_df[[sample_col]] %in% key_samples, , drop = FALSE]
palette_check <- if (!is.null(group_col)) pp_validate_palette(plot_df[[group_col]], "discrete") else pp_validate_palette(plot_df$facet_label, "discrete")
layout_check <- pp_assess_layout_risk(length(unique(plot_df$facet_label)), plot_type = "small_multiples", label_strategy = list(status = label_strategy$status))
data_profile <- pp_data_profile(plot_df, sample_col = sample_col, group_col = group_col, metric_col = metric_col, value_col = "plot_value")
visual_budget <- pp_visual_budget(figure_role, n_panels = length(unique(plot_df$facet_label)), n_labels = length(key_samples), n_legend_entries = if (!is.null(group_col)) length(unique(plot_df[[group_col]])) else 0)

design_brief <- pp_design_brief(
  scientific_message = figure_spec$scientific_message,
  figure_role = figure_role,
  main_comparison = "ranked samples plus selected key metrics",
  data_roles = list(sample_id = "lookup", score = "ranking", metric = "key metric", value = "panel value", group = group_col),
  metric_semantics = as.list(stats::setNames(metric_spec$direction, metric_spec$metric)),
  label_burden = label_strategy$burden,
  acceptable_simplifications = c("full sample names moved to label key sidecar", "only selected key samples are directly labeled", "only a small number of key metrics stay in the main figure"),
  must_show = c("ranking direction", "key metric values", "group color semantics when group_col is set"),
  may_move_to_metadata = c("full sample order", "full sample labels", "non-key metrics")
)

design_plan <- pp_design_plan(
  chart_family = "rank_plus_key_metrics",
  figure_role = figure_role,
  layout_plan = layout,
  label_strategy = label_strategy,
  palette_plan = list(type = if (!is.null(group_col)) "group" else "facet", name = "graphpad_discrete"),
  visible_simplifications = design_brief$acceptable_simplifications,
  risks = c("main figure overload", "dense sample labels", "integrated score direction must be explicit")
)

mapping <- aes(x = rank_index, y = plot_value, colour = facet_label)
if (!is.null(group_col)) mapping <- aes(x = rank_index, y = plot_value, colour = .data[[group_col]])

p <- ggplot(plot_df, mapping) +
  geom_point(size = 1.8, alpha = 0.9) +
  facet_wrap(~ facet_label, ncol = layout$ncol, scales = "free_y") +
  scale_x_continuous(breaks = rank_map$rank_index, labels = rank_map$rank_label, expand = expansion(mult = c(0.03, 0.05))) +
  pp_theme(show_grid = FALSE) +
  labs(x = "Sample rank", y = "Value", colour = group_col)

if (nrow(key_label_df) > 0 && identical(label_strategy$direct_label_mode, "selected_key_samples")) {
  p <- p + geom_text(
    data = key_label_df,
    aes(label = .data[[sample_col]]),
    size = 1.7,
    hjust = -0.12,
    vjust = 0.45,
    show.legend = FALSE,
    check_overlap = TRUE
  )
}

if (!is.null(group_col)) {
  p <- p + pp_scale_color(groups = plot_df[[group_col]])
} else {
  p <- p + pp_scale_color(groups = plot_df$facet_label, guide = "none")
}

output_files <- pp_save_all(p, output_stem, preset = preset, width = layout$width_cm, height = layout$height_cm)
invisible(lapply(output_files, pp_assert_output))

qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec, list(status = label_strategy$status, message = label_strategy$message), palette_check, layout_check),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role)
)

pp_write_notes(notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c("main panel family shows integrated ranking plus selected key metrics", paste("key metrics included:", paste(key_metrics, collapse = ", ")), "full sample labels moved to label key sidecar", "remaining metrics should be placed in notes or extended figures"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Confirm that integrated score direction is higher-is-better",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "facet-discrete", name = "graphpad_discrete"),
  ordering = list(rule = "integrated score descending", sample_order = paste(sample_levels, collapse = ", ")),
  label_strategy = label_strategy, data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "facet-discrete", name = "graphpad_discrete"),
  ordering = list(rule = "integrated score descending", sample_order = sample_levels),
  qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)),
  data_summary = pp_data_summary(df), design_brief = design_brief, design_plan = design_plan,
  data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy,
  palette_plan = list(type = if (!is.null(group_col)) "group" else "facet", name = "graphpad_discrete"),
  sidecars = list(label_key = label_key_path))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
