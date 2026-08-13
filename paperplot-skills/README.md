# paperplot-skills

`paperplot-skills` is a standalone Pi, Codex, and Claude Code skill for publication-ready scientific figures in R/ggplot2.

It does not depend on the PaperPlotR R package. The reusable plotting standards live in `scripts/paperplot_helpers.R`.

## Install

One-line install into Codex:

```bash
curl -fsSL https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | sh
```

If `curl` is unavailable or broken:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | sh
```

Pinned release install:

```bash
wget -qO- https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/v0.1.0/install-paperplot-skill.sh | PAPERPLOT_REF=v0.1.0 sh
```

Restart Codex after installation.

The one-line installer defaults to the runtime profile: `SKILL.md`, `agents/`,
`references/`, `templates/`, and core scripts. Use `PAPERPLOT_PROFILE=full` for
development reports, examples, pressure scenarios, and dev scripts.

If the skill already exists, replace it explicitly:

```bash
curl -fsSL https://raw.githubusercontent.com/Qgzeng-Bio/Paperplotr/main/install-paperplot-skill.sh | PAPERPLOT_OVERWRITE=1 sh
```

Overwrite installation is transactional: the archive is downloaded, staged,
and checked before the previous runtime is switched out. A download or staging
failure leaves the previous installation in place.

## What It Provides

- ggplot2 templates for common scientific plots
- GraphPad-like palettes
- clean manuscript theme defaults
- scoped journal profiles and final-size panel planning
- 9 pt print typography target, 8 pt compact text, and 6 pt absolute floor
- review-trigger cognitive-load checks with documented dense-family exceptions
- standalone bioinformatics data-to-image validation
- versioned PDF and PNG export
- output validation with journal/typography metadata
- sidecar notes
- visual QA gates
- pressure scenarios for agent behavior

## Core contracts

Before composing, select a profile from
[`references/journal-specs-matrix.md`](references/journal-specs-matrix.md) and
verify the current official target-journal guide. Medical profiles are scoped to
medical journals and do not override Nature-like or general genomics defaults.

Ordinary print labels and axes target 9 pt, compact ticks/legends/annotations
target 8 pt, and panel labels target 12 pt bold. Six pt is an absolute floor,
not a design target. Per-panel element/color/shape/legend ceilings trigger
review; dense scientific families may exceed them only with a recorded reason
and final-size QA.

Bioinformatics figures additionally follow
[`references/bioinformatics-figure-validation.md`](references/bioinformatics-figure-validation.md),
which validates source records, references, coordinates, units, transforms,
denominators, sample order, and claim limits independently of rendered-image QA.

## Validate

Run from the full source checkout or a `PAPERPLOT_PROFILE=full` install. From
the directory that contains `paperplot-skills/`:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/test-contract-regressions.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
Rscript paperplot-skills/scripts/run-pressure-scenarios.R
python3 paperplot-skills/scripts/run-visual-pressure-scenarios.py
Rscript paperplot-skills/scripts/validate-figure-output.R <output_dir>
Rscript paperplot-skills/scripts/validate-figure-output.R <output_dir> --manuscript-ready
```

Candidate validation uses bundled base-R contract parsers, checks valid PDF/PNG signatures, complete stem-matched bundles, structured metadata/QA agreement, profile geometry, and orphan core artifacts without requiring Python, `jsonlite`, or a YAML package. Candidate PASS confirms integrity only; it does not emit a readiness verdict.

Manuscript-ready mode additionally requires QA `pass` derived consistently from the complete common gate set, decodable PDF/PNG media, and current-schema strict rendered-image evidence. The validator verifies each tool fingerprint and reruns the bundled pixel analysis; re-signing edited JSON is not accepted. Any visual warning needs structured review acceptance, cognitive-load review must be complete, and bioinformatics `pass` provenance must be backed by real files, checksums, plotting TSV, and checklist evidence. When `figure_spec.old_figure_path` is present, completed old-vs-new evidence is also deterministically replayed, must bind the same verified new-image analysis, and must conclude `improved`.

Because templates refuse overwrites and write metadata before rendered QA, record post-render decisions in a stem-matched `*_review.json` with `pp_write_review_sidecar()`. The sidecar binds metadata, QA, visual QA, and optional old-vs-new evidence by MD5; the strict validator rejects stale sidecars.

Use `PAPERPLOT_RSCRIPT` and `PAPERPLOT_PYTHON` when the default shell points to
the wrong environment. On the qgzeng server, the base Anaconda Pillow currently
has a `libLerc`/`libstdc++` ABI conflict; the existing `claude` environment is the
validated visual-QA interpreter.

## Dependency Policy

Required:

- R
- ggplot2

Manuscript-ready validation also needs an available PDF/image decoder (`pdfinfo`/Poppler and ImageMagick `identify`, or configured Python/Pillow fallback). Candidate integrity validation remains dependency-free beyond R.

Not required:

- PaperPlotR
- patchwork
- ragg
- svglite
- cli
- rlang
- scales
