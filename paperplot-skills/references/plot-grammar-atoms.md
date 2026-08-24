# Plot Grammar Atoms From The R Replica Library

This document turns the full R replica archive into reusable plotting grammar.
It is not a copybook of original scripts. Each atom describes a transferable
code structure, expected data roles, and manuscript QA focus.

## Distribution Atoms

| Atom | Data roles | Code structure | QA focus |
|---|---|---|---|
| Box + jitter | `group`, `value`, optional `sample` | `geom_boxplot(outlier.shape = NA)` plus low-alpha `geom_jitter()` | raw points visible, box stroke not heavy, group count readable |
| Violin + dot | `group`, `value` | `geom_violin(trim = FALSE)` plus dot/jitter layer | avoid decorative mirrored density when n is small |
| Raincloud | `group`, `value`, optional `facet` | half-density/violin + box + jitter | aligned data region, no over-wide density, raw points remain interpretable |
| Ridgeline/density | `group`, `value` | repeated density contours or facets | repeated lines allowed; axis scale and overlap must be clear |

## Matrix Atoms

| Atom | Data roles | Code structure | QA focus |
|---|---|---|---|
| Tile heatmap | `row`, `column`, `value` | `geom_tile()` with continuous fill scale | colorbar semantics, label burden, no mixed units |
| Annotated heatmap | `row`, `column`, `value`, `annotation` | heatmap plus side/top annotation bars | annotation colors documented, legend compression |
| Cell-label heatmap | `row`, `column`, `value`, optional `label` | `geom_tile()` plus small `geom_text()` | text only if cells are large enough at target width |
| Matrix dotplot | `row`, `column`, `effect`, `support` | point size for support, color for effect | size/color legends separated and not dominant |

## Omics Atoms

| Atom | Data roles | Code structure | QA focus |
|---|---|---|---|
| Volcano | `feature`, `effect`, `pvalue`/`padj` | point cloud + threshold lines + sparse labels | threshold meaning, label collision, no red/green dependence |
| MA plot | `base_mean`, `effect`, `padj` | log x-axis + horizontal reference lines | transformed axis explicit, significance not only color |
| Enrichment dotplot | `term`, `ratio`, `qvalue`, `count` | term rank + point size/color | term label burden, q-value colorbar, top-N policy |
| Manhattan | `chr`, `position`, `pvalue` | cumulative genomic coordinate + threshold line | chromosome labels, threshold semantics, dense points allowed |
| Genome track / synteny | `chr`, `start`, `end`, `feature`, links | rectangles/segments/curves | requires real coordinates; do not fake genome structure |

## Comparison Atoms

| Atom | Data roles | Code structure | QA focus |
|---|---|---|---|
| Grouped bar + interval + raw points | `group`, `category`, `value`, `error` | `geom_col()` + `geom_errorbar()` + jittered raw points | error type named, bar geometry not mistaken for grid |
| Stacked fraction bar | `group`, `category`, `value` | `geom_col(position = "fill")` | denominator/fraction meaning visible |
| Lollipop | `category`, `value` | horizontal `geom_segment()` plus terminal point | sorted order, label readability |
| Dumbbell | `category`, two `group` levels, `value` | connector segment + two endpoints | paired/comparison semantics explicit |
| Forest/effect size | `metric`, `estimate`, `lower`, `upper` | reference line + CI segment + point | CI type, reference value, axis units |

## Ordination And Model Atoms

| Atom | Data roles | Code structure | QA focus |
|---|---|---|---|
| PCA/PCoA/NMDS | `axis1`, `axis2`, `group` | point cloud + ellipse/hull + reference axes | method/variance/stress semantics |
| UMAP/t-SNE | `x`, `y`, `cluster` | dense point cloud + sparse labels | avoid over-interpreting distances |
| Model validation | `observed`, `predicted`, `residual`, `group` | observed-vs-predicted, residual, metric summary panels | equal panel geometry, reference lines, performance metric definitions |
| Calibration curve | `predicted`, `observed`, optional `bin` | line/point + identity reference | bin counts and axis scale |

## Layout Atoms

- Shared legend: collect legend once; repeated legends are a multi-panel risk.
- Panel label: small bold label outside data region, aligned across panels.
- Facet grid: acceptable for equal-role panels when panel boxes and data regions stay comparable.
- Inset: only for secondary evidence; it must not hide data marks.
- Sidecar labels: dense sample or term labels move to label key CSV when they dominate the figure.

## Style Atoms

- Font: 5-7 pt at target export width, panel label about 8 pt bold.
- Stroke: 0.25-0.6 pt for axes, intervals, borders; >1.2 pt is a warning.
- Grid: off by default; light grid only for quantitative scatter/line reading.
- Palette: restrained discrete colors, semantic continuous gradients, no rainbow default.
- Export: vector PDF plus PNG preview; notes, metadata, QA, and family QA sidecars.

## Promotion To Recipe

An atom becomes a recipe only when it has a clean data schema, robust mock data,
target-size defaults, export sidecars, and visual/family QA expectations.
