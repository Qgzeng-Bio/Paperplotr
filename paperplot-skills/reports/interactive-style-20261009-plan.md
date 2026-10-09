# Interactive workflow and journal-profile update

Status: source implemented and focused validation passed; deployment approval pending.

## Scope and baseline

User requested syncing the new Nature/Cell profiles and adopting make-figures' information design and lightweight iteration: Wong colors, direct key labels, real observations on box/violin plots, density-aware heatmap values, one message and whitespace. No matplotlib migration, new batch subsystem, analysis changes, formal-result edits, Git operations, dependency installations or publication.

Baseline: branch dev/linux-cairo-pagebox, HEAD 51ceb09. Existing uncommitted journal-profile work spans HANDOFF, SKILL, four references, journal-profiles.md, helper, production renderer, project builders and regression tests; preserve it. Current installed Codex/Claude copies predate profiles; Pi links to Codex. Existing figure-project test assertion was fixed but not revalidated.

## Implementation

1. Preserve journal profile physical/font contracts. Keep production/demo API defaults compatible. Use existing preview mode explicitly for ordinary agent-led interactive work; no new public mode.
2. In existing export helper, preview performs one export pass and basic data/font/file checks, but no external visual QA/OCR, iterative repairs, candidate-copy history or physical export audit. Preserve provenance sufficient for existing metadata/project consumers. Unperformed checks remain unverified; preview can never be manuscript-ready or promoted by recording a review. Production/demo keep existing strict path.
3. Add named Wong palette and use it as default categorical palette; keep explicit named vectors, legacy palettes, gradients and scientific semantic colors. Do not silently generate a purported Wong palette beyond its eight colors. Update current template metadata to match actual default; historical reports remain historical.
4. Keep existing original-observation layers. Add shared density-aware heatmap value-label policy for ordinary heatmaps with explicit on/off, conservative auto limit, no silent removal of explicitly required labels, and no change to source values/order/normalization. Direct labels use existing collision-controlled helpers when suitable, with legends retained where necessary.
5. Update SKILL, current style docs and README: direct generation, consolidated feedback, targeted revision, explicit finalization; read only relevant references and do not run full environment diagnostics or developer test suites for each plot. Existing confirmed project revision/layout protections remain.
6. Fix installer runtime payload omission of fix-cairo-page.py, required by the already committed Linux page-box patch. Do not execute installation yet.

## Verification and acceptance

Focused tests: palette defaults and overrides; heatmap auto/on/off and invalid input; preservation of raw point layers; preview does not call external QA/audit or repairs and reports unverified; production still invokes strict checks; profile dimensions/tag case/font boundaries; rejection/no-overwrite guards. Verify actual small exported files and metadata, not just exit status. Independent read-only review before deployment.

SLURM approval obtained via confirm_action for the exact command `sbatch --parsable /data9/home/qgzeng/projects/3-Biotools_create/Paperplot/logs/interactive-style-20261009/validate.sbatch`: one normal job, 1 CPU, 8G, no added walltime; seven focused checks, logs and synthetic outputs in new task/job paths. Executed once as job 908327: all seven checks PASS, elapsed 14m36s; source hashes unchanged across the run. No cancellation/resubmission or installation approved. Source implementation is not a verified install or stable release. Full 84-recipe formal acceptance and actual scientific/human acceptance are not implied by this task.

Deployment: exact target(s), installer command, verified backup location, output checks, risks and rollback must be disclosed through confirm_action after implementation checks. Do not alter skill discovery topology without authorization. No global rules/memories modified.

## Roles

orchestrator=main; sole-writer=luna-executor for delegated source/tests/docs; reviewer=independent read-only agent after implementation; deployment=main after explicit approval. This plan/verification record is owned by main, not the implementation agent.
