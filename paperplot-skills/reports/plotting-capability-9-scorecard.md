# PaperPlot Skills 9.0 Plotting Capability Scorecard

This scorecard summarizes the implementation state after the 9.0 code-learning
upgrade.

## Implementation Metrics

| Metric | Target | Current |
|---|---:|---:|
| Indexed R/Rmd scripts | 142 | 142 |
| Scripts with explicit skill use | 142 | 142 |
| Recipe manifest entries | 60+ | 84 |
| Production recipes | 40+ | 42 |
| Rendered benchmark recipe figures | 60+ | 67 |
| Template files | 35+ | 35 |
| Real benchmark cases | 100-140 | 142 |
| Gold human rubric queue | 30 | 30 |
| Gold set previews prepared | 30 | 29 |
| Completed human rubric scores | 30 | 30 |
| Positive calibration cases after human scoring | 24 | 24 |
| Baseline/caution cases after human scoring | tracked | 6 |

## Capability Gains

- The skill now uses the full R replica archive through a utilization audit,
  not only a subset of hand-picked recipes.
- The recipe layer covers core statistical plots, omics/genomics plots,
  distribution plots, matrix plots, ordination, model validation, set plots,
  spatial/network/tree/circos references, and multi-panel layouts.
- Optional backend policy allows advanced scientific layouts without turning
  optional packages into hard dependencies.
- Real benchmark infrastructure separates executable redraw cases from
  specialized diagnostics and caution references.
- The template system now includes 35 smoke-tested template files, including
  recipe-driven templates for bar/errorbar, stacked fractions, ridgelines,
  labelled regression, matrix dotplot, time series, network summary, and spatial
  distribution.
- A fillable gold-set scoring pack is available at
  `reports/gold-human-rubric-pack/index.html`, with CSV scoring fields and a
  summarization script.
- Human gold scores are now converted into
  `references/gold-human-calibration-rules.json`, and `family-qa-score.py`
  reports `positive_calibration_status` and `calibrated_positive_score`.

## Remaining Risks Before A True 9/10 Claim

- One gold-set case currently lacks a source preview and should be replaced or
  scored from source metadata.
- PCA/PCoA/ordination examples were judged readable but visually generic. The
  skill now treats ordinary ordination plots as baseline/caution for positive
  Nature-like calibration unless they show stronger hierarchy, marginal or
  statistical context, or refined layout.
- Optional backend recipes are policy-covered but not yet all package-specific
  production implementations.
- Some recipe warnings reflect deterministic QA limitations, especially bar
  geometry versus grid-line burden.
- Python plotting library code has not yet been absorbed in this phase.

## Current Practical Rating

The deterministic code-generation and QA infrastructure is now in the 8.9-9.0
range for R/ggplot2-centered scientific plotting workflows after initial human
gold-score calibration. A more defensible public 9/10 claim still requires at
least one optional-backend promotion pass for specialized figures and a second
round of more granular human scoring on the positive cases.
