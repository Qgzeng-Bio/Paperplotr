# Optional Dependencies

Basic preview remains available with base R plus `ggplot2`. Formal delivery
requires the capabilities reported by `scripts/check-environment.R`: Arial
Regular/Bold/Italic, JSON, vector/raster backends, Python QA and PDF tools.
Missing capabilities are reported, never silently certified.

Low-level legacy helpers retain their compatibility behavior. Production
templates use the explicit contract in `production-render-contract.md`.

## Future Optional Tier

- `ggrepel`: label repulsion for dense direct labels.
- `ragg`: high-quality raster output.
- `svglite`: SVG output for web and vector editing workflows.
- `scales`: breaks, labels, transforms, and palette utilities.
- `patchwork`: complex multi-plot composition when facets are insufficient.

## Rules

- Optional package use must be guarded by `requireNamespace(..., quietly = TRUE)`.
- Each optional feature needs a deterministic fallback.
- Metadata and notes must record when an optional path is used.
