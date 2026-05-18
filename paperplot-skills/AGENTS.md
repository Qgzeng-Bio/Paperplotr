# Agent Notes

Use `paperplot-skills` for standalone R/ggplot2 scientific plotting tasks that need manuscript-style design, export, and QA.

## Required Behavior

- Diagnose source figures before redesigning.
- Use `scripts/paperplot_helpers.R`; do not load PaperPlotR.
- Start from a template in `templates/`.
- Preserve old outputs and create timestamped new outputs.
- Export PDF and PNG.
- Write notes with design decisions and QA results.
- Use small multiples by default for 5-8 heterogeneous metrics.

## Validation

Run from this directory's parent:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```
