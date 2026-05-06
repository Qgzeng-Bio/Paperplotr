# PaperPlotR PCA scatter template

suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "pca_scatter_todo"

# TODO: replace these column names with columns from your dataset.
pc1_col <- "TODO_PC1"
pc2_col <- "TODO_PC2"
group_col <- NULL
sample_label_col <- NULL
pc1_label <- "PC1 (TODO%)"
pc2_label <- "PC2 (TODO%)"
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
required_cols <- c(pc1_col, pc2_col, group_col, sample_label_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), call. = FALSE)
}

mapping <- aes(x = .data[[pc1_col]], y = .data[[pc2_col]])
if (!is.null(group_col)) {
  mapping <- aes(x = .data[[pc1_col]], y = .data[[pc2_col]], colour = .data[[group_col]])
}

p <- ggplot(df, mapping) +
  geom_hline(yintercept = 0, linewidth = 0.25, linetype = "dashed", colour = "#BFBFBF") +
  geom_vline(xintercept = 0, linewidth = 0.25, linetype = "dashed", colour = "#BFBFBF") +
  geom_point(size = 2.0, alpha = 0.85) +
  coord_equal() +
  theme_lab() +
  labs(x = pc1_label, y = pc2_label, colour = group_col)

if (!is.null(sample_label_col)) {
  p <- p + geom_text(aes(label = .data[[sample_label_col]]), nudge_x = 0.05, size = 2.2, show.legend = FALSE)
}

if (!is.null(group_col) && !is.null(semantic_colors)) {
  p <- p + scale_color_groupmap(values = semantic_colors, groups = df[[group_col]])
} else if (!is.null(group_col)) {
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
    paste("- PC1 column:", pc1_col),
    paste("- PC2 column:", pc2_col),
    paste("- group column:", ifelse(is.null(group_col), "none", group_col)),
    paste("- label column:", ifelse(is.null(sample_label_col), "none", sample_label_col)),
    "## Output Files",
    format_output_files(output_files),
    "- PaperPlotR functions: theme_lab(), scale_color_lab()/scale_color_groupmap(), save_lab_plot()",
    "- preset: nature_half",
    "- QA: check explained variance labels, sample label crowding, group colors, and aspect ratio"
  )
)
