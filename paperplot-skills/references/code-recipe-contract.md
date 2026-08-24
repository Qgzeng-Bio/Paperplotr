# Code Recipe Contract

Code recipes are the executable middle layer between the replica source archive
and production templates. They are not raw case scripts. A recipe must expose a
general input schema, render from mock or user data, and survive the same export
and QA expectations as a manuscript figure candidate.

## Required Fields

Every recipe entry must record:

- `recipe_id`: stable lowercase id.
- `figure_family`: pattern family used by the figure-type selector.
- `input_schema`: required and optional roles, not case-specific filenames.
- `source_evidence`: source case names or scripts that inspired the pattern.
- `core_layers`: important ggplot layers, stats, scales, facets, and layout logic.
- `dependencies`: required packages and optional backend packages.
- `default_size`: single-column, double-column, or explicit manuscript size.
- `qa_profile`: global QA plus family-specific QA rules.
- `template_status`: one of `production_recipe`, `template_candidate`,
  `benchmark_recipe`, `optional_backend_recipe`, `reference_recipe`,
  `specialized_reference`, or `caution_reference`.

## Execution Rules

- Recipes must be standalone and must not call `library(PaperPlotR)`,
  `theme_lab()`, `save_lab_plot()`, or any PaperPlotR R package API.
- Required dependencies should stay at base R + `ggplot2` unless the recipe is
  explicitly marked `optional_backend_recipe`, `reference_recipe`, or
  `specialized_reference`.
- Recipes must not depend on original local absolute paths. Provenance paths can
  appear only in metadata or documentation.
- Recipes must export PDF and PNG previews, notes, metadata, and QA sidecars when
  rendered through `scripts/render-code-recipes.R`.
- Recipes must state what scientific semantics are required before manuscript
  use: units, n, error type, test, threshold, normalization, or transform.

## Template Promotion Criteria

Promote a recipe to a production template only when:

- the input schema is compact and common enough for many users;
- the output remains readable at 89 mm or 180 mm target width;
- the plot can be validated with deterministic visual QA;
- optional dependencies have a clear fallback or are not required;
- the recipe improves a real user workflow rather than recreating one case.

Specialized families such as phylogenetic rings, circos, genome tracks, maps,
and networks may remain reference recipes until their data structures and
dependencies are explicit.

## Provenance Archive

Raw R/Rmd scripts copied into `provenance/r-replica-scripts/` are preserved to
retain source evidence and code-level inspiration. They are not guaranteed to be
portable. Use `reports/replica-code-pattern-index.md` to decide which scripts
can be abstracted and which are caution references.
