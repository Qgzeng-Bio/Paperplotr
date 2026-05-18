# Install

This skill is standalone. It does not require the PaperPlotR R package.

## Codex Skill Link

Link this directory into the Codex skills directory:

```bash
mkdir -p ~/.codex/skills
ln -sfn "/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr/paperplot-skills" ~/.codex/skills/paperplot-skills
```

## R Requirement

Templates require `ggplot2`.

```r
install.packages("ggplot2")
```

## Validate

From the repository-local skill parent directory:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```
