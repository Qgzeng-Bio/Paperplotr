#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
row_col <- "TODO_row"
column_col <- "TODO_column"
effect_col <- "TODO_effect"
support_col <- "TODO_support"
sig_col <- NULL
row_group_col <- NULL
row_label_col <- NULL

figure_id <- "compact_dot_matrix_enrichment"
figure_role <- "main"
scientific_message <- "Summarize a categorical enrichment matrix with effect direction, support count, significance, and optional row annotation."
effect_label <- "Effect"
support_label <- "Support (n)"
sig_threshold <- 0.05
max_rows <- 35
preset <- "nature_half"

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)

required_cols <- c(row_col, column_col, effect_col, support_col)
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
if (!is.null(sig_col) && !sig_col %in% names(df)) stop("significance column not found: ", sig_col, call. = FALSE)
if (!is.null(row_group_col) && !row_group_col %in% names(df)) stop("row group column not found: ", row_group_col, call. = FALSE)
if (!is.null(row_label_col) && !row_label_col %in% names(df)) stop("row label column not found: ", row_label_col, call. = FALSE)

df[[effect_col]] <- as.numeric(df[[effect_col]])
df[[support_col]] <- pmax(as.numeric(df[[support_col]]), 0)
if (any(!is.finite(df[[effect_col]]))) stop("effect column contains non-finite values.", call. = FALSE)
if (any(!is.finite(df[[support_col]]))) stop("support column contains non-finite values.", call. = FALSE)

if (is.null(sig_col)) {
  df$pp_sig_flag <- FALSE
} else {
  sig_value <- df[[sig_col]]
  if (is.logical(sig_value)) {
    df$pp_sig_flag <- sig_value
  } else if (is.numeric(sig_value)) {
    df$pp_sig_flag <- sig_value <= sig_threshold
  } else {
    df$pp_sig_flag <- tolower(as.character(sig_value)) %in% c("true", "t", "yes", "y", "sig", "significant", "fdr<0.05", "fdr < 0.05")
  }
  df$pp_sig_flag[is.na(df$pp_sig_flag)] <- FALSE
}

row_score <- tapply(abs(df[[effect_col]]) * log1p(df[[support_col]]), df[[row_col]], max, na.rm = TRUE)
row_levels <- names(sort(row_score, decreasing = TRUE))
if (length(row_levels) > max_rows) {
  keep_rows <- row_levels[seq_len(max_rows)]
  df <- df[df[[row_col]] %in% keep_rows, , drop = FALSE]
  row_levels <- keep_rows
}
row_levels_plot <- rev(row_levels)
column_levels <- unique(as.character(df[[column_col]]))

label_lookup <- tapply(if (is.null(row_label_col)) as.character(df[[row_col]]) else as.character(df[[row_label_col]]), df[[row_col]], function(x) x[which.max(nchar(x))])
label_values <- unname(label_lookup[row_levels_plot])
label_values[is.na(label_values)] <- row_levels_plot[is.na(label_values)]

df$pp_x <- match(as.character(df[[column_col]]), column_levels)
df$pp_y <- match(as.character(df[[row_col]]), row_levels_plot)
bg <- expand.grid(pp_x = seq_along(column_levels), pp_y = seq_along(row_levels_plot))

row_info <- data.frame(
  row = row_levels_plot,
  pp_y = seq_along(row_levels_plot),
  stringsAsFactors = FALSE
)
if (!is.null(row_group_col)) {
  group_lookup <- tapply(as.character(df[[row_group_col]]), df[[row_col]], function(x) x[which.max(tabulate(match(x, unique(x))))])
  row_info$row_group <- unname(group_lookup[row_info$row])
}

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "compact-dot-matrix-enrichment-template",
  figure_role = figure_role,
  scientific_message = scientific_message,
  plot_type = "compact_dot_matrix_enrichment",
  sample_id = row_col,
  group_var = row_group_col,
  output_preset = preset
)
metric_spec <- pp_metric_spec(
  metric = c(effect_col, support_col, if (!is.null(sig_col)) sig_col else "significance_flag"),
  label = c(effect_label, support_label, if (!is.null(sig_col)) "significance" else "significance flag"),
  unit = c("unitless", "count", "unitless"),
  direction = c("neutral", "neutral", "lower_better"),
  transform = c("none", "none", "none"),
  role = c("effect_size", "support", "significance")
)

preset_values <- pp_output_preset(preset)
label_strategy <- pp_label_strategy(label_values, available_width_cm = preset_values$width_cm * 0.42)
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = length(label_values), n_legend_entries = 3)
design_brief <- pp_design_brief(
  scientific_message = scientific_message,
  figure_role = figure_role,
  main_comparison = list(row = row_col, column = column_col, effect = effect_col),
  data_roles = list(row = "matrix row", column = "matrix column", effect = "fill color", support = "point area", significance = "point border", row_group = row_group_col),
  metric_semantics = list(metrics = metric_spec),
  acceptable_simplifications = c("Rows are limited to max_rows by effect-support score.", "Row labels may be shortened when row_label_col is provided."),
  must_show = c(row_col, column_col, effect_col, support_col),
  may_move_to_metadata = c("rows beyond max_rows", "full row labels", "full support denominators")
)
design_plan <- pp_design_plan(
  chart_family = "compact_dot_matrix_enrichment",
  figure_role = figure_role,
  layout_plan = list(type = "compact_matrix_dot", row_count = length(row_levels), column_count = length(column_levels)),
  label_strategy = label_strategy,
  palette_plan = list(effect_palette = "blue_red_diverging_centered_at_zero", support_role = "dot area", significance_role = "border"),
  statistical_plan = list(sig_threshold = sig_threshold, row_filter = "rank by max(abs(effect) * log1p(support))"),
  visible_simplifications = design_brief$acceptable_simplifications,
  risks = c("small non-significant dots may be subtle", "area encoding should not replace exact event counts in text")
)

effect_limit <- max(abs(df[[effect_col]]), na.rm = TRUE)
if (!is.finite(effect_limit) || effect_limit == 0) effect_limit <- 1
effect_limit <- ceiling(effect_limit)
side_colors <- NULL
if (!is.null(row_group_col)) {
  groups <- unique(row_info$row_group)
  side_colors <- setNames(pp_palette(length(groups), palette = "graphpad_muted"), groups)
}

plot <- ggplot() +
  geom_tile(
    data = bg,
    aes(x = pp_x, y = pp_y),
    width = 0.82,
    height = 0.78,
    fill = "#F6F6F3",
    colour = "white",
    linewidth = 0.35
  )
if (!is.null(row_group_col)) {
  plot <- plot +
    geom_segment(
      data = row_info,
      aes(x = 0.38, xend = 0.38, y = pp_y - 0.32, yend = pp_y + 0.32, colour = row_group),
      linewidth = 1.8,
      lineend = "round"
    ) +
    scale_colour_manual(values = side_colors, name = row_group_col)
}
plot <- plot +
  geom_point(
    data = df[!df$pp_sig_flag, , drop = FALSE],
    aes(x = pp_x, y = pp_y, size = .data[[support_col]], fill = .data[[effect_col]]),
    shape = 21,
    colour = "#8F8F8F",
    stroke = 0.18,
    alpha = 0.94
  ) +
  geom_point(
    data = df[df$pp_sig_flag, , drop = FALSE],
    aes(x = pp_x, y = pp_y, size = .data[[support_col]], fill = .data[[effect_col]]),
    shape = 21,
    colour = "black",
    stroke = 0.48,
    alpha = 0.98
  ) +
  scale_fill_gradientn(
    colours = c("#3568A8", "#E9EEF5", "#FAF7F2", "#F0B19D", "#C7352E"),
    limits = c(-effect_limit, effect_limit),
    oob = scales::squish,
    name = effect_label
  ) +
  scale_size_area(max_size = 5.3, name = support_label) +
  scale_x_continuous(
    breaks = seq_along(column_levels),
    labels = column_levels,
    position = "top",
    expand = expansion(mult = c(0.01, 0.02))
  ) +
  scale_y_continuous(
    breaks = seq_along(row_levels_plot),
    labels = label_values,
    expand = expansion(mult = c(0.025, 0.025))
  ) +
  coord_cartesian(xlim = c(0.25, length(column_levels) + 0.45), clip = "off") +
  labs(x = NULL, y = NULL) +
  pp_theme(base_size = 7, show_grid = FALSE) +
  theme(
    axis.line = element_blank(),
    axis.ticks = element_blank(),
    axis.text.x = element_text(face = "bold", margin = margin(b = 2)),
    axis.text.y = element_text(hjust = 1, margin = margin(r = 4)),
    panel.border = element_rect(fill = NA, colour = "#2D2D2D", linewidth = 0.35),
    legend.position = "right",
    legend.box = "vertical",
    plot.margin = margin(3, 3, 3, 5)
  ) +
  guides(
    fill = guide_colourbar(barwidth = unit(3.2, "mm"), barheight = unit(24, "mm"), title.position = "top"),
    size = guide_legend(title.position = "top")
  )

qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role),
  pp_qa_result("compact_dot_matrix_semantics", "pass", "Effect, support, significance, and row annotation use distinct visual channels.")
)
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)

outputs <- pp_save_all(plot, output_stem, preset = preset, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
data_profile <- pp_data_profile(df, group_col = row_group_col, value_col = effect_col)
pp_write_notes(
  notes_path,
  figure_id = figure_id,
  input_path = input_csv,
  output_files = outputs,
  preset = preset,
  design_decisions = c(
    "pattern: compact-dot-matrix-enrichment",
    "Background tiles define a compact lookup grid.",
    "Fill color encodes signed effect and is centered at zero.",
    "Point area encodes support count.",
    "Point border encodes significance."
  ),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Confirm effect units, support denominator, and significance threshold before final submission.",
  figure_spec = figure_spec,
  metric_spec = metric_spec,
  layout = design_plan$layout_plan,
  palette = design_plan$palette_plan,
  label_strategy = label_strategy,
  data_summary = data_profile,
  design_brief = design_brief,
  design_plan = design_plan
)
pp_write_metadata(
  metadata_path,
  figure_spec,
  metric_spec,
  outputs,
  layout = design_plan$layout_plan,
  palette = design_plan$palette_plan,
  qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)),
  data_summary = data_profile,
  design_brief = design_brief,
  design_plan = design_plan,
  data_profile = data_profile,
  visual_budget = visual_budget,
  label_strategy = label_strategy,
  ordering = list(row_order = row_levels, column_order = column_levels)
)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
