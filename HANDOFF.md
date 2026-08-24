# PaperPlotR / paperplot-skills Handoff

Last updated: 2026-08-24 (WP1-WP8 one-shot figure quality optimization round)
Previous major update: 2026-06-13 (v0.1.0 public release + local paperplot-skills work)

---

## 2026-08-24 — One-shot Figure Quality Optimization (WP1-WP8)

Driver: real-world usage showed unified typography / line widths / panel
sizes / legend placement underperforming, with text-element overlap
surviving QA. Audit found the root cause was architectural: consistency
rules were advisory only, several core features were dead code, and QA
was an open loop (detect-but-no-repair). Eight work packages were
implemented and committed.

### Commits in this round

```text
235bc49 Ignore local analysis, third-party replica archive, regenerable assets
7175d91 Refresh QA/benchmark reports and handoff docs
b045d1c Code-recipe system + 15 new templates (20 -> 35)
90e9c79 Visual QA engine upgrade (detail/family/gold-rubric)
41ea7ec Benchmark, auto-QA-mining, replica-audit toolchain
a2ad506 WP1+WP2 Style registry and save-time gates
7ffc245 WP3 Legend coordinator (placement planner + shared-guide fix)
6c1e120 WP4 Overlap prevention layer (ggrepel labels)
6c72a31 WP5 Vector overlap detection promoted; severity fixes
87e39bd WP6 Closed-loop QA auto-fix
c1a5814 WP7 Template hygiene sweep
```

### Engine changes

- `pp_style_registry()` (WP1): single source of truth for base_size,
  font hierarchy, line widths, point-size roles, spacing constants.
- `pp_style_number(path)` (WP1): `options(paperplot.*)` / `PAPERPLOT_*`
  env overrides resolve session-wide; e.g. options(paperplot.base_size=8).
- `pp_theme()` consumes the registry and calls update_geom_defaults()
  for text/label so geom-level text inherits manuscript typography
  (kills the ~11pt giant-label failure). Helper version standalone-0.4.0.
- `pp_finalize(plot)` (WP1): opt-in last-word theme application.
- Save-time gate (WP2): pp_save_plot consumes min_text_pt (was defined
  on every preset, read nowhere); warns when smallest themed/labelled
  text is under the floor; silence via PAPERPLOT_ALLOW_SMALL_TEXT=1.
- Legend coordinator (WP3): pp_shared_guide_plan tautology fixed;
  pp_legend_plan() estimates physical footprint pre-render (calibrated
  on PDF text bboxes; per-label sums; adaptive key shrink >12 entries);
  pp_apply_legend_plan() dual-mode; pp_extract_legend() experimental.
- Overlap prevention (WP4): volcano/ma/bio-genome-quality use
  ggrepel::geom_text_repel when available (seeded), check_overlap
  fallback otherwise; all top-N labels survive render. Burden score
  records optional systemfonts exact_score without loosening gates.
- Vector overlap detection (WP5): one true pairwise word-box overlap
  warns (was silent until >3 / >3%); widespread overlap fails under
  --strict-detail-qa; strict flag threaded through SVG+PDF paths;
  ocr_text_overlap_risk added to family-score BLOCKING_RISKS.
- Closed-loop auto-fix (WP6): MACHINE_FIXES whitelist emitted as
  image_qa.machine_fixes; R gains pp_locate_qa_script(),
  pp_run_visual_qa(), pp_apply_machine_fixes(), and
  pp_save_all_with_qa_loop(max_iterations=1); degrades to plain save
  when python3/script/jsonlite unavailable.

### Template/recipe changes

- run-template-recipe reports presets matching exported canvas dims.
- stacked-fraction normalized to 9.0x6.0 (nature_half exact).
- manhattan 18x7 override records canvas_override_reason in metadata.
- effect-size forest: truthful 9 cm label budget; dense metric sets now
  correctly trigger the rank-index contract and write the sidecar.
- volcano/ma/manuscript-four-panel consume pp_legend_plan.
- recipes scatter grids OFF; enrichment-dotplot uses shared graphpad_
  heatmap ramp; compact-dot-matrix drops its library-only panel.border;
  bio-duplication panel D no longer injects a pseudo legend level.

### Validation state

validate-skill passes; smoke 35/35; visual-pressure suite exit 0 with
30/30 scenarios passing (two stale SVG fixture scenarios repaired by
making the fixture genuinely presentation-scale: 110px title and 14px
stroke at a 1200px canvas).

### Known leftovers

- qa_iterations/machine-fix attributes are not yet wired into the
  *_metadata.json schema (schema bump pending).
- Family threshold overrides still cover only the original five families.
- ggrepel/systemfonts stay optional; exact-width burden data collection
  is passive by design (gates intentionally unchanged).

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

## Latest 2026-06-11 Pangenome Visualization State

The active recent task is an FAD2 pangenome graph/tube-map style figure from the user's real data, not mock data.

Input data directory:

- `/Users/qingguozeng/Documents/1-博士课题/2-油棕基因组/Manuscripts/Review-6.2/Nature稿件修改/第二轮/Pangenome_viz`

Important input files:

- `FAD2_main_RegHap_SV5kb.gfa`
- `FAD2_main_RegHap_SV5kb.sv_summary.tsv`
- `region.txt`
- `FAD2_main_RegHap_SV5kb.xg` exists, but the current static renderer uses the GFA/SV summary/region files rather than parsing the binary xg index directly.

Current renderer:

- `analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py`

Current outputs:

- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_refined.svg`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_refined.pdf`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_refined.png`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_refined_metadata.json`

Latest follow-up experimental outputs:

- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_polished.svg`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_polished.pdf`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_polished.png`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_polished_metadata.json`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_polished_notes.md`
- `analysis/FAD2_pangenome_ggplot2/output/visual_qa_pangenome_tubemap_polished/`
- `analysis/FAD2_pangenome_ggplot2/output/old_vs_new_refined_vs_polished/`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact.svg`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact.pdf`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact.png`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_metadata.json`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_notes.md`
- `analysis/FAD2_pangenome_ggplot2/output/visual_qa_pangenome_tubemap_graph_compact/`
- `analysis/FAD2_pangenome_ggplot2/output/old_vs_new_polished_vs_graph_compact/`
- `analysis/FAD2_pangenome_ggplot2/output/snapshots/graph_compact_9pt_20260613/`
- `analysis/FAD2_pangenome_ggplot2/output/arc_iterations/`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_nature.svg`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_nature.pdf`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_nature.png`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_nature_metadata.json`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_graph_compact_nature_notes.md`
- `analysis/FAD2_pangenome_ggplot2/output/visual_qa_pangenome_tubemap_graph_compact_nature/`
- `analysis/FAD2_pangenome_ggplot2/output/old_vs_new_graph_compact_vs_nature/`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap.svg`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap.pdf`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap.png`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap_metadata.json`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap_notes.md`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap_nodes.csv`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_sequence_tubemap_track_shapes.csv`
- `analysis/FAD2_pangenome_ggplot2/output/visual_qa_pangenome_tubemap_sequence_tubemap/`
- `analysis/FAD2_pangenome_ggplot2/output/old_vs_new_nature_vs_sequence_tubemap/`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph.svg`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph.pdf`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph.png`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph_metadata.json`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph_notes.md`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph_nodes.csv`
- `analysis/FAD2_pangenome_ggplot2/output/pangenome_tubemap_bubble_graph_track_shapes.csv`
- `analysis/FAD2_pangenome_ggplot2/output/visual_qa_pangenome_tubemap_bubble_graph/`
- `analysis/FAD2_pangenome_ggplot2/output/old_vs_new_sequence_tubemap_vs_bubble_graph/`

The renderer now accepts an optional third CLI argument:

```text
python3 analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py <input_dir> <out_dir> refined
python3 analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py <input_dir> <out_dir> polished
python3 analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py <input_dir> <out_dir> graph_compact
python3 analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py <input_dir> <out_dir> graph_compact_nature
python3 analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py <input_dir> <out_dir> sequence_tubemap
python3 analysis/FAD2_pangenome_ggplot2/fad2_static_svg_tubemap_renderer.py <input_dir> <out_dir> bubble_graph
```

`refined` remains the stable baseline. `polished` is an experimental candidate with subtle event-box tinting by haplotype class, half-ellipse event arcs, and local connector smoothing around the dense SV021/SV023/SV026/SV027 cluster. The 2026-06-11 follow-up specifically replaced shallow wave-like event paths with true half-ellipse arcs and uses half-ellipse U-turns for near-vertical connectors instead of merely increasing global arc height. It deliberately does not use the rejected global thick-ribbon/rounded-box style.

`graph_compact` is the current target-style compact tube-map / graph-layout variant. It intentionally stops preserving base-pair coordinate scale and instead lays out reference/SV records as compact graph nodes. Haplotype paths are drawn as continuous tubes through node columns, and short branch connectors use stronger semicircle-like Bézier routing instead of shallow diagonal turns. This is the version to use when the user wants the example-like compact pangenome graph browser style.

`graph_compact_nature` is the current best arc-polished variant after the user asked to save the 9/10 version and iterate 20+ additional versions without rebuilding the frame. The 9/10 `graph_compact` state was saved in `output/snapshots/graph_compact_9pt_20260613/`. A total of 96 stored arc-routing candidates were generated under `output/arc_iterations/` (`arc_*`, `quad_*`, `elbow_*`, `semi_*`). The selected candidate is `quad_18_b20_xm0.06`, which uses single-bend quadratic-like arcs and reverses overlapping branch spans only where the old direction would force a backward U-turn. This version keeps the same node-column frame and is meant to reduce S-shaped connectors and >90-degree back-turns.

`sequence_tubemap` is the static SequenceTubeMap-like variant added after reviewing the public `vgteam/sequenceTubeMap` visual/algorithm structure. It is not a full interactive clone and does not copy the upstream JavaScript renderer. It uses the same conceptual pipeline for this FAD2 data: GFA `S` records become nodes, GFA `P` records become haplotype tracks, path steps retain order/orientation, node widths use a compressed/log-like display policy, tracks are assigned lanes, and the renderer emits straight `track_rectangle` pieces plus cubic `track_curve` connectors. It also writes `*_nodes.csv` and `*_track_shapes.csv` so future iterations can audit the generated geometry.

`bubble_graph` is the user-reference-image style variant added after the user provided a compact bubble sequence graph screenshot and said ATCG sequence text is not needed. The first black-box version was rejected as "非常差劲" because it simply wrapped the old tube map with too many node boxes. It has now been rebuilt as a macro-node schematic: continuous reference runs are merged into a small set of visible boxes (`R001`, `R004-R006`, `R007`, `R008-R013`, `R014-R017`, `R018`, `R019`), and the main SVs are shown as upper/lower bubble boxes. It hides nucleotide sequence strings, coordinate axis, gene/promoter arrow, and legend. It is intended as a reference-style candidate, not as the current best Nature manuscript replacement.

Follow-up QA for `polished`:

```text
visual QA: pass
manuscript_readiness_score: 10
family QA: genome-track/synteny, pass, score 10.0
old-vs-new against refined: deterministic verdict improved; final verdict deterministic_better_pending_human_review
```

Follow-up QA for `graph_compact`:

```text
PNG: 4400 x 1472, 600 dpi
visual QA: warn
manuscript_readiness_score: 9
family QA: genome-track/synteny, pass, score 9.8
old-vs-new against polished: deterministic verdict mixed; target-specific review improved; final tool verdict still worse because the compact version deliberately sacrifices coordinate-preserving metrics
self-assessed visual match to compact tube-map reference: about 9/10
remaining risk: grayscale_discrimination_risk; check grayscale manuscript reproduction
```

Follow-up QA for `graph_compact_nature`:

```text
PNG: 4400 x 1472, 600 dpi
visual QA: pass
manuscript_readiness_score: 10
family QA: genome-track/synteny, pass, score 10.0
old-vs-new against saved graph_compact: deterministic verdict improved; final verdict deterministic_better_pending_human_review
selected arc candidate: quad_18_b20_xm0.06
stored arc candidates: 96
remaining risk: coordinate scale is intentionally compressed; final biological emphasis still needs manuscript-context review
```

Important follow-up detail: a direct left-lane-label experiment was tried and removed because old-vs-new QA showed increased text burden. Do not re-add direct lane labels by default unless the user explicitly values path labels over the extra text burden.

The renderer is deterministic and writes SVG path elements with cubic Bézier `C` commands, PDF, and a 600 dpi PNG preview. `refined` and `polished` are coordinate-preserving locus-panel variants; `graph_compact` is intentionally coordinate-compressed for graph readability. Required SVG groups are present:

- `axis`
- `gene_annotation`
- `haplotype_paths`
- `sv_boxes`
- `legend`
- `scale_bar`

Current structure check for `graph_compact_nature`:

```text
C_commands: cubic Bézier path output retained
SVG height: 736
PNG: 4400 x 1472, 600 dpi
```

Current QA for `graph_compact_nature`:

```text
visual QA: pass, manuscript_readiness_score 10
family QA: pass, score 10.0
blocking risks: none
old-vs-new vs saved graph_compact: improved, pending human review
```

Current QA for `sequence_tubemap`:

```text
PNG: 4400 x 1496, 600 dpi
visual QA: warn
manuscript_readiness_score: 9
family QA: genome-track/synteny, pass, score 9.69
old-vs-new against graph_compact_nature: deterministic verdict mixed/worse because the new figure intentionally uses thicker SequenceTubeMap-like tubes and higher line burden
remaining risk: grayscale_discrimination_risk and edge-text heuristic; the variant should be treated as a target-style static TubeMap candidate, not as a replacement for the current best Nature manuscript figure
```

Current QA for `bubble_graph`:

```text
PNG: 4400 x 1120, 600 dpi
visual QA: warn
manuscript_readiness_score: 6
family QA: genome-track/synteny, pass, score 8.2
old-vs-new against sequence_tubemap: deterministic verdict mixed/worse because the reference-style graph is intentionally very wide and uses thick long horizontal tubes
current state: macro-node rebuild after rejection; visually closer to the provided bubble-graph reference than the first black-box attempt
remaining risk: extreme_aspect_ratio, grayscale_discrimination_risk, and long-line burden; acceptable only if the goal is to match the user's provided bubble graph style
```

Important user feedback:

- The user disliked the initial ggplot2 schematic because it looked like a haplotype bar plot rather than a pangenome graph.
- A later static SVG tube-map renderer was much better, but still felt less polished than SequenceTubeMap-like examples.
- The user then provided a stronger ribbon-like reference image and asked for more curved SV paths using real data.
- A trial with thicker ribbons, rounded SV boxes, and dynamic large arc heights was generated, but the user said: "算了 还不如之前的呢".
- That over-curved trial has now been reverted. The current output is the more conservative previous style, with thinner tubes, modest SV-box arcs, rectangular SV boxes, and clearer data hierarchy.

Do not blindly reapply the rejected over-curved style. In particular, avoid these rejected settings unless explicitly requested:

- very thick tube fill as the dominant mark
- large dynamic long-SV arc heights
- rounded SV boxes as the default
- global "make every SV curve bigger" tuning

Better next direction for this figure:

1. Keep `refined` / `polished` as stable coordinate-preserving baselines.
2. Use `graph_compact` for the user's requested compact graph-browser style.
3. If another pass is needed, improve only local routing and label placement; do not reintroduce thick global ribbons or large decorative arcs.
4. For grayscale publication, either add line-style redundancy or tune class colors after checking the final journal layout.
5. Do not judge `graph_compact` only by coordinate-panel old-vs-new metrics; it optimizes a different visual grammar.

One QA caveat:

- Direct SVG raster QA through ImageMagick can fail on this machine with `unable to read font` even for minimal SVG text. PNG QA is currently reliable. `visual-qa-rendered-image.py` was updated to scale SVG font/stroke sizes by target manuscript width when `--target-width-mm` is provided, but ImageMagick font configuration may still force fallback rasterization for SVG inputs.

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
