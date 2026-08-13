# Template Contract

All R templates must follow this sequence:

1. Load `ggplot2` and source `scripts/paperplot_helpers.R`.
2. Define `input_path`, `output_dir`, `figure_id`, and `preset`.
3. Define `figure_spec`, including or deliberately inferring a `journal_profile`.
4. Define `metric_spec`; multi-metric templates use one row per metric.
5. Read data and assert required columns.
6. Choose layout, palette, ordering, and label strategy.
7. Apply 9 pt base typography, record visual/cognitive burden, and build the ggplot object.
8. Export with `pp_save_all()`.
9. Write notes with `pp_write_notes()`.
10. Write metadata with `pp_write_metadata()`.
11. Write QA report with `pp_write_qa_report()`.
12. Bioinformatics templates write a stem-matched `_plotting_data.tsv` and a provenance scaffold. The scaffold remains `not_recorded` until real reference/statistical fields and evidence checks are completed.
13. Validate candidate outputs with `scripts/validate-figure-output.R`; candidate PASS means bundle integrity only.
14. Run current-schema strict rendered QA and optional old-vs-new comparison, then call `pp_write_review_sidecar()` to write an immutable stem-matched `*_review.json`. Strict validation verifies tool fingerprints and deterministically replays these analyses. Do not rewrite existing metadata merely to attach post-render evidence.
15. Use `--manuscript-ready` only after QA is pass, strict checksum-bound rendered QA exists, cognitive-load review is recorded, and required bioinformatics provenance is complete.
16. When a real old figure exists, set `figure_spec.old_figure_path` and attach completed checksum-matched old-vs-new evidence before manuscript-ready validation.
17. Refuse overwrites for all output and sidecar files.
18. QA reports must retain the common gates `figure_spec`, `cognitive_load_review`, `bioinformatics_validation`, `output_pdf`, `output_png`, `notes`, and `metadata`; template-specific gates may be added but cannot replace this set.

Templates should not install packages, call PaperPlotR APIs, or depend on optional graphics packages.
