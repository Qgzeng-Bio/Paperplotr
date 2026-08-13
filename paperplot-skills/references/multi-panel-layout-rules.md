# Multi-Panel Layout Rules

Multi-panel manuscript figures need hierarchy, not just tiling.

Before composing, select a profile from `journal-specs-matrix.md`. Derive panel boxes from the final export width and review cognitive load before rendering; do not compose at an arbitrary size and shrink afterward.

## Rules

- A main figure should usually have one or two primary panels.
- Primary panels should be upper-left, larger, or visually dominant.
- Supporting panels should not compete with the primary message.
- Prefer shared legends over repeated legends.
- Avoid repeated axis titles unless panel-specific units require them.
- Keep facet strips short; do not use strips as captions.
- Use consistent panel tags: A, B, C, D.
- For equal-role composites, run rendered QA with `--expected-panels <n> --layout-profile equal --strict-nature`.
- Treat `panel_size_imbalance`, `panel_data_region_imbalance`, and `panel_blank_space_imbalance` as blockers unless notes define a deliberate hierarchy.
- More than 7 distinct elements, 3 meaning-carrying colors, 3 shapes, or 4 legend entries in one panel is a review trigger. Split or simplify when possible; dense families may retain the burden only with a recorded scientific reason and final-size QA.

## Metadata

Record `journal_profile`, `panel_hierarchy`, `layout_budget`, `shared_guide_plan`, and any `cognitive_load_exception` in metadata for multi-panel templates.
