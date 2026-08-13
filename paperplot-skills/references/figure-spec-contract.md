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
- `journal_profile`: one profile from `journal-specs-matrix.md`; inferred from known presets unless explicitly selected.
- `analysis_domain`: `general` or `bioinformatics`.
- `figure_spec_schema_version`: currently `2`.

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
- Metadata must record the 9 pt target, 8 pt compact text, 12 pt panel label, 6 pt absolute floor, selected journal-profile snapshot, actual export geometry, cognitive-load review state, and bioinformatics validation state.
- Branded presets (`cell*`, `nature*`, `ncomms*`) must match their scoped profile; every preset/profile pair must stay within the selected profile envelope.
- Only explicit schema v1 input is migrated to v2. The migration infers a missing profile, defaults a missing analysis domain to `general`, and records the original helper/schema. Incomplete v2 and unknown future versions are rejected rather than silently rewritten.
- Set `old_figure_path` only when a real source figure is available for comparison. Manuscript-ready validation then requires checksum-matched old-vs-new evidence with a completed review and final verdict `improved`.
