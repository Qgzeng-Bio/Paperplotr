# Standalone Figure Report

## Generated

Created a publication-ready scientific figure using ggplot2 plus the standalone helper script in `scripts/paperplot_helpers.R`.

## Inputs

- Data: `data.csv`
- Script: `figure_script.R`

## Outputs

- PDF: `figures/example_YYYYMMDD-HHMMSS.pdf`
- PNG: `figures/example_YYYYMMDD-HHMMSS.png`
- Notes: `figures/example_YYYYMMDD-HHMMSS_notes.md`

## Template / Preset

- Template: `multi-metric-small-multiples-template.R`
- Preset: `nature`
- Helpers: `pp_theme()`, `pp_scale_color()`, `pp_save_plot()`, `pp_write_notes()`

## Design Decisions

- Used small multiples because the metrics have different units.
- Kept sample order shared across panels.
- Removed unnecessary gridlines.
- Used GraphPad-like color defaults.

## QA Checks

- PDF and PNG exist and have non-trivial file sizes.
- Panel sizes are consistent.
- No visible label/title/legend overlaps remain.
- Legend semantics are explicit.

## Remaining Issues

- Confirm final sample order with the manuscript text.
