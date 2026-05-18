# Statistical Expression Guide

Scientific figures should show raw evidence, effect size, and uncertainty before decorative significance markers.

## Group Comparisons

- `n < 5` per group: raw points are primary; do not rely on boxplot shape.
- `n 5-20`: boxplot is acceptable only with raw points overlaid.
- `n >= 20`: violin or boxplot with points can be used.
- Do not remove outliers silently.

## Paired Data

- Paired lines require a real paired ID.
- Without a paired ID, use independent-group visualization.
- Record paired variable in metadata.

## Effect Size

- Prefer effect size + confidence interval for main comparisons.
- P-values can go in notes/metadata unless they are central to the figure.
- Wide intervals are part of the result and must remain visible.

## P-values

- Do not use p-value stars as the only statistical expression.
- Multiple p-values should not dominate a main figure.
