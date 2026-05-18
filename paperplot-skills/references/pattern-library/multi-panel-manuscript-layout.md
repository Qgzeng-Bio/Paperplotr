# Pattern: Multi-Panel Manuscript Layout

Derived from replica cases combining scatter, heatmap, ridge, tile, bar, ternary, and diagnostic panels into manuscript-style figures.

## Applies When

- Multiple panels answer one scientific story.
- Panels have clear hierarchy: primary evidence, secondary mechanism, supporting diagnostic.
- Shared legends, scales, and labels can reduce repetition.

## Does Not Apply When

- Panels are unrelated outputs collected for convenience.
- Every panel needs a different color system and unrelated metric scale.
- The figure would be clearer as two separate figures.
- Small panels make text or marks unreadable.

## Input Data Structure

- One or more analysis tables plus a panel plan with `panel_id`, `family`, `message`, `data_source`, `scale`, `legend_role`, and `priority`.
- Metadata must specify which panels share groups, palettes, or axes.

## Visual Encoding

- Primary panel gets most area and strongest visual contrast.
- Supporting panels use smaller marks and lighter annotation.
- Repeated groups use identical colors and legend labels.

## Layout

- Use journal column width first, then choose grid.
- Align plot regions, not just outer boxes.
- Put panel labels outside or at upper-left consistently.
- Keep legend shared unless panel semantics differ.

## Typography And Marks

- One font family and coherent base size across panels.
- Panel labels about 8 pt bold.
- Avoid oversized subplot titles; use caption/notes for narrative.
- Use consistent stroke widths across panels.

## Color Strategy

- One primary palette across panels.
- Secondary palettes only for different data roles, such as heatmap scale versus group colors.
- Limit accents so hierarchy remains visible.

## Common Failure Modes

- Equal-size panels despite unequal importance.
- Repeated legends consume data space.
- Panel titles become a table of contents.
- Mixed units are compressed into one visual scale.

## Nature-Like Principle

Manuscript figures are arguments. Layout must show which evidence is primary and which is contextual.

## Existing Templates

- `manuscript-four-panel-template.R`
- `multi-panel-template.R`
- `multi-metric-small-multiples-template.R`
- `bio-genome-quality-overview-template.R`

## New Template Need

No immediate new template. Existing multi-panel templates need stronger panel hierarchy metadata and shared legend strategy.

## QA Checklist

- Each panel has a one-sentence message.
- Primary/secondary/supporting roles are assigned.
- Shared color/legend semantics are documented.
- Panel labels are consistent.
- Any information removed from panels is preserved in notes/sidecars.

## Visual QA Focus

- `thumbnail_content_density` for small-panel readability.
- `blank_margin_fraction` for layout imbalance.
- `text_burden_score` for repeated legends/titles.

## Old-vs-New Criteria

Improvement means the figure story is clearer, repeated legends/titles are reduced, primary evidence gains space, and all panels remain readable at target width.
