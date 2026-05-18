# Standalone Plotting Workflow

This file keeps the previous workflow filename for compatibility, but the workflow is standalone.

## Standard Steps

1. Load `ggplot2`.
2. Source `scripts/paperplot_helpers.R`.
3. Read input data.
4. Validate required columns.
5. Complete the scientific figure design brief.
6. Build a ggplot object with explicit geoms.
7. Apply `pp_theme(show_grid = FALSE)`.
8. Apply `pp_scale_color()`, `pp_scale_fill()`, or `pp_gradient_palette()` when needed.
9. Export with `pp_save_plot()`.
10. Validate output files and write notes with `pp_write_notes()`.
11. Inspect the rendered output against `visual-qa-gates.md`.

## Minimal Skeleton

```r
suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "figure_todo"
timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")

df <- read.csv(input_path, check.names = FALSE)

p <- ggplot(df, aes(x, y)) +
  geom_point(size = 1.8, alpha = 0.85) +
  pp_theme(show_grid = FALSE)

output_files <- c(pdf = paste0(output_stem, ".pdf"), png = paste0(output_stem, ".png"))
pp_stop_if_outputs_exist(c(output_files, notes_path))
pp_save_plot(p, output_files[["pdf"]], preset = "nature_half")
pp_save_plot(p, output_files[["png"]], preset = "nature_half")
pp_write_notes(notes_path, figure_id, input_path, output_files, "nature_half")
```
