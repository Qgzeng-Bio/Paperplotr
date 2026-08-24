# Code Recipe Gallery Validation

Gallery: `paperplot-skills/reports/code-recipe-gallery`
Recipes expected: 84
Recipes with required outputs: 84/84

## Gallery Index

| Recipe | Family | Status | Outputs | Visual QA | Family QA | Score | Top risks |
|---|---|---|---|---|---|---|---|
| `grouped_bar_errorbar_raw` | grouped bar / errorbar | `production_recipe` | pass | warn | warn | 6 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, axis_title_collision_risk, significance_annotation_overcrowding |
| `stacked_bar_fraction` | stacked bar | `production_recipe` | pass | warn | warn | 6 | grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk |
| `boxplot_jitter` | boxplot / jitter | `production_recipe` | pass | warn | pass | 9 | low_grayscale_contrast, significance_annotation_overcrowding |
| `violin_dot` | violin / dot | `production_recipe` | pass | warn | pass | 8 | gridline_or_long_line_burden, tick_label_collision_risk, axis_title_collision_risk, grid_background_burden |
| `raincloud_violin_jitter` | raincloud | `production_recipe` | pass | warn | pass | 8 | gridline_or_long_line_burden, tick_label_collision_risk, axis_title_collision_risk, grid_background_burden |
| `paired_comparison` | paired comparison | `production_recipe` | pass | warn | pass | 10 | tick_label_collision_risk, axis_title_collision_risk |
| `scatter_regression` | scatter / regression | `production_recipe` | pass | pass | pass | 10 | no_major_deterministic_risk |
| `scatter_marginal_reference` | scatter / marginal | `production_recipe` | pass | warn | pass | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `correlation_heatmap` | heatmap | `production_recipe` | pass | warn | pass | 6 | grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk |
| `annotated_heatmap` | annotated heatmap | `template_candidate` | pass | warn | pass | 6 | label_overlap_or_large_annotation_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk |
| `matrix_dotplot` | matrix dotplot | `production_recipe` | pass | warn | pass | 9 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding, legend_dominates_panel |
| `pca_pcoa_ordination` | PCA / PCoA | `production_recipe` | pass | warn | pass | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `pcoa_marginal_box` | PCoA marginal | `production_recipe` | pass | warn | pass | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `volcano_threshold` | volcano | `production_recipe` | pass | warn | pass | 8 | low_content_density, low_grayscale_contrast, tick_label_collision_risk, significance_annotation_overcrowding |
| `ma_plot` | MA plot | `production_recipe` | pass | warn | pass | 9 | low_grayscale_contrast |
| `enrichment_dotplot` | enrichment | `production_recipe` | pass | warn | pass | 9 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding, legend_dominates_panel |
| `forest_effect_size` | forest / effect-size | `production_recipe` | pass | warn | pass | 10 | tick_label_collision_risk, significance_annotation_overcrowding |
| `model_validation_composite` | model validation | `template_candidate` | pass | warn | pass | 9 | low_grayscale_contrast, significance_annotation_overcrowding |
| `lollipop_ranked` | lollipop / ranked dot | `production_recipe` | pass | warn | pass | 10 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `dumbbell_comparison` | dumbbell | `production_recipe` | pass | warn | pass | 10 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `manhattan_genomewide` | Manhattan / genomewide | `production_recipe` | pass | warn | pass | 8 | grayscale_discrimination_risk, low_grayscale_contrast, tick_label_collision_risk |
| `ridgeline_density` | ridgeline / density | `production_recipe` | pass | warn | pass | 7 | gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `upset_summary` | upset / set | `production_recipe` | pass | warn | pass | 6 | grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, axis_title_collision_risk, stroke_too_heavy |
| `phylo_annotation_reference` | phylo / tree | `specialized_reference` | pass | warn | pass | 8 | low_content_density, low_grayscale_contrast |
| `circos_chord_sankey_reference` | circos / chord / sankey | `specialized_reference` | pass | warn | pass | 8 | excessive_blank_margin, low_grayscale_contrast, axis_title_collision_risk, significance_annotation_overcrowding |
| `bar_dot_errorbar_template` | grouped bar / errorbar | `production_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, text_data_overlap_risk, significance_annotation_overcrowding |
| `horizontal_errorbar_summary` | grouped bar / errorbar | `template_candidate` | pass | warn | missing | 6 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, stroke_too_heavy, grid_background_burden |
| `stacked_fraction_composition` | stacked bar | `production_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, axis_title_collision_risk |
| `diverging_composition_bar` | stacked bar | `benchmark_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, axis_title_collision_risk |
| `composition_bar_labels` | stacked bar | `template_candidate` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, axis_title_collision_risk |
| `box_jitter_facet` | boxplot / jitter | `production_recipe` | pass | warn | missing | 7 | grayscale_discrimination_risk, gridline_or_long_line_burden, significance_annotation_overcrowding, stroke_too_heavy, grid_background_burden |
| `beeswarm_box_reference` | boxplot / jitter | `reference_recipe` | pass | warn | missing | 7 | low_grayscale_contrast, gridline_or_long_line_burden, tick_label_collision_risk, axis_title_collision_risk, grid_background_burden |
| `violin_quantile_dot` | violin / dot | `production_recipe` | pass | warn | missing | 7 | low_grayscale_contrast, gridline_or_long_line_burden, tick_label_collision_risk, axis_title_collision_risk, grid_background_burden |
| `raincloud_facet` | raincloud | `template_candidate` | pass | warn | warn | 7 | grayscale_discrimination_risk, gridline_or_long_line_burden, significance_annotation_overcrowding, stroke_too_heavy, grid_background_burden |
| `ridge_facet_density` | ridgeline / density | `production_recipe` | pass | warn | missing | 7 | gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `histogram_density_overlay` | ridgeline / density | `benchmark_recipe` | pass | warn | missing | 7 | gridline_or_long_line_burden, thumbnail_readability_risk, axis_title_collision_risk, stroke_too_heavy, grid_background_burden |
| `labelled_scatter_regression` | scatter / regression | `production_recipe` | pass | pass | missing | 10 | no_major_deterministic_risk |
| `scatter_ci_ribbon` | scatter / regression | `template_candidate` | pass | pass | missing | 10 | no_major_deterministic_risk |
| `bubble_scatter_support` | scatter / regression | `production_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, axis_title_collision_risk |
| `marginal_rug_scatter` | scatter / marginal | `production_recipe` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `correlation_scatter_grid` | scatter / regression | `benchmark_recipe` | pass | warn | missing | 8 | grayscale_discrimination_risk, low_grayscale_contrast |
| `time_series_line` | time series | `production_recipe` | pass | warn | missing | 7 | low_content_density, grayscale_discrimination_risk, low_grayscale_contrast, axis_title_collision_risk, significance_annotation_overcrowding |
| `time_series_ribbon` | time series | `template_candidate` | pass | warn | missing | 7 | low_grayscale_contrast, gridline_or_long_line_burden, axis_title_collision_risk, significance_annotation_overcrowding, grid_background_burden |
| `pca_confidence_ellipse` | PCA / PCoA | `production_recipe` | pass | warn | missing | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `pcoa_permanova_annotation` | PCoA marginal | `template_candidate` | pass | warn | missing | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `nmds_stress_ordination` | NMDS ordination | `production_recipe` | pass | warn | missing | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `umap_cluster_scatter` | UMAP / embedding | `benchmark_recipe` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `tsne_cluster_scatter` | t-SNE / embedding | `benchmark_recipe` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `heatmap_cluster_reference` | heatmap | `template_candidate` | pass | warn | pass | 6 | grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk |
| `heatmap_annotation_bar` | annotated heatmap | `template_candidate` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk |
| `heatmap_cell_label` | heatmap | `production_recipe` | pass | warn | warn | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk |
| `correlation_triangle_heatmap` | heatmap | `benchmark_recipe` | pass | warn | warn | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk |
| `matrix_dotplot_two_scale` | matrix dotplot | `production_recipe` | pass | warn | missing | 9 | grayscale_discrimination_risk, tick_label_collision_risk, significance_annotation_overcrowding |
| `enrichment_lollipop` | enrichment | `production_recipe` | pass | warn | pass | 9 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding, legend_dominates_panel |
| `enrichment_bar_dot` | enrichment | `template_candidate` | pass | warn | fail | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, text_data_overlap_risk, significance_annotation_overcrowding |
| `gsea_running_score` | GSEA | `benchmark_recipe` | pass | warn | pass | 9 | low_content_density, tick_label_collision_risk, axis_title_collision_risk |
| `volcano_facet` | volcano | `template_candidate` | pass | warn | pass | 8 | low_content_density, low_grayscale_contrast, significance_annotation_overcrowding |
| `volcano_labelled` | volcano | `production_recipe` | pass | warn | pass | 8 | low_content_density, low_grayscale_contrast, tick_label_collision_risk, significance_annotation_overcrowding |
| `ma_density` | MA plot | `benchmark_recipe` | pass | warn | missing | 7 | gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `manhattan_faceted` | Manhattan / genomewide | `template_candidate` | pass | warn | missing | 9 | grayscale_discrimination_risk, tick_label_collision_risk |
| `regional_association_reference` | Manhattan / genomewide | `reference_recipe` | pass | warn | missing | 9 | low_content_density, tick_label_collision_risk, significance_annotation_overcrowding |
| `genome_track_reference` | genome track / synteny | `optional_backend_recipe` | pass | warn | missing | 8 | low_content_density, low_grayscale_contrast |
| `synteny_link_reference` | genome track / synteny | `optional_backend_recipe` | pass | warn | missing | 8 | low_content_density, low_grayscale_contrast |
| `forest_grouped_effect` | forest / effect-size | `production_recipe` | pass | warn | missing | 9 | grayscale_discrimination_risk, significance_annotation_overcrowding |
| `forest_subgroup_effect` | forest / effect-size | `template_candidate` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `model_residual_diagnostic` | model validation | `production_recipe` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `calibration_curve` | model validation | `template_candidate` | pass | warn | missing | 8 | low_content_density, grayscale_discrimination_risk, significance_annotation_overcrowding |
| `prediction_accuracy_heatmap` | model validation | `production_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk |
| `lollipop_grouped` | lollipop / ranked dot | `production_recipe` | pass | warn | missing | 10 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `dumbbell_delta` | dumbbell | `production_recipe` | pass | warn | pass | 10 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `ranking_labelled_lollipop` | lollipop / ranked dot | `template_candidate` | pass | warn | missing | 10 | tick_label_collision_risk, axis_title_collision_risk, significance_annotation_overcrowding |
| `upset_intersection_matrix` | upset / set | `optional_backend_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, tick_label_collision_risk |
| `set_size_bar_matrix` | upset / set | `reference_recipe` | pass | warn | missing | 5 | label_overlap_or_large_annotation_risk, grayscale_discrimination_risk, gridline_or_long_line_burden, thumbnail_readability_risk, stroke_too_heavy |
| `network_edge_list_reference` | network / sankey | `optional_backend_recipe` | pass | warn | missing | 8 | grayscale_discrimination_risk, low_grayscale_contrast, axis_title_collision_risk |
| `sankey_flow_reference` | network / sankey | `optional_backend_recipe` | pass | warn | missing | 8 | grayscale_discrimination_risk, low_grayscale_contrast, axis_title_collision_risk |
| `chord_adjacency_reference` | circos / chord / sankey | `optional_backend_recipe` | pass | warn | missing | 8 | grayscale_discrimination_risk, low_grayscale_contrast, axis_title_collision_risk |
| `circos_ring_reference` | circos / chord / sankey | `optional_backend_recipe` | pass | warn | missing | 8 | grayscale_discrimination_risk, low_grayscale_contrast, axis_title_collision_risk |
| `spatial_point_map_reference` | map / spatial | `optional_backend_recipe` | pass | warn | missing | 8 | label_overlap_or_large_annotation_risk, text_data_overlap_risk, significance_annotation_overcrowding |
| `spatial_tile_map_reference` | map / spatial | `reference_recipe` | pass | warn | missing | 8 | label_overlap_or_large_annotation_risk, text_data_overlap_risk, significance_annotation_overcrowding |
| `phylo_tree_segments_reference` | phylo / tree | `optional_backend_recipe` | pass | warn | missing | 8 | low_content_density, low_grayscale_contrast |
| `phylo_ring_annotation_reference` | phylo / tree | `optional_backend_recipe` | pass | warn | missing | 8 | low_content_density, low_grayscale_contrast |
| `multi_panel_shared_legend` | multi-panel manuscript | `template_candidate` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `inset_scatter_reference` | multi-panel manuscript | `reference_recipe` | pass | warn | missing | 10 | significance_annotation_overcrowding |
| `paired_line_facet` | paired comparison | `production_recipe` | pass | warn | missing | 8 | grayscale_discrimination_risk, text_data_overlap_risk, significance_annotation_overcrowding |

## Interpretation

- `production_recipe` and `template_candidate` outputs should be readable at target manuscript size.
- `specialized_reference` outputs are boundary examples; high line density is a caution, not automatic failure.
- Visual QA warnings are review triggers. They do not replace scientific metadata checks.
