# Standalone single-panel scientific figure template

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "single_panel_todo"
preset <- "nature_half"

x_col <- "TODO_x"
y_col <- "TODO_y"
group_col <- NULL
x_label <- "TODO x label with units"
y_label <- "TODO y label with units"

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "single-panel-template",
  scientific_message = "Show one primary x-y relationship without unnecessary visual noise.",
  plot_type = "single_panel_scatter",
  sample_id = x_col,
  group_var = group_col,
  output_preset = preset
)
metric_spec <- pp_metric_spec(metric = y_col, label = y_label, unit = "a.u.", direction = "neutral")

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, c(".pdf", ".png")), notes_path, metadata_path, qa_path))

if (!file.exists(input_path)) stop("Set input_path to an existing CSV file.", call. = FALSE)
df <- read.csv(input_path, check.names = FALSE)

required_cols <- c(x_col, y_col, group_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

preset_values <- pp_output_preset(preset)
label_strategy <- pp_label_strategy(unique(df[[x_col]]), available_width_cm = preset_values$width_cm)
palette_check <- if (!is.null(group_col)) pp_validate_palette(df[[group_col]], "discrete") else pp_qa_result("palette", "pass", "single-color scatter")
layout <- pp_estimate_canvas_size(1, preset = preset)
layout_check <- pp_assess_layout_risk(1, plot_type = "single_panel", label_strategy = label_strategy)

mapping <- aes(x = .data[[x_col]], y = .data[[y_col]])
if (!is.null(group_col)) mapping <- aes(x = .data[[x_col]], y = .data[[y_col]], colour = .data[[group_col]])

p <- ggplot(df, mapping) +
  geom_point(size = 1.8, alpha = 0.85) +
  pp_theme(show_grid = FALSE) +
  labs(x = x_label, y = y_label, colour = if (!is.null(group_col)) group_col else NULL)

if (!is.null(group_col)) p <- p + pp_scale_color(groups = df[[group_col]])
p <- pp_adjust_margins_for_labels(p, label_strategy)

output_files <- pp_save_all(p, output_stem, preset = preset)
invisible(lapply(output_files, pp_assert_output))

qa_results <- pp_qa_preflight(figure_spec, metric_spec, label_strategy, palette_check, layout_check)
pp_write_notes(
  notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c("single-panel layout", "GraphPad-like discrete color when grouped", "gridlines disabled by default"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Inspect rendered labels before manuscript use",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "none", name = "graphpad_discrete"),
  ordering = list(rule = "input order"), label_strategy = label_strategy, data_summary = pp_data_summary(df)
)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
pp_write_metadata(
  metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "none", name = "graphpad_discrete"),
  ordering = list(rule = "input order"), qa = list(status = pp_qa_status(qa_results)), data_summary = pp_data_summary(df)
)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
