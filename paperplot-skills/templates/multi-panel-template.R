# Standalone multi-panel faceted figure template

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "multi_panel_todo"
preset <- "nature"

x_col <- "TODO_x"
y_col <- "TODO_y"
panel_col <- "TODO_panel"
group_col <- NULL
x_label <- "TODO x label with units"
y_label <- "TODO y label with units"

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "multi-panel-template",
  scientific_message = "Compare related panels with a consistent faceted encoding.",
  plot_type = "faceted_scatter",
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

required_cols <- c(x_col, y_col, panel_col, group_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

n_panels <- length(unique(df[[panel_col]]))
layout <- pp_recommend_facet_grid(n_panels, plot_type = "small_multiples", complex = TRUE)
label_strategy <- pp_label_strategy(unique(df[[x_col]]), available_width_cm = layout$width_cm / max(1, layout$ncol))
palette_check <- if (!is.null(group_col)) pp_validate_palette(df[[group_col]], "discrete") else pp_qa_result("palette", "pass", "no group colors")
layout_check <- pp_assess_layout_risk(n_panels, plot_type = "small_multiples", label_strategy = label_strategy)

mapping <- aes(x = .data[[x_col]], y = .data[[y_col]])
if (!is.null(group_col)) mapping <- aes(x = .data[[x_col]], y = .data[[y_col]], colour = .data[[group_col]])

p <- ggplot(df, mapping) +
  geom_point(size = pp_point_size("normal"), alpha = 0.82) +
  facet_wrap(stats::as.formula(paste("~", panel_col)), ncol = layout$ncol, scales = "free_y") +
  pp_theme(show_grid = FALSE) +
  labs(x = x_label, y = y_label, colour = group_col)

if (!is.null(group_col)) p <- p + pp_scale_color(groups = df[[group_col]])
p <- pp_adjust_margins_for_labels(p, label_strategy)

output_files <- pp_save_all_with_qa_loop(p, output_stem, preset = preset, qa_context = list(family = figure_spec$plot_type), width = layout$width_cm, height = layout$height_cm)
invisible(lapply(output_files, pp_assert_output))

qa_results <- pp_qa_preflight(figure_spec, metric_spec, label_strategy, palette_check, layout_check)
pp_write_notes(
  notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c(paste("faceted multi-panel layout:", layout$ncol, "x", layout$nrow), "standalone ggplot2 facets instead of external composition packages", "panel sizes chosen with pp_recommend_layout()"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "For unrelated geoms per panel, create separate scripts or use a custom grid workflow",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "none", name = "graphpad_discrete"),
  ordering = list(rule = "input order"), label_strategy = label_strategy, data_summary = pp_data_summary(df)
)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "none", name = "graphpad_discrete"),
  ordering = list(rule = "input order"), qa = list(status = pp_qa_status(qa_results)), data_summary = pp_data_summary(df))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
