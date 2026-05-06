# PaperPlotR barplot template

suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "barplot_todo"

# TODO: replace these column names with columns from your dataset.
category_col <- "TODO_category"
value_col <- "TODO_value"
group_col <- NULL
error_col <- NULL
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
required_cols <- c(category_col, value_col, group_col, error_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), call. = FALSE)
}

position <- position_dodge(width = 0.72)
mapping <- aes(x = .data[[category_col]], y = .data[[value_col]])
if (!is.null(group_col)) {
  mapping <- aes(x = .data[[category_col]], y = .data[[value_col]], fill = .data[[group_col]])
}

p <- ggplot(df, mapping) +
  geom_col(width = 0.62, position = position, colour = "white", linewidth = 0.18) +
  theme_lab() +
  labs(x = NULL, y = value_col, fill = group_col)

if (!is.null(error_col)) {
  p <- p +
    geom_errorbar(
      aes(ymin = .data[[value_col]] - .data[[error_col]], ymax = .data[[value_col]] + .data[[error_col]]),
      width = 0.18,
      linewidth = 0.28,
      position = position
    )
}

if (!is.null(group_col) && !is.null(semantic_colors)) {
  p <- p + scale_fill_groupmap(values = semantic_colors, groups = df[[group_col]])
} else if (!is.null(group_col)) {
  p <- p + scale_fill_lab(palette = "main")
} else {
  p <- p + scale_fill_lab(palette = "main", guide = "none")
}

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

save_lab_plot(p, output_files[["pdf"]], preset = "nature_half", device = pdf_device)
save_lab_plot(p, output_files[["png"]], preset = "nature_half", device = png_device)
if ("svg" %in% names(output_files)) {
  save_lab_plot(p, output_files[["svg"]], preset = "nature_half", device = "svglite")
}

write_notes(
  notes_path,
  c(
    "# Figure Notes",
    "",
    paste("- figure id:", figure_id),
    paste("- input data:", input_path),
    paste("- category column:", category_col),
    paste("- value column:", value_col),
    paste("- group column:", ifelse(is.null(group_col), "none", group_col)),
    paste("- error column:", ifelse(is.null(error_col), "none", error_col)),
    "## Output Files",
    format_output_files(output_files),
    "- PaperPlotR functions: theme_lab(), scale_fill_lab()/scale_fill_groupmap(), save_lab_plot()",
    "- preset: nature_half",
    "- QA: check category label density, error bars, legend placement, and bar width"
  )
)
