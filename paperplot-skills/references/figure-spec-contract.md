# Figure Spec Contract

Every plotting template must define `figure_spec` before building the plot.

## Required Fields

- `figure_id`: stable figure identifier.
- `template_id`: template file stem.
- `backend`: always `R/ggplot2` for this skill.
- `scientific_message`: the claim or comparison the figure should support.
- `plot_type`: selected encoding.
- `figure_role`: main, supplement, method, or exploratory.
- `output_preset`: journal or panel size preset.

## Metric Spec

Every template should define `metric_spec`. Multi-metric templates must define one row per metric.

Required columns:

- `metric`
- `label`
- `unit`
- `direction`: `higher_better`, `lower_better`, or `neutral`
- `transform`: `none`, `log`, `log10`, `sqrt`, `rank`, `percentile`, `z_score`, `normalized`, `scaled`, or `user_defined`
- `role`: primary, key, support, ranking, or exploratory

## Rules

- Use `unitless` or `a.u.` when a metric has no physical unit.
- Do not silently transform metrics.
- Different-unit metrics should use small multiples unless a documented transform makes a shared scale meaningful.
