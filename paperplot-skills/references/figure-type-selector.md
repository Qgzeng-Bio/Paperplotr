# Figure Type Selector

Use this before selecting a template. The selector starts from data roles and scientific question, not from the user's preferred chart name. If a requested chart conflicts with the data structure, explain the mismatch and choose the safer family.

## Data Role Detection

Inspect column names, values, and metadata for these roles:

- `sample`: unique specimen, accession, patient, line, replicate, assembly, or observation ID.
- `group`: treatment, genotype, tissue, cohort, condition, batch, site, or class.
- `metric`: repeated measured variable, trait, assay, score, statistic, or feature class.
- `value`: numeric measurement with one unit and one direction.
- `feature`: gene, transcript, protein, OTU, variant, locus, pathway, or term.
- `coordinate`: genomic position, chromosome, contig, latitude/longitude, spatial coordinate, or ordination axis.
- `network`: source, target, edge, weight, flow, membership, or interaction.
- `tree`: Newick/tree file, branch length, tip ID, clade, or tip-level annotation.
- `uncertainty`: SD, SE, CI, IQR, range, bootstrap, posterior interval.
- `statistic`: p-value, adjusted p-value, effect size, enrichment ratio, correlation, R2, PERMANOVA, residual.

If roles cannot be detected, profile the data and ask for the minimum missing field: units, denominator, paired ID, coordinate system, tree/link schema, statistical test, or normalization.

## Family Selection Rules

| data/question signal | preferred family | pattern doc |
|---|---|---|
| categorical groups + numeric value + uncertainty | grouped bar/errorbar or dot/box | `pattern-library/grouped-bar-errorbar.md` |
| group distributions with raw samples | violin/raincloud/jitter | `pattern-library/raincloud-violin-jitter.md` |
| numeric x + numeric y relationship | scatter/regression/marginal | `pattern-library/scatter-regression-marginal.md` |
| matrix values or correlations | heatmap/correlation matrix | `pattern-library/correlation-heatmap.md` |
| ordination coordinates from multivariate data | PCA/PCoA/NMDS/UMAP | `pattern-library/pca-pcoa-ordination.md` |
| feature-level effect + p-value | volcano/MA/enrichment | `pattern-library/volcano-ma-enrichment.md` |
| ordered genome/locus coordinate + score | Manhattan/genome-wide | `pattern-library/manhattan-genomewide.md` |
| tree topology + tip metadata | phylo annotation rings | `pattern-library/phylo-annotation-ring.md` |
| set membership across multiple sets | UpSet/set plot | `pattern-library/upset-set-plot.md` |
| source-target-weight links or flows | chord/circos/Sankey/network | `pattern-library/circos-chord-sankey.md` |
| multiple panels forming one argument | multi-panel layout | `pattern-library/multi-panel-manuscript-layout.md` |
| observed vs predicted, residuals, model metrics | model validation | `pattern-library/model-validation-figures.md` |

## Alternatives By Problem Shape

- Small n group comparison: raw dot + interval, not summary bars alone.
- Medium n distribution: violin/box/jitter or raincloud.
- Large n distribution: density/ridgeline or summarized quantiles, with n and binning stated.
- Many groups: facet, rank top groups, or supplement; do not compress all labels into one main panel.
- Many metrics with mixed units: small multiples or rank-plus-key metrics; do not use one y-axis.
- Paired data: paired plot with `paired_id`; never connect lines without pairing semantics.
- Feature-level differential data: volcano/MA; enrichment terms should be a separate panel/table.
- Model validation: observed-vs-predicted plus residual/metric panel, not R2-only scatter.

## Not Recommended Conditions

- Bar-only display for small n or skewed distribution.
- Violin for tiny groups where density shape is fabricated.
- Heatmap for exact heterogeneous values when users need readable units.
- Radar/polar/circular bars unless circular structure is scientifically meaningful.
- Dual y-axis when variables have different units and no direct relationship.
- Dense direct labels in main figures; use rank index, top labels, or sidecars.
- Significance stars as the primary statistical message.

## Main Figure / Supplement / Diagnostic Strategy

- Main figure: one clear message, controlled label count, top groups/features only, minimal repeated legends.
- Supplement: full label sets, expanded intersections, full heatmaps, alternate thresholds, and complete diagnostics.
- Diagnostic: can be dense or technical, but must not be labeled manuscript-ready without redesign.

## Dense Labels And Large Tables

- More than 12 category labels: consider ranking, faceting, abbreviations, or sidecar key.
- More than 40 heatmap labels: cluster/order and show only high-priority labels in main figure.
- More than 8 color classes: group into biologically meaningful superclasses or move to supplement.
- Long terms/pathways: wrap in a side table or use numbered labels with a key.

## Specialized Plot Boundaries

- Circos/chord/Sankey requires `source`, `target`, `weight`, and grouping/order. Without these, do not fake links.
- Synteny/genome tracks require coordinate intervals, genome order, and feature orientation. Without coordinates, use summary plots only.
- Phylogenetic trees require a tree file plus metadata keyed by tip IDs. Without a tree, use grouped summaries.
- Networks require nodes, edges, and edge weights/types. Without an edge table, use matrix or bar summaries.
- Maps require geographic/spatial coordinates and projection/shape data. Without coordinates, use group/location summaries.

## Final Selection Output

Before plotting, write a short selection record in notes/metadata:

- detected data roles;
- selected figure family;
- pattern-library document consulted;
- rejected alternatives and why;
- main/supplement/diagnostic tier;
- required sidecars or metadata.
