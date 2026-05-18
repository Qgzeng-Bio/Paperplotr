# Visual QA Gates

Use these gates before and after rendering. QA should protect manuscript quality, not force every lookup detail into the visible panel.

## Preflight Gates

- Scientific message is explicit in `design_brief` and `figure_spec`.
- Figure role is recorded as main, supplement, diagnostic, or exploratory.
- Data roles are identified: sample, group, metric, value, panel, color/fill variable.
- Multi-metric figures have a `metric_spec` with label, unit, direction, transform, and role.
- A `design_plan` records chart family, layout, label strategy, palette plan, visible simplifications, and risks.
- Percent, normalized, rank, z-score, and transformed values are labeled as such.
- Different-unit metrics are not placed on one shared axis unless a documented transform is used.
- Layout choice is justified; 5-8 heterogeneous metrics default to small multiples.
- Dense lookup labels do not dominate main figures.
- Palette type matches variable type: discrete for groups, continuous for numeric values.

## Hard Gates

- PDF, PNG, notes, metadata JSON, and QA report exist.
- Metadata contains `design_brief`, `design_plan`, and `label_strategy`.
- Rank-index or abbreviated label strategies preserve full mappings in metadata or sidecars.
- Same group uses consistent color across panels.
- Connecting lines encode real paired, repeated, ordered, or trajectory semantics.
- Main figure does not look like a diagnostic table of labels.

## Soft Warnings

- Label burden is high for the figure role.
- Legend entries are too many or visually dominant.
- Panel hierarchy is unclear.
- Axis titles or facet strips repeat too much text.
- P-value annotations dominate the panel.
- The new figure is valid but visually weaker than the source figure.
- Positive examples can still trigger `warn`; inspect the matching pattern document before failing a dense heatmap, tree, Manhattan, UpSet, lollipop, or model-validation panel.
- Old-vs-new comparisons across SVG and raster formats require human review because structural and pixel metrics are not equivalent.

## Completion Rule

Do not report "ready for manuscript use" unless all hard gates pass and the manuscript readiness score meets the role threshold.
