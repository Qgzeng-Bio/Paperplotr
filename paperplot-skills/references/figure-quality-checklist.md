# Figure Quality Checklist

Use this checklist before final reporting. Prioritize scientific readability over decorative polish.

## Message And Structure

- The figure answers the user's scientific question.
- Panel order follows the intended narrative.
- Each panel has one clear role.
- Redundant encodings are removed unless they improve interpretation.
- Figure title, axis labels, panel labels, and notes agree with the requested task.

## Text And Fonts

- Text is readable at manuscript size.
- Font family is consistent unless the user requests otherwise.
- Axis titles and tick labels do not overlap.
- Long category labels are rotated, wrapped, or moved only when needed.
- No text is clipped by plot boundaries.

## Axes And Ticks

- Axis titles include units where appropriate.
- Tick density is not excessive.
- Scientific notation is used only when helpful.
- Zero baselines are shown when scientifically meaningful.
- Log scales are labeled clearly.

## Color And Legend

- Avoid rainbow palettes.
- Avoid red/green collision unless semantics require it and alternatives are inaccessible.
- Prefer colorblind-aware palettes.
- Group colors are consistent across panels.
- Legends are not duplicated unnecessarily.
- Legends do not crowd the data region.
- Colorbars are not oversized relative to panels.

## Panels And Layout

- Panel labels use small bold `a`, `b`, `c`, `d` by default.
- Panel labels do not collide with titles, strips, legends, or data.
- Panels are aligned and spaced consistently.
- Shared legends are collected only when they remain readable.
- Multi-panel figures avoid excessive whitespace.

## Export QA

- Output files exist.
- Output files have non-trivial file sizes.
- At least one vector format exists for manuscript-grade output.
- Raster outputs use appropriate DPI, normally 600 for submission-quality files.
- Notes record output paths, presets, and QA status.

## Figure Legend / Caption Consistency

If the user provides a figure legend or manuscript text:

- Panel labels in the figure match the legend.
- Panel count and panel order match the legend.
- Group names and colors match the legend.
- Axis variables and units match the legend.
- Any visible annotation is explained or intentionally self-evident.
