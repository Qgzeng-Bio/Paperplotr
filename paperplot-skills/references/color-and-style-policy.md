# Color And Style Policy

The default look is restrained GraphPad-like scientific plotting: clean axes, no decorative effects, no default gridlines, readable labels, and clear legends.

## Theme

- Use `pp_theme(show_grid = FALSE)` by default.
- Turn on gridlines only for quantitative reading tasks where they help.
- Use Arial with 7-8 pt base text for manuscript-scale figures.
- Use line widths around 0.35-0.4 pt.
- Use the selected pattern document before changing defaults; style choices should follow figure family, data density, and target size.
- Avoid large in-panel titles; panel labels and captions carry narrative.

## Discrete Color

- Use `graphpad_discrete` for generic categorical groups.
- Use a user-provided named color vector when group colors have semantic meaning.
- Keep group colors stable across panels.
- Use gray for reference or background groups when contrast should be reduced.
- For differential plots, use neutral background points and at most two accent directions/classes.
- For ordination/group comparisons, keep primary group colors under 8 classes in main figures.
- For set/network/circos plots, color groups rather than every edge/link.

## Continuous Color

- Use `graphpad_heatmap` for heatmaps and quality scales.
- Use `graphpad_heatmap_alt` when the main palette conflicts with group colors.
- The legend title must state the value and unit, for example `Completion (%)`.
- Do not encode a percentage without a percent sign in the legend or axis.
- Use diverging color only with a meaningful center, such as zero correlation or log fold-change.
- Sequential quality scales should state whether higher is better.
- Family-specific dense displays may need a calmer continuous palette than ordinary presentation plots.

## Avoid

- Rainbow palettes.
- Red/green opposition unless required and still interpretable.
- Simultaneous color, size, raw labels, and normalization in dense panels.
- Decorative palettes that compete with the scientific message.
- Gradient backgrounds, shadows, glow, 3D effects, or circular layouts used only for aesthetic novelty.
- Reusing a color to mean different groups in different panels.

## Pattern Defaults

- Grouped comparisons: muted categorical fill plus darker raw points or intervals.
- Raincloud/violin: light fill, readable raw points, restrained significance annotation.
- Heatmap: perceptual sequential/diverging scale with compact annotation strips.
- Scatter/regression: neutral cloud plus sparse highlights; fit line not brighter than the data.
- Volcano/MA: gray background, directional accents, strict label budget.
- Multi-panel: one shared group palette; separate heatmap scale only when it encodes a different data role.
