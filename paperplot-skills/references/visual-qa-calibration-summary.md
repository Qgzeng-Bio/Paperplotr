# Visual QA Calibration Summary

Use this summary when interpreting deterministic rendered-image QA. The full
development calibration reports live in `reports/`, but runtime skill installs
only need the decision rules below.

## Core Interpretation

- Treat `warn` as a review trigger, not an automatic failure.
- Do not lower global thresholds just because a dense specialized figure warns.
- Use the selected figure family and pattern document before deciding whether a
  warning is expected structure or a real manuscript risk.
- Do not claim manuscript-ready status from deterministic image metrics alone.
  Human review is still required for scientific hierarchy, label meaning, and
  aesthetics.

## Family-Specific Notes

- Heatmaps, correlation matrices, and matrix dotplots can legitimately have
  dense tiles, structural grid burden, and moderate thumbnail risk. Check color
  scale semantics, unreadable cell labels, and annotation clarity.
- Manhattan and genome-wide plots can have dense point clouds and wide aspect
  ratios. Check chromosome labels, coordinate units, threshold lines, and
  highlighted loci.
- Phylogenetic trees with annotation rings can have high line burden. Check
  whether tips, clades, and rings remain decipherable at final export size.
- UpSet and set-matrix figures can be dense by design. Check set labels,
  intersection bars, and whether rare intersections should move to a sidecar.
- Lollipop, dumbbell, and rank dotplots can contain many stems. Check sample or
  feature label burden and whether full labels belong in the main panel.
- Model-validation panels can look sparse. Check metric units, interval
  semantics, calibration meaning, and whether the figure has enough evidence for
  the manuscript claim.

## Practical Rule

If a warning disappears only after applying a family threshold profile, record
why that structure is expected in notes or metadata. A family profile should
explain a legitimate figure form, not hide a real design problem.
