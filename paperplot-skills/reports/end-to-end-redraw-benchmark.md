# End-to-end redraw benchmark

This benchmark tests whether the upgraded pattern-library workflow can move real user-flagged figures toward manuscript-ready scientific graphics. The deterministic old-vs-new verdict is intentionally kept conservative: a higher manuscript-readiness score is not treated as automatic success when other metrics worsen.

## Summary

| case | reference pattern | old score | new score | old-vs-new verdict | manuscript candidate |
|---|---|---:|---:|---|---|
| Genomic selection quality traits | `multi-panel-manuscript-layout` + `model-validation-figures` | 6 | 10 | mixed | yes, after science/label review |
| High-confidence NLR counts | `grouped-bar-errorbar` adapted to sorted lollipop | 5 SVG / 6 PNG | 9 | mixed | yes, especially supplement/single-column |

## Case 1: Genomic selection quality traits

- Original figure: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/10-GS/final_results/figures/fig4_quality_traits.png`
- Data path: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/10-GS/final_results/tables/quality_nonlinear_summary.tsv`
- New figure: `paperplot-skills/reports/redraw-benchmark/fig4_quality_traits_pattern_redraw.png`
- New PDF: `paperplot-skills/reports/redraw-benchmark/fig4_quality_traits_pattern_redraw.pdf`
- Reference pattern: `references/pattern-library/model-validation-figures.md` with `references/pattern-library/multi-panel-manuscript-layout.md`

### Original Problems

The old figure has an extreme wide aspect ratio, presentation-style centered title, heavy bar geometry, dense legend burden, and many long line structures. Visual QA flagged aspect ratio, grayscale discrimination, gridline/line burden, and thumbnail readability.

Old visual QA:

| metric | value |
|---|---:|
| status | warn |
| image size | 2055 x 649 px |
| aspect ratio | 3.1664 |
| blank margin fraction | 0.0759 |
| content density | 0.2417 |
| text burden score | 74.98 |
| line burden score | 0.3176 |
| color count estimate | 11 |
| manuscript-readiness score | 6 |

### Redraw Strategy

The redraw replaces thick grouped bars with horizontal point-ranges, keeps model identity in a restrained shared legend, uses facet-level hierarchy for traits, removes the oversized title, and uses uncertainty intervals as the primary statistical expression. This follows the model-validation pattern: emphasize ranked performance and uncertainty rather than decorative fill area.

New visual QA:

| metric | value |
|---|---:|
| status | pass |
| image size | 2881 x 1464 px |
| aspect ratio | 1.9679 |
| blank margin fraction | 0.1139 |
| content density | 0.0385 |
| text burden score | 32.48 |
| line burden score | 0.0029 |
| color count estimate | 10 |
| manuscript-readiness score | 10 |

Old-vs-new comparison:

| metric | old | new | delta |
|---|---:|---:|---|
| blank margin fraction | 0.0759 | 0.1139 | worse |
| text burden score | 74.98 | 32.48 | improved |
| content density | 0.2417 | 0.0385 | worse |
| color count estimate | 11 | 10 | improved |
| thumbnail content density | 0.299 | 0.0757 | improved |
| line burden score | 0.3176 | 0.0029 | improved |
| manuscript-readiness score | 6 | 10 | improved |

Verdict: `mixed`. The new figure is cleaner and much more manuscript-like, but deterministic content-density and blank-margin metrics worsened. This is acceptable only after human review because the old bar-heavy figure was visually dense for the wrong reason.

Manual aesthetic review: improved. The new figure has clearer hierarchy, less visual noise, and a more credible manuscript panel grammar. It still needs scientific review of trait naming, model grouping, and whether uncertainty intervals are SD, SE, or CI.

Manuscript candidate: yes, but not final without confirming statistical semantics and journal column target.

Remaining risks:

- Low content density is expected for a point-range redesign, but the panel could be tightened further if targeting one-column width.
- Trait labels and model names should be checked against manuscript terminology.
- The figure should state the interval definition in caption or axis/legend notes.

## Case 2: High-confidence NLR count by sample

- Original SVG: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_count_by_sample.svg`
- Comparable old PNG: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/06_supplementary_qc_figures/final_figures/png_600dpi/high_nlr_count_by_sample.final.png`
- Data path: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/data/high_nlr_sample_counts_for_plot.tsv`
- New figure: `paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png`
- New PDF: `paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.pdf`
- Reference pattern: `references/pattern-library/grouped-bar-errorbar.md`, adapted to a sorted lollipop because each sample has one scalar count.

### Original Problems

The old SVG uses a large centered title, many gridlines, and presentation-scale text. For a sample-rank count figure, the important reading task is rank and outlier detection; the original styling spends too much attention on frame and title.

Old SVG visual QA:

| metric | value |
|---|---:|
| status | warn |
| canvas size | 1100 x 650 |
| text count | 47 |
| line count | 8 |
| rect count | 21 |
| median font size | 11 |
| max font size | 22 |
| light gridline count | 6 |
| manuscript-readiness score | 5 |

New visual QA:

| metric | value |
|---|---:|
| status | warn |
| image size | 2102 x 1937 px |
| aspect ratio | 1.0852 |
| blank margin fraction | 0.0739 |
| content density | 0.0736 |
| text burden score | 35.37 |
| line burden score | 0.0393 |
| color count estimate | 8 |
| manuscript-readiness score | 9 |

Old-vs-new comparison against old SVG:

Verdict: `mixed`. The comparison now records a mixed-media limitation: SVG structural QA does not expose the same raster density, text, and color metrics as PNG QA. The readiness score improves from 5 to 9, but individual raster metrics are not directly comparable.

Old-vs-new comparison against comparable old PNG:

| metric | old PNG | new PNG | delta |
|---|---:|---:|---|
| blank margin fraction | 0.2134 | 0.0739 | improved |
| text burden score | 5.93 | 35.37 | worse |
| content density | 0.3657 | 0.0736 | worse |
| color count estimate | 11 | 8 | improved |
| thumbnail content density | 0.4133 | 0.1322 | improved |
| line burden score | 0.6188 | 0.0393 | improved |
| manuscript-readiness score | 6 | 9 | improved |

Verdict: `mixed`. The old PNG is dense because bars/grid structures fill the panel; the new lollipop reduces line burden and blank margin but increases label burden through readable sample labels.

Manual aesthetic review: improved. A sorted horizontal lollipop is the right grammar for one scalar count per sample. A trial iteration with horizontal bars increased deterministic line/content burden and was rejected; the lollipop version was kept because it better matches manuscript minimalism and ranking readability.

Manuscript candidate: yes for a supplement or single-column main figure panel. For a crowded main figure, the figure may need a top-N inset or grouped aggregation.

Remaining risks:

- If every sample label must remain visible, text burden will remain inherently high.
- If the manuscript message is not individual rank but accession class comparison, the data should include group labels and the design should switch to grouped summary plus selected labels.
- SVG-vs-PNG old-vs-new metrics should be treated as review prompts rather than hard pass/fail evidence.

## Workflow Lessons

- Pattern-based redraw can improve manuscript-readiness while still receiving a `mixed` deterministic verdict.
- Content density is not a universal quality target: bar-heavy old figures can look dense because of ink burden, while point-range/lollipop redesigns can be better with lower density.
- Family-specific interpretation is required for rank plots, model-validation panels, heatmaps, trees, and set matrices.
- Old-vs-new should report both deterministic metrics and human aesthetic review; neither alone is sufficient.
