# Standalone Skill Release Note

`paperplot-skills` is now a standalone R/ggplot2 scientific plotting skill. It no longer depends on the PaperPlotR R package. The skill vendors its plotting standards through `scripts/paperplot_helpers.R`, including theme, palettes, figure presets, export checks, notes, and multi-metric layout heuristics.

Highlights:

- standalone ggplot2 helper layer
- GraphPad-like palettes
- no default gridlines
- versioned PDF and PNG outputs
- design diagnosis before redraws
- hard visual QA gates
- small-multiple default for 5-8 heterogeneous metrics
