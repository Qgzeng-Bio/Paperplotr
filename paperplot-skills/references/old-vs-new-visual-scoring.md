# Old-vs-new visual scoring

Use `scripts/compare-old-new-figures.py` when an original figure and a redesigned figure are both available.

```bash
python3 scripts/compare-old-new-figures.py <old_image> <new_image> --out <qa_dir>
```

When the new figure uses a known family-specific profile, pass it explicitly:

```bash
python3 scripts/compare-old-new-figures.py <old_image> <new_image> --out <qa_dir> --new-family lollipop
```

## Compared metrics

- blank margin fraction,
- text/mark burden,
- content density,
- color burden,
- line/gridline burden,
- thumbnail density,
- manuscript-readiness score.

## Verdicts

| verdict | meaning |
|---|---|
| improved | new figure is measurably better on visual burden/readiness metrics |
| same | no material metric change |
| worse | new figure is measurably worse |
| mixed | some metrics improved and others worsened |

## Interpretation Rules

- Compare like with like when possible. SVG structural QA and raster QA expose different metrics; mixed SVG/PNG or SVG/PDF comparisons are review prompts, not direct numeric proof.
- Content density is family-dependent. A point-range, lollipop, model-validation, or sparse annotation redesign can be better with lower density if text burden, line burden, hierarchy, and manuscript-readiness improve.
- Dense families such as heatmaps, Manhattan plots, phylogenetic annotation rings, and UpSet matrices should be judged against their pattern document before treating density as failure.
- A higher manuscript-readiness score is not enough by itself. Scientific meaning, interval semantics, label burden, and grayscale/color risks still need review.

## Required response

If the verdict is `worse` or `mixed`, do not present the new figure as final. Explain which metrics worsened and propose the next visual edit.
