# PaperPlotR

[![R-CMD-check](https://github.com/Qgzeng-Bio/Paperplotr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Qgzeng-Bio/Paperplotr/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/Qgzeng-Bio/Paperplotr/actions/workflows/lint.yaml/badge.svg)](https://github.com/Qgzeng-Bio/Paperplotr/actions/workflows/lint.yaml)
[![test-coverage](https://github.com/Qgzeng-Bio/Paperplotr/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/Qgzeng-Bio/Paperplotr/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/gh/Qgzeng-Bio/Paperplotr/graph/badge.svg)](https://app.codecov.io/gh/Qgzeng-Bio/Paperplotr)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

`PaperPlotR` is an R package for publication-ready scientific figures built on
top of `ggplot2`. It does not replace `ggplot2`; it standardizes the parts of a
figure workflow that are often repeated across papers and reports:

- plot themes
- panel and figure sizing
- color palettes and semantic color mappings
- multi-panel composition
- export presets
- lightweight comparison-plot helpers

## Installation

Install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("Qgzeng-Bio/Paperplotr")

library(PaperPlotR)
```

Or install from the package source directory during local development:

```r
install.packages("devtools")
devtools::install(".")

library(PaperPlotR)
```

## Core Workflow

The intended workflow has five steps:

1. Build a single plot in `ggplot2`
2. Apply `theme_lab()` for consistent styling
3. Apply `scale_*_lab()` or `scale_*_groupmap()` for consistent color use
4. Combine panels with `layout_lab()`
5. Export with `save_lab()` or `save_lab_plot()`

The package focuses on standardization rather than automatic plotting.

## Quick Start

```r
library(PaperPlotR)
library(ggplot2)

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point(size = 2.2) +
  scale_color_lab(palette = "main") +
  theme_lab()

save_lab(
  plot = p,
  filename = "figures/scatter.png",
  spec = "4.9x4.9",
  journal = "nature"
)
```

## Main Interfaces

### Themes

Use `theme_lab()` to apply a compact scientific theme:

```r
p + theme_lab(base_size = 7, line_width = 0.35)
```

### Figure Sizing

Inspect the built-in figure specification helpers:

```r
available_fig_specs()
panel_size("4.9x2")
get_fig_size_cm("4.9x2", ncol = 3, nrow = 1)
journal_preset("cell")
recommend_panel_spec(n_panels = 4)
```

For dense multi-panel figures, `recommend_panel_spec()` provides a starting
point and can flag cases where splitting a figure is likely to be clearer.

You can also register custom figure and export presets at runtime:

```r
register_fig_spec(
  name = "6x4",
  panel_w_cm = 6,
  panel_h_cm = 4,
  layout_hint = "Wide single-panel figures"
)

register_journal_preset(
  name = "journal_x",
  figure_width_cm = 16.5,
  base_size_pt = 8
)

register_output_preset(
  name = "journal_x_half",
  journal = "journal_x",
  width_cm = 8.2,
  height_cm = 6
)
```

### Palettes and Semantic Colors

Use `scale_*_lab()` for palette-driven color assignment:

```r
ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) +
  geom_boxplot() +
  scale_fill_lab(palette = "prism_light") +
  theme_lab()
```

Use `scale_*_groupmap()` when category names should retain stable colors across
plots:

```r
df <- data.frame(
  condition = c("Control", "Treatment", "WT"),
  value = c(0.95, 1.32, 1.10)
)

ggplot(df, aes(condition, value, fill = condition)) +
  geom_col(width = 0.75) +
  scale_fill_groupmap(dictionary = "default") +
  theme_lab()
```

The built-in default semantic dictionary is intentionally generic. Register your
own palettes and semantic dictionaries for project-specific groups:

```r
register_palette(
  name = "my_discrete",
  values = c("#1B3A57", "#2E6F95", "#58A4B0")
)

register_group_dictionary(
  name = "study_groups",
  values = c(Control = "#4D4D4D", Treatment = "#D55E00", Rescue = "#009E73")
)
```

### Layout and Export

Combine panels with `layout_lab()`:

```r
combo <- layout_lab(p1, p2, p3, ncol = 3, guides = "collect")
```

Export by canonical panel specification with `save_lab()`:

```r
save_lab(
  plot = combo,
  filename = "figures/combo.png",
  spec = "4.9x2",
  ncol = 3,
  journal = "cell",
  device = "ragg_png"
)
```

Or export by named output preset with `save_lab_plot()`:

```r
save_lab_plot(
  plot = combo,
  filename = "figures/combo_half.png",
  preset = "nature_half",
  device = "svglite"
)
```

For PDF output on macOS, `device = "quartz_pdf"` can be useful when native font
handling is more reliable than Cairo-based PDF devices. Exports are checked by
default so missing or suspiciously small files fail early.

### Comparison Plots

For common manuscript-style grouped comparisons, use:

- `plot_box_paper()`
- `plot_violin_paper()`
- `plot_dot_paper()`

You can also assemble the layers manually:

- `position_paper_jitter()`
- `layer_points_paper()`
- `layer_summary_paper()`
- `layer_signif_paper()`

Example:

```r
df <- data.frame(
  condition = rep(c("Control", "Treatment"), each = 12),
  value = c(rnorm(12, 5, 0.4), rnorm(12, 6.1, 0.5))
)

plot_box_paper(
  data = df,
  x = condition,
  y = value,
  dictionary = "default",
  show_points = TRUE,
  show_summary = TRUE,
  show_signif = TRUE,
  comparisons = list(c("Control", "Treatment"))
)
```

## Example Gallery

See `vignette("gallery", package = "PaperPlotR")` for a compact visual workflow
covering semantic colors, tagged multi-panel layouts, and explicit export
devices.

To generate a small gallery of reusable example figures:

```r
paths <- render_paperplotr_examples("figures/paperplotr_gallery")
print(paths)
```

## Development

Typical development commands:

```r
devtools::document()
devtools::test()
```

Command-line validation:

```bash
R CMD build .
R CMD check --no-manual PaperPlotR_*.tar.gz
```
