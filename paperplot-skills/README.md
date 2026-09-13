# paperplot-skills

`paperplot-skills` is a standalone Codex skill for publication-ready scientific figures in R/ggplot2.

It does not depend on the PaperPlotR R package. The reusable plotting standards live in `scripts/paperplot_helpers.R`.

Production uses final-size Arial typography: 6-8 pt ordinary text and 12 pt bold
A/B/C/D tags, 180 mm main-composite width or 89 mm single-column width.
The IGS case uses 183 x 105 mm. Run `scripts/check-environment.R` first;
see [the production contract](references/production-render-contract.md) for
data preservation, explicit demo mode, physical export audits and final QA.
No missing data are synthesized in production. File smoke-test success is
reported separately from visual acceptance and human review.

## Install

One-line install into Codex:

```bash
curl -fsSL https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | sh
```

If `curl` is unavailable or broken:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | sh
```

Pinned release install:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/v0.1.0/install-paperplot-skill.sh | PAPERPLOT_REF=v0.1.0 sh
```

Restart Codex after installation.

The one-line installer defaults to the runtime profile: `SKILL.md`, `agents/`,
`references/`, `templates/`, and core scripts. Use `PAPERPLOT_PROFILE=full` for
development reports, examples, pressure scenarios, and dev scripts.

If the skill already exists, replace it explicitly:

```bash
curl -fsSL https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | PAPERPLOT_OVERWRITE=1 sh
```

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

Run from the full source checkout or a `PAPERPLOT_PROFILE=full` install. From
the directory that contains `paperplot-skills/`:

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
