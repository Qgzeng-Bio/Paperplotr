# Backend policy

The full locked runtime includes the backends in recipes/recipe_manifest.csv. “Optional” describes a reduced development environment, not permission to substitute a production chart.

ComplexHeatmap, ComplexUpset, ape/treeio/ggtree, igraph/ggraph, ggalluvial, circlize, sf and distribution/layout packages are actual implementations. Missing dependencies fail explicitly; no simulated diagram or raster fallback.

Native backends draw at allocated physical dimensions into vector grid objects and apply render-spec fonts internally. Wrapped objects do not inherit internal text changes from outer themes; see [wrap_elements](https://patchwork.data-imaginist.com/reference/wrap_elements.html).

Setup lives in ../INSTALL.md. Historical manifest status classifications do not override current handler/backend routing.
