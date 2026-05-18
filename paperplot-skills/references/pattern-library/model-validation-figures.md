# Pattern: Model Validation / Prediction Accuracy

Derived from model-recovery, residual, scatter-fit, density, and box/swarm validation replica cases.

## Applies When

- The figure evaluates prediction accuracy, calibration, recovery, residuals, or method performance.
- Ground truth, prediction, residual, group, and metric roles are explicit.
- The goal is model credibility, not visual decoration.

## Does Not Apply When

- Only a single aggregate score exists; use a compact dot/bar with interval.
- Residuals or calibration data are unavailable but implied.
- Different metrics are mixed without normalization or units.
- The model is compared across groups without sample-size disclosure.

## Input Data Structure

- Table with `sample_id`, `observed`, `predicted`, optional `residual`, `group`, `fold`, `model`, `metric`, and `unit`.
- Summary table with `metric`, `estimate`, `ci_low`, `ci_high`, and `direction`.

## Visual Encoding

- Observed-vs-predicted scatter with identity line for calibration.
- Residual distribution as secondary panel.
- Metric forest/dotplot for model comparisons.
- Density/box/swarm for group-wise recovery distributions.

## Layout

- Calibration scatter first, residuals second, metric summary third.
- Avoid hiding poor calibration behind high correlation.
- Facet by model or metric only when scales remain interpretable.

## Typography And Marks

- Identity line thin and gray.
- Prediction points 1.1-1.8 mm with alpha.
- Confidence intervals 0.35-0.55 pt.
- Text statistics limited to essential metrics.

## Color Strategy

- Use model/group colors sparingly.
- Keep identity/reference lines neutral.
- Use consistent model colors across panels.

## Common Failure Modes

- R2 reported without calibration/residual evidence.
- Residuals are omitted even when bias is visible.
- Multiple metrics with different directionality are plotted as if higher is always better.
- Dense labels obscure outliers.

## Nature-Like Principle

Validation figures should expose failure modes. A polished accuracy plot that hides residual structure is not manuscript credible.

## Existing Templates

- `correlation-scatter-template.R`
- `effect-size-forest-template.R`
- `multi-metric-small-multiples-template.R`
- `model-validation-composite-template.R`

## New Template Need

No immediate new template is required for the core fit/residual/performance workflow. Future variants could add fold-aware calibration curves, prediction-interval ribbons, or residual-density insets when the input data justify them.

## QA Checklist

- Observed/predicted/residual roles are explicit.
- Identity/reference line is present when calibration is shown.
- Metric direction and units are documented.
- Outlier label rule is defined.
- Cross-validation/fold semantics are recorded when relevant.

## Visual QA Focus

- `text_burden_score` for statistic and outlier labels.
- `blank_margin_fraction` if scatter is under-scaled.
- `content_density` and `line_burden_score` for composites.

## Old-vs-New Criteria

Improvement means calibration, residual, and metric evidence are easier to compare, model failures are not hidden, and the visual hierarchy emphasizes validation over decoration.
