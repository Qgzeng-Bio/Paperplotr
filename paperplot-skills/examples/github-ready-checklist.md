# paperplot-skills GitHub-Ready Checklist

Use this checklist before publishing `paperplot-skills` or opening a pull request. It is a manual and agent review guide, not an automatically generated test result.

## Structural Validation

- [ ] `paperplot-skills/SKILL.md` exists and starts with valid frontmatter.
- [ ] `name: paperplot-skills` is present.
- [ ] `description` is present and under 1024 characters.
- [ ] `README.md`, `references/`, `templates/`, `examples/`, and `scripts/` are present.
- [ ] `Rscript paperplot-skills/scripts/validate-skill.R` passes.

## Smoke Test Matrix

Run:

```bash
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

Expected result:

```text
8/8 templates passed smoke tests
```

Template matrix:

| Template | Runs | PDF | PNG | Notes | Notes include bytes | Notes include preset |
| --- | --- | --- | --- | --- | --- | --- |
| `single-panel-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `multi-panel-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `comparison-boxplot-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `violin-dot-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `correlation-scatter-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `heatmap-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `pca-scatter-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| `barplot-template.R` | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

## Genericity Check

- [ ] Templates do not contain local machine paths.
- [ ] Templates do not contain project-specific default data names.
- [ ] `SKILL.md` does not make domain-specific dictionaries default behavior.
- [ ] Optional domain extensions are described as opt-in only.
- [ ] Template examples use generic scientific column names.

## PaperPlotR API Check

- [ ] Templates load `ggplot2` and `PaperPlotR`.
- [ ] Templates use `theme_lab()`.
- [ ] Templates use `scale_*_lab()` or `scale_*_groupmap()` when color mapping is relevant.
- [ ] Multi-panel templates use `layout_lab()` when composition is needed.
- [ ] Exports use `save_lab()` or `save_lab_plot()`.
- [ ] No template calls a PaperPlotR function unless it exists in the package.

## Export/Versioning Check

- [ ] Every template defines `timestamp`.
- [ ] Every template defines `output_stem`.
- [ ] Every template defines `notes_path`.
- [ ] Every template refuses to overwrite existing outputs.
- [ ] Every template writes output file paths and byte sizes to notes.
- [ ] Publication-grade workflows include at least one vector format.

## Boundary/Non-Goal Check

- [ ] The skill clearly rejects mechanism diagrams, pathway cartoons, graphical abstracts, flowcharts, interactive charts, image generation, and Python-only plotting as default PaperPlotR tasks.
- [ ] The skill directs non-ggplot scientific diagrams to more appropriate tools.
- [ ] The skill does not claim to replace ggplot2.
- [ ] The skill frames PaperPlotR as a standardization and export workflow.

## Remaining Known Limitations

- [ ] Smoke tests verify files and notes, but they do not perform pixel-level visual review.
- [ ] The templates are generic skeletons and still require task-specific axis labels, units, statistics, and captions.
- [ ] The skill does not validate statistical correctness automatically.
- [ ] CI integration is optional and can be added later after the skill artifact is stable.
