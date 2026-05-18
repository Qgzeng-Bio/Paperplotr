# Figure type quality rubric

## Bar plot

Use for counts, proportions, or simple summaries. Avoid for distributions unless raw points or intervals are shown. Bars need baseline, unit, denominator for proportions, and uncertainty when inferential.

## Boxplot / violin / jitter

Show raw points for small and medium n. Boxplot is not primary evidence for n < 5. Violin needs enough observations to estimate density. State what center, whiskers, and intervals mean.

## Scatter / correlation

Use for numeric relationships. Show uncertainty/trend only when justified. Avoid overplotting with alpha, small points, hex/binning, or sampling. Report correlation/model context in notes.

## Line plot

Use only for ordered, temporal, dose, trajectory, or paired data. Do not connect unordered categories for decoration.

## Heatmap

Use for matrix-like comparable values. Require scale, transform, clustering method, missing-value handling, and color legend. Mixed units require transformation and clear annotation.

## PCA / UMAP / t-SNE

Report input features, normalization, distance/embedding method, and explained variance where applicable. Do not over-interpret UMAP/t-SNE distances. Use stable group colors and avoid label clutter.

## Volcano / MA

Volcano: x = effect size, y = adjusted significance. MA: x = abundance, y = effect size. Label selected genes only. State thresholds and adjusted p-value method.

## Enrichment dot plot

Recommended mapping: x = enrichment ratio/effect, y = term, size = count, color = q-value/significance. Limit visible terms and move full table to metadata/supplement.

## Effect-size forest

Use effect size and CI as primary visual. Keep zero/no-effect line visible. Do not replace intervals with p-value stars.

## Manhattan plot

Requires chromosome/order semantics, genomic position, significance threshold, and genome build. Use alternating chromosome colors and label only key loci.

## Genome tracks

Require genome build, coordinates, track units, strand, and scaling. Align tracks precisely and avoid inconsistent y-scales unless labeled.

## Circos / synteny

Require explicit genomic intervals, linkage/synteny pairs, orientation, scale, and filtering. Do not fake circular or synteny diagrams from summary tables alone.

## Phylogenetic tree

Require tree format, branch length meaning, rooting, support values, and label strategy. Do not alter topology for aesthetics.

## Network

Require node/edge definitions, layout method, edge filtering, and community/group semantics. Avoid hairballs; summarize or filter if density is high.

## Workflow schematic / model architecture

Use when the input is conceptual rather than numeric. Keep typography, alignment, arrow direction, and visual hierarchy consistent. Do not use data-plot templates for diagrams.
