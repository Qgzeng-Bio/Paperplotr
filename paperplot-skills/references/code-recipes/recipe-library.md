# PaperPlot Code Recipe Library v2

This library translates recurring code structures from the R replica archive
into reusable plotting recipes. Each recipe is executable through
`scripts/render-code-recipes.R` and documented here as a general plotting
pattern, not a one-case reproduction.

The 9.0 upgrade expands the executable manifest from 25 recipes to 84 recipe,
benchmark, optional-backend, and reference entries. The authoritative machine
manifest is `recipes/recipe_manifest.csv`; this document explains how those
entries should be used.

## Recipe Entries

| Recipe id | Figure family | Required roles | Core layers | QA focus | Status |
|---|---|---|---|---|---|
| `grouped_bar_errorbar_raw` | grouped bar / errorbar | group, category, value, error | `geom_col`, `geom_errorbar`, raw `geom_point` | bar width, interval meaning, raw point visibility | template candidate |
| `stacked_bar_fraction` | stacked bar | group, category, value | `geom_col(position="fill")` | denominator, percent axis, restrained palette | production recipe |
| `boxplot_jitter` | boxplot / jitter | group, value | `geom_boxplot`, `geom_jitter` | small-n raw points, no heavy grid | production recipe |
| `violin_dot` | violin / dot | group, value | `geom_violin`, `geom_boxplot`, `geom_jitter` | distribution vs raw points, label burden | template candidate |
| `raincloud_violin_jitter` | raincloud | group, value | violin, interval, jitter | density readability, point overlap, panel padding | template candidate |
| `paired_comparison` | paired comparison | sample, group, value | connecting `geom_line`, `geom_point` | paired id required, order semantics | production recipe |
| `scatter_regression` | scatter / regression | x, y, group | `geom_point`, `geom_smooth(method="lm")` | fit line visibility, axis units, light grid allowed | template candidate |
| `scatter_marginal_reference` | scatter / marginal | x, y, group | `geom_point`, rugs, density cues | marginal cue does not dominate scatter | production recipe |
| `correlation_heatmap` | heatmap | metric, category, value | `geom_tile`, continuous scale | colorbar, row/column label burden | template candidate |
| `annotated_heatmap` | annotated heatmap | metric, category, value, group | `geom_tile`, annotation strip | annotation strip size, cell border discipline | template candidate |
| `matrix_dotplot` | matrix dotplot | metric, category, value, count | `geom_point(size, color)` | dual encoding clarity, legend burden | production recipe |
| `pca_pcoa_ordination` | PCA / PCoA | pc1, pc2, group | `geom_point`, reference axes | variance labels, legend/data cloud balance | template candidate |
| `pcoa_marginal_box` | PCoA marginal | pc1, pc2, group | ordination plus marginal distribution cues | equal panel rhythm, no oversized marginal | template candidate |
| `volcano_threshold` | volcano | feature, log2fc, padj | `geom_point`, threshold lines, selected labels | threshold semantics, label collision | production recipe |
| `ma_plot` | MA plot | feature, base_mean, log2fc, padj | log axis, threshold lines | transform visibility, muted background | production recipe |
| `enrichment_dotplot` | enrichment | term, ratio, qvalue, count | dot size + color | term label burden, q-value scale | template candidate |
| `forest_effect_size` | forest / effect-size | metric, estimate, lower, upper | reference line, interval, point | CI method, zero/reference line | template candidate |
| `model_validation_composite` | model validation | x, y, group | observed-vs-predicted, residuals, summary | residual semantics, equal panel sizes | template candidate |
| `lollipop_ranked` | lollipop / ranked dot | category, value | `geom_segment`, `geom_point` | ordering, label readability, grid rejection | template candidate |
| `dumbbell_comparison` | dumbbell | category, group, value | paired endpoints and segment | two-group clarity, label alignment | production recipe |
| `manhattan_genomewide` | Manhattan | chr, position, pvalue | dense points, threshold line | chromosome labels, threshold semantics | template candidate |
| `ridgeline_density` | ridgeline / density | group, value | density facets | overlap, scale comparability | production recipe |
| `upset_summary` | upset / set | item, set, present | set-size bars + matrix | set labels, matrix/bar linkage | template candidate |
| `phylo_annotation_reference` | phylo / tree | node, parent, group | segment tree + annotation strip | specialized caution, line density allowed | specialized reference |
| `circos_chord_sankey_reference` | circos / chord / sankey | source, target, value | flow segments, grouped endpoints | specialized caution, dependency boundary | specialized reference |

## Shared Input Role Vocabulary

Use these role names when translating user data into a recipe:

- Identity: `sample`, `feature`, `item`, `node`, `source`, `target`.
- Grouping: `group`, `category`, `set`, `panel`, `chr`.
- Measures: `value`, `x`, `y`, `pc1`, `pc2`, `estimate`, `lower`, `upper`,
  `log2fc`, `base_mean`, `pvalue`, `padj`, `qvalue`, `ratio`, `count`.
- Semantics: `unit`, `threshold`, `normalization`, `transform`, `error_type`,
  `test`, `n`.

## 9.0 Expansion Families

The expanded manifest covers these additional recipe groups:

- Bar/composition: raw-point errorbar, horizontal interval summaries, stacked
  fractions, diverging composition, and label-burden variants.
- Distribution: faceted box/jitter, violin quantile dot, raincloud facets,
  ridgeline/density, and histogram-density overlays.
- Scatter/line: labelled regression, CI ribbon, bubble scatter, marginal rugs,
  correlation scatter grids, time-series lines, and ribbons.
- Ordination/embedding: PCA/PCoA ellipses, PERMANOVA annotation, NMDS stress,
  UMAP, and t-SNE.
- Matrix: cluster-like heatmap references, annotation bars, cell-labelled
  heatmaps, triangular correlation heatmaps, and two-scale matrix dotplots.
- Omics/genomics: enrichment lollipop/bar-dot, GSEA running score, faceted and
  labelled volcano plots, MA variants, Manhattan facets, regional association,
  genome track, and synteny references.
- Comparison/modeling: grouped/subgroup forest plots, model residuals,
  calibration curves, prediction heatmaps, grouped lollipops, dumbbells, and
  ranked lollipop labels.
- Specialized references: UpSet, set matrix, network, Sankey, chord, circos,
  spatial map, phylo tree, phylo ring annotation, shared-legend multi-panel,
  inset, and paired-line facets.

These entries are intentionally tiered:

- `production_recipe`: safe default recipe for data-backed plotting.
- `template_candidate`: stable enough to drive a production template after
  additional smoke-test promotion.
- `benchmark_recipe`: used to test family coverage and QA behavior.
- `optional_backend_recipe`: requires specialized backend policy before a
  faithful manuscript implementation.
- `reference_recipe`: design/code structure reference, not a default execution
  path for user data.

## How The Skill Should Use Recipes

1. Detect data roles and figure family.
2. Select a pattern-library document.
3. Query this recipe library for matching input roles.
4. If the recipe is `template_candidate` or `production_recipe`, generate a
   data-backed plot and run visual QA.
5. If the recipe is `optional_backend_recipe`, `reference_recipe`, or
   `specialized_reference`, report required data structures and optional
   dependencies before attempting a faithful rendering.
6. Promote only stable, general recipes into `templates/`; do not turn every
   source script into a template.
