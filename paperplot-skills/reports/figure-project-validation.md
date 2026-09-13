# Figure project validation

Version: standalone-0.6.0, project schema 1. Date: 2026-09-13.

## Functional verification

`scripts/test-figure-project.R` passed using the installed R 4.5.1 runtime and
its matching package library. The suite exercises:

- Creation/resume, a generated dimensioned layout sketch, and confirmation gates.
- Smaller-than-budget widths, explicit 183 mm exceptions, and rejection of an
  unrecorded over-budget canvas.
- Writer lock exclusion and immutable panel/assembly revision allocation.
- Independent builds at planned 90 mm slots (not a forced 89 mm child size).
- B-only revisions with unchanged A/C/D revision IDs and object hashes.
- Failed build preservation, working-script backup and historical restoration.
- Used versus unused shared configuration invalidation, layout reflow/rebuild,
  and restored-layout confirmation.
- Rejection of scientific changes labelled as style; explicit scientific revisions.
- Stale/incomplete final assembly rejection, placeholder drafts, guide conflicts,
  failed-panel-review gates and unregistered dependency warnings.
- Shared-row category-loss prevention and physical alignment error detection.
- Actual gtable outer/data-region measurement and contextual panel PNGs.

The existing standalone/structure validator and production contract suite also
passed. Five existing Python export-audit regression tests passed. The ordinary
independent-figure interface remains available.

## Simulated walkthrough and physical output

`create-example-project.R <new-dir> --run-demo` generated four different simulated
views (scatter, distribution, profile, density), confirmed the test layout,
built A-D, recorded a simulated A review, moved only B's legend and assembled
again. Final panel IDs: association r000001, distribution r000002, profile
r000001, density r000001. No raw data or other panel scripts were changed.

The generated PDF/SVG/PNG audit confirms the declared 180 x 120 mm page,
Arial typography, embedded PDF fonts, editable SVG text, unique bold panel tags
and 600 dpi PNG dimensions on this machine. Gtable geometry was measured and
the complete figure plus its B context preview were visually inspected.
The current raster QA still reports warnings/failures for some synthetic
layouts, and generic text/mark clearance remains unverified. These are not
certified manuscript figures, despite successful workflow tests.

Local example artifacts are in ignored
`visual-checks/figure-project-example-verified/figure-demo/`.
Each assembly has `assembly.json`, `delivery.md`, the production QA report,
full vector/raster exports and `context-A.png` through `context-D.png`.
The example generator refuses a nonempty output directory.

## Reproduce

```sh
Rscript paperplot-skills/scripts/test-figure-project.R
Rscript paperplot-skills/scripts/create-example-project.R figures/example --run-demo
Rscript paperplot-skills/scripts/figure-project.R status figures/example/figure-demo
Rscript paperplot-skills/scripts/test-production-contract.R
PAPERPLOT_MODE=demo Rscript paperplot-skills/scripts/validate-skill.R
python3 paperplot-skills/scripts/test-export-audit.py
```

Set `PAPERPLOT_PROJECT_TEST_OUTPUT` to retain test artifacts. Use a matching R
runtime/library; the default R 4.6 installation on the development machine
does not contain the earlier installed dependencies.

## Boundaries

- Only ggplot2/patchwork objects are supported. No raster stitching or external
  vector-file editing is implied.
- Dependency declarations plus static I/O checks do not sandbox arbitrary R
  code or prove absence of every hidden dependency. Warnings prevent full
  reproducibility certification.
- Cached objects are not the sole reproduction source. Raw input files remain
  external; restoration never edits or restores those scientific data files.
- Planned slots and measured allocations are separately recorded. Context
  previews use the resolved assembled gtable, preserving actual allocation.
  Nested/custom panel geometry may remain unverified.
- Real IGS and held-out manuscript acceptance still require original data,
  scripts and scientific/visual review. Demo confirmations do not replace them.
