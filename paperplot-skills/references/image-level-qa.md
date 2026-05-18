# Image-level QA

Use this after rendering a figure. Code-level validation is not enough.

## Required visual checks

Inspect the actual PNG/PDF preview at:

1. full size,
2. target publication width,
3. 50% zoom or thumbnail view,
4. grayscale/black-white mental simulation when relevant.

## Checklist

| category | pass condition | fail condition |
|---|---|---|
| readability | all labels readable at final size | text below readable size or overlapping |
| hierarchy | primary message visible in 3-5 seconds | viewer must decode every legend/label first |
| panel balance | panels align and have appropriate relative weight | all panels equal weight despite different roles |
| label burden | lookup labels reduced or sidecarred | dense sample names dominate data |
| legend burden | legend supports data reading | legend larger than data or repeated |
| color | meaning is accessible and consistent | red/green dependence, rainbow, ambiguous classes |
| black-white robustness | groups still partly distinguishable by position/shape/labels | color is the only encoding for critical classes |
| statistics | uncertainty and n/test semantics visible or documented | p-values or stars appear without context |
| export | PDF vector and PNG preview are crisp | rasterized text, fuzzy lines, tiny file, wrong aspect |

## Old-vs-new visual comparison

When old and new images are available, compare:

- message clarity,
- label load,
- legend load,
- visual rhythm,
- panel alignment,
- statistical expression,
- color semantics,
- print/readability risk.

The new figure must be better for the scientific message, not merely more compliant.

## When to fail manuscript readiness

Fail or warn if:

- QA report passes but the rendered figure looks like a diagnostic plot,
- the new figure is visually worse than the old one,
- labels are technically present but unreadable,
- scientific semantics are only in code and not in figure/notes/metadata,
- vector output does not preserve editable text.
