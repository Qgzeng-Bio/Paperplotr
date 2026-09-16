# Production render contract — 0.7 RC

## One physical specification

`pp_render_spec()` controls layout, label budget, normalization, export and metadata. Defaults: 89×62 mm single; 180×120 mm main; `case="igs"` 183×105 mm; `case="manhattan"` 180×70 mm. An explicit exception belongs in the spec. Legacy width/height in cm must agree with it, otherwise fail.

Arial Regular/Bold/Italic; body/titles 7 pt, species/annotations 6.5 pt, ticks/legend/caption 6 pt, panel tags 12 pt bold. Native vector backends apply these at rendering. `pp_theme()` has no global side effects. Normalization does not change original plots or scientific mappings. Network/tree layout coordinates do not acquire misleading numeric axes.

The isolated runtime and locks are described in ../INSTALL.md. A missing dependency or font cannot produce formal success. PDF/SVG stay vector; PNG is 600 dpi. SVG editable text references Arial but does not embed the font.

## Source evidence

Input contracts run before drawing. `_data_evidence.rds` preserves original/validated tables, parameters, statistics, coordinates, order, labels and trained encoding scales. Style retries compare evidence. Reversed colour meanings, altered axis units, dropped categories or changed intervals are scientific changes, not cosmetics.

`pp_igs_figure()` consumes original species/suffix/n/bin percentages/median/max, preserves row order and validates sums. Synthetic IGS tests do not accept the user's real figure.

## Candidate history and QA

`pp_save_all_with_qa_loop()` saves each candidate's PDF/SVG/PNG and QA in iteration folders. At most two theme repairs; reject a candidate with no verified improvement and deliver the selected version. Overwrite explicitly archives prior QA; originals are not silently discarded.

Exact checks: actual page size (0.1 mm), typography (0.2 pt), embedded PDF fonts, editable SVG text, tags, pixel dimensions and source/file hashes. Failures block approval.

Heuristics: raster density, estimated text boxes and ambiguous marks. These yield located review tasks, not proof of correctness. SVG ancestors, inherited styles and affine transforms are parsed; unsupported geometry/font/transform evidence remains unverified. Scientific interpretation and unsupported geometry need item-level inspection.

The required-check set is explicit. Empty/missing checks cannot pass. Non-applicable checks need an actual reason. Scores are diagnostic only.

## Valid review

Use `pp_effective_export_qa(stem)` or project status; they verify the current detector/config and files. Do not trust cached JSON pass alone.

`pp_review_export()` and `pp_project_review()` bind reviewer, reason and named check conclusions to the exact evidence hash and revision. They can resolve listed heuristic/unsupported-geometry/source-review items, never a precise failure. Only actual human review may satisfy the release human-review gate.

Final states: fail for a precise error; warn/manuscript candidate for missing, stale or unreviewed evidence; pass/manuscript-ready only for valid required checks and bound review. A panel's later rejection immediately invalidates overall approval.

Schema-1 approvals require migration and fresh validation. Detector-only changes expire QA, not cached data builds; changed scientific inputs need explicit scientific rebuilding.
