# Production render contract (standalone 0.5.0)

## Start with the final canvas

`pp_render_spec()` is the production authority. Main composites use 180 x 120 mm;
single-column figures use 89 x 62 mm. Height may be explicitly changed; above
170 mm, consider a split instead of shrinking text. `case = "igs"` uses 183 x
105 mm. Explicit `render_spec` values override case/default values. When no
render_spec is provided, legacy save-loop width/height overrides are interpreted
in cm. Production templates pass an explicit spec and no longer derive final
size from source image dimensions. Low-level pp_finalize remains compatible.

All production fonts are Arial: body/axis/panel titles 7 pt regular;
species 6.5 pt (scientific name italic; suffix roman); annotation 6.5 pt;
ticks, legends, captions 6 pt; final A/B/C/D tags 12 pt bold upright.
`text_pt = list(axis_title = 8)` records an explicit user override.
Mapped text size is not silently overwritten: declare its scientific meaning
and implement an explicit reviewed adapter. `pp_text_role(layer, "species")`
can identify a text layer. `pp_scientific_labels(names, suffixes)` preserves
mixed italic/roman species labels. Existing large text is normalized on a copy.

Canvas/spacing are mm; typography and stroke specifications are pt. The adapter
converts ggplot text and historical linewidth units. Do not paste matplotlib
scatter area values into a ggplot size argument. Validate the resulting vector
dimensions instead of assuming backend numeric values are interchangeable.

## Environment and output

Run `Rscript paperplot-skills/scripts/check-environment.R` before production.
It reports capabilities and never installs dependencies. Formal output needs
Arial Regular/Bold/Italic, ggplot2, systemfonts, jsonlite, ragg, svglite, Python
Pillow/pypdf and Poppler. Heterogeneous composites additionally need patchwork.
Missing Arial prevents formal export. `mode = "preview"` may render a fallback
preview, but cannot certify Arial or manuscript readiness. `mode = "demo"`
labels simulated tests visibly. Neither mode can become manuscript-ready.

Default production output is white RGB PDF/SVG plus 600 dpi PNG. Inspect PDF
font embedding; SVG text elements retain an Arial dependency and do not imply
embedded fonts. Never distribute proprietary font files in this repository.

## Protect scientific information

Missing input/required recipe roles are errors. Only explicit demo mode may
use mock data. Specialized reference recipes require reviewed adapters and
cannot fabricate a real network/tree/genome model. Recipe templates build
their mapped tables from real columns rather than retaining mock columns.

The renderer saves `_data_evidence.rds` with source plot tables, layer tables,
factor attributes and built scientific coordinates, and checks equivalence
after style changes with numeric tolerance 1e-10. Stochastic jitter is fixed
on a plot copy. This verifies styling preservation, not the correctness of
an upstream statistical analysis: compare original scripts/tables as a separate
scientific review. Do not auto-normalize proportions or truncate intervals.

`pp_igs_figure()` accepts species, suffix, n, p_ge95, p90_95, p85_90, p80_85,
p_lt80, median, max. Percentages must sum to 100; input row order is preserved.
It accepts an optional original_annotations table and stops on disagreements.
Screenshots are not a substitute for the original table. Its species rows,
single n header, colors, 0.95 threshold and text hierarchy have a synthetic
contract test; the user's real IGS figure is NOT yet accepted.

## Layout and evidence

Use facets for homogeneous panels. Use `pp_compose_manuscript(plots, design,
widths, heights)` for heterogeneous panels; design strings use patchwork areas.
`pp_shared_rows()` shares a declared discrete species order. Do not force an
unjustified primary-panel size ratio. Use dedicated guides for different
semantics. Vertical labels need a height budget; horizontal labels need width.
`pp_apply_rank_labels()` changes visible tick text and writes a real key without
changing row values or order. Rebuild nonstandard annotation layers explicitly.

The export audit checks actual PDF/SVG page size (0.1 mm), font sizes (0.2 pt),
Arial, embedding and editable text, PNG dimensions and color mode. Declared
shared species labels are measured in SVG (0.2 mm). It also reports text/circle
clearance candidates with bounding boxes; arbitrary paths, curved labels and
complex geometries still need human review. Unknown evidence is never pass.

The existing raster QA is heuristic, even in strict mode. OCR defaults to auto;
production enables strict Nature/detail requests. Known detector exit 2 means
a detected failure, not an unavailable engine. Up to two located machine-fix
attempts are checked and rejected if they worsen the result. Y-axis crowding
must not trigger an X-axis rotation. Unsupported changes become agent tasks.

## One final decision

`_production_qa.json`, metadata and `_delivery.md` use `pp_final_qa()`:
hard failure -> fail/analysis sketch; incomplete or warned evidence/pending
human review -> manuscript candidate; all required checks and human review
pass -> manuscript-ready. Legacy scores are deprecated compatibility fields.
File smoke checks use `validate-figure-output.R <dir> --smoke`; they report
generation only. Without --smoke, incomplete final QA fails acceptance.

Reports include render configuration, detector hash, output hashes and data
evidence hash. Run the export loop again after detector/config/input changes;
do not reuse a historical pass. `_agent_tasks` in metadata lists unresolved
locations/advice; no automatic score can establish scientific message quality.

## Acceptance still pending

First validate mechanisms with explicitly simulated fixtures. Then use original
IGS data/scripts and a separate unseen 4-6-panel manuscript figure for review.
Preserve old outputs and document improvements and regressions. These real
case inputs are not currently available; synthetic tests do not close that gate.
