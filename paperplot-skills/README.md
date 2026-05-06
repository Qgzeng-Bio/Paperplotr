# paperplot-skills

`paperplot-skills` is a repository-local AI skill for using PaperPlotR as a publication-ready scientific figure workflow. It guides an AI agent to choose an appropriate plot template, generate a complete runnable R script, apply PaperPlotR styling and export helpers, version outputs, and record quality notes.

This directory does not change the PaperPlotR R package itself. It is an added skill artifact that lives beside the package source.

## Quick Start

From the PaperPlotR repository root:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

Use `SKILL.md` as the AI entrypoint. For implementation work, the agent should then read the relevant reference file and one template under `templates/`.

## Repository-Local Usage

This skill is designed to stay inside the repository as `paperplot-skills/`. It can be copied or referenced by an AI agent without installing or modifying the PaperPlotR R package.

Recommended agent sequence:

1. Read `paperplot-skills/SKILL.md`.
2. Read `references/template-selection-guide.md`.
3. Select one template from `templates/`.
4. Read only the workflow reference files needed for the task.
5. Generate a complete runnable R script, not a loose code snippet.
6. Render the figure, inspect the outputs, and write notes.
7. Report generated files, presets, checks, and remaining issues.

## What It Does

The skill helps an AI agent:

- Decide whether a figure task fits PaperPlotR.
- Choose a reusable scientific plot template.
- Generate reproducible R scripts around ggplot2 and PaperPlotR.
- Use `theme_lab()`, `scale_*_lab()`, `scale_*_groupmap()`, `layout_lab()`, `save_lab()`, and `save_lab_plot()` where applicable.
- Export versioned PDF, SVG, PNG, and TIFF outputs when requested.
- Avoid overwriting old figures by default.
- Write sidecar notes documenting files, presets, panel mapping, and QA checks.
- Iterate with small targeted edits when visual QA finds hard issues.

## What It Does Not Do

This skill is not for mechanism diagrams, pathway cartoons, graphical abstracts, flowcharts, network architecture diagrams, interactive charts, image generation, or Python-only plotting workflows. Use a diagram, SVG, slide, web visualization, Graphviz, Mermaid, Illustrator, or similar workflow for those cases.

## Recommended Trigger Scenarios

- "Create a publication-ready boxplot from this CSV."
- "Refine this ggplot2 figure for a manuscript without overwriting the old image."
- "Build a 2x2 multi-panel figure and export PDF plus PNG."
- "Standardize colors and panel labels with PaperPlotR."
- "Generate a journal-style R figure with versioned outputs."
- "Create a bioinformatics-style statistical plot using ggplot2 and PaperPlotR."

The skill should not trigger for every visualization request. It is best for R or ggplot2 scientific plots where reproducibility, journal sizing, semantic colors, panel layout, and export quality matter.

## How To Validate

Run the static validator from the PaperPlotR repository root:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
```

The validator checks:

- Required skill files exist.
- `SKILL.md` frontmatter is valid and concise.
- README contains GitHub-facing usage and contribution sections.
- All 8 R templates include no-overwrite logic, timestamped stems, notes, file-size reporting, and PaperPlotR export calls.
- Templates and the skill entrypoint do not contain project-specific paths or default domain rules.
- The smoke test script covers every template.

Expected success line:

```text
paperplot-skills validation passed
```

## How To Run Smoke Tests

Run the template smoke test from the PaperPlotR repository root:

```bash
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

The script creates temporary CSV inputs and temporary output directories under `tempdir()`. It does not write smoke artifacts into the repository.

Each template is copied to a temporary location, patched with generic column names and temporary paths, then executed with `Rscript`. The smoke test checks that every template produces at least:

- one PDF
- one PNG
- one notes file

It also checks the notes contain output file records, byte sizes, PaperPlotR functions, and preset information.

Expected success line:

```text
8/8 templates passed smoke tests
```

## Template Outputs

Every R template is expected to generate a timestamped output stem:

```text
<output_dir>/<figure_id>_<YYYYMMDD-HHMMSS>
```

Typical files:

```text
figure_id_YYYYMMDD-HHMMSS.pdf
figure_id_YYYYMMDD-HHMMSS.png
figure_id_YYYYMMDD-HHMMSS.svg
figure_id_YYYYMMDD-HHMMSS_notes.md
```

SVG output is optional and depends on `svglite`. PNG may use `ragg` when available. Publication-grade tasks should include at least one vector format such as PDF or SVG.

## File Structure

```text
paperplot-skills/
  SKILL.md
  README.md
  references/
  templates/
  examples/
  scripts/
```

`references/` contains workflow rules and QA guidance. `templates/` contains reusable R script skeletons. `examples/` contains example prompts, final report format, and a GitHub-ready review checklist. `scripts/` contains validation and smoke test utilities.

## Adapting Templates

Start by copying one template into a task-specific output or analysis directory. Then update:

- `input_path`
- `output_dir`
- `figure_id`
- column names
- axis labels and units
- palette or semantic color mapping
- export preset
- notes content

Keep these rules:

- Use complete runnable R scripts.
- Keep timestamped `output_stem` logic.
- Keep `stop_if_outputs_exist()` or equivalent no-overwrite protection.
- Use PaperPlotR helpers where they match the task.
- Record output files and file sizes in notes.
- Do not introduce project-specific data, paths, or default domain dictionaries.
- Prefer small, testable refinements over large visual rewrites.

## GitHub Readiness Checklist

Before publishing or opening a pull request:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
find paperplot-skills -type f | sort
git status --short -- paperplot-skills
git status --short -- . ':!paperplot-skills'
```

Pass criteria:

- Static validation passes.
- 8 of 8 templates pass smoke tests.
- All new skill files are inside `paperplot-skills/`.
- No smoke test outputs are written to the repository.
- The skill remains generic and does not default to a project-specific dictionary.
- Existing PaperPlotR package files are not modified by the skill validation process.

The first GitHub-ready commit should normally contain only `paperplot-skills/`. Add repository integration such as GitHub Actions, main README links, pkgdown links, or release notes in a later commit.

## Contribution Rules

When changing this skill:

- Do not modify `R/`, `man/`, `tests/`, `vignettes/`, `DESCRIPTION`, `NAMESPACE`, package `README.md`, or pkgdown files unless the task explicitly includes package integration.
- Keep all skill-specific assets under `paperplot-skills/`.
- Add or update smoke coverage when adding a template.
- Do not invent PaperPlotR APIs. Inspect the package first and use existing functions.
- Keep the skill general. Domain-specific dictionaries are optional extensions only and must require explicit user intent.
- Avoid default ggplot gray styling, rainbow palettes, red-green contrast, and decoration that does not clarify the science.
- Preserve no-overwrite behavior and sidecar notes in every runnable template.

## Keeping The Skill General

PaperPlotR may include optional domain examples in the R package. This skill must not use those as defaults. For general scientific plotting, prefer generic palettes or user-provided semantic color mappings. Only use a domain-specific dictionary when the user explicitly asks for that domain or provides a mapping.
