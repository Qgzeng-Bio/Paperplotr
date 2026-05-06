# Template Selection Guide

Choose a template before writing code. Adapt the selected template rather than starting from a blank script.

| User task | Template | Input columns | Recommended geoms/helpers | PaperPlotR functions | Export preset |
|---|---|---|---|---|---|
| Single scatter, line, or simple bar plot | `templates/single-panel-template.R` | x, y, optional group | `geom_point()`, optional `geom_line()` or `geom_col()` | `theme_lab()`, `scale_color_lab()` | `nature_half` |
| Multi-panel manuscript figure | `templates/multi-panel-template.R` | panel-specific columns | Multiple ggplots plus `layout_lab()` | `theme_lab()`, `layout_lab()`, `save_lab()` | `nature` |
| Group comparison boxplot | `templates/comparison-boxplot-template.R` | group, value | `plot_box_paper()` if available, otherwise `geom_boxplot()` + jitter | `theme_lab()`, `scale_fill_lab()` or `scale_fill_groupmap()` | `cell_half` |
| Distribution comparison | `templates/violin-dot-template.R` | group, value, optional facet | `geom_violin()`, jitter, summary | `theme_lab()`, `scale_fill_lab()` | `cell_half` |
| Correlation or association scatter | `templates/correlation-scatter-template.R` | x, y, optional group | `geom_point()`, optional `geom_smooth()` | `theme_lab()`, `scale_color_lab()` | `nature_half` |
| Long-form heatmap | `templates/heatmap-template.R` | x, y, value | `geom_tile()` | `theme_lab()`, `lab_gradient_palette()` | `nature` |
| PCA or ordination scatter | `templates/pca-scatter-template.R` | PC1, PC2, optional group, optional label | `geom_point()`, optional `geom_text()` | `theme_lab()`, `scale_color_lab()` or `scale_color_groupmap()` | `nature_half` |
| Summary or grouped barplot | `templates/barplot-template.R` | category, value, optional group, optional error | `geom_col()`, optional `geom_errorbar()` | `theme_lab()`, `scale_fill_lab()` or `scale_fill_groupmap()` | `nature_half` |

## Selection Rules

- If the user asks for multiple panels, start with `multi-panel-template.R`.
- If the user asks for a manuscript-ready comparison of groups, start with `comparison-boxplot-template.R` or `violin-dot-template.R`.
- If stable group colors matter across panels, use `scale_*_groupmap()` with a user-provided named vector.
- If no semantic mapping is provided, use `scale_*_lab()` with a suitable generic palette.
- If the task is a diagram, graphical abstract, mechanism cartoon, or interactive visualization, do not use these templates.
