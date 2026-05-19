# PaperPlotR / paperplot-skills Handoff

Last updated: 2026-05-19

## Repository

- Workspace: `/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR`
- R package root: `/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr`
- Skill root: `/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr/paperplot-skills`
- Replica R library: `/Users/qingguozeng/Documents/1-博士课题/3-科研资料/MsTt笔记100+绘图合集/R科研绘图合集`
- Replica Python library: `/Users/qingguozeng/Documents/1-博士课题/3-科研资料/MsTt笔记100+绘图合集/Python科研绘图合集`

## Current State

`paperplot-skills` has been upgraded from a rule-driven scientific plotting skill into a pattern-library-driven scientific figure design system.

The skill remains standalone:

- Do not call `library(PaperPlotR)`.
- Do not depend on `theme_lab()`, `save_lab_plot()`, or other PaperPlotR package APIs.
- R templates should remain based on base R + ggplot2 unless a template explicitly documents an optional dependency.
- Python is used for indexing, calibration, rendered-image QA, and old-vs-new comparison, not as the primary plotting backend for this round.

The main workflow is now:

```text
input data/code/old figure
-> detect data roles and figure family
-> consult pattern library
-> generate design brief
-> generate pattern-based design plan
-> select template or redraw strategy
-> render PDF/PNG
-> run rendered-image visual QA
-> run old-vs-new comparison when an old figure exists
-> iterate or report remaining risks
-> write notes, metadata, QA, sidecars
```

Important behavioral rule: detecting that a figure is bad is not enough. If data/code are available, the skill should attempt a better pattern-based redraw and verify it. If the new figure is not clearly better, it must say so and either iterate or explain the missing information.

Important layout rule from the latest GS-quality demo review: proportional balance is a hard manuscript requirement. Multi-panel previews must not stitch plots with different source aspect ratios as if they were equal panels. Equal-role panels need equal panel boxes and visually comparable data regions; unequal panel sizes must encode a deliberate evidence hierarchy, not accidental export dimensions, legend placement, or margin differences.

Current QA upgrade in progress/completed after that review: `visual-qa-rendered-image.py` now supports PDF/SVG rasterized QA, panel geometry metrics, and optional OCR status; `compare-old-new-figures.py` now writes an old-vs-new review rubric and does not claim final improvement without completed human review. Use `--expected-panels` and `--layout-profile equal` for equal-role multi-panel figures.

## Git / Working Tree Note

The worktree was rechecked on 2026-05-18 and is not clean.

A checkpoint commit was created before the follow-up implementation:

```text
bf65495 Upgrade paperplot skills pattern library
```

Follow-up work after that checkpoint added family-specific visual QA profiles and the model-validation composite template. Inspect `git status --short` and `git diff` before any further commit.

Do not assume all modified files were touched in the final handoff step.

## Major Deliverables Completed

### Replica Pattern Index

Generated:

- `paperplot-skills/reports/nature-replica-pattern-index.md`
- `paperplot-skills/reports/nature-replica-pattern-index.json`
- script: `paperplot-skills/scripts/index-replica-patterns.py`

Latest run:

```text
indexed 87 cases
R=80, Python=7
```

The index records case directory, language, output file types, code files, data file types, likely figure family, application scenario, skill suitability, visual-QA suitability, template suitability, dependency complexity, and generalization risks.

Observed family coverage includes heatmaps, grouped bars, scatter/regression, violin/raincloud/jitter, enrichment/volcano/MA, ridgeline/density, multi-panel layouts, polar/radar, circos/chord/synteny-like plots, ordination, network/Sankey, map/spatial, dot/lollipop/dumbbell, UpSet, Manhattan, and phylogenetic annotation-ring plots.

### Pattern Library

Created:

- `paperplot-skills/references/pattern-library/grouped-bar-errorbar.md`
- `paperplot-skills/references/pattern-library/raincloud-violin-jitter.md`
- `paperplot-skills/references/pattern-library/scatter-regression-marginal.md`
- `paperplot-skills/references/pattern-library/correlation-heatmap.md`
- `paperplot-skills/references/pattern-library/pca-pcoa-ordination.md`
- `paperplot-skills/references/pattern-library/volcano-ma-enrichment.md`
- `paperplot-skills/references/pattern-library/manhattan-genomewide.md`
- `paperplot-skills/references/pattern-library/phylo-annotation-ring.md`
- `paperplot-skills/references/pattern-library/upset-set-plot.md`
- `paperplot-skills/references/pattern-library/circos-chord-sankey.md`
- `paperplot-skills/references/pattern-library/multi-panel-manuscript-layout.md`
- `paperplot-skills/references/pattern-library/model-validation-figures.md`

Each pattern doc includes:

- applies / does not apply
- input data structure
- visual encoding
- layout
- typography, line width, point size, legend strategy
- color strategy
- common failure modes
- Nature-like manuscript principles
- existing template links
- whether a new template is needed
- QA checklist
- visual QA focus
- old-vs-new criteria

### Visual QA Calibration

Generated:

- `paperplot-skills/reports/visual-qa-calibration-from-replica-library.md`
- `paperplot-skills/reports/visual-qa-calibration-from-replica-library.json`
- script: `paperplot-skills/scripts/calibrate-visual-qa.py`

Latest run:

```text
calibrated 30 positive examples
status counts after family-specific profiles: warn=28, pass=2, fail=0
```

Key conclusion: many high-quality positive examples still trigger deterministic `warn`. Treat `warn` as a review prompt, not an automatic failure. Dense families such as heatmaps, Manhattan plots, phylogenetic rings, UpSet matrices, and multi-panel figures need family-specific interpretation.

Family-specific visual QA profiles now exist for:

- `rank-lollipop`
- `model-validation`
- `heatmap`
- `manhattan`
- `phylo-annotation-ring`

Use:

```bash
python3 paperplot-skills/scripts/visual-qa-rendered-image.py <figure.png> --out <qa_dir> --family <family>
```

`compare-old-new-figures.py` also accepts `--family`, `--old-family`, and `--new-family`.

### Figure Type Selector and Style System

Updated / added:

- `paperplot-skills/references/figure-type-selector.md`
- `paperplot-skills/references/publication-visual-standards.md`
- `paperplot-skills/references/manuscript-aesthetics-rules.md`
- `paperplot-skills/references/nature-like-style-principles.md`
- `paperplot-skills/references/color-and-style-policy.md`
- `paperplot-skills/references/old-vs-new-visual-scoring.md`
- `paperplot-skills/references/visual-qa-gates.md`

The selector now emphasizes data-role detection:

- sample
- group
- metric
- value
- feature
- genomic coordinate
- uncertainty/statistic
- network edge/node
- tree/tip/annotation

It also documents when not to use a family, main-vs-supplement-vs-diagnostic strategy, dense labels, too many groups/metrics, small n, paired data, mixed units, and specialized data requirements for circos, synteny, genome tracks, phylogenetic trees, and networks.

### SKILL.md Workflow

Updated:

- `paperplot-skills/SKILL.md`

Current `SKILL.md` requires:

1. diagnose user input
2. detect roles and figure family
3. consult pattern library
4. create design brief
5. create figure/metric spec
6. create pattern-based design plan
7. run visual burden checks
8. render/export
9. run image QA
10. run old-vs-new comparison when applicable
11. iterate or report blocker if new figure is not better
12. output PDF/PNG/notes/metadata/QA/visual_qa/old_vs_new

### Helper and Template Updates

Important helper changes:

- `paperplot-skills/scripts/paperplot_helpers.R`
  - helper version now `standalone-0.3.0`
  - added `pp_pattern_reference()`
  - metadata and notes now include pattern-library references when available
- `paperplot-skills/scripts/lib/design-brief.R`
  - `pp_design_plan()` accepts and stores `pattern_reference`
- `paperplot-skills/scripts/compare-old-new-figures.py`
  - now records `old_media`, `new_media`, and `comparison_limitation`
  - mixed SVG/raster comparisons are flagged as limited, not directly numeric-equivalent

Selected templates were tightened with pattern-informed style defaults and output notes:

- `grouped-boxplot-jitter-template.R`
- `violin-dot-template.R`
- `correlation-scatter-template.R`
- `heatmap-template.R`
- `pca-scatter-template.R`
- `volcano-plot-template.R`

Added:

- `model-validation-composite-template.R`

All 20 templates passed smoke tests after the changes.

## End-to-End Redraw Benchmark

Generated:

- `paperplot-skills/reports/end-to-end-redraw-benchmark.md`
- script: `paperplot-skills/scripts/run-redraw-benchmark.R`
- output directory: `paperplot-skills/reports/redraw-benchmark/`

### Case 1: GS Quality Traits

Old figure:

- `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/10-GS/final_results/figures/fig4_quality_traits.png`

Data:

- `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/10-GS/final_results/tables/quality_nonlinear_summary.tsv`

New outputs:

- `paperplot-skills/reports/redraw-benchmark/fig4_quality_traits_pattern_redraw.pdf`
- `paperplot-skills/reports/redraw-benchmark/fig4_quality_traits_pattern_redraw.png`

Result:

- old manuscript-readiness score: 6
- new manuscript-readiness score: 10
- old-vs-new verdict: `mixed`

Interpretation: visually and manuscript-style improved, but deterministic blank-margin and content-density metrics worsened. The report correctly does not claim unconditional success.

### Case 2: High NLR Count by Sample

Old SVG:

- `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_count_by_sample.svg`

Comparable old PNG:

- `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/06_supplementary_qc_figures/final_figures/png_600dpi/high_nlr_count_by_sample.final.png`

Data:

- `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/data/high_nlr_sample_counts_for_plot.tsv`

New outputs:

- `paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.pdf`
- `paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png`

Result:

- old SVG manuscript-readiness score: 5
- old PNG manuscript-readiness score: 6
- new manuscript-readiness score: 10
- old-vs-new verdict: `mixed`

Interpretation: sorted lollipop is more manuscript-like for one count per sample. A horizontal-bar iteration was tried and rejected because it increased visual burden. Mixed SVG/raster comparison is explicitly flagged as limited.

## Self Review

Generated:

- `paperplot-skills/reports/skill-self-review-after-pattern-library.md`

Main conclusions:

- The skill is now more professional because it has an indexed pattern corpus, pattern docs, a role-based selector, positive-example calibration, pattern-linked metadata, and real redraw benchmarks.
- Remaining weak areas: specialized templates for Manhattan/UpSet, PDF rasterization for calibration, and stronger mixed-panel layout examples.
- Visual QA can still over-warn on high-quality dense figures.
- Old-vs-new comparison is useful but cannot prove scientific correctness or all aesthetic tradeoffs.

Corrections applied after review:

- `compare-old-new-figures.py` now records mixed-media comparison limitations.
- `old-vs-new-visual-scoring.md` and `visual-qa-gates.md` now explicitly warn about density interpretation and SVG/raster comparability.

## Validation Run

All required verification commands were run successfully from:

```text
/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr
```

Commands and results:

```bash
python3 paperplot-skills/scripts/index-replica-patterns.py
```

```text
indexed 87 cases
```

```bash
python3 paperplot-skills/scripts/calibrate-visual-qa.py
```

```text
calibrated 30 positive examples
```

```bash
Rscript paperplot-skills/scripts/run-redraw-benchmark.R
```

```text
redraw benchmark figures written to paperplot-skills/reports/redraw-benchmark
```

```bash
Rscript paperplot-skills/scripts/validate-skill.R
```

```text
paperplot-skills standalone validation passed
```

```bash
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

```text
20/20 templates passed smoke tests
temporary smoke root: /tmp/paperplot-skills-smoke-20260518-233459
```

```bash
Rscript paperplot-skills/scripts/run-pressure-scenarios.R
```

```text
5/5 pressure scenarios passed
temporary pressure root: /tmp/paperplot-pressure-20260518-233522
```

```bash
python3 paperplot-skills/scripts/run-visual-pressure-scenarios.py
```

```text
all expected visual scenarios passed
visual-old-vs-new-metric-delta: warn / mixed
visual-family-lollipop-threshold: pass / readiness 10
```

Benchmark QA and comparisons rerun:

```bash
python3 paperplot-skills/scripts/visual-qa-rendered-image.py \
  paperplot-skills/reports/redraw-benchmark/fig4_quality_traits_pattern_redraw.png \
  --out paperplot-skills/reports/redraw-benchmark/qa_fig4_new \
  --family model-validation

python3 paperplot-skills/scripts/visual-qa-rendered-image.py \
  paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png \
  --out paperplot-skills/reports/redraw-benchmark/qa_nlr_new \
  --family lollipop

python3 paperplot-skills/scripts/compare-old-new-figures.py \
  /Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/10-GS/final_results/figures/fig4_quality_traits.png \
  paperplot-skills/reports/redraw-benchmark/fig4_quality_traits_pattern_redraw.png \
  --out paperplot-skills/reports/redraw-benchmark/compare_fig4 \
  --new-family model-validation

python3 paperplot-skills/scripts/compare-old-new-figures.py \
  /Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_count_by_sample.svg \
  paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png \
  --out paperplot-skills/reports/redraw-benchmark/compare_nlr_svg_old \
  --new-family lollipop

python3 paperplot-skills/scripts/compare-old-new-figures.py \
  /Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/06_supplementary_qc_figures/final_figures/png_600dpi/high_nlr_count_by_sample.final.png \
  paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png \
  --out paperplot-skills/reports/redraw-benchmark/compare_nlr_png_old \
  --new-family lollipop
```

## Important Reports

- `paperplot-skills/reports/nature-replica-pattern-index.md`
- `paperplot-skills/reports/visual-qa-calibration-from-replica-library.md`
- `paperplot-skills/reports/end-to-end-redraw-benchmark.md`
- `paperplot-skills/reports/skill-self-review-after-pattern-library.md`
- `paperplot-skills/reports/visual-qa-real-figure-test-report.md`
- `paperplot-skills/reports/final-skill-test-report.md`

## Current Limitations

- The skill is design-system-like, but not a learned visual model.
- Visual QA remains heuristic and deterministic.
- Positive examples show that many good figures can be `warn`, especially dense scientific panels.
- SVG is structurally inspected; raster metrics are not directly comparable unless the SVG is rendered to pixels.
- PDF-only replica cases were not directly calibrated because a PDF rasterization path is not yet wired into calibration.
- CircOS/chord/tree/UpSet/Manhattan patterns are documented, but not all have stable standalone templates.
- Scientific correctness still depends on data semantics, caption context, interval definitions, and human review.

## Recommended Next Phase

Highest-value next work:

1. Add `manhattan-plot-template.R`.
2. Add `upset-summary-template.R`.
3. Add PDF rasterization to visual QA calibration.
4. Strengthen heatmap annotation-strip and dendrogram strategy.
5. Improve benchmark iteration so old-vs-new can produce a clearer `improved` verdict when appropriate.
6. Add more real redraw benchmarks across heatmap, scatter/regression, enrichment, and ordination families.

## Practical Release Checklist

Before committing or publishing:

1. Recheck `git status --short`.
2. Inspect `git diff -- paperplot-skills`.
3. Confirm no generated temporary files should be excluded.
4. Run:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
Rscript paperplot-skills/scripts/run-pressure-scenarios.R
python3 paperplot-skills/scripts/run-visual-pressure-scenarios.py
```

5. Confirm `paperplot-skills` still has no hard dependency on the PaperPlotR R package.
6. If publishing as a Codex skill, copy/install the updated `paperplot-skills` directory to the intended skills location.
