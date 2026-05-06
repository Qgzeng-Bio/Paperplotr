# PaperPlotR correlation scatter template

suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "correlation_scatter_todo"

# TODO: replace these column names with columns from your dataset.
x_col <- "TODO_x"
y_col <- "TODO_y"
group_col <- NULL
x_label <- "TODO x label with units"
y_label <- "TODO y label with units"

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
required_cols <- c(x_col, y_col, group_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), call. = FALSE)
}

mapping <- aes(x = .data[[x_col]], y = .data[[y_col]])
if (!is.null(group_col)) {
  mapping <- aes(x = .data[[x_col]], y = .data[[y_col]], colour = .data[[group_col]])
}

p <- ggplot(df, mapping) +
  geom_point(size = 1.8, alpha = 0.8) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.45, colour = "#4D4D4D") +
  # TODO: add correlation text only after confirming the statistical method.
  theme_lab() +
  labs(x = x_label, y = y_label, colour = group_col)

if (!is.null(group_col)) {
  p <- p + scale_color_lab(palette = "main")
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
    paste("- x column:", x_col),
    paste("- y column:", y_col),
    paste("- group column:", ifelse(is.null(group_col), "none", group_col)),
    "## Output Files",
    format_output_files(output_files),
    "- PaperPlotR functions: theme_lab(), scale_color_lab(), save_lab_plot()",
    "- preset: nature_half",
    "- QA: check axis units, smoothing appropriateness, point overlap, and correlation text if added"
  )
)
