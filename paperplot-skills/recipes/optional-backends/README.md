# Optional Backend Recipes

This directory is reserved for specialized scientific plot recipes whose
layout is not honestly handled by base ggplot2 alone.

Default skill behavior remains standalone. Optional backend recipes must:

- check packages with `requireNamespace()`;
- return a skip reason when packages are unavailable;
- expose a clean input schema;
- avoid local absolute paths;
- export PDF/PNG and sidecar metadata when executed;
- use family-specific QA instead of ordinary line-density thresholds.

Recommended backend families:

- `ComplexHeatmap`: complex heatmaps and annotation tracks.
- `circlize`: circos, chord, and circular genome summaries.
- `sf`: map and spatial figures.
- `ggtree`/`treeio`: phylogenetic trees and annotation rings.
- `igraph`/`ggraph`: networks.
- `ComplexUpset`/`UpSetR`: set intersection plots.

The first 9.0 implementation records these as policy and benchmark targets.
Promotion to executable optional recipes should happen only after a source case
has been cleaned, parameterized, and verified.
