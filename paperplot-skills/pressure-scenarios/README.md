# PaperPlot pressure scenarios

Pressure scenarios are regression checks for design decisions, not just template execution. A scenario passes only when the generated metadata/sidecars show the intended manuscript-design behavior.

Initial scenarios:

- `quinoa-genome-quality`: dense sample labels plus heterogeneous genome metrics must use rank index, selected labels, and label-key sidecar.
- `dense-sample-labels`: multi-metric figures must not dump all long sample names into visible axes.
- `volcano-selected-labels`: volcano plots must label only selected genes and record threshold semantics.
- `enrichment-top-terms`: enrichment plots must show selected top terms and record term filtering.
- `duplication-panel-hierarchy`: duplication-mode summaries must record panel hierarchy and mode semantics.
