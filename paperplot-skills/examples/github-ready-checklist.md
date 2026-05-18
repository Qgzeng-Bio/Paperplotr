# Skill Readiness Checklist

## Standalone Dependency Check

- [ ] Templates load `ggplot2`.
- [ ] Templates source `scripts/paperplot_helpers.R`.
- [ ] Templates do not load PaperPlotR.
- [ ] Templates do not require patchwork, ragg, svglite, cli, rlang, or scales.
- [ ] Helper functions use base R, grDevices, grid, tools, and ggplot2 only.

## Template Check

- [ ] All templates refuse overwrites.
- [ ] All templates use timestamped output stems.
- [ ] All templates export PDF and PNG.
- [ ] All templates write notes.
- [ ] Notes include design decisions and QA gate results.

## Design Behavior Check

- [ ] Old figure redraws start with diagnosis.
- [ ] 5-8 heterogeneous metrics default to small multiples.
- [ ] Dot/bubble heatmaps are rejected when harder to read.
- [ ] Color legends include units or percentages.
- [ ] Gridlines are disabled unless justified.

## Validation

- [ ] `Rscript paperplot-skills/scripts/validate-skill.R`
- [ ] `Rscript paperplot-skills/scripts/smoke-test-templates.R`
