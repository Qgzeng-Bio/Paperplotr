# Optional Backend Policy

PaperPlot Skills stays standalone. The default path is base R plus ggplot2 and
`scripts/paperplot_helpers.R`. Optional backends are allowed only when a figure
family genuinely needs a specialized layout engine.

## Backend Tiers

- `core`: base R, ggplot2, grid. Must work in the default skill environment.
- `light_optional`: packages that improve manuscript quality but have clear
  fallbacks, such as `ggrepel`, `patchwork`, `cowplot`, `scales`, or
  `RColorBrewer`.
- `specialized_optional`: packages required for specialized scientific layout,
  such as `ComplexHeatmap`, `circlize`, `sf`, `ggtree`, `treeio`, `ggraph`,
  `igraph`, `ComplexUpset`, or `UpSetR`.

## Rules

- Never call `library(PaperPlotR)` or any PaperPlotR R-package API.
- Optional recipes must use `requireNamespace(pkg, quietly = TRUE)`.
- Missing optional packages must produce a clear skip reason or fallback
  suggestion, not a broken figure.
- Optional backend output is benchmarked separately from core smoke tests.
- Do not use optional backends to avoid data-role validation. Specialized plots
  still require explicit tree, network, genomic, spatial, or set structures.

## Backend-To-Family Map

| Family | Preferred backend | Fallback |
|---|---|---|
| Complex heatmap / annotation heatmap | `ComplexHeatmap` | ggplot2 tile heatmap with simplified annotation bars |
| Circos / chord / circular genome | `circlize` | reference recipe and design plan only |
| Spatial map | `sf`, `ggspatial` | longitude/latitude scatter or tile map if coordinates exist |
| Phylogenetic tree | `ggtree`, `treeio`, `ape` | segment-based diagnostic tree only |
| Network | `igraph`, `ggraph` | edge-list summary or adjacency matrix |
| UpSet / set plot | `ComplexUpset`, `UpSetR` | matrix-dot + bar summary |
| Multi-panel manuscript layout | `patchwork`, `cowplot` | base ggplot facets or saved panels with geometry QA |

## QA Policy

Specialized optional figures are not judged with ordinary grid/line-density
thresholds alone. They still fail on unreadable text, severe panel imbalance,
ambiguous legends, missing scientific semantics, or data-role mismatch.

## Promotion Policy

A source script can be promoted from `specialized_reference` to
`optional_backend_recipe` only when it has:

- a clean input schema,
- no required absolute local path,
- graceful missing-package handling,
- PDF/PNG export,
- visual QA and family QA sidecars,
- documented fallback behavior.
