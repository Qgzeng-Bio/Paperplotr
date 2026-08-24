# Standalone heatmap template

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "heatmap_todo"
preset <- "nature"

x_col <- "TODO_x"
y_col <- "TODO_y"
value_col <- "TODO_value"
value_label <- "TODO value"

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "heatmap-template",
  scientific_message = "Show matrix-like relative patterns with one explicit continuous value scale.",
  plot_type = "heatmap",
  sample_id = x_col,
  output_preset = preset
)
metric_spec <- pp_metric_spec(metric = value_col, label = value_label, unit = "%", direction = "neutral")

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, c(".pdf", ".png")), notes_path, metadata_path, qa_path))

if (!file.exists(input_path)) stop("Set input_path to an existing CSV file.", call. = FALSE)
df <- read.csv(input_path, check.names = FALSE)

missing_cols <- setdiff(c(x_col, y_col, value_col), names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

preset_values <- pp_output_preset(preset)
label_strategy <- pp_label_strategy(unique(df[[x_col]]), available_width_cm = preset_values$width_cm)
palette_check <- pp_validate_palette(variable_type = "continuous", palette = "graphpad_heatmap")
layout <- pp_estimate_canvas_size(1, plot_type = "heatmap", complex = TRUE, preset = preset)
layout_check <- pp_assess_layout_risk(1, plot_type = "heatmap", label_strategy = label_strategy)

p <- ggplot(df, aes(x = .data[[x_col]], y = .data[[y_col]], fill = .data[[value_col]])) +
  geom_tile(colour = NA, linewidth = 0) +
  scale_fill_gradientn(
    colours = pp_gradient_palette(256, palette = "graphpad_heatmap"),
    name = value_label,
    guide = guide_colorbar(barheight = grid::unit(28, "mm"), barwidth = grid::unit(3.5, "mm"))
  ) +
  pp_theme(show_grid = FALSE) +
  theme(axis.ticks = element_blank(), axis.line = element_blank()) +
  labs(x = NULL, y = NULL)
p <- pp_adjust_margins_for_labels(p, label_strategy)

output_files <- pp_save_all_with_qa_loop(p, output_stem, preset = preset, qa_context = list(family = figure_spec$plot_type))
invisible(lapply(output_files, pp_assert_output))

qa_results <- pp_qa_preflight(figure_spec, metric_spec, label_strategy, palette_check, layout_check)
pp_write_notes(notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c("pattern: correlation-heatmap", "GraphPad-like continuous heatmap palette", "single color scale", "cell borders suppressed to avoid gridline burden", "no per-cell labels by default"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Use small multiples if original metric units matter more than relative pattern",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = "continuous", name = "graphpad_heatmap"), ordering = list(rule = "input order"),
  label_strategy = label_strategy, data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = "continuous", name = "graphpad_heatmap"), ordering = list(rule = "input order"),
  qa = list(status = pp_qa_status(qa_results)), data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
