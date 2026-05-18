# Standalone barplot template

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "barplot_todo"
preset <- "nature_half"

category_col <- "TODO_category"
value_col <- "TODO_value"
group_col <- NULL
error_col <- NULL
y_label <- "TODO value with units"

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "barplot-template",
  scientific_message = "Show summary values when raw distributions are unavailable.",
  plot_type = "summary_barplot",
  sample_id = category_col,
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

required_cols <- c(category_col, value_col, group_col, error_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

preset_values <- pp_output_preset(preset)
label_strategy <- pp_label_strategy(unique(df[[category_col]]), available_width_cm = preset_values$width_cm)
palette_check <- if (!is.null(group_col)) pp_validate_palette(df[[group_col]], "discrete") else pp_validate_palette(df[[category_col]], "discrete")
layout <- pp_estimate_canvas_size(1, preset = preset)
layout_check <- pp_assess_layout_risk(1, plot_type = "summary", label_strategy = label_strategy)

mapping <- aes(x = .data[[category_col]], y = .data[[value_col]])
if (!is.null(group_col)) mapping <- aes(x = .data[[category_col]], y = .data[[value_col]], fill = .data[[group_col]])

p <- ggplot(df, mapping) +
  pp_theme(show_grid = FALSE) +
  labs(x = NULL, y = y_label, fill = group_col)

if (!is.null(group_col)) {
  p <- p +
    geom_col(position = position_dodge(width = 0.72), width = 0.62, linewidth = 0.25, colour = "white") +
    pp_scale_fill(groups = df[[group_col]])
} else {
  p <- p +
    geom_col(aes(fill = .data[[category_col]]), width = 0.62, linewidth = 0.25, colour = "white") +
    pp_scale_fill(groups = df[[category_col]], guide = "none")
}

if (!is.null(error_col)) {
  p <- p + geom_errorbar(
    aes(ymin = .data[[value_col]] - .data[[error_col]], ymax = .data[[value_col]] + .data[[error_col]]),
    width = 0.18, linewidth = 0.3, position = position_dodge(width = 0.72)
  )
}
p <- pp_adjust_margins_for_labels(p, label_strategy)

output_files <- pp_save_all(p, output_stem, preset = preset)
invisible(lapply(output_files, pp_assert_output))

qa_results <- pp_qa_preflight(figure_spec, metric_spec, label_strategy, palette_check, layout_check)
pp_write_notes(notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c("barplot for summary values", "GraphPad-like fills", "x label strategy recorded"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Use dot/box/violin templates when raw distributions are available",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = "discrete", name = "graphpad_discrete"), ordering = list(rule = "input category order"),
  label_strategy = label_strategy, data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = "discrete", name = "graphpad_discrete"), ordering = list(rule = "input category order"),
  qa = list(status = pp_qa_status(qa_results)), data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
