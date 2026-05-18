# Pattern: Phylogenetic Tree With Annotation Rings

Derived from the tree plus outer heatmap/bar-ring replica case.

## Applies When

- A valid tree structure is central to the scientific question.
- Tip-level metadata or quantitative traits need to be aligned to tree tips.
- The tree topology, branch lengths, and metadata join keys are available.

## Does Not Apply When

- There is no tree file or tip metadata.
- The figure is only trying to compare groups; use grouped summaries.
- Rings exceed the readable metadata budget.
- The tree is decorative rather than analytical.

## Input Data Structure

- Tree file such as `nwk` plus metadata table with `tip_id` and ring columns.
- Optional quantitative tracks require unit and scale.
- Group annotations require color dictionaries.

## Visual Encoding

- Tree topology encodes relationship.
- Outer rings encode compact categorical or continuous metadata.
- Bar rings encode tip-level quantities only when scale is clear.

## Layout

- Circular trees need enough tips and a reason for circular layout.
- Rectangular trees are often better for fewer tips or long labels.
- Ring order should move from primary biological grouping near the tree to secondary details outward.

## Typography And Marks

- Tip labels should be selective or sidecar-based for dense trees.
- Ring strokes very thin; legend compact and grouped by ring.
- Avoid thick branch lines.

## Color Strategy

- Categorical rings need stable named palettes.
- Continuous rings need clear colorbars with units.
- Avoid encoding many unrelated ring variables with many unrelated palettes.

## Common Failure Modes

- Rings become decorative bands with no readable legend.
- Tip labels overlap.
- Metadata rows fail to match tree tip order.
- Branch-length semantics are missing.

## Nature-Like Principle

Tree figures are specialized evidence displays; they require data integrity and metadata discipline before aesthetic polishing.

## Existing Templates

- No direct template.
- `bio-genome-quality-overview-template.R` can share metadata-sidecar practices, not tree layout.

## New Template Need

No immediate template in the standalone core. A future optional backend would need explicit `ggtree`/tree handling and validation.

## QA Checklist

- Tree and metadata join keys are verified.
- Branch length/topology semantics are documented.
- Ring order and color legends are defined.
- Dense labels move to sidecars.
- Required optional dependencies are declared.

## Visual QA Focus

- Family-specific thresholds required: dense rings may raise `content_density`.
- `text_burden_score` catches tip-label overload.
- `grayscale_discrimination_risk` matters across ring palettes.

## Old-vs-New Criteria

Improvement means topology is preserved, ring semantics are clearer, label overlap decreases, and metadata interpretation becomes easier without hiding key tree structure.
