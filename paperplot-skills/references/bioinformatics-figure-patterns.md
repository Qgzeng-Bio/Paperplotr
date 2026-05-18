# Bioinformatics figure patterns

Use these patterns when a plotting task is clearly about genome assembly, gene duplication, differential expression, enrichment, or other recurring bioinformatics manuscript figures.

## Genome quality overview

Default to 2x3 small multiples when comparing 5-8 heterogeneous genome or assembly metrics. Preserve raw units in facet labels. Do not silently z-score or rank metrics in the visible y-axis. Dense sample names should use rank index, selected key labels, label-key sidecar, and metadata sample order.

## Duplication mode comparison

Keep duplication modes semantically stable across panels. Common modes include WGD, TD, PD, TRD, and DSD. Do not reuse the same color scale for both group and mode in the same panel unless the mapping is explicit. Effect-size summaries should show intervals when available.

## Volcano plot

Use log2 fold change on x and adjusted significance on y. Color should encode significance/direction classes, not arbitrary group. Label only a small number of selected genes. Full gene identifiers should remain in metadata or a sidecar when necessary.

## MA plot

Use abundance or base mean on x and log2 fold change on y. Avoid implying low-count effects are equally stable; alpha or point size can de-emphasize noisy low-abundance observations. Significant genes may be colored but should not dominate the axis semantics.

## Enrichment dot plot

Use term on y, enrichment ratio on x, count as point size, and q-value or adjusted p-value as color. Keep term labels short; move full names to notes or sidecars if they dominate the figure.
