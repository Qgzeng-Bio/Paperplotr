# Pattern: Scatter / Regression / Marginal Diagnostics

Derived from replica cases using regression lines, marginal histograms, double error bars, quadrant FC-FC plots, and residual boxplots.

## Applies When

- Two numeric variables are the primary relationship.
- A trend line, model fit, residual panel, or marginal distribution directly supports the scientific question.
- The sample size and overplotting level allow point-level reading or principled summarization.

## Does Not Apply When

- The x-axis is categorical; use grouped comparisons.
- The fit is shown without model assumptions or confidence interpretation.
- Error bars encode heterogeneous uncertainty types.
- Marginal plots would consume space without adding scientific evidence.

## Input Data Structure

- Table with `x`, `y`, optional `group`, `x_error`, `y_error`, `label`, `model_fit`, `residual`, `unit_x`, and `unit_y`.
- Regression needs model family, transformation, and whether confidence bands are shown.

## Visual Encoding

- Primary encoding: point position.
- Optional group: color or shape, not both unless necessary.
- Regression: thin line plus light confidence band when justified.
- Marginals/residuals: smaller supporting panels with shared scales.

## Layout

- Main scatter should occupy the largest area.
- Marginal histograms/densities or residuals should be secondary strips, not equal-weight panels.
- Quadrant plots need labeled zero/threshold lines and sparse direct labels.

## Typography And Marks

- Point size 1.1-2.0 mm; alpha 0.45-0.85.
- Regression stroke 0.45-0.65 pt; confidence fill alpha 0.12-0.22.
- Threshold lines 0.3-0.45 pt and gray unless they are primary findings.

## Color Strategy

- Use one color for a global trend, or a restrained group palette for known classes.
- Dense FC-FC/volcano-like scatters should use neutral background points and highlight only biologically interpreted subsets.

## Common Failure Modes

- Regression line used as decoration.
- Too many labels on individual points.
- Correlation/R2 text dominates the panel.
- Marginal plots duplicate information already visible in the main cloud.

## Nature-Like Principle

The main panel should show the relationship; supporting diagnostics should prove the relationship is not an artifact.

## Existing Templates

- `correlation-scatter-template.R`
- `pca-scatter-template.R` for ordination-like scatter.
- `effect-size-forest-template.R` for interval alternatives.

## New Template Need

No default new template. A future `model-validation-composite-template.R` can reuse this pattern when residual/calibration panels are required.

## QA Checklist

- x/y units and transformations are explicit.
- Fit method and confidence band semantics are stated.
- Thresholds are named and justified.
- Dense labels are moved to sidecars or top-priority labels.
- Overplotting is controlled by alpha, bins, facets, or summary density.

## Visual QA Focus

- `text_burden_score` for point labels and statistics.
- `content_density` should not be too low when many points exist.
- `line_burden_score` for too many threshold/error lines.
- `grayscale_discrimination_risk` for highlighted classes.

## Old-vs-New Criteria

Improvement means the relationship is more legible, labels are more selective, fitted/statistical information is present but secondary, and residual/marginal panels clarify rather than clutter.
