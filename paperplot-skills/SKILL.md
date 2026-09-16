---
name: paperplot-skills
description: Use for data-backed scientific figures, R/ggplot2 plotting, manuscript figure projects, publication-size exports, scientific and visual QA, and old-vs-new comparisons.
---

# PaperPlot Skills

Create scientifically faithful figures with reproducible revisions. Standalone: never load PaperPlotR or call its APIs.

## Start here

1. Run `scripts/paperplot-run`: diagnose the locked runtime, actual interpreters, dependencies and licensed Arial. Missing capabilities block formal work. Plotting never installs packages.
2. Read `references/code-recipe-contract.md` and `references/production-render-contract.md`, then only the relevant pattern-library document.
3. Inspect supplied data, units, observation IDs, groups, intervals and upstream results. Do not scan unrelated private directories. An image alone permits diagnosis, not a claimed faithful reconstruction.
4. Select the recipe from `recipes/recipe_manifest.csv` and a template from `templates/template_manifest.csv`. Handler/variant/backend are executable routing. Legacy status labels are historical classifications, not acceptance claims.
5. Resolve one `pp_render_spec()` before building. Export through `pp_save_all_with_qa_loop()`. Low-level save helpers are compatibility utilities, not acceptance gates.

## Main figures and revisions

Follow `references/figure-project-workflow.md`. Resume research-workspace `project.json` and recompute `pp_project_status()` before acting. Resolve ambiguous project/panel matches with the user.

Create a millimetre-labelled layout sketch and obtain user confirmation before building. Layout confirmation is not scientific or final approval. Changing order, spans or canvas requires renewed confirmation.

Each panel defines `build_panel(inputs, context)` and returns `list(plot, evidence, backend, dependencies)`. Supported objects: ggplot, patchwork and vector grid objects with backend adapters. Build at the allocated physical size; never assemble resized PNGs.

For “only change B”, preserve A/C/D scripts and data builds, revise B, then reassemble and measure the actual layout. Changed guide space may require affected rendering, not recomputation of unchanged analyses. Shared legends require identical meaning, categories, breaks, labels and colour mapping.

Schema 1 is read-only. Inspect `pp_project_migrate(project)` before an explicitly authorized backed-up migration. Migrated panels need one explicit scientific revalidation build; historical approvals are not current approvals.

## Scientific rules

- `pp_recipe_plot(recipe_id, df, params, mode)` requires real nonempty input. Simulation is available only through explicit `mode="demo"`; outputs remain labelled and cannot become manuscript-ready.
- Never invent PCA variance, NMDS stress, p-values, GSEA curves, trees, edges, intervals or genomic distances. Specialized analyses come from upstream.
- Raw summaries require independent-unit IDs, grouping and an explicit method. Supplied estimates/bounds are not re-averaged. Preserve forest subgroup keys and enrichment group identities.
- Validate supplied fractions/percentages unchanged. Convert counts only with explicit `input_scale="counts"` and record denominators. Negative compositions, incomplete pairs and duplicate keys stop execution.
- Common statistics are explicit mean/median/SD/SE/t intervals, lm, Pearson/Spearman, Welch/paired t and Wilcoxon. No default stars or guessed multiplicity correction.
- Mixed-method legacy IDs require a variant. Missing backends fail; never substitute a different chart.
- Never hide required labels with `check_overlap=TRUE`. Use collision-controlled labels; unresolved crowding remains a review item. Removing/abbreviating scientific labels needs explicit intent.

## Physical output and QA

Render spec is authoritative: single column 89 mm; main composite 180 mm; IGS 183 × 105 mm; Manhattan 180 × 70 mm. Legacy dimensions must agree or fail.

Arial: ordinary roles 6–8 pt, final tags 12 pt bold. `pp_theme()` is pure. Normalize copies; native backends set fonts during drawing. Do not resize exports or blindly traverse raw grobs to change text.

Export retains each candidate and its QA, attempts at most two repairs, and keeps the previous candidate when no improvement is verified. Evidence includes source data, statistics, mappings, labels, file hashes and detector fingerprints.

- `fail`: precise error; no human override.
- `warn / manuscript candidate`: missing evidence, heuristic risk, incomplete environment or pending review.
- `pass / manuscript-ready`: every required check valid and an actual review bound to the exact evidence.

Inspect the exported image and located tasks. Raster/bbox heuristics do not prove full correctness. Record only reviews actually performed, with reviewer, reason and per-check evidence; never impersonate the user or invent human approval. Later rejection or changed data/export/detectors invalidates affected approval. Use effective status, not a cached historical pass.

## Delivery

Show the figure, key QA result, editable choices and output location. Keep detailed evidence in sidecars. Preserve originals; old-vs-new comparisons must preserve scientific meaning.

Engineering/demo/public cases do not replace private IGS and independent main-figure acceptance. 0.7 remains RC until all declared gates are completed.

Setup: `INSTALL.md`. Examples: `USAGE.md`. Developer acceptance: `references/release-acceptance.md`. Historical reports describe their own version only.
