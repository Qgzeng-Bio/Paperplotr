# Executable recipe and scientific input contract (0.7 RC)

`pp_recipe_plot(recipe_id, df, params=list(), mode="production")` preserves every stable ID. A nonempty table is mandatory. Manifest handler/variant/backend replace name heuristics. Both direct handlers and the public entry validate input; production never synthesizes missing data.

Required/optional columns come from recipes/recipe_manifest.csv. Numeric measurements must already be numeric and finite; probabilities are in [0,1], counts/errors/weights nonnegative, genomic coordinates nonnegative integers with start≤end, and set membership binary. No coercion, absolute-value conversion or silent row removal. Missing values require explicit `na_action="omit"`; only matrix values may use `"keep"`. Identifiers cannot be missing. Optional group/category means one group called All.

## Conditional parameters and keys

| Handler | Contract |
|---|---|
| bar | `data_kind="raw"`: explicit summary, unit_id and error_type; raw units unique within category+group. Summary: preserve estimate/lower/upper/n/error type; value+error requires explicit error_type. |
| composition | Unique group+category. `input_scale="fraction"/"percent"` validates totals 1/100 unchanged; counts explicitly divided by their recorded within-group denominator; signed values only in diverging variant. |
| paired / dumbbell | Unique sample/category+group, complete matching IDs, explicit condition order when scientifically meaningful. Dumbbell requires exactly two groups, not the first two found. |
| distribution | Actual observations, bandwidth in params if prescribed. Histogram requires binwidth. Density needs adequate nonconstant data; no pseudo-observations. |
| scatter | lm/CI only with `fit="lm"`, or supplied lower/upper for ribbon. Coordinates retain their units; optional x_label/y_label declare them. |
| matrix | Unique metric+category+group. Missing cells remain NA. Different groups must remain separate. Correlation values must be provided, not inferred from unrelated labels. |
| complex_heatmap | Unique cells; row/column annotations match axis IDs. Cluster variant requires explicit distance+linkage, or both upstream dendrograms. value_limits/value_label describe the actual scale. |
| ordination | Upstream pc1/pc2 coordinates. Mixed `pca_pcoa_ordination` requires variant pca/pcoa. Optional variance_percent, stress, permanova_p are supplied; conflicting column/parameter results fail. Ellipse level must be explicit. |
| differential | Actual log2fc/padj/base_mean. Explicit alpha and effect_threshold. Zero probabilities require declared p_display_floor for display only. |
| enrichment | Unique term+group+category; supplied ratio/qvalue/count preserved. Optional top_n is recorded selection, never averaging q-values. |
| GSEA | Unique rank+pathway, actual running_score and optional hit markers. No inferred NES/p-value or random curve. |
| forest | Unique metric+group+subgroup; supplied lower≤estimate≤upper. No raw aggregation. interval_label must match the actual interval meaning. |
| timeseries | Unique time+group. Supplied errors retained; distinguish error type in labels/metadata. |
| model | Observed/predicted/residual must agree. Composite needs an actual performance table. Calibration requires explicit bins, data_kind and unit_id for raw probabilities; probabilities in [0,1]. Training metrics are not validation evidence. |
| rank | Unique category+group; provided order must include every category. |
| genome | Real bp. Manhattan requires threshold; supplied chromosome_lengths or explicitly recorded observed maxima set offsets. Synteny needs target chromosome/start/end; strand and target_strand are +/- and preserve orientation. |
| sets | Unique item+set, present=0/1. Compute actual set sizes/intersections. |
| network | Real source/target/weight, explicit logical directed. Optional node table has unique name IDs. Layout is not biological distance. |
| flow | Real nonnegative weights. Mixed legacy reference requires variant sankey/chord; chord requires directed. Two-stage stage_order may name axes. Multi-stage Sankey requires flow_id, source stage and stage_order; each full trajectory has constant weight and matching intermediate nodes. Split flows need separately identified trajectories. |
| circos | Real chr/start/end/value, named chromosome_lengths bounding every interval. Positions remain bp; sector labels and axis units are drawn. |
| spatial | Explicit CRS. Polygon values join unique region IDs to valid sf geometry with the same CRS; unmatched keys/conflicts fail. Point coordinates are interpreted only under that CRS. |
| tree | Supplied phylo or a connected node/parent tree; one root, no cycles, valid branch lengths. No tree inference. Annotations must match actual tips. |
| layout | Supplied coordinates with identical guide semantics; inset bounds explicit. Main figures still require confirmed project layouts. |

Multiple explicit `panel` IDs must be built separately in a figure project, not collapsed into a single recipe panel. Recipe-specific facets such as metric/pathway/group remain supported.

## Explicit common statistics

`pp_summary_statistics`: mean/median, SD/SE or mean t CI, explicit independent unit and grouping. Median uncertainty comes from upstream rather than misusing mean intervals.

`pp_statistical_test`: Welch t, paired t, Wilcoxon/paired Wilcoxon, Pearson/Spearman or lm. Specify paired IDs, groups, confidence level and NA handling. `pp_adjust_pvalues` requires an explicit correction method. No significance stars are added.

Paired `n` is the number of independent pairs, not twice that number. Raw row count, per-group counts and test degrees of freedom are retained separately. `exact=NULL` follows the standard R policy; explicit exactness overrides, warnings and the actual confidence level are recorded. An unavailable confidence band is not silently omitted from a requested fit.

`params$statistical_result` accepts an upstream result with method and n. If recomputation is also explicitly requested in params$statistics, conflicts stop the call. Results are preserved in evidence and an export statistics JSON; raw/summarized tables remain auditable.

## Demo and compatibility

`pp_recipe_mock_data()` is a labelled test fixture constructor, never a default input. Use only `mode="demo"`; it cannot certify a manuscript. Native grid outputs receive the same demo marker.

Old scripts relying on missing statistics, implicit averaging, numeric coercion or approximate specialized diagrams now stop with migration guidance. Historical manifest status strings describe origin; the handler/backend columns and current test results describe implementation. No missing backend may silently fall back to another chart.

Raw third-party source archives are inspiration/provenance, not runtime inputs or redistributable fixtures.
