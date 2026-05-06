# PaperPlotR Handoff

Last updated: 2026-05-06

## Repository

- Local package path: `/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr`
- GitHub repository: `https://github.com/Qgzeng-Bio/Paperplotr`
- Package version: `0.1.0`
- Package site: `https://qgzeng-bio.github.io/Paperplotr/`
- Current public package direction: publication-ready `ggplot2` helpers for scientific figures.

## Current Git State

- Branch: `main`
- Latest pushed commits:
  - `33f8698 feat: add paperplot AI skill wrapper`
  - `2da8d02 Fix CI for gallery workflow updates`
  - `2873d9b Improve plot export and gallery workflows`
- `paperplot-skills/` is now tracked and pushed.
- This handoff file is intentionally tracked, but excluded from R package builds via `.Rbuildignore`.

## Completed Package Work

- `scale_fill_lab()` and `scale_color_lab()` now expose a `guide` argument, so `guide = "none"` no longer causes duplicate-argument errors.
- `layout_lab()` now supports panel tags directly:
  `tag_levels`, `tag_size`, `tag_face`, `tag_family`, and `tag_position`.
- `save_lab()` and `save_lab_plot()` now validate named graphics devices before calling `ggplot2::ggsave()`.
- Explicit export devices are supported:
  `quartz_pdf`, `ragg_png`, `ragg_tiff`, and `svglite`.
- Saved output files are checked by default for existence and suspiciously small size.
- `ragg` and `svglite` are included in `Suggests`.
- Domain-specific semantic color dictionaries are no longer listed by default.
  Use `available_group_dictionaries(include_examples = TRUE)` to list example dictionaries.
- Legacy example dictionary names remain resolvable, with warnings that encourage project-specific registration.
- A formal gallery vignette was added at `vignettes/gallery.Rmd`.
- Visual regression snapshots were added for semantic group mapping and tagged multi-panel layouts.
- `visual-checks/`, `Rplots.pdf`, and `HANDOFF.md` are excluded from R package builds.
- `visual-checks/` and `Rplots.pdf` are ignored by git.

## AI Skill Wrapper

- `paperplot-skills/` was added as a repository-local AI skill wrapper for PaperPlotR.
- It contains:
  - `SKILL.md`
  - GitHub-ready `README.md`
  - workflow references
  - 8 reusable R plotting templates
  - example prompts and report templates
  - static validation and smoke test scripts
- The skill is generic scientific plotting infrastructure, not a domain-specific workflow.
- The skill defaults to no-overwrite, timestamped output stems, notes files, PaperPlotR export helpers, and template-based R scripts.

## Verification Already Run

Package verification:

```bash
R_LIBS=/private/tmp/paperplotr-r-lib Rscript -e 'testthat::test_local()'
R_LIBS=/private/tmp/paperplotr-r-lib R CMD build --no-build-vignettes /Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr
R_LIBS=/private/tmp/paperplotr-r-lib R CMD check --no-manual --ignore-vignettes /private/tmp/PaperPlotR_0.1.0.tar.gz
```

Results:

- `testthat::test_local()`: 153 passed, 0 failed.
- `R CMD build --no-build-vignettes`: succeeded.
- `R CMD check --no-manual --ignore-vignettes`: `Status: OK`.

Skill verification:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

Results:

- `paperplot-skills validation passed`
- `8/8 templates passed smoke tests`

## Local Artifacts

- `visual-checks/` exists locally and contains generated visual inspection outputs.
- `Rplots.pdf` exists locally and appears to be an accidental graphics-device artifact from testing.
- These artifacts are ignored or build-excluded and should not be committed unless deliberately promoted into official examples.

## Known Residual Risks

- GitHub Actions should be checked after each push, especially after changes touching vignettes, snapshots, or CI.
- `devtools` was not installed in the active local R 4.6 library. Verification used a temporary R library at `/private/tmp/paperplotr-r-lib`.
- `R CMD check` printed transient repository index warnings in the dependency check step, but completed with `Status: OK`.
- Full vignette building was not part of the last `R CMD check`; the check used `--ignore-vignettes`.

## Recommended Next Steps

1. Check GitHub Actions for the latest `main` push.
2. Decide whether to add a GitHub Actions workflow for `paperplot-skills`.
3. Optionally link `paperplot-skills/` from the main README or pkgdown site.
4. Consider a full vignette build check before release.
5. Do not create a GitHub Release yet unless the package workflow and skill wrapper have both been reviewed.
