# Multi-Metric Figure Design

Use this before combining several metrics into fewer panels.

## Core Rule

Compression must reduce cognitive load. If the compressed design needs more explanation than small multiples, keep small multiples.

## Default For 5-8 Heterogeneous Metrics

Use small multiples as the default:

- one panel per metric
- shared sample order
- original units visible
- consistent group colors
- no per-point text unless sparse and readable
- 2 x 3 for six metrics, 2 x 4 for seven or eight metrics

This default is intentionally conservative because it protects units and avoids overloaded legends.

## When To Use A Rank + Key Metrics Figure

Use a rank panel plus 2-3 key metric panels when the main story is "which samples are best" rather than "show every metric".

Keep the remaining metrics in notes, a table, or extended data.

## When A Heatmap Is Acceptable

Use a heatmap only when:

- relative patterns matter more than original units
- one color scale can explain the panel
- labels do not need to be printed inside every cell
- the legend is simple
- the result is faster to explain than small multiples

## Hard Stops

Do not use a dot or bubble heatmap when:

- there are more than 15 samples and more than 4 metrics
- color, size, raw labels, and normalization are all needed
- text inside marks overlaps
- the legend takes as much work to decode as the data
- the result is less clear than a 2 x 3 small-multiple layout
