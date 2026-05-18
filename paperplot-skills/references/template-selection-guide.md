# Template Selection Guide

Choose a template before writing code. Adapt the selected template rather than starting from a blank script. For broader rules, read `figure-type-selector.md`.

| User task | Template | Input columns | Default layout |
|---|---|---|---|
| Single scatter, line, or simple point plot | `templates/single-panel-template.R` | x, y, optional group | one panel |
| Multi-panel manuscript figure | `templates/multi-panel-template.R` | x, y, panel, optional group | faceted panels |
| Group comparison boxplot | `templates/comparison-boxplot-template.R` | group, value | one comparison panel |
| Distribution comparison | `templates/violin-dot-template.R` | group, value | violin plus dots |
| Correlation scatter | `templates/correlation-scatter-template.R` | x, y, optional group | scatter plus trend |
| Long-form heatmap | `templates/heatmap-template.R` | x, y, value | tile heatmap |
| PCA or ordination scatter | `templates/pca-scatter-template.R` | PC1, PC2, optional group | ordination scatter |
| Summary barplot | `templates/barplot-template.R` | category, value, optional group/error | grouped or simple bars |
| 5-8 heterogeneous metrics | `templates/multi-metric-small-multiples-template.R` | sample, metric, value, unit | 2x3 or 2x4 facets |
| Ranked samples plus key metrics | `templates/rank-plus-key-metrics-template.R` | sample, score, metric, value | rank view plus facets |
| Four-panel manuscript figure | `templates/manuscript-four-panel-template.R` | x, y, panel, optional group | 2x2 manuscript grid |

## Contract Rules

- Every template must define `figure_spec` before reading or plotting data.
- Every template must define `metric_spec`; multi-metric templates must define one row per metric.
- Every template must run `pp_label_strategy()` for dense sample/category axes.
- Every template must write PDF, PNG, notes, metadata JSON, and QA report.
- Every template must refuse overwrites.

## Selection Rules

- If stable group colors matter, use a named color vector or `pp_group_colors()`.
- If no semantic mapping is provided, use `pp_scale_color()` or `pp_scale_fill()` with `graphpad_discrete`.
- Prefer small multiples when metrics have different units and original values matter.
- Use heatmaps only when normalized relative patterns are the main message.
- Use rank-plus-key-metrics when a main figure would otherwise include too many metrics.
- If the task is conceptual drawing rather than plotting data, do not use this skill.
