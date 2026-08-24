# Standalone comparison boxplot template

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "comparison_boxplot_todo"
preset <- "cell_half"

group_col <- "TODO_group"
value_col <- "TODO_value"
y_label <- "TODO value with units"
semantic_colors <- NULL

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "comparison-boxplot-template",
  scientific_message = "Compare distributions across groups while preserving individual observations.",
  plot_type = "boxplot_with_points",
  group_var = group_col,
  output_preset = preset
)
metric_spec <- pp_metric_spec(metric = value_col, label = y_label, unit = "a.u.", direction = "neutral")

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, c(".pdf", ".png")), notes_path, metadata_path, qa_path))

if (!file.exists(input_path)) stop("Set input_path to an existing CSV file.", call. = FALSE)
df <- read.csv(input_path, check.names = FALSE)

missing_cols <- setdiff(c(group_col, value_col), names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

preset_values <- pp_output_preset(preset)
label_strategy <- pp_label_strategy(unique(df[[group_col]]), available_width_cm = preset_values$width_cm)
palette_check <- pp_validate_palette(df[[group_col]], "discrete")
layout <- pp_estimate_canvas_size(1, preset = preset)
layout_check <- pp_assess_layout_risk(1, plot_type = "comparison", label_strategy = label_strategy)

p <- ggplot(df, aes(x = .data[[group_col]], y = .data[[value_col]], fill = .data[[group_col]])) +
  geom_boxplot(width = 0.55, outlier.shape = NA, linewidth = 0.35, alpha = 0.78) +
  geom_jitter(aes(colour = .data[[group_col]]), width = 0.12, size = pp_point_size("normal"), alpha = 0.65, show.legend = FALSE) +
  pp_scale_fill(groups = df[[group_col]], values = semantic_colors, guide = "none") +
  pp_scale_color(groups = df[[group_col]], values = semantic_colors, guide = "none") +
  pp_theme(show_grid = FALSE) +
  labs(x = NULL, y = y_label)
p <- pp_adjust_margins_for_labels(p, label_strategy)

output_files <- pp_save_all_with_qa_loop(p, output_stem, preset = preset, qa_context = list(family = figure_spec$plot_type))
invisible(lapply(output_files, pp_assert_output))

qa_results <- pp_qa_preflight(figure_spec, metric_spec, label_strategy, palette_check, layout_check)
pp_write_notes(notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c("boxplot plus jitter shows distribution and individual observations", "GraphPad-like group colors", "no default gridlines"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Add statistical annotations only when comparisons are specified",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = "discrete", name = "graphpad_discrete"), ordering = list(rule = "input group order"),
  label_strategy = label_strategy, data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = "discrete", name = "graphpad_discrete"), ordering = list(rule = "input group order"),
  qa = list(status = pp_qa_status(qa_results)), data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
