# Install

This skill is standalone. It does not require the PaperPlotR R package.

## Skill Links (Codex + Claude Code)

Link this directory into the agent skill directories. Run from inside the
`paperplot-skills/` directory so the path resolves relative to the repo —
do not hardcode a machine-specific absolute path.

```bash
SKILL_DIR="$(pwd)"   # run from the paperplot-skills/ directory
mkdir -p ~/.codex/skills ~/.claude/skills
ln -sfn "$SKILL_DIR" ~/.codex/skills/paperplot-skills
ln -sfn "$SKILL_DIR" ~/.claude/skills/paperplot-skills
```

## Dependencies

### R (required)
```r
install.packages(c("ggplot2", "dplyr", "tidyr", "readr",
                   "scales", "patchwork", "cowplot", "ggrepel"))
```

### R (recommended for robust raster/font export)
`ragg`, `systemfonts`, `textshaping` — used for the `ragg` PNG/TIFF device and
font resolution. Without them the skill falls back to the default device.
```r
install.packages(c("ragg", "systemfonts", "textshaping"))
```

### Python (required for visual QA)
```bash
python3 -m pip install pillow numpy pandas pypdf
```

### System tools
- `pdftoppm`, `pdftotext` (poppler) — PDF rasterization / text extraction.
- `magick` (ImageMagick) — optional; preferred SVG rasterizer. A built-in
  Pillow fallback runs when it is absent, so SVG QA still works without it.
- `tesseract` — optional OCR (`--ocr auto` degrades gracefully when missing).

On conda systems (conda-forge):
```bash
# Use conda, mamba, or micromamba depending on the local environment.
micromamba install -c conda-forge \
  r-ggplot2 r-dplyr r-tidyr r-readr r-scales r-patchwork r-cowplot r-ggrepel \
  r-ragg r-systemfonts r-textshaping poppler imagemagick
```

## Fonts

The default theme targets Arial/Helvetica. `pp_resolve_family()` automatically
falls back to Liberation Sans / DejaVu Sans / generic `sans` when Arial is not
installed, and PDF export uses `cairo_pdf` on non-macOS so the chosen font
renders without the PostScript-font-database error. No manual font setup is
required; installing `msttcorefonts` (real Arial) is optional for exact fidelity.

## Validate

From the repository-local skill parent directory:

```bash
PAPERPLOT_RSCRIPT=${PAPERPLOT_RSCRIPT:-Rscript}
PAPERPLOT_PYTHON=${PAPERPLOT_PYTHON:-python3}

"$PAPERPLOT_RSCRIPT" paperplot-skills/scripts/validate-skill.R
"$PAPERPLOT_RSCRIPT" paperplot-skills/scripts/smoke-test-templates.R
"$PAPERPLOT_RSCRIPT" paperplot-skills/scripts/run-pressure-scenarios.R
"$PAPERPLOT_PYTHON" paperplot-skills/scripts/run-visual-pressure-scenarios.py
"$PAPERPLOT_PYTHON" paperplot-skills/scripts/validate-qa-coverage.py
```

Set `PAPERPLOT_RSCRIPT` or `PAPERPLOT_PYTHON` when the default `Rscript` /
`python3` on `PATH` is not the environment with the required packages.

`validate-qa-coverage.py` is a self-audit: it fails if any visual-QA risk code
lacks a remediation entry (or explicit informational exemption) or points at a
missing reference doc — keeping the audit/how-to-fix mapping from rotting.
