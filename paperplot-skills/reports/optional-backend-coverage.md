# Optional Backend Coverage

This report records the 9.0 optional-backend layer. Optional backends are not
hard dependencies; they are controlled capability tiers for specialized
scientific figures.

## Coverage Summary

- Optional backend recipe entries: 10.
- Specialized reference entries: 2.
- Reference-only entries: 5.
- Specialized diagnostic source scripts in the R replica benchmark: 45.
- Core skill remains base R + ggplot2 + `scripts/paperplot_helpers.R`.

## Backend Families

| Family | Backend tier | Skill behavior |
|---|---|---|
| Complex heatmap / annotation heatmap | `ComplexHeatmap` optional | Use ggplot2 tile fallback unless complex annotations are required. |
| Circos / chord / circular genome | `circlize` optional | Use reference recipe and design plan when package/data are missing. |
| Spatial map | `sf` optional | Use longitude/latitude scatter fallback when map geometry is unavailable. |
| Phylogenetic tree | `ggtree` / `treeio` optional | Use segment diagnostic fallback; do not fake true tree layout without tree data. |
| Network | `igraph` / `ggraph` optional | Use edge-list or adjacency summaries when layout packages are missing. |
| UpSet / set plot | `ComplexUpset` / `UpSetR` optional | Use set-size and matrix-dot fallback. |
| Multi-panel manuscript layout | `patchwork` / `cowplot` optional | Use facets or recipe templates when package is missing. |

## Promotion Rules

- Promote a specialized reference only after input schema, package check,
  fallback behavior, export, and family QA are stable.
- Missing optional packages must create a skip reason, not a failed default
  workflow.
- Specialized line density is a caution, not a generic grid failure.
- Text overlap, missing legends, scientific semantic gaps, and panel imbalance
  remain hard risks regardless of backend.

## Current 9.0 Status

The optional layer is ready as policy and recipe manifest coverage. Full
package-specific execution should be expanded case by case in the next backend
promotion pass.
