# AI Behavior Rules

These rules are mandatory when this skill is active.

## Before Coding

- Confirm the task is a data-driven R/ggplot2 scientific plot.
- Inspect available data columns when data is accessible.
- Diagnose source-figure issues before redesigning.
- Choose a template before writing a script.
- Use complete runnable scripts for implementation tasks.
- Do not provide snippets only unless the user explicitly asks for snippets.

## API Discipline

Use only the standalone helper functions in `scripts/paperplot_helpers.R`:

- `pp_theme()`
- `pp_palette()` and `pp_gradient_palette()`
- `pp_group_colors()`
- `pp_scale_color()` and `pp_scale_fill()`
- `pp_output_preset()` and `pp_panel_size()`
- `pp_recommend_layout()`
- `pp_save_plot()`
- `pp_assert_output()`
- `pp_write_notes()`

Do not call external package-specific helper APIs beyond ggplot2.

## Output Discipline

- Do not overwrite old output files by default.
- Use a timestamped or versioned output stem.
- Export at least one vector format.
- Export PNG for preview.
- Write notes with design decisions and QA results.

## Iteration Discipline

- Render first.
- Inspect for hard issues.
- Patch one or two targeted settings at a time.
- Re-render after each targeted change.
- Report remaining issues instead of pretending the figure is final.
