# PaperPlotR violin plus dot template

suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "violin_dot_todo"

# TODO: replace these column names with columns from your dataset.
group_col <- "TODO_group"
value_col <- "TODO_value"
facet_col <- NULL

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
required_cols <- c(group_col, value_col, facet_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), call. = FALSE)
}

p <- ggplot(df, aes(x = .data[[group_col]], y = .data[[value_col]], fill = .data[[group_col]])) +
  geom_violin(width = 0.9, alpha = 0.65, colour = NA) +
  geom_jitter(width = 0.12, size = 0.9, alpha = 0.55, colour = "#1F1F1F") +
  stat_summary(fun = median, geom = "point", shape = 23, size = 2, fill = "white", colour = "#1F1F1F") +
  scale_fill_lab(palette = "main", guide = "none") +
  theme_lab() +
  labs(x = NULL, y = value_col)

if (!is.null(facet_col)) {
  p <- p + facet_wrap(stats::as.formula(paste("~", facet_col)))
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
    paste("- facet column:", ifelse(is.null(facet_col), "none", facet_col)),
    "## Output Files",
    format_output_files(output_files),
    "- PaperPlotR functions: theme_lab(), scale_fill_lab(), save_lab_plot()",
    "- preset: cell_half",
    "- QA: check distribution readability, jitter density, facet spacing, and legend suppression"
  )
)
