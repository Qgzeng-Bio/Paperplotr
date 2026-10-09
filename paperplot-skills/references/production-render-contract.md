# Production render contract — 0.7 RC

## One physical specification

`pp_render_spec()` controls layout, label budget, normalization, export and metadata. Defaults follow the journal profile (Nature unless `journal`, `options(paperplot.journal)` or `PAPERPLOT_JOURNAL` says otherwise): Nature 89×62 mm single, 183×120 mm main, `case="igs"` 183×105 mm, `case="manhattan"` 183×70 mm; Cell 85×62 / 174×120 / 174×105 / 174×70 mm (`column="mid"` gives Cell 114 mm; Nature has no published 1.5-column width). Details in `journal-profiles.md`. An explicit exception belongs in the spec. Legacy width/height in cm must agree with it, otherwise fail.

Arial Regular/Bold/Italic; body/titles 7 pt, species/annotations 6.5 pt, ticks/legend/caption 6 pt, panel tags 8 pt bold (lowercase a/b/c for Nature, uppercase A/B/C for Cell). Ordinary text outside the profile range (Nature 5–7 pt, Cell 6–8 pt) and Cell strokes outside 0.5–1.5 pt fail at `pp_render_spec()`. Native vector backends apply these at rendering. `pp_theme()` has no global side effects. Normalization does not change original plots or scientific mappings. Network/tree layout coordinates do not acquire misleading numeric axes.

The isolated runtime and locks are described in ../INSTALL.md. A missing dependency or font cannot produce formal success. Default PDF remains vector and JPG is actual RGB JPEG at 300 dpi, white background, quality 95. JPG is lossy; PDF preserves precise text. No default SVG/PNG delivery or hidden SVG audit export. Explicit legacy formats remain available; an explicitly requested SVG references Arial without embedding it.

## Preview exception

`PAPERPLOT_MODE=preview` uses the same journal-profiled physical size, Arial role sizes and PDF + 300-dpi JPG export as production, and still performs data/glyph/file assertions plus provenance. It intentionally skips candidate-copy history, external visual QA/OCR, repair retries and export audit; those checks are recorded as `not_run`/`unverified`, and the tier is `interactive draft`. A preview review, including human review metadata, cannot change it to manuscript-ready; rerun in explicit production for final QA.

## Source evidence

Input contracts run before drawing. `_data_evidence.rds` preserves original/validated tables, parameters, statistics, coordinates, order, labels and trained encoding scales. Style retries compare evidence. Reversed colour meanings, altered axis units, dropped categories or changed intervals are scientific changes, not cosmetics.

`pp_igs_figure()` consumes original species/suffix/n/bin percentages/median/max, preserves row order and validates sums. Synthetic IGS tests do not accept the user's real figure.

## Candidate history and QA

`pp_save_all_with_qa_loop()` saves each candidate's requested exports (default PDF/JPG) and QA in iteration folders. At most two theme repairs; reject a candidate with no verified improvement and deliver the selected version. Overwrite explicitly archives prior QA; originals are not silently discarded.

Exact checks: declared `render_spec$export_formats` completeness (default PDF/JPG even when a file is missing), actual page size (0.1 mm), PDF typography (0.2 pt), embedded PDF fonts, required labels and exact tag case/count/bold, raster encoding, RGB mode, pixel dimensions, actual DPI metadata and source/file hashes. Missing requested files and precise PDF label/tag failures block approval and cannot be human-overridden. Legacy SVG editable text is checked only when requested.

PDF label checks establish exact text presence (including declared multi-line labels), not visibility. Without SVG, `pdf_text_visibility` remains `unverified` and requires an actual final-size check for clipping, bounds and overlap. Without a requested SVG, shared-row alignment, scientific-name italics, IGS marker dimensions and related stroke checks remain `unverified` with item-level review tasks; absent scientific requirements are `not_applicable` with reasons. PDF text extraction is not a geometry proof. Heuristics: raster density, estimated text boxes and ambiguous marks. These yield located review tasks, not proof of correctness. SVG ancestors, inherited styles and affine transforms are parsed; unsupported geometry/font/transform evidence remains unverified. Scientific interpretation and unsupported geometry need item-level inspection.

The required-check set is explicit. Empty/missing checks cannot pass. Non-applicable checks need an actual reason. Scores are diagnostic only.

## Valid review

Use `pp_effective_export_qa(stem)` or project status; they verify the current detector/config and files. Do not trust cached JSON pass alone.

`pp_review_export()` and `pp_project_review()` bind reviewer, reason and named check conclusions to the exact evidence hash and revision. They can resolve listed heuristic/unsupported-geometry/source-review items, never a precise failure. Only actual human review may satisfy the release human-review gate.

Final states: fail for a precise error; warn/manuscript candidate for missing, stale or unreviewed evidence; pass/manuscript-ready only for valid required checks and bound review. A panel's later rejection immediately invalidates overall approval.

Schema-1 approvals require migration and fresh validation. Detector-only changes expire QA, not cached data builds; changed scientific inputs need explicit scientific rebuilding.
