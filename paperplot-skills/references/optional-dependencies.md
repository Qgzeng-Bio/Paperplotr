# Optional Dependencies

The core skill must continue to work with base R plus `ggplot2` only.

Optional packages may be considered later, but they must never become required for existing templates.

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
