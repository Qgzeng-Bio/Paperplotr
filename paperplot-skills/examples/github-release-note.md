# GitHub Release Note Draft

## paperplot-skills v1

This release adds `paperplot-skills`, a repository-local AI scientific plotting
skill for PaperPlotR. The skill turns PaperPlotR into a reusable AI-guided
workflow for publication-ready R figures: template selection, semantic color
mapping, panel sizing, journal/export presets, versioned no-overwrite outputs,
sidecar notes, and quality checks.

The skill is intentionally generic. It is not a project-specific plotting
workflow and does not use domain-specific dictionaries by default.

Validation:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

Current coverage includes 8 runnable R templates:

- single-panel figure
- multi-panel layout
- comparison boxplot
- violin plus dot plot
- correlation scatter
- heatmap
- PCA scatter
- barplot

Use it when an AI agent needs to produce reproducible, publication-ready
scientific figures with ggplot2 and PaperPlotR. Do not use it for mechanism
diagrams, pathway cartoons, graphical abstracts, interactive charts, or
Python-only workflows.
