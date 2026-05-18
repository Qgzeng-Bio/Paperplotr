# Pattern: Correlation Heatmap / Matrix Dotplot

Derived from replica cases using correlation matrices, clustered heatmaps, dot-matrix significance, table heatmaps, and marginal bar annotations.

## Applies When

- The data are matrix-like and the pattern of relationships is the message.
- Rows and columns have meaningful order, clustering, or grouped annotation.
- Values share a common scale or have a documented transformation.

## Does Not Apply When

- The viewer needs exact raw values for heterogeneous metrics.
- Row/column labels are too dense for the target figure size.
- Missing values, transformations, or scales are undocumented.
- Circular heatmaps are used only for decoration.

## Input Data Structure

- Wide matrix or long table with `row`, `column`, `value`, optional `p_value`, `group_row`, `group_col`, `unit`, and `transform`.
- Correlation matrices need method (`Pearson`, `Spearman`, etc.) and sample count.

## Visual Encoding

- Fill color encodes value; dot size or star can encode significance only when necessary.
- Annotation strips encode row/column classes.
- Dendrograms are used only when clustering method is meaningful.

## Layout

- Square or near-square matrix for symmetric correlations.
- Triangular layout for redundant symmetric matrices.
- Marginal bars should be thin and secondary.
- Split very large matrices into main top features plus supplement.

## Typography And Marks

- Cell borders off or very thin.
- Axis text 5-6 pt, angled only when labels are short.
- Significance glyphs must be sparse; many stars become texture, not information.

## Color Strategy

- Diverging palette centered at zero for signed correlations.
- Sequential palette for abundance/score matrices.
- Colorbar title must name value, unit, transform, and midpoint if relevant.

## Common Failure Modes

- Rainbow scales.
- Too many row/column labels.
- Significance stars over every cell.
- Clustering visually implies biology without method documentation.
- Continuous and categorical annotations share ambiguous colors.

## Nature-Like Principle

Heatmaps are pattern displays. They become manuscript figures when ordering, scale, annotation, and label strategy are intentional.

## Existing Templates

- `heatmap-template.R`
- `multi-metric-small-multiples-template.R`
- `bio-genome-quality-overview-template.R`

## New Template Need

No immediate new template; upgrade heatmap metadata with matrix method, transform, ordering, and family-specific QA thresholds.

## QA Checklist

- Matrix scale/transform is explicit.
- Colorbar is readable and not wider than the data.
- Label count fits target size or uses a key sidecar.
- Clustering/order method is recorded.
- Missing-value encoding is documented.

## Visual QA Focus

- Dense matrices may legitimately trigger high `content_density`; judge with family-specific ranges.
- `text_burden_score` and `thumbnail_content_density` catch unreadable labels.
- `grayscale_discrimination_risk` matters for diverging palettes.

## Old-vs-New Criteria

Improvement means matrix ordering is clearer, color scale semantics are stronger, label burden is lower, and the new plot does not hide important row/column groups.
