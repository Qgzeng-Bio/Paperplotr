# Template Contract

All R templates must follow this sequence:

1. Load `ggplot2` and source `scripts/paperplot_helpers.R`.
2. Define `input_path`, `output_dir`, `figure_id`, and `preset`.
3. Define `figure_spec`.
4. Define `metric_spec`; multi-metric templates use one row per metric.
5. Read data and assert required columns.
6. Choose layout, palette, ordering, and label strategy.
7. Build the ggplot object.
8. Export with `pp_save_all()`.
9. Write notes with `pp_write_notes()`.
10. Write metadata with `pp_write_metadata()`.
11. Write QA report with `pp_write_qa_report()`.
12. Refuse overwrites for all output and sidecar files.

Templates should not install packages, call PaperPlotR APIs, or depend on optional graphics packages.
