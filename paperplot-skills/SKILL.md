---
name: paperplot-skills
description: Use for data-backed scientific figures, R/ggplot2 plotting, manuscript figure projects, publication-size exports, scientific and visual QA, and old-vs-new comparisons.
---

# PaperPlot Skills

Create scientifically faithful figures with reproducible revisions. Standalone: never load PaperPlotR or call its APIs.

## Start here

1. For ordinary agent-led plotting, inspect the existing runtime/environment first and run explicitly in draft mode: `PAPERPLOT_MODE=preview scripts/paperplot-run <plot.R>`. Preview preserves journal-profiled dimensions, Arial roles, PDF + 300-dpi JPG output, data/glyph/file checks and provenance, but defers external visual QA, repair retries and export audit; it is an `interactive draft`, never manuscript-ready.
2. Only when the run reports a missing capability, use targeted environment diagnosis. Do not run an unconditional developer `doctor` or install packages; plotting never installs dependencies.
3. Read the selected journal profile, supplied data contract and executable recipe/template route. Read `references/color-and-style-policy.md` when choosing or revising style. Read `references/production-render-contract.md` only for finalization or export-logic changes, not on every ordinary draft.
4. Inspect supplied data, units, observation IDs, groups, intervals and upstream results. Do not scan unrelated private directories. An image alone permits diagnosis, not a claimed faithful reconstruction.
5. Select the recipe from `recipes/recipe_manifest.csv` and a template from `templates/template_manifest.csv`. Handler/variant/backend are executable routing. Resolve one `pp_render_spec()` before building and export through `pp_save_all_with_qa_loop()`.
6. For several plots, generate the set before presenting it for consolidated feedback; do not wait for per-plot approval or launch reviewer agents during ordinary iteration. Revise only the requested plots, and do not recompute statistics for purely cosmetic changes. Only when the user explicitly requests finalization (e.g. “定稿” or “正式导出”), rerun in production: `PAPERPLOT_MODE=production scripts/paperplot-run <plot.R>`. Do not keep polishing beyond the requested revision; show remaining issues. Preview is not an automatic project cache or promotion path.

## Interactive style defaults

- Use `wong` for generic categorical groups, keep mappings stable across panels, and stop at eight colors unless facets or an explicit alternative/named mapping is supplied.
- When useful, directly label a few key values or curve endpoints; never invent statistics and keep legends for dense panels rather than labeling every curve.
- Keep real observations in box/violin distributions. Heatmap `show_values="auto"` is conservative for small matrices; explicit required labels are not silently hidden.
- Give each figure one main message, preserve whitespace, and avoid decoration. Read the color/style policy only when the task needs a style decision.

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

Default deliveries are PDF and RGB JPG at 300 dpi (white background, JPEG quality 95); no SVG or PNG is generated for delivery or hidden export audit. JPG is lossy; PDF preserves precise vector text and lines. Explicit legacy `formats` can still request PNG/SVG/TIFF. Keep journal requirements distinct: flag stricter submission requirements rather than silently changing output, physical dimensions, fonts or scientific values.

Render spec is authoritative and journal-profiled (`journal="nature"` default, or `"cell"`; also `options(paperplot.journal=)` / `PAPERPLOT_JOURNAL`). Nature: single 89 mm, double 183 mm, max height 170 mm. Cell: single 85, 1.5-column 114, double 174 mm. IGS = profile double width × 105 mm; Manhattan = profile double width × 70 mm. Legacy dimensions must agree or fail. See `references/journal-profiles.md`.

Arial: ordinary roles stay inside the profile range (Nature 5–7 pt, Cell 6–8 pt; out-of-range overrides fail); final tags 8 pt bold, lowercase a/b/c for Nature, uppercase A/B/C for Cell. `pp_theme()` is pure. Normalize copies; native backends set fonts during drawing. Do not resize exports or blindly traverse raw grobs to change text.

Production/demo export retains each candidate and its QA, attempts at most two repairs, and keeps the previous candidate when no improvement is verified. Preview intentionally skips candidate copies, external visual QA/repair and export audit while retaining evidence/provenance; its unperformed checks remain `unverified`/`not_run`. Evidence includes source data, statistics, mappings, labels, file hashes and detector fingerprints.

- `fail`: precise error; no human override.
- `warn / interactive draft`: preview mode or deferred checks; never a final approval.
- `warn / manuscript candidate`: missing evidence, heuristic risk, incomplete environment or pending review.
- `pass / manuscript-ready`: every required check valid and an actual review bound to the exact evidence.

Inspect the exported image and located tasks. Raster/bbox heuristics do not prove full correctness. Record only reviews actually performed, with reviewer, reason and per-check evidence; never impersonate the user or invent human approval. Later rejection or changed data/export/detectors invalidates affected approval. Use effective status, not a cached historical pass.

## Delivery

Show the figure, key QA result, editable choices and output location. Keep detailed evidence in sidecars. Preserve originals; old-vs-new comparisons must preserve scientific meaning.

Engineering/demo/public cases do not replace private IGS and independent main-figure acceptance. 0.7 remains RC until all declared gates are completed.

Setup: `INSTALL.md`. Examples: `USAGE.md`. Developer acceptance: `references/release-acceptance.md`. Historical reports describe their own version only.
