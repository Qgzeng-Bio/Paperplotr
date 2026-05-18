# Label Burden Strategies

Readable does not mean every label must be visible in the manuscript panel.

## Default Decision Order

1. Decide whether sample identity is the main message or lookup metadata.
2. Count labels and estimate label burden.
3. For main figures, preserve visual rhythm over exhaustive labels.
4. Move full label mappings to sidecars and metadata when labels are lookup details.

## Strategies

| Situation | Strategy |
|---|---|
| Few labels | show all labels |
| Moderate labels | rotate, wrap, or abbreviate |
| Many lookup labels in main figure | rank index + selected key labels + label key sidecar |
| Sample identity is core message | allow more labels, but still check visual budget |
| Diagnostic figure | full labels allowed |

## Preferred Dense-Sample Strategy

For 5-8 metric small multiples with many samples:

- use a rank/index x axis;
- direct-label only key samples, outliers, references, top/bottom examples;
- write `*_label_key.csv` with the full mapping;
- store full sample order in metadata;
- avoid y-axis label dump unless sample identity itself is the message.
