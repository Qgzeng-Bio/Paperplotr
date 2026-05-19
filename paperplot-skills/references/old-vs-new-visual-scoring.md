# Old-vs-new visual scoring

Use `scripts/compare-old-new-figures.py` when an original figure and a redesigned figure are both available.

```bash
python3 scripts/compare-old-new-figures.py <old_image> <new_image> --out <qa_dir>
```

When the new figure uses a known family-specific profile, pass it explicitly:

```bash
python3 scripts/compare-old-new-figures.py <old_image> <new_image> --out <qa_dir> --new-family lollipop
```

For multi-panel comparison, pass panel expectations:

```bash
python3 scripts/compare-old-new-figures.py old.png new.png --out qa --expected-panels 2 --layout-profile equal
```

## Compared metrics

- blank margin fraction,
- text/mark burden,
- content density,
- color burden,
- line/gridline burden,
- thumbnail density,
- manuscript-readiness score,
- panel-area and content-area balance,
- optional OCR-derived text box risks when Tesseract is available.

## Structured Review Rubric

The tool always writes `old_vs_new_review_template.json`. A completed review JSON can be passed back with `--review-json`.

The rubric has eight 1-5 dimensions:

- message clarity,
- scientific completeness,
- visual hierarchy,
- proportional balance,
- readability at target size,
- statistical expression,
- color/legend discipline,
- data preservation.

Without review JSON, `final_verdict` must remain `human-review-required`, even when deterministic metrics improve. A final `improved` verdict requires no deterministic hard failure, new manuscript-readiness score at least 8, no severe panel geometry risk, and a higher total review score.

## Verdicts

| verdict | meaning |
|---|---|
| improved | new figure is measurably better on visual burden/readiness metrics |
| same | no material metric change |
| worse | new figure is measurably worse |
| mixed | some metrics improved and others worsened |

## Interpretation Rules

- Compare like with like when possible. PNG, PDF, and SVG now enter pixel QA through rasterization, but source media should still be reported because SVG structural checks and rasterized antialiasing are supplemental signals, not direct proof of message clarity.
- Content density is family-dependent. A point-range, lollipop, model-validation, or sparse annotation redesign can be better with lower density if text burden, line burden, hierarchy, and manuscript-readiness improve.
- Dense families such as heatmaps, Manhattan plots, phylogenetic annotation rings, and UpSet matrices should be judged against their pattern document before treating density as failure.
- A higher manuscript-readiness score is not enough by itself. Scientific meaning, interval semantics, label burden, and grayscale/color risks still need review.
- Severe panel geometry risks prevent an `improved` final verdict until the layout is fixed or explicitly justified.

## Required response

If `final_verdict` is `worse`, `mixed`, or `human-review-required`, do not present the new figure as final. Explain which metrics or rubric dimensions remain unresolved and propose the next visual edit.
