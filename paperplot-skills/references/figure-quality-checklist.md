# Figure Quality Checklist

Use this checklist before final reporting. `visual-qa-gates.md` contains the hard gates; this file is the broader readability checklist.

## Message And Structure

- The figure answers the user's scientific question.
- Panel order follows the intended narrative.
- Each panel has one clear role.
- Redundant encodings are removed unless they improve interpretation.
- A compressed figure is easier to read than the small-multiple version it replaces.

## Text And Fonts

- Text is readable at manuscript size.
- Axis titles and tick labels do not overlap.
- Long category labels are rotated, wrapped, or moved only when needed.
- Numeric labels inside dense tiles, bubbles, or points do not overlap.
- No text is clipped by plot boundaries.

## Axes And Ticks

- Axis titles include units where appropriate.
- Tick density is not excessive.
- Zero baselines are shown when scientifically meaningful.
- Log scales are labeled clearly.

## Color And Legend

- Avoid rainbow palettes.
- Prefer colorblind-aware palettes.
- Group colors are consistent across panels.
- Legends are not duplicated unnecessarily.
- Colorbars are not oversized relative to panels.
- Percentages and quality scores are clearly labeled.

## Panels And Layout

- Panel labels use small bold `a`, `b`, `c`, `d` by default.
- Panel labels do not collide with titles, strips, legends, or data.
- Panels are aligned and spaced consistently.
- Multi-panel figures avoid excessive whitespace.
- For 5-8 heterogeneous metrics, prefer clean small multiples.
