# Bioinformatics Figure Validation

Rendered-image QA cannot prove that a genomics or omics figure represents the
right records. Apply this contract before describing a bioinformatics figure as
manuscript-ready.

## Required provenance

Record:

- input data path(s), checksums or stable version identifiers when available;
- sample and group identifiers, sample order, exclusions, and replicate policy;
- organism, assembly/reference build, annotation release, and database versions;
- coordinate convention (`0-based half-open` or `1-based closed`) and chromosome
  naming policy;
- units, denominator, normalization, transform, aggregation, and missing-value
  handling;
- statistical test, multiple-testing correction, uncertainty definition, and
  sample size where applicable;
- plotting-code path, parameters, output preset, journal profile, and generated
  sidecars.

Missing provenance is a manuscript-readiness blocker when it changes the meaning
of the visible axes, colors, intervals, or comparisons. Bioinformatics templates
declare `analysis_domain = "bioinformatics"`, write a stem-matched
`*_plotting_data.tsv`, and initialize `pp_bioinformatics_scaffold()` with status
`not_recorded`. The scaffold is evidence routing, not scientific approval.

Change it to `pp_bioinformatics_validation(status = "pass", ...)` only after:

- every input and plotting-data path is a readable file;
- the helper records path, size, and MD5 for every file;
- `coordinate_system` uses a supported enum (`0-based_half-open`,
  `1-based_closed`, `not_applicable_gene_level`,
  `not_applicable_nonpositional`, or `mixed_documented`);
- the plotting table is the exact stem-matched TSV used for the figure;
- `source_records_checked`, `sample_order_checked`, `units_checked`,
  `statistics_checked`, and `plotting_data_checked` are all explicitly true.

`--manuscript-ready` rejects placeholder text, missing/stale files, checksum
mismatch, incomplete evidence flags, or a plotting table that is not stem
matched.

## Data-to-image gates

1. Confirm plotted row counts and identifiers against the source TSV/BED/GFF/VCF
   or analysis output rather than only reading labels from the image.
2. Confirm explicit sample/category order; never accept accidental alphabetic or
   file-system order as biological order.
3. Confirm that units and transformations in `metric_spec` match the actual data.
4. Confirm that filters and highlighted subsets reproduce the documented rule.
5. Confirm that labels, intervals, and chromosome positions remain within the
   declared reference and coordinate convention.
6. Save the exact plotting table as a tab-separated, stem-matched
   `*_plotting_data.tsv` next to code, metadata, notes, QA, PDF, and PNG.

## Family-specific checks

### Genomic tracks, centromeres, and chromosome features

- Validate BED/GFF interval bounds, strand when meaningful, chromosome naming,
  and reference length compatibility.
- State smoothing/window/bin size and whether tracks are counts, coverage,
  enrichment, ratios, or transformed scores.
- Check that track alignment is data-based, not approximate image alignment.

### Synteny and structural variants

- Record query/reference direction and both assembly versions.
- Distinguish chromosome order/orientation edits from detected rearrangements.
- Verify breakpoint/interval labels against the normalized source calls.
- Do not infer biological rearrangements from line crossings caused by layout.

### Variant, GWAS, and Manhattan figures

- State variant filters, allele-frequency/sample denominators, ploidy/model, and
  significance threshold derivation.
- Validate chromosome offsets and cumulative positions.
- Separate genome-wide thresholds, suggestive thresholds, and selected labels.

### RNA-seq and enrichment

- State normalized values versus raw counts, contrast direction, effect-size
  definition, adjusted-p method, and label-selection rule.
- For enrichment, state ontology/database release, tested background universe,
  gene-set size, ratio denominator, and correction method.

### Assembly and genome-quality metrics

- Keep heterogeneous metrics in their native units unless an explicit
  transformation is scientifically justified.
- Record whether higher or lower is better and preserve metric-specific
  denominators.
- Treat rankings and key-sample selections as sidecar-backed display choices,
  not biological evidence by themselves.

### Heatmaps, trees, and pangenomes

- State transformation/scaling direction and whether clustering is by rows,
  columns, both, or neither.
- Preserve tree-tip, matrix-row, sample, and annotation alignment.
- Report any subset selection and the universe from which it was selected.

## Claim boundary

Separate:

- **Observation**: directly visible and traceable to validated plotting data.
- **Interpretation**: a supported reading of that observation.
- **Hypothesis**: biologically plausible but requiring further evidence.
- **Limitation**: missing provenance, unresolved mapping, model assumptions, or
  visualization uncertainty.

A visually clean figure does not validate the upstream analysis. State what the
figure supports and what remains a visual or biological hypothesis.

## Bioflow interoperability

This reference is standalone and ships with PaperPlot. When the `bioflow` skill
is available in a Bioflow-managed project, also apply its relevant project
acceptance and claim rules. Do not hardcode a relative dependency on a
`bio-workflow/` checkout, and do not claim Bioflow QA when that skill was not
actually loaded or its evidence was not checked.
