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

## Family-Specific Threshold Profiles

`scripts/visual-qa-rendered-image.py` accepts `--family <name>` for families where global thresholds over-warn on legitimate structure. The output records `figure_family`, `threshold_profile`, and `family_thresholds`.

| profile | use for | main threshold change | keep reviewing |
|---|---|---|---|
| `rank-lollipop` | sorted lollipop, rank dotplot, dumbbell | allows legitimate horizontal stems and lower ink density | sample-label burden and whether labels belong in main figure |
| `model-validation` | accuracy, calibration, residual, prediction-performance panels | allows sparse point-range evidence and moderate thumbnail density | interval semantics and metric units |
| `heatmap` | heatmap, correlation heatmap, matrix dotplot | allows dense tiles, higher thumbnail density, and structural grid burden | color scale semantics and unreadable cell labels |
| `manhattan` | genome-wide coordinate plots | allows wider aspect and dense point clouds | axis/chromosome labels and threshold-line meaning |
| `phylo-annotation-ring` | trees with rings, clades, and tip annotations | allows dense circular/tree structure | whether annotation rings remain decipherable |

Do not add a family profile to hide a real problem. If a warning disappears under a family profile, the notes should still explain why the structure is expected for that family.

## Completion Rule

Do not report "ready for manuscript use" unless all hard gates pass and the manuscript readiness score meets the role threshold.
