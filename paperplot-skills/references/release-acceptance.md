# 0.7 release acceptance

Run from the full repository checkout with the isolated runtime. The formal gate must stop on missing dependencies, unavailable Arial, skipped cases, bad physical exports or scientific regressions.

```sh
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/validate-skill.R
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-recipe-contract.R
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-specialized-contract.R
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-recipe-exports.R
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/smoke-test-templates.R
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-figure-project.R
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-production-contract.R --require-production
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-skill-install.py
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/fetch-public-cases.py
paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/test-public-cases.R
```

The automated formal-render runner executes these checks and records exact code/lock/environment fingerprints and logs. It reports engineering checks separately from manuscript acceptance. No successful skipped formal job.

## Evidence levels

1. All 84 IDs: minimal legal input, missing-required rejection, scientific family contracts and actual vector/raster export at target size.
2. All 36 templates: actual generation plus metadata/final-QA linkage.
3. Every specialized backend: real public case and deliberate invalid input.
4. Project lifecycle: confirmation, immutable builds, B-only revision, measured reassembly, failed-build recovery, restored history, data/detector/export freshness and rejection propagation.
5. Clean/upgrade installation: actual commands and exports outside the checkout; download/profile/dependency/post-switch failures retain the old installation.
6. Real final review: at least one genuinely reviewed valid example reaches pass; a hard-error example stays fail despite an attempted approval. Mechanism tests using “test fixture” reviewers do not count as human scientific approval.
7. User's original IGS and independent 4–6-panel main figure: provided data/scripts only; never substituted with demos or public cases.

Public fixture source URLs/content hashes and all transformations are in fetch-public-cases.py, test-public-cases.R and each generated provenance.json. Real public inputs are downloaded into ignored visual-checks, not redistributed blindly.

Remain RC until every agreed gate is complete. When personal materials or human approval are unavailable, explicitly report their pending state. Engineering success does not authorize a stable release.
