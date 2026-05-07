# Agent Entry Point

Use this file when an AI agent does not have native skill discovery.

## Scope

Use `paperplot-skills` for R or ggplot2 scientific plotting tasks where the user
wants publication-ready output with PaperPlotR.

Do not use it for mechanism diagrams, pathway cartoons, graphical abstracts,
interactive web charts, image generation, or Python-only plotting workflows.

## Required Reading Order

1. Read `paperplot-skills/SKILL.md`.
2. Read `paperplot-skills/references/template-selection-guide.md`.
3. Select one R template under `paperplot-skills/templates/`.
4. Read only the reference files needed for the selected task.

## Agent Rules

- Generate complete runnable R scripts for implementation tasks.
- Use PaperPlotR functions when applicable.
- Do not invent PaperPlotR APIs.
- Do not overwrite prior figure outputs by default.
- Use timestamped or versioned output stems.
- Export at least one vector format for manuscript-ready figures.
- Write sidecar notes recording outputs, presets, and quality checks.
- Keep the workflow generic unless the user explicitly provides a domain-specific mapping.

## Validation

From the PaperPlotR repository root:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```
