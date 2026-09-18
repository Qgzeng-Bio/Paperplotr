# Main figure projects

Build panels independently within a confirmed final figure plan. Do not draw
arbitrarily sized panels and then scale their fonts while stitching images.

## Natural-language routing

| User request | Action |
|---|---|
| Start Figure 2 | Find/create its project, record the scientific message and panel questions, present the layout sketch |
| This layout is good | Record `pp_project_confirm_layout()` with the user's confirmation; not figure approval |
| Draw A | Build the stable panel ID currently displayed as A |
| Only change B's legend | Modify B's working builder through revise; preserve all other source/object revisions and generate a contextual draft |
| A looks good | Record panel review for the exact revision and dependency/layout context |
| C should span a full row | Save a new layout, present its sketch and obtain confirmation; rebuild affected placements |
| Export final Figure 2 | Require all panels fresh and present; assemble, run production QA, request actual figure review if pending |
| Return to the previous B | Restore its builder and object revision; preserve unbuilt working edits and recheck dependency freshness |

Locate projects only in the relevant research workspace, normally
`figures/<figure_id>/project.json`. Resolve multiple candidates or ambiguous
labels with the user. Do not put data/projects in the installed Skill directory.
Read `pp_project_status()` every time; the Markdown summary can be stale after
external edits. A/B/C/D are display labels; stable IDs survive rearrangement.

## Project layout and confirmation

`pp_project_create(figure_id, message, panels, project, layout, column, shared,
shared_config, mode)` creates schema version 2. Existing projects resume without
being overwritten. Each panel has an id, title, scientific question, role,
optional script, named inputs, named extra source scripts, and dependency
declaration. A missing script means a planned placeholder, not invented data.

Default double-column budget is 180 mm, single-column 89 mm. Width defaults to
the budget, but may be smaller. Height starts at 120 mm; above 170 mm produces
a split/reflow recommendation. `width_exception` records a specific exception.
Font sizes do not scale with canvas size. Layout changes require confirmation.

`layout` supports `design` (patchwork area letters and # blanks), `order` (stable
IDs), positive `widths`/`heights` weights, and `guides = "keep"` or `"collect"`.
Example: `list(design="AB\nCC\nDD", width_mm=180, height_mm=140)`.
Each area must be rectangular; at most 26 display labels are supported in v1.
Plots may span tracks. Planned slots include titles, axes and their guides.
Actual outer allocations/data regions are measured after assembly. Guides and
long labels may change those measurements, so contextual previews are authoritative.

## Panel builder contract

```r
build_panel <- function(inputs, context) {
  d <- read.csv(inputs$values)
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) +
    ggplot2::geom_point(colour = context$shared$colors$signal)
  list(plot = p, evidence = d)
}
```

`inputs` contains named absolute file paths. `context` supplies the slot,
render_spec, panel ID/question/role, seed and shared settings. Return a ggplot
or patchwork object, or a vector grid object with a backend adapter. Prefer
`list(plot=..., evidence=..., backend=..., dependencies=...)`; dependency paths
must already be registered. Arbitrary external SVG/PDF/raster panels remain
unsupported. Do not export files, edit inputs, or add outer panel
letters inside the builder. Declare existing manual tag layers through the
panel's `manual_tag_layers` list when migrating a script.

Register all data paths under `inputs`, additional R code under `sources`.
Sources are loaded before the builder, then copied into the revision. Declare
`dependencies_declared=TRUE` only after reviewing the code. Static checks warn
about direct file reads not made through inputs and environment/time/system
calls. This is dependency auditing, not an R sandbox or proof that arbitrary
user code has no hidden dependencies. Unverified dependencies block readiness.

Panel colors/orders can come from inline `shared` or a referenced JSON
`shared_config`. `shared_keys` restricts the settings visible to that panel;
without it the whole shared configuration participates in its fingerprint.
Global typography is always shared. Each build records the configuration used.

Shared legends require the same nonempty `guide_semantics` and shared color
mapping. Explicit `shared_rows` groups specify panels and order. Explicit
`shared_axes` groups specify panels, x/y axis and limits; v1 supports Cartesian
axes. These choices are scientific display decisions and must be reviewed.

## Four operations and auxiliary commands

Source `scripts/paperplot_helpers.R` once, then use:

```r
pp_project_create("figure2", "The actual core scientific message", panels,
                  layout = list(design = "AB\nCD"))
pp_project_confirm_layout("figures/figure2", reviewer = "user")
pp_project_build_panel("figures/figure2", "A")
pp_project_revise_panel("figures/figure2", "B", script = "new-B.R",
                        change_type = "style", reason = "Move B legend")
pp_project_assemble("figures/figure2")
```

`change_type="scientific"` explicitly permits changed data/statistics/order and
records the reason; do not use it to evade a failed style-preservation check.
Draft assembly rebuilds stale panels, but will not silently rebuild changed
input data as a styling edit. Unavailable/stale panels remain labelled placeholders.
`final=TRUE` refuses incomplete/stale inputs. Production QA still controls the
final status; this flag does not grant manuscript readiness.

`pp_project_configure()` updates shared/style settings or registered panel
dependencies; `pp_project_set_layout()` saves a layout proposal.
`pp_project_review(project, target, decision, reviewer)` records panel or `figure`
review. `pp_project_restore(project, target, revision)` restores a panel or
`layout` version. Restoring never rolls back external raw data or source files;
if they differ, the restored result is correctly marked stale.

CLI equivalents use `scripts/paperplot-run scripts/figure-project.R`:

```text
create config.json
status project-dir
confirm-layout project-dir reviewer
build project-dir A
revise project-dir B request.json
assemble project-dir [final]
set-layout project-dir layout.json
configure project-dir settings.json [panel]
review project-dir A pass reviewer
review project-dir figure pass reviewer
review project-dir figure pass reviewer item-review.json
migrate project-dir [apply]
restore project-dir B r000001
restore project-dir layout r000001
```

Create JSON keys match the R creation arguments. Revision request keys are
`script`, `change_type`, `reason`. Configuration paths are relative to the project;
internal paths are stored relatively and external data stay explicit absolute
paths. Item-review JSON supplies checks and reason; it may only close listed
reviewable items, not exact failures.

Schema 1 can be read and inspected but not written before explicit migration.
Migration defaults to dry-run, then backs up project.json and retains historical
revisions/reviews without moving raw inputs. A migrated panel requires a first
scientific rebuild with reason="schema migration revalidation" because the old
evidence lacks schema-2 encoding/statistical fields. No old pass is inherited.

## Persistence and acceptance

`project.json` is authoritative and replaced atomically under `.project-lock`.
Never manually edit it while operations run. A leftover lock contains owner
information; inspect before manual recovery instead of automatically stealing it.
Immutable revisions contain builder snapshots, context, object/evidence caches,
QA and logs. Working edits are backed up before revise/restore overwrites them.
Failure logs remain; unsuccessful builds do not replace the current usable panel.

Cache keys cover input/script/source hashes, used shared settings, physical slot,
render settings, seed, helper source hashes and R/package versions. Corrupted
object caches are rebuilt. RDS is an optimization, not the reproducibility source.
Changing B does not rerun A/C/D unless their own dependencies or allocation change.
Every assembly produces contextual cell previews from the resolved physical
gtable; these may change with shared layout without changing panel source revisions.

Assemblies use the existing production QA plus project completeness, measured
geometry and dependency checks. Figure approval is separate from panel approval.
Pending review or unavailable evidence stays candidate; a hard failure stays fail.
Raw export reports capture the review state at render time; later review events
are stored in project.json without rewriting historical reports.

## Example and limitations

Run `Rscript scripts/create-example-project.R <new-dir>` to create an explicitly
simulated project and sketch. Add `--run-demo` to execute its scripted demo-only
confirmation/build/assembly walkthrough. This is not user scientific approval.

Real IGS and held-out manuscript data are still required for real acceptance.
Nested patchwork data regions and arbitrary custom geometries can be unverified;
read geometry notes and inspect the assembled figure. No raster stitching or
automatic font substitution is used to claim formal production compatibility.
