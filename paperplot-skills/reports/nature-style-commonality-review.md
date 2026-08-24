# Nature Style Commonality Review

This report summarizes reusable visual-detail principles learned from the R replica library. It abstracts shared design behavior and excludes source-code copying.

## Common High-Level Traits

- Manuscript-style examples keep titles small or absent; panel labels and captions carry the narrative.
- Axes and intervals are thin enough to remain secondary to data marks.
- Raw points, uncertainty intervals, or matrix cells carry the evidence; annotations remain compact.
- Legends are restrained, merged, moved outside repeated panels, or replaced by direct labels only when label burden stays low.
- Equal-role panels use comparable data-region sizes; unequal panels need an explicit evidence hierarchy.

## Detail Rules To Enforce

- Flag text/data overlap before judging color or aesthetics.
- Treat dense tick labels as a layout failure unless labels are the primary data.
- Treat default gray ggplot grids as suspect in group, violin, bar, and small-multiple figures.
- Allow grid/cell boundaries in heatmaps and tree/circular structures only through family-specific profiles.
- Compare old and new figures on detail regressions: panel size, data-region balance, grid burden, legend dominance, target-size typography, and scientific information preservation.

## What Remains Human-Reviewed

- Whether a label is scientifically necessary or should move to a sidecar.
- Whether a specialized circular/tree/network layout is justified by the data structure.
- Whether a cleaner redraw preserved the main scientific argument.
