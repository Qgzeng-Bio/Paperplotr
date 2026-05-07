# Installing paperplot-skills For Local Agents

`paperplot-skills` is a repository-local AI skill. It can be used directly from
this repository or installed into an agent-specific skill directory.

## Repository-Local Mode

No installation is required. Tell the agent:

```text
Use paperplot-skills/SKILL.md for this PaperPlotR scientific plotting task.
```

The agent should read:

1. `paperplot-skills/SKILL.md`
2. `paperplot-skills/references/template-selection-guide.md`
3. the relevant R template under `paperplot-skills/templates/`

## Codex

Recommended during development: symlink the skill into the Codex skill root.

```bash
mkdir -p ~/.codex/skills

ln -sfn \
  "/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr/paperplot-skills" \
  ~/.codex/skills/paperplot-skills
```

Then restart Codex or open a new session.

For a fixed copy instead of a live symlink:

```bash
mkdir -p ~/.codex/skills

rsync -a --delete \
  "/Users/qingguozeng/Documents/1-博士课题/8-Code/Codex/PaperPlotR/paperplotr/paperplot-skills/" \
  ~/.codex/skills/paperplot-skills/
```

## Claude Code

Claude Code can use the skill content even if it does not auto-discover this
directory. Use one of these routes:

- Keep the skill in the repository and explicitly tell Claude Code to read
  `paperplot-skills/SKILL.md`.
- Copy or symlink `paperplot-skills/` into your Claude skill or instruction
  directory if your local Claude setup supports skill discovery.
- Add a short project instruction that points PaperPlotR plotting tasks to
  `paperplot-skills/AGENTS.md`.

## OpenCode

OpenCode can use the skill as a repo-local instruction bundle. Add an instruction
or prompt such as:

```text
For PaperPlotR scientific figures, first read paperplot-skills/AGENTS.md.
```

If your OpenCode setup supports reusable instruction directories, copy or
symlink `paperplot-skills/` there.

## Generic CLI Agents

For agents without skill discovery, use the generic entrypoint:

```text
Read paperplot-skills/AGENTS.md before handling PaperPlotR plotting tasks.
```

The skill is designed to be readable as plain Markdown plus reusable R template
files. Automatic skill discovery is helpful, but not required.

## Validation After Installation

From the PaperPlotR repository root:

```bash
Rscript paperplot-skills/scripts/validate-skill.R
Rscript paperplot-skills/scripts/smoke-test-templates.R
```

Expected:

```text
paperplot-skills validation passed
8/8 templates passed smoke tests
```
