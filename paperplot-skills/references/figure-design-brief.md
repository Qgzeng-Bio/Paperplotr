# Figure Design Brief

Create a design brief before plotting. The brief is the contract between scientific intent and visible design.

## Required Fields

- `scientific_message`: the claim or comparison the figure supports.
- `figure_role`: `main`, `supplement`, `diagnostic`, or `exploratory`.
- `main_comparison`: the primary comparison or trend.
- `data_roles`: sample, group, metric, value, panel, color/fill roles.
- `metric_semantics`: units, direction, transforms, and roles.
- `label_burden`: whether labels are direct evidence or lookup metadata.
- `legend_burden`: whether legends dominate the visible figure.
- `must_show`: information that must remain in the visible figure.
- `may_move_to_metadata`: lookup details that can leave the visible figure.
- `acceptable_simplifications`: simplifications that preserve the scientific message.

## Rule

A main figure does not need to display every lookup label. It must preserve the message and record omitted lookup details in notes, metadata, and sidecars.
