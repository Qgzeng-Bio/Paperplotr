# Publication visual standards

These standards define the minimum visual floor for professional scientific figures. They are Nature-inspired but not a claim of journal acceptance.

## Size presets

| use case | width | height guidance |
|---|---:|---:|
| single column | 89 mm | usually 50-90 mm |
| double column | 180-183 mm | usually 80-140 mm |
| full figure max | 180-183 mm | about 170 mm max when a legend must fit below |
| supplement | flexible | must remain readable when embedded in PDF |

Use the smallest size that preserves readability. Multi-panel figures may need double-column width.

For Nature-like manuscript work, choose size from information burden:

- Single simple panel: 55-89 mm wide.
- Dense scatter, heatmap, or distribution panel: 89 mm only if labels remain readable; otherwise 120-180 mm.
- Two to four manuscript panels: usually 180 mm wide, with the primary panel 1.3-2.0x the area of supporting panels.
- Full-page composite: avoid exceeding about 170 mm height unless the target journal permits taller figures.

## Typography

- Use Arial, Helvetica, or a close sans-serif fallback.
- Keep vector text editable; do not outline or rasterize text.
- Most text: 5-7 pt at final size.
- Panel labels: about 8 pt bold, upright; use consistent `a, b, c` or `A, B, C` based on journal/user preference.
- Axis titles should be concise and include units in parentheses.
- Avoid plot titles inside manuscript panels unless the title carries scientific meaning; prefer panel labels and caption text.
- Tick labels can be 5-6 pt for dense panels, but must remain readable in the rendered PNG preview.
- Long labels should move to sidecars, numbered keys, or supplement before shrinking below readable size.

## Strokes and marks

| element | default |
|---|---:|
| axis line | 0.3-0.45 pt |
| tick line | 0.25-0.35 pt |
| interval/error line | 0.35-0.55 pt |
| boxplot line | 0.35-0.55 pt |
| trend line | 0.45-0.7 pt, only if statistically/semantically justified |
| point size | 1.2-2.2 mm depending on density |
| jitter alpha | 0.55-0.9 |
| bar width | 0.55-0.75 of category width |

Do not use thick default presentation-style strokes in manuscript figures.

For common pattern families:

- Box/violin/jitter: show raw points first; keep violins light and box outlines thin.
- Error bars: cap width should be short and error type must be named.
- Heatmaps: cell borders off or very thin; annotation strips should not compete with the matrix.
- Volcano/MA: background points small and muted; highlight classes sparse and justified.

## Color

- Color must encode meaning, not decoration.
- Prefer accessible palettes such as black, orange, sky blue, bluish green, blue, vermillion, and reddish purple.
- Avoid red/green dependence and rainbow scales.
- Do not use colored text as the only key; use black text plus colored keys/markers.
- Reuse the same color for the same group across panels.
- If group count exceeds 8, consider facet, top groups plus other, or supplement.
- Continuous scales need units, transform, midpoint, and direction when relevant.
- Diverging scales require a meaningful center; do not use diverging color for one-sided metrics.

## Axes and grids

- Include axis lines and tick marks unless the chart type has a strong reason not to.
- Axis labels need variables and units.
- Background gridlines are off by default.
- If gridlines are needed, keep them thin and light and explain why.
- Do not mix incompatible units on one y-axis.
- Axis titles are required unless the panel is a small multiple with a shared axis label.
- Remove redundant tick labels only when panel alignment preserves the scale.

## Legends

- Use shared legends for multi-panel figures when semantics are shared.
- Put legends near the data but do not let them dominate.
- Avoid repeated legends across panels.
- Legend labels must explain units, denominators, classes, and thresholds when relevant.
- Shared legends belong outside the data region or in a deliberately reserved panel.
- If the legend is larger than 15-20% of the data region, simplify classes or move details to notes.

## Information Hierarchy

- Primary evidence receives the largest area, strongest contrast, and clearest labels.
- Supporting diagnostics use smaller panels, lighter annotation, and fewer direct labels.
- Remove information from the visible figure only when it is preserved in notes, metadata, sidecars, or supplement.
- Add auxiliary explanation when scale, denominator, statistic, grouping, or transformation would otherwise be ambiguous.

## Export

- Export PDF for editable vector artwork.
- Export PNG for preview and QA.
- Use RGB color.
- Keep text and lines vector in PDF/SVG.
- Use at least 300 dpi for raster images and 600 dpi for line-heavy previews when possible.
- Do not artificially upscale low-resolution images.
