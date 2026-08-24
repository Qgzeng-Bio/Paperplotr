---
name: paperplot-skills
description: Use for publication-ready scientific figure diagnosis, redesign, R/ggplot2 plotting, manuscript QA, old-vs-new comparison, and bioinformatics figure workflows.
---

# PaperPlot Skills

## Purpose

This is a standalone professional scientific plotting skill. It helps researchers diagnose, optimize, redraw, and QA manuscript figures across life sciences, genomics, omics, statistics, machine learning, medicine, and bioinformatics. It does not depend on the PaperPlotR R package.

The target is not decorative plotting. The target is a manuscript-credible figure: clear scientific message, controlled information hierarchy, readable typography, functional color, reproducible export, and documented scientific assumptions.

## Independence Rule

- Do not ask the user to install PaperPlotR.
- Do not call `library(PaperPlotR)` or PaperPlotR APIs such as `theme_lab()`, `save_lab()`, `save_lab_plot()`, `layout_lab()`, or `scale_*_lab()`.
- Default implementation uses base R + `ggplot2` + `scripts/paperplot_helpers.R`.
- Optional packages are allowed only when already installed and must have fallback behavior.
- Python/matplotlib, seaborn, Illustrator, SVG, and PDF workflows may be advised, but the core skill remains standalone and reproducible.

## Required Operating Mode

1. Diagnose before drawing.
2. Detect data roles and choose a figure family with `references/figure-type-selector.md`.
3. Consult the matching `references/pattern-library/*.md` document.
4. Write a design brief.
5. Define `figure_spec` and `metric_spec`.
6. Create a pattern-based design plan.
7. Query `references/plot-grammar-atoms.md` and the code recipe manifest before writing new plot code.
8. Select a production template, executable recipe, optional backend plan, or diagnostic benchmark path.
9. Apply visual budget, proportional layout, and label/legend/panel burden checks.
10. Render/export PDF and PNG.
11. Perform image-level QA, detail QA, and Nature guardrail review when an image is available.
12. If old and new figures exist, perform old-vs-new comparison.
13. If the new figure is not objectively better, iterate or state the blocker.
14. Write notes, metadata JSON, QA report, visual QA, and conditional sidecars.
15. Report remaining scientific and manuscript-readiness risks.

## Input Handling

- If the user gives only an image: diagnose visual design, infer likely data roles cautiously, request data before claiming a faithful redraw.
- If the user gives only code: review code and propose a safer redesign; run only if the user asks or the task requires implementation.
- If the user gives only data: profile data, select figure type, define specs, then plot.
- If the user gives image plus data/code: compare the old figure to the data-backed redraw and preserve useful visual rhythm.
- If critical scientific metadata are missing, ask for the minimum missing fields: units, sample size, group meaning, statistical test, normalization, or paired status.

## Manuscript Figure Tiers

Classify every figure before finalizing:

- `analysis sketch`: useful for exploration; not suitable for manuscript.
- `presentation figure`: readable for slides; may be too large, decorative, or under-documented.
- `manuscript candidate`: clear and exportable; minor risks remain.
- `manuscript-ready`: no hard QA failures, readable at target size, scientific semantics documented, and old-vs-new risks addressed when applicable.

Do not call a figure manuscript-ready just because the code runs.

## Default Visual Standards

Use `references/publication-visual-standards.md` as the baseline. Key defaults:

- Width: 89 mm single column, 180-183 mm double column, max height about 170 mm for Nature-like layouts.
- Font: Arial or Helvetica-equivalent sans serif; keep text editable in vector output.
- Text: 5-7 pt for most figure text; panel labels about 8 pt bold lowercase or journal-specific equivalent.
- Lines: 0.25-0.6 pt for axes, intervals, and borders; avoid thick strokes.
- Points: usually 1.2-2.2 mm depending on density; use alpha for overplotting.
- Bars: avoid over-wide bars; show raw points or intervals when statistical evidence matters.
- Gridlines: off by default; use only when they materially improve quantitative reading.
- Color: accessible, functional, consistent across panels; avoid rainbow and red/green dependence.
- Multi-panel proportion: panel boxes, data regions, legends, typography, and blank space must look intentionally balanced at final export size. Equal scientific roles usually require equal panel boxes; unequal roles require an explicit hierarchy and proportional justification.
- Export: PDF as editable vector plus PNG preview; RGB; no flattened text for vector figures.

## Scientific Hard Gates

Stop and revise when:

- Axis labels or legends omit units, denominators, transforms, or normalization.
- Percentages lack denominator or scale meaning.
- Error bars do not say SD, SE, CI, IQR, or range.
- Boxplots are used as primary evidence for very small groups.
- Paired/repeated data are plotted as independent samples, or connecting lines lack pairing/order semantics.
- P-value stars are the main statistical message without effect size or uncertainty.
- Heterogeneous metrics are silently z-scored, ranked, or mixed on one axis.
- Heatmaps mix incompatible units without explicit transformation and annotation.
- A color scale encodes quality/significance but the legend is ambiguous.

## Visual Hard Gates

Stop and revise when:

- Text overlaps or becomes unreadable at target width.
- Dense lookup labels dominate the figure instead of moving to rank index, key labels, metadata, or sidecars.
- The figure is QA-compliant but looks like a diagnostic dump rather than a manuscript figure.
- Legends are repeated or larger than the data region without a reason.
- Panels are misaligned, unordered, or lack visual hierarchy.
- Multi-panel figures have accidental size/aspect mismatch: one panel appears visually enlarged or shrunken because source plots were exported at different dimensions, legends consume unequal space, or outer image stitching ignores data-region size.
- Strict Nature guardrails fail for exported size, text overlap, blank margin, thumbnail readability, or multi-panel balance.
- Decorative icons, shadows, saturated colors, unnecessary frames, or background gridlines reduce clarity.
- Old-figure redesign destroys useful visual rhythm without justification.

## Figure Type Rules

Use `references/figure-type-selector.md`, `references/figure-type-quality-rubric.md`, `references/template-selection-guide.md`, and the matching pattern-library document before choosing a template. Important defaults:

- 5-8 heterogeneous metrics: small multiples, not compressed dot/bubble heatmaps unless justified.
- Dense sample labels in main figures: rank index + key labels + label-key sidecar.
- Group comparison: raw points first; box/violin summaries depend on n.
- Paired comparison: require paired ID before drawing connecting lines.
- Effect summaries: prefer effect size + CI over p-value-only displays.
- Volcano/MA/enrichment: keep effect, significance, count, and label roles separate.
- Multi-panel figures: define primary, secondary, and supporting panels.
- Unsupported specialized plots such as circos, synteny, genome tracks, phylogenetic trees, networks, schematics, and model diagrams: provide diagnosis and implementation plan; do not fake specialized layout without the required data structure.
- If there is no data, only diagnose and propose redraw strategy; do not claim a faithful data-backed redraw.
- If data and code exist, redraw and verify instead of stopping at critique.
- Every redesign should record the selected pattern document in metadata.
- When the requested family matches a learned code pattern, consult `references/code-recipe-contract.md`, `references/code-recipes/recipe-library.md`, and `recipes/recipe_manifest.csv` before writing new plotting code.

## Templates

Choose and adapt one template:

- General and layout: `single-panel`, `multi-panel`, `manuscript-four-panel`, `multi-metric-small-multiples`, `rank-plus-key-metrics`.
- Group comparison: `comparison-boxplot`, `grouped-boxplot-jitter`, `paired-comparison`, `violin-dot`, `raincloud`, `barplot`, `bar-dot-errorbar`, `stacked-fraction-bar`.
- Association, ordination, and matrix: `correlation-scatter`, `labelled-regression`, `pca-scatter`, `pcoa-marginal`, `heatmap`, `annotated-heatmap`, `matrix-dotplot`.
- Bio/omics: `volcano-plot`, `ma-plot`, `enrichment-dotplot`, `compact-dot-matrix-enrichment`, `manhattan-plot`.
- Summaries, spatial, and validation: `effect-size-forest`, `model-validation-composite`, `time-series-ribbon`, `ridgeline-density`, `lollipop-ranked`, `upset-summary`, `network-summary`, `spatial-distribution`, `bio-genome-quality-overview`, `bio-duplication-mode-comparison`.

The code recipe layer now has 80+ manifest entries. Use production recipes for normal redraws; use optional-backend/reference recipes for complex heatmaps, circos, maps, trees, networks, UpSet, genome tracks, or synteny-like figures only when required data structures and packages are available.

All templates must source `scripts/paperplot_helpers.R`, refuse overwrites, export PDF/PNG, and write notes, metadata, QA, and required sidecars.

## Image-Level QA

Rendered-image QA is mandatory after generating or modifying a figure. Do not claim manuscript readiness from code, notes, or metadata alone.

Use `references/visual-perception-qa.md`, `references/visual-detail-qa-spec.md`,
`references/nature-figure-detail-rubric.md`, and
`references/nature-figure-guardrails.md`, then run:

```bash
${PAPERPLOT_PYTHON:-python3} scripts/visual-qa-rendered-image.py <image_or_output_dir> --out <qa_dir>
```

For final manuscript candidates, use strict Nature mode:

```bash
${PAPERPLOT_PYTHON:-python3} scripts/visual-qa-rendered-image.py <figure> --out <qa_dir> --strict-nature
```

Visual QA requires Pillow for raster images. PDF and SVG inputs are rasterized before pixel QA when `pdftoppm` or ImageMagick are available; SVG structural checks are retained as supplemental signals. OCR is optional: `--ocr auto` uses Tesseract if available and otherwise records an unavailable OCR engine without failing.

The visual QA layer must report image size, blank margin, content density, color burden, grayscale risk, gridline/line burden, approximate text/mark burden, panel geometry, OCR availability, manuscript-readiness score, and top risks. If visual QA returns `warn` or `fail`, either revise the plot or report why the risk remains accepted.

For multi-panel figures, pass explicit layout expectations whenever possible:

```bash
${PAPERPLOT_PYTHON:-python3} scripts/visual-qa-rendered-image.py <figure> --out <qa_dir> --expected-panels 2 --layout-profile equal
```

For Nature-like detail review, pass target-size expectations:

```bash
python3 scripts/visual-qa-rendered-image.py <figure> --out <qa_dir> --target-width-mm 89 --journal-profile nature --allow-grid auto
```

The detail QA layer must inspect text/data collision, tick label crowding, target-size font risk, stroke burden, grid-background burden, legend dominance, panel data-region mismatch, and excessive panel padding. Panel geometry warnings such as `panel_size_imbalance`, `panel_data_region_imbalance`, `panel_data_region_mismatch`, and `unjustified_panel_hierarchy_risk` are manuscript layout risks, not cosmetic nits.

For SVG/PDF inputs, treat vector text and stroke extraction as stronger evidence than raster heuristics. SVG reports true font/stroke distributions; PDF text boxes use `pdftotext -bbox`, and PDF strokes/paths use `pypdf` content-stream parsing when available.

When the figure family is known or inferred, add family-specific scoring:

```bash
python3 scripts/family-qa-score.py --qa-json <qa_dir>/visual_qa.json --out <qa_dir>/family_qa.json
```

Family scoring prevents ordinary statistical-plot thresholds from incorrectly failing heatmaps, tree rings, maps, networks, or other specialized layouts, while keeping text overlap and severe panel imbalance as blocking manuscript risks.

When `references/gold-human-calibration-rules.json` exists, family QA also reports whether the figure family is supported by local human-scored positive examples. Treat generic ordination/PCA/PCoA plots as baseline/caution unless they show stronger manuscript hierarchy than the current gold set.

Strict Nature failures are revision blockers unless the accepted hierarchy or dense family-specific structure is explicitly justified in notes and metadata.

Positive calibration examples summarized in `references/visual-qa-calibration-summary.md` show that `warn` is a review trigger, not automatic failure. Heatmaps, tree rings, Manhattan plots, and set matrices need family-specific interpretation.

## Old-vs-New Comparison

When redesigning an existing figure, use `references/old-vs-new-comparison.md`, `references/old-vs-new-visual-scoring.md`, and record:

- What was preserved.
- What was removed.
- What became clearer.
- What became worse or riskier.
- Whether the new figure is actually better than the old one.

If the old figure has good rhythm but poor labels, refine rather than rebuild.

When old and new rendered images both exist, run:

```bash
${PAPERPLOT_PYTHON:-python3} scripts/compare-old-new-figures.py <old_image> <new_image> --out <qa_dir> --new-strict-nature
```

The comparison writes `old_vs_new_review_template.json`. Without a completed review JSON, the final verdict can at most be `deterministic_better_pending_human_review`; deterministic visual metrics alone cannot prove that the scientific message is clearer. If the new figure has worse visual burden, severe panel geometry/detail risk, or a lower manuscript-readiness score, do not present it as final.

Optional vision-model review may be used only through `scripts/vision-review-adapter.py` as a second opinion. It is not a default dependency and cannot override deterministic hard failures.

Only identifying that a figure is bad is not enough. With data/code, produce a better pattern-based candidate, run QA, compare old-vs-new, and continue iterating until the tradeoff is explicit.

## Output Contract

Default outputs:

- PDF vector figure.
- PNG preview.
- R script or reproducible plotting code.
- `*_notes.md`.
- `*_metadata.json`.
- `*_qa.md`.
- Conditional `*_label_key.csv`, `*_sample_order.csv`, or design sidecars.

## Final Response

Report generated files, template, preset, design decisions, visible simplifications, scientific assumptions, QA status, old-vs-new verdict if applicable, and remaining manuscript-readiness risks.
