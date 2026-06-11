# Multi-Panel Layout Rules

Multi-panel manuscript figures need hierarchy, not just tiling.

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

## Metadata

Record `panel_hierarchy`, `layout_budget`, and `shared_guide_plan` in metadata for multi-panel templates.
