# Production render validation, 2026-09-13

Implementation: standalone-0.5.0. Tests were run using R 4.5.1 with its matching
package library, because the machine's default R 4.6 library lacks ggplot2.
Do not mix the old compiled packages into the new R runtime.

## Verified behavior

- Production R contract suite passed: role normalization on a copy, Arial face
  validation, explicit overrides, data/order/threshold-change rejection,
  missing input/column rejection, demo behavior, final fail/unverified propagation,
  strict detector exit 2 classification, composite building and physical exports.
- Five Python audit tests passed, including large fonts, Helvetica/Arial Narrow
  substitution, page-size mismatch, text/circle collision, shared-row mismatch,
  duplicate n formatting and the 12 pt panel-tag exception.
- Existing standalone contract and structural validator passed.
- 36/36 production templates generated PDF/PNG/notes/metadata/QA artifacts in
  explicit demo mode. This is generation/compatibility verification only.
- Full smoke run reported 25 warn and 11 fail visual states. Subsequent targeted
  tests corrected a 17.7 pt underscore used as a median marker and an auditor
  that confused dark boxplot strokes with axes; both affected templates then
  generated successfully with warn status. No smoke plot is manuscript-ready.

## Physical IGS fixture

This is a synthetic test, not reconstructed user data. Actual PDF/SVG dimensions
pass the 183 x 105 mm check (0.1 mm tolerance). PDF fonts are embedded Arial;
SVG retains text with Arial/italic/bold roles. Font sizes pass 0.2 pt tolerance.
Shared species label positions pass 0.2 mm alignment tolerance. There is one n
header. Actual SVG axes/ticks measure 0.6/0.5 pt. Filled median circle diameter
and maximum triangle height meet 4.5/5.0 pt targets. PNG matches 600 dpi output.

The four-panel synthetic fixture also verifies a 180 x 120 mm canvas with unique
bold 12 pt A/B/C/D labels. Both previews were visually inspected, including the
white data-region background; neither is a scientific result or gold standard.

## Remaining evidence and boundaries

- Original IGS scripts/tables and an unseen 4-6-panel figure are still needed
  for real scientific and design acceptance. The screenshot threshold discrepancy
  must be resolved against those inputs, not guessed from the image.
- PNG connected-component risks remain heuristic; they may overflag dense
  matrices/facets. Use vector evidence and human review to interpret them.
- SVG text/circle clearance and shared-row checks have limited geometric
  coverage. Unsupported shapes/transformations are unverified, not passed.
- Data evidence proves preservation during styling. It does not independently
  validate upstream models or establish that a chosen plot type tells the best
  scientific story.
- Arial is not redistributed. A CI machine without licensed Arial reports that
  physical production export tests are skipped; demo generation is separate.

## Reproduce

```sh
Rscript paperplot-skills/scripts/check-environment.R
Rscript paperplot-skills/scripts/test-production-contract.R
python3 paperplot-skills/scripts/test-export-audit.py
PAPERPLOT_MODE=demo Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

The smoke script accepts `PAPERPLOT_RSCRIPT` for a matching R runtime and
`PAPERPLOT_SMOKE_TEMPLATES` for a comma-separated targeted regression subset.
Use `PAPERPLOT_TEST_OUTPUT` to retain synthetic export artifacts in a chosen
new directory. Tests refuse to overwrite existing figure artifacts.
