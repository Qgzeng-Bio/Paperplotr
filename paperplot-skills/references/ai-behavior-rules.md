# AI Behavior Rules

These rules are mandatory when this skill is active.

## Before Coding

- Confirm the task is appropriate for PaperPlotR.
- Inspect available data columns when data is accessible.
- Choose a template before writing a script.
- Use complete runnable scripts for implementation tasks.
- Do not provide snippets only unless the user explicitly asks for snippets.

## PaperPlotR API Discipline

Do not invent PaperPlotR APIs. Prefer confirmed functions:

- `theme_lab()`
- `lab_palette()`
- `lab_gradient_palette()`
- `scale_fill_lab()`
- `scale_color_lab()`
- `scale_fill_groupmap()`
- `scale_color_groupmap()`
- `layout_lab()`
- `save_lab()`
- `save_lab_plot()`
- `panel_size()`
- `get_fig_size_cm()`
- `journal_preset()`
- `recommend_panel_spec()`
- `plot_box_paper()`, `plot_violin_paper()`, and `plot_dot_paper()` when present and appropriate.

If a desired helper is not confirmed, use ordinary `ggplot2` geoms plus PaperPlotR theme, scale, layout, and export helpers.

## Output Discipline

- Do not overwrite old output files by default.
- Use a timestamped or versioned output stem.
- Export at least one vector format for publication-grade work.
- Export a raster preview when useful.
- Write a notes file.
- Record file paths, file sizes, presets, devices, and QA checks.

## Iteration Discipline

- Render first.
- Inspect for hard issues.
- Patch one or two targeted settings at a time.
- Re-render after each targeted change.
- Do not make large unrelated visual changes in one pass.
- Report remaining issues instead of pretending the figure is final.

## Final Report Discipline

Report:

- What was generated.
- Input data used.
- Output files.
- PaperPlotR functions and presets.
- Quality checks.
- Remaining issues.
- Manuscript readiness.
