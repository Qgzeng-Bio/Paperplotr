# Pattern: Compact Dot-Matrix Enrichment

Derived from manuscript-style bubble heatmaps and correlation dot-matrix figures where categorical rows and columns are fixed, most marks are small, and space economy matters.

## Applies When

- The data form a categorical matrix: row feature/clade/pathway/family by column class/condition/SV type.
- One signed continuous statistic describes direction and strength, such as `log2 OR`, correlation, enrichment score, or standardized effect.
- One non-negative support metric describes evidence volume, such as event count, gene count, candidate count, or abundance.
- Significance or confidence can be encoded with border weight, not stars as the primary message.
- Optional row annotation, such as family/superfamily/group, improves interpretation without needing a full legend-heavy panel.

## Does Not Apply When

- The x-axis is genuinely numeric or ordered by distance/time; use scatter, line, or genome-wide patterns instead.
- Exact values must be read from every cell; use a table heatmap or annotated table.
- There are more than roughly 12 columns or 35 rows in a main figure without filtering or sidecar labels.
- Dot area would encode a denominator-free metric or a metric with mixed units.

## Input Data Structure

Long table with:

- `row`: feature, clade, pathway, TE family, taxon, term, or other row label.
- `column`: comparison class, SV type, condition, or category.
- `effect`: signed continuous statistic, ideally centered at 0.
- `support`: non-negative count or abundance for dot area.
- optional `significance`: adjusted p-value/FDR, logical significant flag, or significance class.
- optional `row_group`: row annotation for a compact side strip.
- optional `row_label`: shortened display label when row names are long.

## Visual Encoding

- Background tiles define a compact lookup grid and help locate tiny dots.
- Fill color encodes signed effect with a diverging palette centered at 0.
- Dot area encodes support count; use area scaling, not radius scaling.
- Border weight/color encodes significance. Avoid star overlays unless the matrix is sparse.
- A thin side strip can encode row group/family; keep it secondary.

## Layout

- Use fixed cell width and a narrow canvas instead of spreading columns across the page.
- Put column labels on top when the matrix is short and wide.
- Keep legends on the right for standalone panels; in multi-panel figures, move shared legends outside the panel grid.
- Shorten row labels when the biological class is repeated elsewhere, e.g. `Gypsy/CRM` -> `CRM` with a side strip for `Gypsy`.

## Typography And Marks

- Axis text 5-7 pt at final size.
- Dot outlines 0.15-0.25 pt for non-significant cells and 0.4-0.6 pt for significant cells.
- Tile borders should be white or absent; avoid dark gridlines around every cell.
- Maximum dot size should leave visible padding inside each cell.

## Color Strategy

- Use a blue-white-red or blue-neutral-vermilion diverging scale only when the midpoint has meaning.
- Use muted row-strip colors and limit row annotation classes to roughly 3-6.
- Ensure direction is explained in the legend or caption.

## Common Failure Modes

- Columns are treated as ordinary discrete x positions on a wide canvas, producing excessive white space.
- Tiny dots float without cell backgrounds, making low-support patterns unreadable.
- Significance stars dominate the matrix.
- Row labels repeat a higher-level family prefix and waste width.
- Legends consume more area than the matrix.

## Nature-Like Principle

The figure succeeds when it reads as a compact evidence matrix: effect direction, support magnitude, and significance are visually separable, while the categorical grid remains tight enough to fit as a manuscript panel.

## Existing Templates

- `compact-dot-matrix-enrichment-template.R`

## QA Checklist

- Effect scale, midpoint, and units are explicit.
- Support metric has a denominator or clear count definition.
- Significance threshold and border meaning are documented.
- Row and column ordering rules are recorded.
- Label shortening is recorded and original labels are preserved in metadata or sidecar when needed.

## Visual QA Focus

- `blank_margin_fraction` for excessive canvas padding.
- `text_burden_score` for long row labels and oversized legends.
- `grayscale_discrimination_risk` for diverging effect color.
- `line_burden_score` for overly dark cell borders.

## Old-vs-New Criteria

Improvement means the new plot reduces x-axis spacing and legend burden, preserves row/column lookup accuracy, and makes low-support cells easier to locate without hiding large significant signals.
