# Export And Versioning

Default behavior is to preserve old figures. Never overwrite existing outputs unless the user explicitly requests it.

## Output Stem

Use a timestamped stem:

```r
timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
```

Recommended output paths:

```r
output_files <- c(
  pdf = paste0(output_stem, ".pdf"),
  png = paste0(output_stem, ".png")
)
```

Add SVG or TIFF when requested or when the target workflow benefits from them.

## No-Overwrite Check

Check all planned files before rendering:

```r
stop_if_outputs_exist <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) > 0) {
    stop(
      paste("Refusing to overwrite existing output files:", paste(existing, collapse = ", ")),
      call. = FALSE
    )
  }
}
```

Call this before any export:

```r
stop_if_outputs_exist(c(output_files, notes_path))
```

## Formats

- PDF: preferred vector output for manuscript review.
- SVG: useful for later vector editing when `svglite` is available.
- PNG: quick preview and web/share output.
- TIFF: submission system output when explicitly requested.

Use 600 dpi for raster output unless user or journal instructions require another value.

## PaperPlotR Export Helpers

Prefer:

```r
save_lab_plot(plot, filename, preset = "nature_half", device = "ragg_png")
save_lab(plot, filename, spec = "4.9x4.9", ncol = 2, nrow = 2, journal = "nature")
```

Use `device = "quartz_pdf"` for macOS PDF when native font handling is needed. Use `ragg_png` or `ragg_tiff` when `ragg` is installed. Use `svglite` for SVG when installed.

## Notes

Write a sidecar markdown file for every render batch. It should include:

- Figure ID.
- Input data.
- Script path.
- Output files.
- PaperPlotR functions and presets.
- Panel mapping.
- QA checklist.
- Remaining issues.
