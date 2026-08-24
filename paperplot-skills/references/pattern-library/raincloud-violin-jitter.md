# Pattern: Raincloud / Violin / Jitter

Derived from replica cases using violin, half-violin, box, jitter, beeswarm, and significance overlays for distribution comparisons.

## Applies When

- The goal is to compare distributions across groups while preserving raw-sample evidence.
- Group n is moderate enough to estimate shape, or the violin is secondary to raw dots and intervals.
- The metric has one unit and a clear measurement scale.

## Does Not Apply When

- n is too small for a violin shape; use points plus interval.
- The visible groups exceed about 8 in a main figure.
- Paired/repeated samples need connecting lines; use a paired-comparison pattern.
- Heterogeneous metrics are being mixed on one y-axis.

## Input Data Structure

- Long table with `sample_id`, `group`, `value`, optional `paired_id`, `metric`, `unit`, `facet`, and `comparison`.
- Statistical annotations need precomputed comparison labels or a declared test and correction method.

## Visual Encoding

- Primary: raw dots or beeswarm.
- Secondary: thin box/IQR or median line.
- Optional: half-violin/raincloud density when n supports distribution shape.
- P-values should be compact and secondary to effect/uncertainty.

## Layout

- Single metric: horizontal categories with enough space for dots.
- Multiple metrics: small multiples, one y-axis unit per panel.
- Dense groups: rank/order by median or scientific order and move full labels to a sidecar.

## Typography And Marks

- Dot size 1.0-1.6 mm; alpha 0.55-0.85.
- Violin fill alpha 0.25-0.45; outline 0.3-0.45 pt.
- Box width 0.12-0.22 of category width; outlier glyphs off if raw dots are shown.

## Color Strategy

- One restrained hue per group; use light fill and darker outline/dots.
- Avoid gradient backgrounds and decorative shadows even if present in replicas.
- Use gray for baseline/control when treatment contrast is the message.

## Common Failure Modes

- Over-wide violins imply precision without enough samples.
- Jitter overlaps make distribution unreadable.
- P-value stars occupy more visual space than raw data.
- Category labels become the figure's dominant visual element.

## Nature-Like Principle

The figure should make the distribution and sample evidence visible before it makes the statistic decorative.

## Existing Templates

- `violin-dot-template.R`
- `grouped-boxplot-jitter-template.R`
- `comparison-boxplot-template.R`
- `paired-comparison-template.R`

## New Template Need

Consider `raincloud-template.R` only after the existing violin/jitter template supports half-violin fallback without optional dependencies.

## QA Checklist

- Raw data shown or the reason for summary-only plotting is stated.
- n per group is available in notes or labels.
- Paired data are not treated as independent.
- Density/violin only used when n supports it.
- Significance method and correction are documented.

## Visual QA Focus

- `small_component_count` and `thumbnail_content_density` for dot/label overload.
- `content_density` should be moderate, not sparse bars.
- `grayscale_discrimination_risk` for multiple groups with similar fills.

## Old-vs-New Criteria

Improvement means raw evidence is clearer, distribution summaries are less decorative, p-value burden is lower, labels remain readable at target size, and group order supports the scientific message.

## Detail QA Rules

- Raw dots must remain visible; label or bracket collision with dots, violins, boxes, or quartile lines triggers `text_data_overlap_risk`.
- Gridlines are off by default. A dense background grid competes with distribution shape.
- Violin/box outlines and jitter points should be light enough that raw observations remain the evidence layer.
- Significance annotations should be compact and outside the main density where possible; top-heavy annotation raises `significance_annotation_overcrowding`.
- Long group labels should be wrapped, abbreviated with metadata, or moved to facets; collided tick labels trigger `tick_label_collision_risk`.
- Legends are often unnecessary when x-axis groups already encode color.
