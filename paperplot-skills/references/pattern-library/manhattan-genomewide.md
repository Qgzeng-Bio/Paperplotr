# Pattern: Manhattan / Genome-Wide Signal

Derived from the genome-wide and OTU Manhattan-style replica case.

## Applies When

- Features have ordered genomic, taxonomic, or locus-like coordinates.
- The question concerns peaks or intervals across a long ordered axis.
- Chromosome/contig/group boundaries and significance thresholds are known.

## Does Not Apply When

- Features have no stable order.
- The x-axis is only a ranked list; use lollipop or dotplot.
- Thresholds are arbitrary or undocumented.
- Labels for many peaks are required in the main panel.

## Input Data Structure

- Table with `feature`, `chromosome` or `group`, `position`, `score` or `pvalue`, optional `effect`, `label_priority`, and `annotation`.
- Threshold metadata and coordinate system are required.

## Visual Encoding

- x = ordered coordinate; y = signal such as -log10 p or effect.
- Alternate muted colors by chromosome/group.
- Highlight only peak categories or nominated loci.

## Layout

- Long horizontal panel, usually double-column width.
- Put threshold line and chromosome separators in gray.
- Use an inset or side table for top hits rather than labeling all peaks.

## Typography And Marks

- Points 0.35-0.9 mm depending on feature count.
- Threshold line 0.35-0.5 pt.
- Axis labels sparse; chromosome labels need enough spacing.

## Color Strategy

- Alternating gray/blue-gray chromosome colors.
- One restrained accent for highlighted peaks.
- Avoid rainbow by chromosome unless the chromosome count is very low.

## Common Failure Modes

- Thousands of points become a solid block.
- Peak labels overlap.
- Axis tick labels imply base-pair precision where bins were used.
- Thresholds are unexplained.

## Nature-Like Principle

Genome-wide plots should let peaks emerge from a disciplined background rather than rely on color spectacle.

## Existing Templates

- No direct existing template.
- `volcano-plot-template.R` and `rank-plus-key-metrics-template.R` share label-priority concepts.

## New Template Need

`manhattan-plot-template.R` is a reasonable future addition if coordinate-schema validation is implemented.

## QA Checklist

- Coordinate columns and ordering are present.
- Thresholds are named and justified.
- Label priority is capped.
- Chromosome/group separators are legible.
- Full hit table is written as a sidecar.

## Visual QA Focus

- High `content_density` can be normal; text burden should remain low.
- `line_burden_score` catches excessive separators.
- `thumbnail_content_density` identifies unreadable dense previews.

## Old-vs-New Criteria

Improvement means peaks are easier to find, the background is calmer, thresholds and coordinate semantics are clearer, and label burden is reduced.
