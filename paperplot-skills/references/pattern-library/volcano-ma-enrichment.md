# Pattern: Volcano / MA / Enrichment

Derived from replica cases combining volcano plots, MA plots, GSEA/MSigDB scores, enrichment bars/dotplots, and multi-group differential panels.

## Applies When

- The analysis has feature-level effect size and significance or expression abundance.
- The message is differential signal, highlighted genes/features, or pathway enrichment.
- Effect, significance, count, and term semantics can be kept separate.

## Does Not Apply When

- Only p-values are available without effect size.
- Labeling every significant feature would dominate the panel.
- Enrichment terms are redundant and not collapsed.
- Feature counts or denominators are missing.

## Input Data Structure

- Volcano: `feature`, `log2fc`, `padj` or `pvalue`, optional `base_mean`, `class`, `label_priority`.
- MA: `feature`, `base_mean`, `log2fc`, `padj`.
- Enrichment: `term`, `ratio`, `qvalue`, `count`, optional `category`.

## Visual Encoding

- Volcano: x = effect, y = -log10 adjusted p; neutral background with highlighted subsets.
- MA: x = abundance, y = effect, with clear thresholds.
- Enrichment: dot position = ratio/effect, size = count, color = adjusted significance.

## Layout

- Keep volcano/MA and enrichment in separate panels unless the composite has a clear hierarchy.
- Use top labels only; move full significant feature lists to sidecars.
- Split very dense term lists into top terms per category.

## Typography And Marks

- Background points 0.5-0.9 mm with alpha 0.25-0.45.
- Highlight points 0.9-1.4 mm.
- Threshold lines 0.3-0.45 pt and gray.
- Labels 5-6 pt with strict count limits.

## Color Strategy

- Neutral gray for non-significant/background.
- One or two muted highlight colors for direction/classes.
- Continuous q-value color should be perceptually ordered and labeled.

## Common Failure Modes

- Saturated red/green volcano palette.
- P-value threshold is visually louder than effect size.
- Too many direct gene labels.
- Enrichment terms overlap or use unreadable long labels.

## Nature-Like Principle

Differential figures are credible when they separate statistical evidence from biological interpretation and do not turn significance into confetti.

## Existing Templates

- `volcano-plot-template.R`
- `ma-plot-template.R`
- `enrichment-dotplot-template.R`

## New Template Need

No immediate new template. Future composite templates should be built only when input contains both feature-level and term-level tables.

## QA Checklist

- Adjusted p-value method is documented.
- Effect threshold and significance threshold are explicit.
- Label selection rule is recorded.
- Background and highlighted feature classes are distinct.
- Enrichment terms are deduplicated or grouped.

## Visual QA Focus

- `text_burden_score` for labels.
- `content_density` for dense feature clouds.
- `grayscale_discrimination_risk` for directional highlights.
- `saturated_presentation_palette` for red/green risk.

## Old-vs-New Criteria

Improvement means highlighted biology is clearer, label count is lower, thresholds are explicit, and the new plot keeps or improves readiness score without hiding major signal classes.
