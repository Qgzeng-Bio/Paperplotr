# Redraw Strategy

Old figures often contain both problems and useful visual rhythm. Do not rebuild automatically.

## Modes

| Mode | Use when |
|---|---|
| `preserve_structure` | Old figure rhythm is strong and only labels, legend, or palette need repair |
| `refine_structure` | Old figure structure works but label burden or visual burden needs redesign |
| `recompose` | Panel hierarchy, axis repetition, or legends need re-composition |
| `rebuild` | Chart type, scale, line semantics, or statistical expression is misleading |
| `diagnostic_only` | Goal is data inspection, not manuscript output |

## Connecting Lines

Keep connecting lines only when they encode paired, repeated, ordered, or trajectory semantics. If lines merely create visual rhythm, replace them with rank index, spacing, subtle guides, or selected labels.
