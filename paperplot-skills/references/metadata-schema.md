# Metadata Schema

Each template writes `*_metadata.json` using `pp_write_metadata()`.

## Required Top-Level Keys

- `figure_id`
- `template_id`
- `backend`
- `helper_version`
- `task_type`
- `figure_role`
- `scientific_message`
- `plot_type`
- `journal_profile`
- `journal_profile_snapshot`
- `analysis_domain`
- `figure_spec_schema_version`
- `bioinformatics_validation`
- `cognitive_load_review`
- `visual_qa_review`
- `old_vs_new_review`
- `data`
- `metrics`
- `ordering`
- `style`
- `layout`
- `export`
- `export_geometry`
- `qa`

## Required Meaning

- `data` records input size and columns.
- `metrics` records labels, units, directions, transforms, and roles.
- `ordering` records sample/group/rank order.
- `style.font_family` must equal `Arial`; `style.palette` records palette type and name; style records 9 pt target, 8 pt compact text, 12 pt panel label, and 6 pt absolute floor. PaperPlot 0.5.1+ does not permit font substitution.
- `journal_profile` names a profile from `journal-specs-matrix.md`; `journal_profile_snapshot` records scope, source URL/status, checked date, and width/height envelope. Final submission still verifies the current official guide.
- `layout` records nrow, ncol, panel spec, width, and height when relevant.
- Multi-panel work records `panel_hierarchy`, layout budget/shared-guide decisions, and any cognitive-load exception in the design plan or sidecars.
- `export_geometry` records preset, final width/height, DPI, column class, and profile envelope; it must agree with the rendered PNG physical dimensions.
- `qa.status` is `pass`, `warn`, or `fail`, and must agree with the exact machine-readable `overall status` in `*_qa.md`.
- `visual_qa_review` records whether a strict visual warning was accepted and why. It cannot override a hard visual failure.
- `old_vs_new_review` is `not_applicable` unless `figure_spec.old_figure_path` exists; then it points to checksum-matched completed comparison evidence.
- Post-render decisions may live in a stem-matched `*_review.json` written by `pp_write_review_sidecar()` instead of overwriting metadata. Review schema v1 binds the immutable metadata, QA report, current-schema rendered QA, and optional current-schema old-vs-new evidence by path and MD5.
- Bioinformatics `pass` records readable input files and MD5 checksums, organism/reference, coordinate enum, sample order, units/transforms/denominators, statistics, a stem-matched TSV plotting table and checksum, and five confirmed validation-evidence flags.
