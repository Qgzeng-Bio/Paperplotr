# PaperPlotR comparison boxplot template

suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "comparison_boxplot_todo"

# TODO: replace these column names with columns from your dataset.
group_col <- "TODO_group"
value_col <- "TODO_value"
semantic_colors <- NULL

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

stop_if_outputs_exist <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) > 0) {
    stop(
      paste("Refusing to overwrite existing output files:", paste(existing, collapse = ", ")),
      call. = FALSE
    )
  }
}

write_notes <- function(path, lines) {
  writeLines(lines, con = path)
}

format_output_files <- function(paths) {
  sizes <- file.info(unname(paths))[["size"]]
  paste0("- ", names(paths), ": ", unname(paths), " (", sizes, " bytes)")
}

if (!file.exists(input_path)) {
  stop("Set input_path to an existing CSV file before running this template.", call. = FALSE)
}

df <- read.csv(input_path, check.names = FALSE)
required_cols <- c(group_col, value_col)
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), call. = FALSE)
}

# Optional: add annotation_df with columns xmin, xmax, y_position, annotation.
annotation_df <- NULL

p <- ggplot(df, aes(x = .data[[group_col]], y = .data[[value_col]], fill = .data[[group_col]])) +
  geom_boxplot(width = 0.55, outlier.shape = NA, linewidth = 0.3, alpha = 0.85) +
  geom_jitter(width = 0.12, size = 1.2, alpha = 0.65, shape = 21, colour = "#1F1F1F") +
  theme_lab() +
  labs(x = NULL, y = value_col, fill = group_col)

if (!is.null(semantic_colors)) {
  p <- p + scale_fill_groupmap(values = semantic_colors, groups = df[[group_col]])
} else {
  p <- p + scale_fill_lab(palette = "main", guide = "none")
}

if (!is.null(annotation_df)) {
  p <- p +
    geom_segment(
      data = annotation_df,
      aes(x = xmin, xend = xmax, y = y_position, yend = y_position),
      inherit.aes = FALSE,
      linewidth = 0.25
    ) +
    geom_text(
      data = annotation_df,
      aes(x = (xmin + xmax) / 2, y = y_position, label = annotation),
      inherit.aes = FALSE,
      vjust = -0.3,
      size = 2.4
    )
}

# Optional PaperPlotR helper route, if you prefer its high-level comparison API:
# p <- plot_box_paper(df, TODO_group, TODO_value, palette = "main")

pdf_device <- if (identical(Sys.info()[["sysname"]], "Darwin")) "quartz_pdf" else "pdf"
png_device <- if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"

output_files <- c(
  pdf = paste0(output_stem, ".pdf"),
  png = paste0(output_stem, ".png")
)
if (requireNamespace("svglite", quietly = TRUE)) {
  output_files <- c(output_files, svg = paste0(output_stem, ".svg"))
}

stop_if_outputs_exist(c(output_files, notes_path))

save_lab_plot(p, output_files[["pdf"]], preset = "cell_half", device = pdf_device)
save_lab_plot(p, output_files[["png"]], preset = "cell_half", device = png_device)
if ("svg" %in% names(output_files)) {
  save_lab_plot(p, output_files[["svg"]], preset = "cell_half", device = "svglite")
}

write_notes(
  notes_path,
  c(
    "# Figure Notes",
    "",
    paste("- figure id:", figure_id),
    paste("- input data:", input_path),
    paste("- group column:", group_col),
    paste("- value column:", value_col),
    "## Output Files",
    format_output_files(output_files),
    "- PaperPlotR functions: theme_lab(), scale_fill_lab()/scale_fill_groupmap(), save_lab_plot()",
    "- preset: cell_half",
    "- QA: check group order, point overlap, annotation placement, text size, and output sizes"
  )
)
