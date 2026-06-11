# PaperPlotR / paperplot-skills Handoff

Last updated: 2026-06-11 (v0.1.0 public release + local Codex install)
Previous major update: 2026-06-10 (Linux server deployment + portability/QA branch)
Earlier Mac update: 2026-05-19 (pattern-library upgrade — see sections below)

---

## 2026-06-11 — v0.1.0 Public Release + Current Codex Install

Final public-distribution step is complete.

### GitHub release state

- `main` has been fast-forwarded and pushed.
- `v0.1.0` annotated tag has been created and pushed.
- Release commit:

```text
9b2478a Add remote skill install workflow
```

- `HEAD`, `origin/main`, `origin/portability-linux-fixes`, and `v0.1.0` all point at `9b2478a` at handoff time.
- Local repo state after release: `main...origin/main` with no uncommitted changes.

### Public install commands

Latest `main` runtime install:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | sh
```

Pinned `v0.1.0` runtime install:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/v0.1.0/install-paperplot-skill.sh | PAPERPLOT_REF=v0.1.0 sh
```

Full development/validation bundle:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/v0.1.0/install-paperplot-skill.sh | PAPERPLOT_REF=v0.1.0 PAPERPLOT_PROFILE=full sh
```

Note: this server's conda `curl` reports `curl: (48) An unknown option was passed in to libcurl`; the installer falls back to `wget`. Prefer the `wget` command on this host.

### GitHub Actions status

New workflow:

- `.github/workflows/skill-remote-install.yaml`

Verified successful runs for commit `9b2478a`:

```text
skill-remote-install  main    completed success
skill-remote-install  v0.1.0  completed success
R-CMD-check           main    completed success
test-coverage         main    completed success
lint                  main    completed success
pkgdown               main    completed success
paperplot-skills      main    completed success
```

The remote-install workflow tests both:

- runtime profile: installs only `SKILL.md`, `agents/`, `references/`, `templates/`, and core scripts; confirms `reports/` and dev benchmark scripts are absent.
- full profile: confirms committed reports, examples, and validation scripts are present.

### Current local Codex install

Installed into the active Codex skills directory from the `v0.1.0` release:

```text
/data9/home/qgzeng/.codex/skills/paperplot-skills
```

Important: this path is now a real runtime directory, not the previous symlink to the development checkout.

The previous backup remains untouched:

```text
/data9/home/qgzeng/.codex/skills/paperplot-skills.bak-20260610
```

Installed runtime contents:

```text
SKILL.md
agents/
references/
scripts/
templates/
```

Core runtime script set:

```text
scripts/compare-old-new-figures.py
scripts/lib/bioinformatics-semantics.R
scripts/lib/design-brief.R
scripts/lib/design-qa.R
scripts/lib/label-strategy.R
scripts/lib/layout-planner.R
scripts/lib/redraw-strategy.R
scripts/lib/statistical-expression.R
scripts/paperplot_helpers.R
scripts/validate-figure-output.R
scripts/visual-qa-rendered-image.py
scripts/visual-qa-report.R
```

Local install validation:

```text
quick_validate.py /data9/home/qgzeng/.codex/skills/paperplot-skills -> Skill is valid!
installed runtime size on this host -> 450K
```

Codex must be restarted to load the newly installed `v0.1.0` skill in a fresh session.

### Final quality score after release hardening

Current assessment for the skill, in its intended positioning as a publication-ready scientific figure skill:

```text
9.3 / 10
```

Rationale:

- Core plotting/QA ability retained: `smoke-test-templates.R` passed 20/20 templates.
- Public distribution is now real: `main` install, pinned `v0.1.0` install, and GitHub Actions remote install all pass.
- Runtime profile is lightweight and stable; full profile preserves development reports and validation assets.
- Remaining gap to 9.5+: broader cross-environment user testing beyond GitHub Actions/Linux and more external user examples.

---

## 2026-06-11 — Remote-Install Readiness Fixes

Superseded by the `v0.1.0` public release section above. Keep this section as historical implementation detail.

- R smoke/pressure validation now reuses the invoking R binary by default (`file.path(R.home("bin"), "Rscript")`) and still supports `PAPERPLOT_RSCRIPT`; child template/scorer calls no longer require bare `Rscript` on `PATH`.
- `validate-skill.R` now requires `scripts/validate-qa-coverage.py`, so the risk-code remediation self-audit cannot be accidentally omitted from a release.
- `run-visual-pressure-scenarios.py` now writes generated reports to its temporary run directory by default. Set `PAPERPLOT_REPORT_DIR=paperplot-skills/reports` only when intentionally refreshing committed reports. Missing private fixtures are reported as `skipped`, not pass.
- `compare-old-new-figures.py` now supports `--strict-nature`, `--old-strict-nature`, and `--new-strict-nature`; a new figure that fails strict Nature guardrails is a final-verdict failure.
- Validation commands should use `PAPERPLOT_RSCRIPT` / `PAPERPLOT_PYTHON` when the default shell environment is not the intended R/Python environment.

Current release status: superseded. The final state is `main` + `v0.1.0` release with remote-install CI passing.

---

## 2026-06-10 — Linux Server Deployment + Portability & QA Enhancements

### Deployment (Linux server, env `claude`)

- Repo clone: `/data9/home/qgzeng/projects/3-Biotools_create/Paperplot/PaperPlotR` (origin `https://github.com/Qgzeng-Bio/Paperplotr.git`, branch `main`).
- Skill root: `…/PaperPlotR/paperplot-skills` (repo root IS the R package; there is no nested `paperplotr/` layer — note the older Mac paths below say `paperplotr/`, that layer does not exist in this repo).
- Skill symlinked into `~/.codex/skills/paperplot-skills` and `~/.claude/skills/paperplot-skills`.
- Replica R library uploaded to `…/Paperplot/reference/R科研绘图合集` (80 cases). Python replica library not present on server.
- Deps installed via micromamba/conda-forge (base conda/mamba solver is broken on this host): R ggplot2/dplyr/tidyr/readr/scales/patchwork/cowplot/ggrepel + ragg/systemfonts/textshaping, imagemagick; pip pypdf. tesseract not installed (optional).
- Generated artifacts (pattern index, calibration) are written OUTSIDE the repo to `…/Paperplot/artifacts/paperplot-skills-reports/` so generated reports never enter git.

### Branch `portability-linux-fixes` (NOT yet committed/pushed)

Two themes, candidate for two commits:

**(a) Portability — make it run unchanged off the author's Mac**
- `scripts/paperplot_helpers.R`: added `pp_resolve_family()` (Arial→Liberation/DejaVu/sans fallback); `pp_theme` no longer hardcodes `base_family="Arial"`; `pp_default_device()` uses `cairo_pdf` on non-macOS (fixes `font family 'Arial' not found in PostScript font database -> invalid font type`) and prefers `ragg` for raster.
- `scripts/index-replica-patterns.py`: removed hardcoded `/Users/qingguozeng/...` defaults → `PAPERPLOT_R_ROOT`/`PAPERPLOT_PY_ROOT` env + `--r-root` required; `write_report` no longer assumes a Python root.
- `scripts/visual-qa-rendered-image.py`: SVG QA falls back to the built-in Pillow rasterizer when ImageMagick is absent (was a hard crash).
- `scripts/run-visual-pressure-scenarios.py` + `scripts/run-redraw-benchmark.R`: author-private fixture paths now driven by `PAPERPLOT_FIXTURE_DIR` (skip gracefully when unset).
- `INSTALL.md`: relative symlink command, corrected layout, full dependency list.

**(b) QA review→fix enhancements**
- **Family auto-detection** (`visual-qa-rendered-image.py`): when `--family` is omitted, family is inferred from a sibling `*_metadata.json` (`figure_spec.plot_type`/`chart_family`), then from filename keywords. Previously family-specific thresholds only fired if the caller manually passed `--family`; now they fire automatically. Output records `figure_family_source`.
- **Risk→remediation binding**: every visual-QA `risk_code` carries a `remediation` (one-line fix + reference doc) in both `visual_qa.json` and `.md`. Makes the "audit" output also say how to fix.
- **Self-audit**: new `scripts/validate-qa-coverage.py` fails if any emitted risk code lacks a remediation/exemption or points at a missing doc. (Caught and fixed a real gap: `svg_extreme_aspect_ratio`.)
- **Nature guardrails**: new `references/nature-figure-guardrails.md` defines 10 final rendered-figure checks. `visual-qa-rendered-image.py --strict-nature` now writes `nature_guardrails` to JSON/Markdown and returns non-zero on hard failures such as excessive blank space, text/annotation overlap, unreadable thumbnail structure, or equal-role panel imbalance.

### Verification (all run on Linux, no `.Rprofile` workaround, no regressions)

`validate-skill ✅ | smoke 20/20 ✅ | run-pressure 5/5 ✅ | run-visual-pressure all pass ✅ | validate-qa-coverage ✅ (28 codes, 24 remediation entries, all docs present)`

Indexer re-run on the uploaded library: `indexed 80 cases` (R only). Calibration re-run: `calibrated 39 positive examples` (only 39 of 80 cases have an analyzable raster/SVG/PDF sample).

### Open TODOs / Deferred

1. **Commit & push branch `portability-linux-fixes`** — recommended as two commits (portability / QA). Push + PR pending owner decision.
2. **Data-driven QA thresholds — intentionally NOT auto-adopted.** Per-family calibration has only **1–3 positive samples** each (39 total). Auto-deriving thresholds from so few good samples can only *loosen* them, which for a review tool risks false negatives (missing real problems). Decision left to a human. The refreshed per-family metric distributions are in `artifacts/.../visual-qa-calibration-fulllib.json` for manual tuning of gap families.
3. **Hand-tuned family overrides still cover only** `rank-lollipop, model-validation, heatmap, manhattan, phylo-annotation-ring`. The other ~7 pattern families fall back to global thresholds. Grow the replica/sample set, then hand-tune from data.
4. **P2 leftover (doc-only):** `reports/visual-qa-calibration-from-replica-library.md` (committed) still embeds absolute `/Users/qingguozeng/...` paths in its table. Regenerate with relative/sanitized paths.
5. Carry-over from 2026-05-19 next phase (still open): `manhattan-plot-template.R`, `upset-summary-template.R`, PDF rasterization in calibration, heatmap annotation-strip/dendrogram strategy, more real redraw benchmarks, clearer `improved` old-vs-new verdicts.
6. **Portability invariant:** keep the repo free of machine-specific absolute paths and `Arial`-hardcoding. A future lint/test could assert no `/Users/` or `/home/<user>/` literals in `scripts/`.

---

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
