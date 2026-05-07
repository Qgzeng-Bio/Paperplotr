# PaperPlotR Handoff

Last updated: 2026-05-07

## Repository

- Local package path: `/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr`
- GitHub repository: `https://github.com/Qgzeng-Bio/Paperplotr`
- Package version: `0.1.0`
- Package site: `https://qgzeng-bio.github.io/Paperplotr/`
- Latest skill release: `paperplot-skills v1.0.0`
- Release URL: `https://github.com/Qgzeng-Bio/Paperplotr/releases/tag/skill-v1.0.0`
- Current public package direction: publication-ready `ggplot2` helpers for scientific figures plus a repo-local AI scientific plotting skill.

## Current Git State

- Branch: `main`
- Current `HEAD`: `bd81d88 docs: add multi-agent skill installation guide`
- Local working tree was clean after the last push.
- `HEAD` and `origin/main` were synchronized after the last push.
- Latest pushed commits:
  - `bd81d88 docs: add multi-agent skill installation guide`
  - `785045f ci: use portable fonts in skill smoke tests`
  - `df204e8 ci: stabilize paperplot skills smoke tests`
  - `bf71bbb docs: publish paperplot skills entrypoints`
  - `7975936 docs: add PaperPlotR handoff notes`
  - `33f8698 feat: add paperplot AI skill wrapper`
  - `2da8d02 Fix CI for gallery workflow updates`
  - `2873d9b Improve plot export and gallery workflows`
- `HANDOFF.md` is tracked, but excluded from R package builds via `.Rbuildignore`.

## Completed Package Work

- `scale_fill_lab()` and `scale_color_lab()` expose a `guide` argument, so `guide = "none"` no longer causes duplicate-argument errors.
- `layout_lab()` supports panel tags directly:
  `tag_levels`, `tag_size`, `tag_face`, `tag_family`, and `tag_position`.
- `save_lab()` and `save_lab_plot()` validate named graphics devices before calling `ggplot2::ggsave()`.
- Explicit export devices are supported:
  `quartz_pdf`, `ragg_png`, `ragg_tiff`, and `svglite`.
- Saved output files are checked by default for existence and suspiciously small size.
- `ragg` and `svglite` are included in `Suggests`.
- Domain-specific semantic color dictionaries are opt-in:
  `available_group_dictionaries(include_examples = TRUE)`.
- Legacy example dictionary names remain resolvable, with warnings encouraging project-specific `register_group_dictionary()`.
- `vignettes/gallery.Rmd` was added.
- Visual regression snapshots were added for semantic group mapping and tagged multi-panel layouts.
- `visual-checks/`, `Rplots.pdf`, and `HANDOFF.md` are excluded from R package builds.
- `visual-checks/` and `Rplots.pdf` are ignored by git.

## paperplot-skills Status

- `paperplot-skills/` is tracked, pushed, and released as `skill-v1.0.0`.
- It is a repo-local AI skill wrapper for PaperPlotR, not a separate R package.
- It is generic scientific plotting infrastructure, not a project-specific workflow.
- It guides AI agents to:
  - choose scientific figure templates,
  - generate complete runnable R scripts,
  - use PaperPlotR theme, palette, semantic mapping, layout, and export helpers,
  - default to no-overwrite versioned outputs,
  - write sidecar notes,
  - run output QA.
- It now includes:
  - `SKILL.md`
  - `README.md`
  - `AGENTS.md`
  - `INSTALL.md`
  - `references/`
  - `templates/`
  - `examples/`
  - `scripts/validate-skill.R`
  - `scripts/smoke-test-templates.R`

## Multi-Agent Compatibility

- Codex: install by symlink or copy into `~/.codex/skills/paperplot-skills`.
- Claude Code: use repo-local mode by telling Claude to read `paperplot-skills/SKILL.md`, or copy/symlink into a Claude skill/instruction directory if configured.
- OpenCode: point local instructions to `paperplot-skills/AGENTS.md`.
- Generic CLI agents: use `paperplot-skills/AGENTS.md` as the entrypoint.
- Native auto-discovery is agent-specific; the skill is intentionally usable as plain Markdown plus R templates even without auto-discovery.

## Release and CI

- GitHub Release created:
  `https://github.com/Qgzeng-Bio/Paperplotr/releases/tag/skill-v1.0.0`
- Main README now links to `paperplot-skills/` and includes a skill workflow badge.
- `_pkgdown.yml` includes an `AI Skill` navigation item linking to the GitHub skill directory.
- Dedicated workflow added:
  `.github/workflows/paperplot-skills.yaml`
- The workflow runs:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

- CI smoke mode uses base graphics devices and `base_family = "sans"` in temporary template copies to avoid Linux CI Arial font issues. This does not change the real templates.

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
PAPERPLOTR_SMOKE_BASE_DEVICES=true PAPERPLOTR_SMOKE_BASE_FAMILY=sans Rscript paperplot-skills/scripts/smoke-test-templates.R
```

Results:

- `paperplot-skills validation passed`
- default smoke: `8/8 templates passed smoke tests`
- CI-mode smoke: `8/8 templates passed smoke tests`

Latest GitHub Actions after `bd81d88`:

- `paperplot-skills`: success
- `R-CMD-check`: success
- `pkgdown`: success
- `test-coverage`: success
- `lint`: success

## Local Artifacts

- `visual-checks/` exists locally and contains generated visual inspection outputs.
- `Rplots.pdf` exists locally and appears to be an accidental graphics-device artifact from testing.
- These artifacts are ignored or build-excluded and should not be committed unless deliberately promoted into official examples.

## Known Residual Risks

- `devtools` was not installed in the active local R 4.6 system library. Some verification used a temporary R library at `/private/tmp/paperplotr-r-lib`.
- Full vignette building was not part of the last local `R CMD check`; the check used `--ignore-vignettes`. GitHub `pkgdown` did build the site successfully after the latest push.
- `paperplot-skills` is multi-agent readable, but automatic discovery depends on each agent's local skill mechanism.

## Recommended Next Steps

1. For local Codex use, install the skill by symlink:

```bash
mkdir -p ~/.codex/skills
ln -sfn "/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr/paperplot-skills" ~/.codex/skills/paperplot-skills
```

2. Start a new session and ask the agent to use `paperplot-skills` on a real CSV or ggplot script.
3. Optionally add agent-specific install notes for any exact Claude Code/OpenCode directory conventions once confirmed locally.
4. Do not create a separate GitHub repository unless the skill is later generalized beyond PaperPlotR.
