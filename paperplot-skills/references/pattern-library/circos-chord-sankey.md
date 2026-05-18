# Pattern: Circos / Chord / Sankey

Derived from chord, circos, Sankey, circular bar, and network-flow replica cases.

## Applies When

- The data are many-to-many links, flows, or genomic intervals where circular/flow layout serves the science.
- Source, target, weight, and grouping variables are explicit.
- The viewer needs relationship structure more than exact individual values.

## Does Not Apply When

- A simple matrix, bar chart, or network table would communicate better.
- Links are too numerous for readable paths.
- Circular layout is chosen only because it looks impressive.
- Source/target semantics or weights are missing.

## Input Data Structure

- Link table with `source`, `target`, `weight`, optional `source_group`, `target_group`, `direction`, and `category`.
- Genomic circos needs interval coordinates and chromosome/order metadata.

## Visual Encoding

- Link width encodes weight.
- Group order and outer bars encode aggregate context.
- Direction should be encoded only when directional flow is real.

## Layout

- Order groups to minimize crossings.
- Aggregate low-weight links before plotting.
- Use rectangular alluvial/Sankey layout when circular geometry hurts readability.

## Typography And Marks

- Labels outside link paths; avoid label rotation that breaks reading.
- Thin borders; link alpha helps crossing density.
- Legends should explain link weight and group color separately.

## Color Strategy

- Use group colors for sources/targets, not every link.
- Use muted alpha for secondary links and one accent for the scientific focus.

## Common Failure Modes

- Path crossings create visual texture rather than information.
- Link colors and group colors conflict.
- Labels around the circle become unreadable.
- Optional packages make the workflow fragile.

## Nature-Like Principle

Circular and flow figures are legitimate only when their topology carries evidence; otherwise they are usually less manuscript-like than matrices or ranked bars.

## Existing Templates

- No direct core template.
- Existing templates should reference this pattern as a boundary rule.

## New Template Need

No immediate template. Add only after defining a strict link-table contract and optional backend policy.

## QA Checklist

- Source/target/weight columns are validated.
- Aggregation threshold is recorded.
- Link direction semantics are clear.
- Simpler alternatives were considered.
- Optional dependency risk is documented.

## Visual QA Focus

- `content_density` and `line_burden_score` can be high; require family-specific interpretation.
- `text_burden_score` catches unreadable ring labels.
- `grayscale_discrimination_risk` for group colors.

## Old-vs-New Criteria

Improvement means fewer crossings, clearer group ordering, lower label burden, and no loss of important link-weight structure.
