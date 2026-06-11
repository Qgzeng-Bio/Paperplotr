# Nature figure guardrails

Use these guardrails as the final rendered-figure contract for manuscript-grade
scientific plots. They convert design advice into checks that can be reported
by `scripts/visual-qa-rendered-image.py`.

Run strict mode for final candidates:

```bash
python3 scripts/visual-qa-rendered-image.py <figure.pdf-or-png> --out <qa_dir> --strict-nature
```

For equal-role multi-panel figures, always provide the expected structure:

```bash
python3 scripts/visual-qa-rendered-image.py <figure.pdf-or-png> --out <qa_dir> \
  --expected-panels 4 --layout-profile equal --strict-nature
```

## Ten guardrails

1. **Export floor**: PDF/SVG vector artwork and PNG preview must be large
   enough for target-size reading; extreme aspect ratios require redesign.
2. **Readable typography**: text should remain readable at publication width;
   dense tick labels, tiny OCR boxes, and oversized presentation titles trigger
   review.
3. **No visible overlap**: text, ticks, labels, legends, and annotations must
   not collide. Use repel, offsets, fewer direct labels, or sidecars.
4. **Controlled whitespace**: the data region should visibly fill the canvas.
   Large dead margins or sparse content require crop, margin, or layout changes.
5. **Balanced multi-panel geometry**: equal-role panels need equal panel boxes
   and comparable data-region sizes. Unequal panels require an explicit hierarchy.
6. **Thumbnail readability**: the figure must still communicate the main
   structure in a small preview; if it reads as texture, reduce visible burden.
7. **Color and grayscale safety**: color must encode semantics, avoid
   presentation saturation, and retain luminance contrast for grayscale review.
8. **Gridline and stroke discipline**: gridlines are off by default; long-line
   burden, heavy borders, and decorative structure must be removed or justified.
9. **Legend and edge burden control**: repeated legends, edge-heavy labels, and
   large guide areas should be consolidated or moved outside the data region.
10. **Actionable remediation**: every deterministic risk must carry a concrete
    fix and a reference document; a warning is useful only if it tells the agent
    what to change next.

## Strict mode interpretation

- `pass`: no deterministic guardrail risk was found.
- `warn`: a review risk exists; inspect the figure and decide whether the
  family-specific structure justifies it.
- `fail`: strict Nature mode found a hard visual problem. Do not report the
  figure as manuscript-ready until it is revised or the hierarchy is explicitly
  justified in notes and metadata.

## What strict mode cannot prove

The guardrails catch common rendered-image failures. They do not prove
scientific correctness, statistical validity, or whether the figure tells the
best possible story. Those still require data semantics, notes, metadata, and
old-vs-new review when a source figure exists.
