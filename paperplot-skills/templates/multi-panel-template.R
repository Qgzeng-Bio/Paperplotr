# PaperPlotR multi-panel figure template

suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "multi_panel_todo"

# TODO: replace these column names and panel definitions with your dataset.
x_col <- "TODO_x"
y_col <- "TODO_y"
group_col <- NULL

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

p1 <- ggplot(df, mapping) +
  geom_point(size = 1.5, alpha = 0.85) +
  theme_lab() +
  labs(title = "Panel a", x = x_col, y = y_col)

p2 <- ggplot(df, mapping) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.4, colour = "#4D4D4D") +
  geom_point(size = 1.2, alpha = 0.65) +
  theme_lab() +
  labs(title = "Panel b", x = x_col, y = y_col)

p3 <- ggplot(df, aes(x = .data[[x_col]])) +
  geom_histogram(bins = 30, fill = "#1F77B4", colour = "white", linewidth = 0.15) +
  theme_lab() +
  labs(title = "Panel c", x = x_col, y = "Count")

p4 <- ggplot(df, aes(x = .data[[y_col]])) +
  geom_histogram(bins = 30, fill = "#D55E00", colour = "white", linewidth = 0.15) +
  theme_lab() +
  labs(title = "Panel d", x = y_col, y = "Count")

if (!is.null(group_col)) {
  p1 <- p1 + scale_color_lab(palette = "main")
  p2 <- p2 + scale_color_lab(palette = "main", guide = "none")
}

combo <- layout_lab(
  p1, p2, p3, p4,
  ncol = 2,
  guides = "collect",
  tag_levels = "a",
  tag_size = 9,
  tag_face = "bold",
  tag_position = c(0, 1)
)

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

save_lab(combo, output_files[["pdf"]], spec = "4.9x4.9", ncol = 2, nrow = 2, journal = "nature", device = pdf_device)
save_lab(combo, output_files[["png"]], spec = "4.9x4.9", ncol = 2, nrow = 2, journal = "nature", device = png_device)
if ("svg" %in% names(output_files)) {
  save_lab(combo, output_files[["svg"]], spec = "4.9x4.9", ncol = 2, nrow = 2, journal = "nature", device = "svglite")
}

write_notes(
  notes_path,
  c(
    "# Figure Notes",
    "",
    paste("- figure id:", figure_id),
    paste("- input data:", input_path),
    "## Output Files",
    format_output_files(output_files),
    "- PaperPlotR functions: theme_lab(), scale_color_lab(), layout_lab(), save_lab()",
    "- preset: spec 4.9x4.9, 2x2, journal nature",
    "",
    "## Panel Mapping",
    "- panel a: TODO describe panel a",
    "- panel b: TODO describe panel b",
    "- panel c: TODO describe panel c",
    "- panel d: TODO describe panel d",
    "",
    "## QA",
    "- Check panel labels, legend collection, spacing, axis density, and caption consistency."
  )
)
