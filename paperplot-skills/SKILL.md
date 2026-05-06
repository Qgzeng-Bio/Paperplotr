---
name: paperplot-skills
description: Use this skill when creating, refining, or QA-checking publication-ready scientific figures with PaperPlotR and ggplot2 in R. It guides AI agents to choose scientific plot templates, write complete reproducible R scripts, apply theme_lab(), scale_*_lab()/scale_*_groupmap(), layout_lab(), save_lab()/save_lab_plot(), version outputs, export vector and raster formats, and record quality notes. Do not use for mechanism diagrams, graphical abstracts, interactive web charts, image generation, or Python-only plotting.
---

# PaperPlot Skills

## Overview

This is a general scientific plotting AI skill with PaperPlotR as the R execution backend. Use it as a figure standardizer: choose an appropriate scientific plot template, write a complete runnable R script, apply PaperPlotR styling/sizing/export helpers, render new versioned files, and record QA notes.

This is not a PaperPlotR API manual. It is a workflow for producing reproducible, publication-ready ggplot2 figures.

## When to Use

Use this skill for:

- R or ggplot2 scientific plotting tasks.
- Publication-ready manuscript, journal, report, or grant figures.
- Nature, Cell, Nature Communications, or similar style figure export.
- Multi-panel scientific figures.
- Statistical comparison plots.
- Bioinformatics-style statistical plots.
- Figure style standardization.
- Legend, color, panel size, and export control.

## Do Not Use For

Do not use this skill for:

- Mechanism diagrams, pathway cartoons, graphical abstracts, or complex SVG illustrations.
- Flowcharts, network architecture diagrams, or Mermaid/Graphviz-style diagrams.
- Interactive web charts or dashboards.
- Python/matplotlib-only workflows.
- Map/geospatial plots unless the user explicitly wants an R/ggplot2 route.
- Image generation, AI art, or decorative illustration.

For boundary decisions, read `references/boundaries-and-non-goals.md`.

## Core Philosophy

- Clarity > logic > consistency > aesthetics.
- Scientific message first.
- No software-default look.
- No unnecessary decoration.
- Reproducibility first.

## Mandatory AI Behavior Rules

- For implementation tasks, generate a complete runnable R script; do not provide snippets only.
- Inspect available PaperPlotR functions before inventing APIs.
- Use PaperPlotR functions when applicable: `theme_lab()`, `scale_*_lab()`, `scale_*_groupmap()`, `layout_lab()`, `save_lab()`, and `save_lab_plot()`.
- Do not overwrite previous outputs by default.
- Use a timestamped or versioned output stem.
- Export at least one vector format for publication-grade work.
- Record output paths, file sizes, presets, and QA notes.
- When refining an existing plot or script, preserve the original and create new output files.

For strict agent rules, read `references/ai-behavior-rules.md`.

## Standard PaperPlotR Workflow

1. Read and validate input data.
2. Construct a `ggplot2` object.
3. Apply `theme_lab()`.
4. Apply `scale_*_lab()` for palette-driven colors or `scale_*_groupmap()` for semantic group colors.
5. Compose panels with `layout_lab()` when needed.
6. Export with `save_lab()` or `save_lab_plot()`.
7. Validate output files.
8. Write sidecar notes.

For details and code skeletons, read `references/paperplotr-workflow.md`.

## Preserve PaperPlotR Strengths

Use PaperPlotR to preserve:

- Panel size and figure size presets.
- Journal presets.
- Semantic color mapping.
- Palette consistency.
- Legend control.
- Minimum text size validation.
- Export validation.
- Multi-panel composition.
- Reproducible R scripts.

## Figure Quality Rules

Check fonts, line widths, axis design, tick density, legend placement, color palette, colorblind safety, panel labels, multi-panel alignment, and caption/figure legend consistency. Read `references/figure-quality-checklist.md` before final QA.

## Export and Versioning Rules

- Never overwrite old outputs by default.
- Use a timestamped output stem.
- Export PDF or SVG for vector output.
- Export PNG or TIFF when previews or submission systems need raster output.
- Use 600 dpi for raster output unless a journal/user requirement says otherwise.
- Write a sidecar notes file.

Read `references/export-and-versioning.md` when building export code.

## Template Selection

Choose one template first, then adapt it:

- `templates/single-panel-template.R`
- `templates/multi-panel-template.R`
- `templates/comparison-boxplot-template.R`
- `templates/violin-dot-template.R`
- `templates/correlation-scatter-template.R`
- `templates/heatmap-template.R`
- `templates/pca-scatter-template.R`
- `templates/barplot-template.R`

For template choice, read `references/template-selection-guide.md`.

## Iterative QA Loop

1. Render the figure.
2. Inspect the output.
3. Detect hard issues: overlaps, crowded axes, legend collisions, colorbar crowding, unreadable text, panel label collisions, wrong panel order, or figure legend mismatch.
4. Patch one targeted issue at a time.
5. Re-render.
6. Stop when hard issues are resolved or report remaining issues clearly.

## Optional Domain Extensions

Domain-specific color dictionaries are optional. Do not use project-specific mappings by default. Use them only when the user explicitly requests that domain or provides a semantic color mapping.

## Final Response Format

When a plotting task is complete, report:

1. What was generated.
2. Input data used.
3. Output files.
4. PaperPlotR preset used.
5. Quality checks performed.
6. Remaining issues, if any.
7. Whether the figure is ready for manuscript use or needs another refinement pass.
