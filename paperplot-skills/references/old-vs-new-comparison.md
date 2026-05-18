# Old-vs-new figure comparison

Use this whenever the user provides an existing figure to optimize.

## Redesign modes

| mode | use when | action |
|---|---|---|
| preserve_structure | old figure has strong rhythm; issues are labels, legend, palette, export | keep layout, fix details |
| refine_structure | message is clear but layout density or labels need improvement | keep main encoding, adjust structure |
| recompose | panel hierarchy or figure story is weak | reorganize panels |
| rebuild | chart type/statistics are misleading | redesign from data |
| diagnostic_only | goal is data checking | prioritize complete labels over aesthetics |

## Comparison table

Record:

| item | old | new | verdict |
|---|---|---|---|
| scientific message | | | better/same/worse |
| label burden | | | |
| legend burden | | | |
| panel hierarchy | | | |
| statistical expression | | | |
| color semantics | | | |
| visual rhythm | | | |
| manuscript readiness | | | |

## Hard rules

- Do not preserve connecting lines unless they encode paired, repeated, ordered, or trajectory semantics.
- Do not convert dense x labels into a y-axis label dump unless identity is the primary message.
- Do not destroy useful rhythm just to satisfy a mechanical QA rule.
- If old figure is aesthetically stronger, say so and iterate.
