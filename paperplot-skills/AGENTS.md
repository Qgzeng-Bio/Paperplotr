# Agent Notes

Use `paperplot-skills` for standalone R/ggplot2 scientific plotting tasks that need manuscript-style design, export, and QA.

## Required Behavior

- For main figures, load the project state and recompute freshness first; follow `references/figure-project-workflow.md`.
- Obtain layout confirmation separately from panel and final figure reviews. Build each panel at its allocated final size.
- Preserve immutable revisions and original data; compose drawing objects, never resized PNG tiles.
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
