# Nature Figure Detail Rubric

This rubric converts common high-level Nature/Cell/Science-style plotting traits into reusable QA criteria. It is not a request to copy any source figure.

## Typography

- Manuscript figure text usually sits in the 5-7 pt range at final width; panel labels are typically larger and bold.
- Large centered titles are presentation/report style unless the journal explicitly requires them.
- Tick labels must not collide, clip, or crowd the axis; dense lookup labels should move to a key, sidecar, supplement, or ranked index.
- Font QA must distinguish vector certainty from raster estimates. SVG/PDF vector text can support direct font-size review; PNG text size is heuristic.

## Stroke And Marks

- Axes, ticks, error bars, box outlines, violin outlines, and connector lines should remain visually secondary to data marks.
- Heavy strokes are a manuscript risk when they dominate bars, intervals, heatmap cells, or grid backgrounds.
- Very light strokes are a risk when axes, intervals, or data boundaries disappear at target width.
- Error bars require a named uncertainty type: SD, SE, CI, IQR, range, or model interval.

## Panel Geometry

- Equal-role panels require comparable panel boxes and comparable data-region sizes.
- Unequal panels are allowed only for deliberate hierarchy; the notes should identify primary and supporting panels.
- Legends, titles, and annotations must not shrink one data region while another panel keeps full plotting area.
- Excessive internal padding is a layout failure when content could be enlarged without losing labels.

## Text And Data Collision

- Text/data overlap is a hard detail QA issue when labels cover points, lines, bars, boxes, heatmap cells, or error bars.
- Significance brackets and stars must not compress the data region or become the main visual message.
- Direct labels should be limited to high-priority entities; dense labels need `ggrepel`-style collision control or a label-key sidecar.

## Grid And Background

- Gridlines are off by default for group comparison, violin/raincloud, bar, lollipop, enrichment, and most small-multiple figures.
- Light gridlines are acceptable for scatter, line, map, and quantitative reading tasks when they support scale reading.
- Heatmaps, tree rings, UpSet matrices, and circular annotation plots need family-specific grid interpretation; structural cell or ring boundaries are not automatically bad.
- Decorative backgrounds, gradients, shadows, glow effects, or heavy panel frames should not enter default manuscript templates.

## Color And Legend Discipline

- Color encodes scientific grouping, numeric magnitude, direction, significance, or annotation class; it is not decoration.
- Main figures usually work best with 6-8 categorical colors or fewer.
- Continuous palettes need a semantic midpoint or clear monotonic meaning.
- Legends should be merged, simplified, moved outside repeated panels, or replaced by compact direct labels when that reduces burden.

## Scientific Semantics

- Units, denominators, normalization, transformation, threshold definitions, sample size, and error type must be visible or recorded in notes/metadata.
- A visually cleaner redraw is worse if it removes scientific context.
- Old-vs-new improvement requires detail QA improvement and scientific information preservation.
