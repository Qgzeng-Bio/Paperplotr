# PaperPlotR Workflow

Use PaperPlotR as the standard layer around ordinary `ggplot2` code. The agent should not hide the plot logic. It should make the data, aesthetics, panels, export settings, and QA traceable.

## Standard Steps

1. Load `ggplot2` and `PaperPlotR`.
2. Read input data from a user-provided path.
3. Validate required columns before plotting.
4. Build a regular `ggplot` object with explicit geoms.
5. Apply `theme_lab()`.
6. Apply `scale_*_lab()` for palette-driven colors or `scale_*_groupmap()` for semantic group colors.
7. Use `layout_lab()` for multi-panel composition.
8. Export with `save_lab()` or `save_lab_plot()`.
9. Validate output files.
10. Write sidecar notes.

## Recommended R Skeleton

```r
suppressPackageStartupMessages({
  library(ggplot2)
  library(PaperPlotR)
})

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "figure_todo"

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_path)) {
  stop("Set input_path to an existing data file.", call. = FALSE)
}

df <- read.csv(input_path, check.names = FALSE)

required_cols <- c("TODO_x", "TODO_y")
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), call. = FALSE)
}

p <- ggplot(df, aes(.data[["TODO_x"]], .data[["TODO_y"]])) +
  geom_point(size = 1.8, alpha = 0.85) +
  theme_lab()

pdf_path <- paste0(output_stem, ".pdf")
png_path <- paste0(output_stem, ".png")

if (file.exists(pdf_path) || file.exists(png_path) || file.exists(notes_path)) {
  stop("Refusing to overwrite existing output files.", call. = FALSE)
}

pdf_device <- if (identical(Sys.info()[["sysname"]], "Darwin")) "quartz_pdf" else "pdf"
png_device <- if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"

save_lab_plot(p, pdf_path, preset = "nature_half", device = pdf_device)
save_lab_plot(p, png_path, preset = "nature_half", device = png_device)

writeLines(
  c(
    "# Figure Notes",
    "",
    paste("- figure id:", figure_id),
    paste("- input:", input_path),
    paste("- outputs:", paste(c(pdf_path, png_path), collapse = ", ")),
    "- PaperPlotR functions: theme_lab(), save_lab_plot()",
    "- QA: output files were rendered with PaperPlotR validation"
  ),
  notes_path
)
```

## Export Rule

Do not use bare `ggsave()` by default. Prefer `save_lab()` or `save_lab_plot()` so PaperPlotR controls size presets, journal presets, minimum text validation, device handling, and output validation.

Use bare `ggsave()` only when a specific object or device is unsupported by PaperPlotR helpers. If this happens, document the reason in the notes file.

## Semantic Color Rule

Use `scale_*_groupmap()` when group labels must keep stable meanings across panels. Prefer a user-provided named color vector for project-specific semantics. Use `scale_*_lab()` when a generic discrete palette is enough.

## Multi-Panel Rule

Use `layout_lab()` for multi-panel figures. Default panel tags should be lowercase bold letters unless the user or target journal requires another style.
