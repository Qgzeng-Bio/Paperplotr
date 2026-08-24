# Pattern: Grouped Bar / Stacked Bar / Errorbar

Derived from replica cases covering grouped bars with raw dots, stacked bars, ANOVA/post-hoc annotations, and line/bar composites.

## Applies When

- The scientific question compares group means, proportions, or composition across a small number of treatments, time points, tissues, or genotypes.
- Each category has a clear denominator, replicate count, and uncertainty definition.
- The main message is a group-level summary, not the full distribution shape.

## Does Not Apply When

- Sample size is small and raw individual values are the main evidence; prefer dot/box/violin.
- Categories exceed roughly 8 groups in a main figure.
- Components in stacked bars have incompatible denominators.
- A dual y-axis is only used to save space; split panels are usually safer.

## Input Data Structure

- Long table with `category`, `group`, `value`, optional `error`, `n`, `unit`, `facet`, and `comparison`.
- Stacked bars require `component` and a denominator or explicit `fraction`.
- Error bars require an `error_type` such as SD, SE, CI, or IQR.

## Visual Encoding

- Use bars for estimates, raw dots or intervals for evidence, and thin error bars for uncertainty.
- Use stacked bars only for part-to-whole composition and keep component order stable.
- Use line overlays only for connected time/order semantics, not arbitrary categories.

## Layout

- Single column for 3-5 categories; double column or small multiples for many groups.
- Put direct comparison panels before supporting composition panels.
- Facet by metric rather than mixing units on one axis.

## Typography And Marks

- Axis/title text 5-7 pt at final size; panel labels about 8 pt bold.
- Bar width 0.55-0.72; errorbar width 0.12-0.22; stroke 0.35-0.55 pt.
- Raw points 1.1-1.7 mm with alpha 0.55-0.85 and deterministic jitter.

## Color Strategy

- Use muted categorical colors for groups and gray for reference/control.
- Limit stacked components to 5-7; beyond that use top components plus `Other`.
- Avoid saturated presentation palettes and red/green opposition.

## Common Failure Modes

- Missing error-bar definition.
- Bars hide small n or non-normal distributions.
- Repeated legends and oversized p-value brackets dominate the data.
- Stacked bars imply composition when values are independent measurements.

## Nature-Like Principle

Bars are acceptable when they serve the statistical summary, but manuscript figures usually regain credibility by showing uncertainty, n, and raw-value evidence.

## Existing Templates

- `barplot-template.R`
- `grouped-boxplot-jitter-template.R`
- `bio-duplication-mode-comparison-template.R`
- `manuscript-four-panel-template.R`

## New Template Need

No immediate new template. Upgrade existing bar and grouped-comparison templates with stronger error semantics and p-value restraint.

## QA Checklist

- Axis has variable and unit.
- Denominator and error type are stated.
- Raw points are shown when n is small or moderate.
- Group colors are stable across panels.
- Significance marks do not replace effect size or uncertainty.

## Visual QA Focus

- `text_burden_score` for bracket/label overload.
- `line_burden_score` for excessive errorbar/grid structures.
- `saturated_presentation_palette` for over-bright group colors.
- `thumbnail_content_density` for stacked/faceted composites.

## Old-vs-New Criteria

Improvement means the new figure reduces repeated legends and annotation burden, clarifies uncertainty/n, preserves category order, and does not reduce manuscript-readiness score or content density.

## Detail QA Rules

- Text density should stay low; repeated p-value brackets, long category labels, and in-panel titles are common failure points.
- Background gridlines are usually off; use only light y-gridlines when they materially help compare bar heights.
- Error bars and bar outlines should be thin. Heavy caps or thick axes trigger `stroke_too_heavy`.
- Legends should be top/right/outside or removed through direct labeling; they fail when `legend_dominates_panel` is raised.
- Equal-role facets must keep comparable data-region sizes. Legend-only shrinkage of one panel triggers `panel_data_region_mismatch`.
- `text_data_overlap_risk` is serious because labels or brackets can cover bars, raw points, or error bars.
