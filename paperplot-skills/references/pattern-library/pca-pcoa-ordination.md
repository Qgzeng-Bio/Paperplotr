# Pattern: PCA / PCoA / NMDS / UMAP / t-SNE

Derived from ordination replica cases with group ellipses, marginal boxplots, PERMANOVA/ANOSIM notes, and multi-group PCoA layouts.

## Applies When

- Samples are projected into two dimensions from multivariate data.
- The scientific question concerns separation, clustering, gradients, or batch/group structure.
- The method, distance metric, and explained variance or stress are known.

## Does Not Apply When

- Coordinates are arbitrary x/y values; use scatter.
- The method/distance metric is unknown.
- Group ellipses are used with too few samples.
- Marginal distributions are shown without an interpretable coordinate axis.

## Input Data Structure

- Coordinate table with `sample_id`, `axis1`, `axis2`, `group`, optional `batch`, `shape`, `label`.
- Metadata for method, distance metric, variance explained, stress, PERMANOVA/ANOSIM statistics.

## Visual Encoding

- Position encodes ordination axes.
- Color encodes primary group; shape can encode batch only if not too many classes.
- Ellipses/hulls are optional and require enough samples.
- Marginal boxplots/densities can support axis-wise group separation.

## Layout

- Main ordination cloud is primary.
- Marginal panels should be thin and aligned to axes.
- Statistical text belongs in notes or a small annotation, not a headline.

## Typography And Marks

- Points 1.4-2.2 mm.
- Ellipse stroke 0.35-0.55 pt; fill alpha 0.08-0.15.
- Axis labels include method and explained variance when available.

## Color Strategy

- Use stable group colors; limit primary groups to 6-8.
- Use shape or stroke for batch only when it does not create a legend wall.

## Common Failure Modes

- Treating ordination axes as raw units.
- Overconfident ellipses with small n.
- Labels on every sample.
- Missing distance metric or explained variance.

## Nature-Like Principle

Ordination figures should communicate structure and uncertainty without pretending the 2D projection is the original data.

## Existing Templates

- `pca-scatter-template.R`
- `manuscript-four-panel-template.R`

## New Template Need

Consider `pcoa-marginal-template.R` after the pattern-library work, especially for microbiome/community data with PERMANOVA.

## QA Checklist

- Method, distance, variance/stress, and n are documented.
- Ellipses/hulls have enough samples.
- Sample labels are selective or moved to sidecar.
- Legend does not dominate the data cloud.
- Batch/group semantics are separated.

## Visual QA Focus

- `text_burden_score` for sample labels.
- `blank_margin_fraction` if ordination cloud is tiny inside large margins.
- `grayscale_discrimination_risk` for group colors.

## Old-vs-New Criteria

Improvement means the sample cloud is larger and clearer, group semantics are documented, labels are less burdensome, and statistical annotations are readable but not dominant.
