# Final skill test report

## Scope

This report records the finalization pass for `paperplot-skills` as a standalone professional scientific plotting skill. The skill remains independent of the PaperPlotR R package and uses base R + ggplot2 as the hard dependency baseline.

## External references consulted

- Nature Research Figure Guide: graph requirements, accessibility, editable vector output, text size, standard fonts, and avoidance of gridlines/decorative elements.
- Nature figure sizing guidance: 89 mm single-column, 183 mm double-column, and about 170 mm maximum height.
- NCBI GEO DataSets: public repository context for gene expression and functional genomics data.
- NCBI-generated RNA-seq count data: public RNA-seq count matrix structure, raw/normalized count caveats, and differential-expression visualization use cases.

No copyrighted figure was copied. Public guidance and public data structures were used to define reproducible pressure scenarios and QA expectations.

## Current skill audit

### Strengths

- Standalone R/ggplot2 implementation.
- 19 executable templates.
- PDF, PNG, notes, metadata JSON, QA sidecars.
- No PaperPlotR dependency.
- Design brief, design plan, visual budget, label strategy, statistical expression, and bioinformatics semantics are implemented.
- Pressure scenarios check design decisions, not just file existence.

### Gaps found before this pass

- `SKILL.md` was outdated and listed only 11 templates.
- Final visual standards were not centralized.
- Image-level QA was described only implicitly.
- Old-vs-new comparison did not have a dedicated final workflow document.
- Cross-backend guidance was incomplete.
- Figure-type-specific quality standards did not cover specialized scientific plots such as Manhattan, genome tracks, synteny, phylogeny, networks, and schematics.

## Changes in this pass

- Rewrote `SKILL.md` as final professional entrypoint.
- Added `publication-visual-standards.md`.
- Added `image-level-qa.md`.
- Added `old-vs-new-comparison.md`.
- Added `figure-type-quality-rubric.md`.
- Added `cross-backend-workflows.md`.
- Added `visual-qa-report.R` for rendered-output dimension checks and visual QA report scaffolding.
- Updated `validate-skill.R` to require the final-version files.

## Validation cases

### Static skill validation

Checks skill structure, required files, forbidden PaperPlotR/API patterns, required helper functions, and all templates.

Expected: pass.

### Template smoke tests

Runs all 19 templates against reproducible synthetic scientific data covering:

- single panel,
- multi-panel,
- boxplot/jitter,
- violin/dot,
- scatter/correlation,
- heatmap,
- PCA,
- barplot,
- multi-metric small multiples,
- rank-plus-key metrics,
- manuscript four-panel layout,
- paired comparison,
- effect-size forest,
- genome quality overview,
- duplication-mode comparison,
- volcano,
- MA,
- enrichment dot plot.

Expected: 19/19 pass.

### Pressure scenarios

Runs decision-level checks for:

- genome quality dense labels,
- dense sample labels,
- volcano selected labels,
- enrichment top terms,
- duplication panel hierarchy.

Expected: 5/5 pass.

## Nature-style principle alignment

| principle | implementation |
|---|---|
| standard figure widths | publication visual standards and presets |
| legible editable text | visual standards, export contract, backend notes |
| accessible colors | color standards and QA hard gates |
| avoid decorative elements | SKILL hard gates |
| axis units and tick marks | scientific hard gates |
| efficient panel layout | multi-panel hierarchy and old-vs-new workflow |
| vector export | PDF default and backend guidance |
| dense labels reduced | rank-index + sidecar policy |

## Self-review after finalization

### Remaining limits

- Image-level QA is still checklist-driven and dimension-aware, not full computer-vision overlap detection.
- Specialized plots such as circos, synteny, genome tracks, phylogenetic trees, and networks have strong rubric guidance but not complete drawing templates.
- Python backend is documented but not implemented as a full parallel template system.
- Nature-like quality still requires human/agent visual inspection of rendered output.

### Next iteration recommendation

- Add true image analysis for label overlap and whitespace balance.
- Add specialized data-structure templates for genome tracks, synteny, Manhattan, phylogeny, and networks.
- Add a Python backend only after the R design contract remains stable.

## Actual validation run

Run date: 2026-05-18 Asia/Shanghai.

Commands executed:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
Rscript paperplot-skills/scripts/run-pressure-scenarios.R
Rscript paperplot-skills/scripts/validate-figure-output.R /tmp/paperplot-skills-smoke-20260518-203110/bio-genome-quality-overview-template/outputs
Rscript paperplot-skills/scripts/visual-qa-report.R /tmp/paperplot-skills-smoke-20260518-203110/bio-genome-quality-overview-template/outputs
```

Results:

- Static validation: passed.
- Template smoke tests: 19/19 templates passed.
- Pressure scenarios: 5/5 scenarios passed.
- Figure output validation for genome-quality output: passed.
- Rendered visual QA scaffold generated at `/private/tmp/paperplot-skills-smoke-20260518-203110/bio-genome-quality-overview-template/outputs/visual_qa_report_20260518-203138.md`.

## Iteration record

Initial finalization pass added the final entrypoint and reference documents. Self-review found that the workflow still lacked a concrete rendered-output QA artifact, so `scripts/visual-qa-report.R` was added and included in validation. This provides dimension/file checks and a mandatory manual image-level QA checklist without adding new hard dependencies.

## Final assessment

The skill is now suitable as a stable professional baseline for AI-assisted scientific plotting. It has strong coverage for common R/ggplot2 manuscript plots and bioinformatics figures. It can diagnose and control the figure-quality floor, but fully automated visual judgement remains limited without true computer-vision overlap detection or domain-specific specialized templates for circos, synteny, genome tracks, phylogenetic trees, and networks.
