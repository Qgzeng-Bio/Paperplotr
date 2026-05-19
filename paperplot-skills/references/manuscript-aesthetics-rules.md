# Manuscript Aesthetics Rules

These rules translate the replica-library review into stable figure-design decisions. They are not a request to imitate any source figure; they are an abstract style system for clear scientific evidence.

## Figure Tiers

- Analysis sketch: dense, exploratory, allowed to be rough.
- Diagnostic figure: technical and complete; may be too dense for main text.
- Manuscript candidate: clear hierarchy, target-size readable, scientific semantics documented.
- Manuscript-ready: passes visual QA, preserves data accuracy, and old-vs-new comparison does not show deterministic worsening.

## Layout And Size

- Single-column panels should use 89 mm only when the message remains readable.
- Double-column figures should reserve more space for primary evidence than supporting panels.
- Multi-panel layouts must define primary, secondary, and supporting panels before plotting.
- Panel spacing should be tight but not cramped; align data regions, not only outer plot boxes.
- Show a hint of repeated structure through alignment, not through repeated legends and titles.
- Proportional balance is a hard manuscript requirement. Panels with equal scientific weight should use equal panel boxes and comparable data-region sizes; panels with different weights may be unequal only when the hierarchy is deliberate and documented.
- Do not stitch plots that were exported at different aspect ratios as if they were equal panels. Re-export each panel to the target panel box, reserve legend space deliberately, and check the composite preview at final size.

## Text

- Use one sans-serif family, preferably Arial/Helvetica-equivalent.
- Most manuscript text: 5-7 pt at final size.
- Panel labels: about 8 pt bold, placed consistently.
- In-panel titles are usually removed; use axis labels, panel labels, and caption/notes instead.
- Abbreviate or index long labels only when the full mapping is written to a sidecar.

## Marks

- Axis and interval strokes: 0.25-0.6 pt.
- Points: 1.0-2.2 mm depending on density.
- Bars: 0.55-0.75 category width; avoid over-wide bars.
- Error bars: short caps, thin strokes, named uncertainty.
- Violin/box/jitter: raw dots are evidence; density/box is summary.

## Color

- Use color for semantics, not decoration.
- Default discrete palettes should be muted and color-blind aware.
- Use gray for background/reference points.
- Limit main-figure categorical colors to about 6-8.
- Avoid rainbow, saturated gradients, decorative backgrounds, shadows, and glow effects.

## Annotation

- Significance labels should be compact and secondary.
- Effect size and uncertainty are preferred over p-value-only annotation.
- Thresholds must be named in labels or notes.
- Direct labels should be top-priority only; dense labels move to a key/sidecar.

## Gridlines And Frames

- Gridlines are off by default.
- Use light gridlines only when they improve quantitative reading.
- Avoid boxed panels unless matrix/table semantics require them.
- Heatmaps may use cell boundaries only when boundaries help reading.

## Add Or Remove Information

- Remove visible details when they burden the main message and can be preserved in notes/sidecars.
- Add visible aids when the viewer cannot infer scale, threshold, denominator, unit, or group semantics.
- Do not simplify away sample size, uncertainty type, transformation, or normalization.

## QA Translation

- High text burden means revise labels before shrinking text.
- High color burden means reduce classes or move to facets/supplement.
- High density is acceptable for heatmaps/Manhattan plots only with family-specific justification.
- Multi-panel size mismatch is not a minor aesthetic issue; it means the layout has failed unless unequal panel sizes encode a deliberate evidence hierarchy.
- A visually cleaner redraw is not better if it removes required scientific semantics.
