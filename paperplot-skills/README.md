# paperplot-skills

`paperplot-skills` is a standalone Codex skill for publication-ready scientific figures in R/ggplot2.

It does not depend on the PaperPlotR R package. The reusable plotting standards live in `scripts/paperplot_helpers.R`.

## What It Provides

- ggplot2 templates for common scientific plots
- GraphPad-like palettes
- clean manuscript theme defaults
- figure and panel size presets
- versioned PDF and PNG export
- output validation
- sidecar notes
- visual QA gates
- pressure scenarios for agent behavior

## Validate

Run from the directory that contains `paperplot-skills/`:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

## Dependency Policy

Required:

- R
- ggplot2

Not required:

- PaperPlotR
- patchwork
- ragg
- svglite
- cli
- rlang
- scales
