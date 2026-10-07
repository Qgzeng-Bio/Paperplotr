# PaperPlotR / paperplot-skills Handoff

Last updated: 2026-08-13 (Arial-only font contract in source; runtime sync pending)
Previous release update: 2026-06-11 (v0.1.0 public release + local Codex install)
Previous major update: 2026-06-10 (Linux server deployment + portability/QA branch)
Earlier Mac update: 2026-05-19 (pattern-library upgrade — see sections below)

---

## 2026-08-13 — Arial-only Figure Font Contract (Source Validated; Runtime Sync Pending)

User decision: all PaperPlot figure text must use **Arial**, not an
Arial/Helvetica-equivalent fallback.

Implementation in the current uncommitted source diff:

- `paperplot_helpers.R` is `standalone-0.5.1`; `pp_resolve_family()` now requires
  Arial Regular, Bold, Italic, and Bold Italic and fails explicitly when the
  family is unavailable.
- `pp_theme()` rejects a non-Arial `base_family`; `pp_save_plot()` enforces Arial
  across the ggplot theme and text/label layers before export.
- Metadata records `style.font_family="Arial"`; the output validator requires
  that contract for 0.5.1+ output and uses Poppler `pdffonts` in manuscript-ready
  mode to reject non-Arial or non-embedded PDF fonts.
- Templates with direct `geom_text()` calls explicitly set `family="Arial"`;
  smoke tests inspect every generated PDF font table.
- CI installs Microsoft core fonts, confirms `fc-match Arial`, and tests that
  Helvetica substitution is rejected.
- This server has the four required Arial faces under
  `~/.local/share/fonts/msttcorefonts/`; a Cairo probe embedded `ArialMT` and
  `Arial-BoldMT` successfully.

Validation completed:

- helper resolution and non-Arial rejection: PASS;
- real Cairo PDF probes, including character-based `shape=95`: embedded Arial
  only, PASS;
- contract regression, including forged font metadata and a real Helvetica PDF
  negative fixture: PASS at
  `/tmp/paperplot-contract-regressions-20260813-111754`;
- 20-template smoke: **20/20 PASS**, with each PDF inspected by `pdffonts` and
  containing only embedded Arial faces, at
  `/tmp/paperplot-skills-smoke-20260813-111750`;
- behavior pressure: **5/5 PASS**; available visual-pressure scenarios behaved
  as expected; quick/standalone validators and runtime-profile strict replay:
  PASS.

The first Arial smoke run correctly caught `LiberationSans` in the violin
median `shape=95`; the device family was then fixed to Arial and the complete
suite passed. A subsequent focused read-only audit found three P1 boundaries:
`fc-match` did not verify returned styles, global `theme_get()` text elements
could bypass the plot-local check, and the main `paperplot-skills.yaml` workflow
lacked Arial/Poppler installation. All three were fixed with exact family/style
matching, global-plus-local theme inspection, matching Arial setup in both CI
workflows, and dedicated negative regressions. Post-fix contract regression and
20-template embedded-Arial smoke both pass. A new bounded read-only audit signed
off the frozen result: **PASS, no P0/P1, no P2 suggestions**. The active Pi/Codex
runtime intentionally remains 0.5.0 until a separate post-review sync
confirmation.

## 2026-08-12 — Source Contract Optimization (Not Yet Installed or Published)

Purpose: reconcile an August runtime-copy experiment with the Git source, adopt
the user-approved `make-figures` typography policy, and stop medical journal
rules from silently becoming universal scientific-figure rules.

### Decisions

- Ordinary print labels and axes target **9 pt**; ticks, legends, and compact
  annotations target **8 pt**; panel labels target **12 pt bold**.
- **6 pt is an absolute floor**, not the normal PaperPlot target. A smaller-than-
  target exception requires a target-journal allowance, a documented dense-family
  reason, and final-size rendered QA.
- More than 7 visual elements, 3 meaning-carrying colors, 3 shapes, or 4 legend
  entries in one panel is a review trigger rather than a universal failure.
  Heatmaps, Manhattan plots, tree rings, UpSet matrices, and other dense families
  can retain higher burden only with a recorded scientific reason.
- Journal dimensions are scoped profiles. Medical Radiology-family dimensions do
  not override Nature-like, Cell Press, or general genomics/life-science work.
- PaperPlot ships its own bioinformatics data-to-image validation contract and
  does not require a relative `bio-workflow/` checkout. Bioflow remains an
  optional additional project-policy layer.

### Source changes

- Removed the local `disable-model-invocation: true` frontmatter experiment so
  the skill remains cross-harness valid and automatically available to Bioflow.
- Added `references/journal-specs-matrix.md` with `general_scientific`,
  `nature_like`, `nature_communications`, `cell_press`, and
  `medical_radiology` profiles, provenance scope,
  typography, DPI, review triggers, and a spec-first compositing workflow.
- Added `references/bioinformatics-figure-validation.md` covering source paths,
  reference/build, coordinates, sample order, units/transforms/denominators,
  statistics, family-specific checks, and claim boundaries.
- Updated `SKILL.md`, visual standards, metadata/figure/template contracts,
  multi-panel rules, style guidance, and affected pattern documents.
- Upgraded `paperplot_helpers.R` to `standalone-0.5.0`: 9 pt default theme,
  enforced 6 pt API floor, explicit pt-to-mm conversion for `geom_text`, scoped
  profile snapshots and geometry envelopes, explicit v1-to-v2-only figure-spec
  migration, machine-readable 9/8/12/6 pt typography, cognitive-load review,
  real-file/checksum/checklist-backed bioinformatics provenance, exact TSV
  plotting-data sidecars, and immutable post-render `*_review.json` sidecars.
- Updated templates and the redraw benchmark to stop explicitly drawing 7 pt
  theme text or 5.8–6.5 pt labels.
- Strengthened `validate-skill.R`: cross-harness frontmatter allowlist, SKILL
  reference existence, new required references/helpers, typography/profile
  implementation checks, below-target template detection, and stale typography
  detection.
- Reworked `validate-figure-output.R` around bundled dependency-free contract
  parsers. Candidate mode validates PDF/PNG signatures and completeness,
  stem-matched exports/sidecars across the full tree, exact QA/metadata status,
  supported schema, scoped profile snapshot, export geometry, and structured
  provenance. Candidate PASS is integrity only, not WARN or readiness.
- `--manuscript-ready` additionally requires QA `pass`, checksum-bound strict
  rendered QA, a structured accepted reason for any visual warning, recorded
  cognitive-load review, complete real-file/checksum/checklist-backed
  bioinformatics PASS, and checksum-matched old-vs-new `improved` evidence only
  when a real `old_figure_path` is declared.
- Added `scripts/lib/contract-parsers.R` with duplicate-key rejection, preserved
  JSON nulls, Unicode surrogate handling, bounded nesting, and strict flat
  cross-harness SKILL frontmatter parsing.
- Added `scripts/test-contract-regressions.R` with positive general/bio strict
  bundles plus negative media, QA, visual-QA, orphan, JSON, profile, schema,
  provenance, review-sidecar, and old-vs-new checksum fixtures.
- All 20 templates now record cognitive-load review explicitly. Five
  bioinformatics templates write exact stem-matched plotting TSVs and a
  `not_recorded` provenance scaffold; they cannot become manuscript-ready until
  the scientific TODO fields and validation evidence are completed.

### Validation completed

- Agent Skills quick validation: PASS.
- Standalone `validate-skill.R`: PASS for all 20 templates and new contracts.
- Helper assertions: profile normalization/inference, 8 pt conversion, review
  trigger and documented exception: PASS.
- Contract regression suite: PASS, including general/bio strict positive
  fixtures and all review-discovered false-positive regressions; latest root
  `/tmp/paperplot-contract-regressions-20260813-023117`; positive strict
  fixtures run the real rendered-QA and old-vs-new tools. Adversarial negatives
  now also cover deletion of required QA gates, refingerprinted visual-metric
  forgery, refingerprinted comparison-score forgery, locale-dependent JSON
  numbers, and the earlier media/parser/profile/provenance cases. Strict v3
  evidence is fingerprint-verified and deterministically replayed against the
  current pixels; v2 evidence remains candidate-compatible but cannot receive
  readiness.
- Template smoke test: **20/20 PASS**; candidate bundles validate, all unfinished
  smoke outputs are correctly rejected by manuscript-ready mode; latest root
  `/tmp/paperplot-skills-smoke-20260813-025230`; all 20 QA reports contain the
  common `figure_spec`, cognitive, bioinformatics, PDF, PNG, notes, and metadata
  gate set.
- Behavior pressure scenarios: **5/5 PASS**; latest root
  `/tmp/paperplot-pressure-20260813-025230`.
- Visual pressure scenarios: all **11 available synthetic/repository fixtures**
  behaved as expected (pass/warn/fail/expected-error and old-vs-new outcomes);
  **5 optional private fixtures were skipped as `fixture_missing`**. Latest root
  `/tmp/paperplot-visual-pressure-m_ova2f_`, using the existing `claude` Python.
- `git diff --check`: PASS at the documented checkpoints.
- Review-first iteration: two independent read-only reviews found no P0 and six
  classes of P1 (strict readiness false positives, visual-QA orphan masking,
  JSON null/duplicate semantics, profile/geometry labels without enforcement,
  fabricated bioinformatics provenance, and incomplete frontmatter parsing).
  Every reported P1 was independently reproduced under `/tmp` before repair.
  A fresh implementation audit then found five further P1 adversarial gaps:
  crafted media, QA gate/overall contradiction, forged visual/comparison JSON,
  unknown-preset/DPI bypass, and unsafe PNG chunk lengths. These were all
  reproduced or confirmed, then fixed with CRC/chunk/xref/decoder checks,
  recomputed QA state, versioned tool schemas and internally consistent evidence,
  explicit preset/profile/DPI agreement, and bounded parsers. The review's four
  P2 parser/writer/YAML/TSV-orphan findings were fixed in the same batch. Two
  later bounded reviews found five additional P1 boundaries: missing required
  QA gates, self-asserted visual metrics, unbound comparison summaries,
  non-transactional runtime overwrite, and locale-sensitive JSON numbers. All
  five were reproduced or confirmed and fixed with common-gate enforcement,
  v3 tool fingerprints plus real analysis replay, new-analysis cross-binding,
  staging-before-atomic-switch installation, and locale-independent numeric
  serialization. Fault-injected download failure preserved the old runtime at
  `/tmp/paperplot-transaction-o86hsf`; a staged runtime strict replay passed
  against the latest real evidence bundle.

The first visual-pressure attempt under base Anaconda failed before QA because
Pillow could not load `libLerc.so.4` against the system `libstdc++`
(`GLIBCXX_3.4.29` missing). This is an existing interpreter ABI problem, not a
PaperPlot regression. No package was installed or upgraded; the already-working
`claude` Python (Pillow 12.0.0, NumPy 2.4.0) passed the suite.

### Current state / next gate

- The reviewed optimization batch was committed locally as
  `40908caae74629af0f0eebf6729ece2ad634cc98` (`Harden paperplot skill
  contracts`). Before this HANDOFF-only update, the source worktree was clean and
  local `main` was one commit ahead of `origin/main`.
- `~/.codex/skills/paperplot-skills` (also used by Pi) was transactionally
  replaced with the runtime profile built from commit `40908ca`. Post-switch
  validation passed Agent Skills discovery, helper/runtime assertions, a real
  template candidate run, and an exact **85/85** runtime manifest/checksum
  comparison against the committed source profile.
- The previous runtime was preserved without modification at
  `~/.codex/skills/.paperplot-skills.backup-before-40908ca` (83 files, about
  456K). Do not delete it until the new runtime passes a fresh-session real-task
  acceptance test.
- The active runtime contains `scripts/lib/contract-parsers.R` and
  `references/bioinformatics-figure-validation.md`, and excludes development
  reports, contract regressions, pressure runners, and benchmark scripts as
  intended.
- Claude still points to the source checkout. Pi/Codex should be restarted or a
  new session opened so skill discovery does not reuse an in-memory copy from
  before the runtime switch.
- No push, tag, release, remote download, or package install was performed.
  `origin/main` remains at `94f465db75ab06f2e3aff7faa510df0692a4fa12`.
- A broad final audit hit its turn limit without producing review evidence and
  is not counted as signoff. Two bounded audits then found the five P1 items
  above; their FAIL verdicts triggered the final hardening batch.
- Two new bounded post-fix read-only audits independently signed off the frozen
  result: strict-v3 false-positive boundary **PASS, no P0/P1**; runtime install,
  locale JSON, and standalone boundary **PASS, no P0/P1**. Their requested
  environment-specific contract run is the passing regression root above.
  The only remaining review suggestion is a non-blocking P2 to add CI fault
  injection for activation-`mv` failure; local failure injection already proved
  restoration and no transaction debris.
- Test-only Python cache artifacts were removed after explicit confirmation.
- The expected uncommitted changes after `40908ca` are this HANDOFF update and
  the user-requested Arial-only 0.5.1 source contract described above.
- Next safe step: complete Arial contract regressions, then separately confirm a
  local commit and transactional Pi/Codex runtime resync. Push, tag, and release
  remain separate actions.

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

- `v0.1.0` points at `9b2478a`.
- `origin/portability-linux-fixes` also points at `9b2478a`.
- `main` received a later handoff-only documentation commit after the release tag; this does not change the pinned `v0.1.0` release contents.
- Local repo state after the handoff update should be `main...origin/main` with no uncommitted changes.

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
- Historical 2026-06-10 behavior: `scripts/paperplot_helpers.R` added `pp_resolve_family()` with Arial→Liberation/DejaVu/sans fallback; `pp_default_device()` used `cairo_pdf` on non-macOS. **Superseded on 2026-08-13:** current 0.5.1 source requires real Arial and forbids substitution.
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
6. **Portability invariant (updated 2026-08-13):** keep the repo free of machine-specific absolute paths. Arial is now intentionally hard-required by user decision; portability means validating/installing Arial rather than silently substituting another font.

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
