# Code Recipe Intelligence Upgrade Summary

## What Changed

- Raw R/Rmd scripts from the R replica library are archived in
  `provenance/r-replica-scripts/`.
- `scripts/index-replica-code-patterns.py` indexes source code structure:
  packages, readers, data file types, ggplot layers, aesthetics, output calls,
  inferred input roles, risks, and recipe suitability.
- `references/code-recipe-contract.md` defines the reusable recipe standard.
- `references/code-recipes/recipe-library.md` documents the v2 recipe system.
- `recipes/recipe_manifest.csv` and `recipes/paperplot_code_recipes.R` provide
  executable recipe metadata and plotting functions.
- `scripts/render-code-recipes.R` renders the recipe gallery.
- `scripts/validate-code-recipes.py` validates recipe outputs and writes
  `reports/code-recipe-gallery.md`.

## Scale

- R/Rmd scripts indexed: 142.
- R/Rmd provenance scripts archived: 142.
- Recipe manifest entries: 84.
- Production recipes: 42.
- Rendered benchmark recipe figures: 67.
- Production templates after upgrade: 35.
- New recipe-backed templates: raincloud, Manhattan, UpSet summary, PCoA
  marginal, annotated heatmap, lollipop-ranked, stacked fraction bar,
  bar-dot-errorbar, ridgeline density, labelled regression, matrix dotplot,
  time-series ribbon, network summary, and spatial distribution.
- Existing templates explicitly linked to recipe evidence: model-validation
  composite and effect-size forest.

## Validation Snapshot

- `index-replica-code-patterns.py`: indexed 142 scripts.
- `render-code-recipes.R`: renders the expanded recipe gallery from the 84-entry
  manifest.
- `validate-code-recipes.py`: validates PDF, PNG, notes, metadata, and QA
  sidecars for every rendered entry.
- `audit-replica-utilization.py`: maps 142/142 source scripts to explicit skill
  uses.
- `build-real-figure-benchmark.py`: builds 142 real benchmark cases and a
  30-case gold human rubric queue.
- `validate-skill.R`: passed.
- `smoke-test-templates.R`: 27/27 templates passed.
- `run-pressure-scenarios.R`: 5/5 scenarios passed.
- `run-visual-pressure-scenarios.py`: all visual pressure scenarios passed.

## Known Recipe QA Backlog

The gallery intentionally records visual/family QA warnings instead of hiding
them. Current high-priority refinements:

- grouped bar/errorbar and stacked bar: still show `warn` because raster QA
  treats bar boundaries and interval structure as long-line/grid burden. They
  no longer trigger text-data overlap as a hard blocker, but need a future
  bar-structure detector to separate true background grids from bar geometry.
- annotated heatmap: refined from family `fail` to family `pass` by reducing
  mock matrix density, using 12 cm target width, and suppressing cell borders.
- matrix dotplot: refined to family `pass` with a smaller matrix and compact
  legend guides.
- Manhattan: refined to family `pass` by increasing point density and shortening
  chromosome tick labels.
- UpSet and ridgeline: refined to family `pass`; remaining visual warnings are
  family-specific caution signals rather than blockers.

## Refinement Round 1

- Recipe mock data are now family-aware rather than one dense table reused by
  all figure families.
- `render-code-recipes.R` now passes target visual QA width from each recipe's
  declared manuscript width instead of assuming 89 mm for every gallery image.
- Heatmap-like recipes suppress unnecessary cell borders by default to avoid
  false grid burden.
- Set and density recipes use lighter structural marks to reduce stroke burden.
- Family QA scoring allows family-tolerated structural risks to be interpreted
  above the raw global raster score when no blocking risk is present.

## Practical Impact

The skill now has a code-learning layer: it can inspect the user's replica
scripts, understand the input schema and ggplot layer grammar behind common
Nature-like figures, select a reusable recipe, render a standardized candidate,
and subject that candidate to the same visual/family QA used by production
templates.

## 9.0 Upgrade Layer

- `references/plot-grammar-atoms.md` abstracts reusable plotting atoms from the
  full R replica archive.
- `references/optional-backend-policy.md` defines how ComplexHeatmap, circlize,
  sf, ggtree, ggraph, and UpSet backends can be used without becoming hard
  dependencies.
- `reports/full-replica-code-utilization-audit.md` ensures no indexed script is
  orphaned.
- `reports/real-figure-benchmark.md` tracks executable, specialized diagnostic,
  and caution benchmark cases.
- `reports/plotting-capability-9-scorecard.md` records the current 9.0
  readiness status and remaining risks.
