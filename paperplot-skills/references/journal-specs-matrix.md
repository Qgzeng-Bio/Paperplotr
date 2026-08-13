# Journal Specs Matrix

Use this matrix before composing a final figure. It is a profile selector, not a
substitute for the current journal instructions. Record the selected profile in
`figure_spec.journal_profile` and recheck the official guide at submission.

## Provenance and precedence

1. A current official target-journal guide overrides every value here.
2. A named profile applies only to the journal family in its `Scope` field.
3. `general_scientific` is the fallback when no reliable named guide is fixed.
4. The typography policy follows the reviewed `make-figures` skill: ordinary
   print labels and axes target 9 pt; ticks, legends, and compact annotations
   target 8 pt; panel labels target 12 pt bold. Six pt is an absolute floor, not
   a normal target.
5. Dimensions are maximum design envelopes. Compose at final width instead of
   building a large canvas and shrinking it later.

Last reviewed: 2026-08-12. Every metadata record snapshots profile `Scope`,
`Source_URL`, `Source_status`, `Last_checked`, and the active width/height
envelope so later validation is auditable.

## Figure profiles

| Profile | Scope | Single column | Intermediate | Full/double width | Max height | Source status |
|---|---|---:|---:|---:|---:|---|
| `general_scientific` | General research fallback | 8.8 cm | 12.7 cm | 17.8 cm | 24.1 cm | Local fallback adapted from `make-figures`; verify target journal |
| `nature_like` | Nature-like life-science and genomics layouts | 8.9 cm | Not fixed | 18.0 cm | 17.0 cm | Existing PaperPlot project baseline; verify current Nature Portfolio title guide |
| `nature_communications` | Nature Communications project layouts | 9.0 cm | Not fixed | 18.0 cm | 17.0 cm | Separate profile for `ncomms*` presets; verify current title guide |
| `cell_press` | Cell Press two-column research figures | 8.5 cm | 11.4 cm | 17.4 cm | 20.0 cm | Official Cell Press figure guidance reviewed 2026-08-12 |
| `medical_radiology` | Radiology-family journal figures | 8.56 cm | 12.8 cm | 17.35 cm | 23.34 cm | Imported medical profile; verify the named journal before submission |

Official Cell Press source:
<https://www.cell.com/information-for-authors/figure-guidelines>.

Nature Portfolio source to recheck for the selected title:
<https://research-figure-guide.nature.com/>.

The medical profile is intentionally separate. Do not apply AJR/Radiology/KJR
sizes to plant genomics or general life-science figures simply because those
values exist in another skill.

## DPI and format by content type

| Content | Minimum raster resolution | Preferred output |
|---|---:|---|
| Vector line art and statistical plots | 600 dpi preview; vector retained | Editable PDF plus PNG |
| Halftone or photographic panels | 300 dpi at final size | TIFF/PNG plus composite PDF as accepted |
| Combination line art + halftone | 600 dpi at final size | PDF/TIFF according to journal |
| Review or presentation copy | 150 dpi minimum; 300 dpi preferred | PNG |

Use the strictest requirement present in a mixed composite. Never upscale a
low-resolution image to manufacture compliance. Keep plotting text and lines
vector whenever the format permits.

## Typography contract

| Element | Target at final print size | Policy |
|---|---:|---|
| Axis labels and ordinary figure text | 9 pt | Default implementation in `pp_theme()` |
| Tick labels and legend text | 8 pt | Compact but readable |
| In-panel annotations and inset/table text | 8 pt | Reduce visible burden before reducing text |
| Panel labels | 12 pt bold | Consistent placement and case |
| Absolute floor | 6 pt | Requires target-journal allowance and documented dense-family exception |

A target journal may require larger text. A smaller journal minimum does not
force PaperPlot to shrink an otherwise readable design.

## Cognitive-load review triggers

These values trigger review; they are not universal hard failures:

| Per-panel signal | Review trigger |
|---|---:|
| Distinct visual elements | More than 7 |
| Meaning-carrying colors | More than 3 |
| Distinct marker shapes | More than 3 |
| Legend entries | More than 4 |

If two or more triggers fire, first split, simplify, directly label, or move
lookup detail to a sidecar/supplement. Dense scientific families—heatmaps,
Manhattan plots, phylogenetic annotation rings, UpSet matrices, and some
multi-group ordinations—may retain higher burden only when:

- the additional encodings are scientifically necessary;
- the selected pattern document permits the structure;
- `cognitive_load_exception` records the reason;
- final-size rendered QA and grayscale review remain interpretable.

## Spec-first compositing workflow

1. Select the target profile and verify the current official guide. Branded
   presets must match their profile (`cell*` → `cell_press`, `nature*` →
   `nature_like`, `ncomms*` → `nature_communications`).
2. Choose the final width and derive panel boxes from that width.
3. Apply the typography contract at final print size.
4. Run cognitive-load review per panel and record any justified exception.
5. Define `panel_hierarchy`, `layout_budget`, and `shared_guide_plan`.
6. Render PDF plus PNG at target size.
7. Run strict rendered QA with explicit panel expectations when applicable.
8. Recheck dimensions, fonts, formats, and file-size limits at submission.
