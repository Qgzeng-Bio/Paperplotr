# Visual perception QA

Rendered-image QA is mandatory after a figure is generated. Code, metadata, and sidecars can prove reproducibility, but they cannot prove that the rendered figure is readable.

## Visual QA Engine

Use `scripts/visual-qa-rendered-image.py` for deterministic image checks.

```bash
python3 scripts/visual-qa-rendered-image.py <image_or_output_dir> --out <qa_dir>
```

The engine accepts PNG/JPG/JPEG/SVG/PDF. PNG/JPG inputs are inspected directly. PDF inputs are rendered with `pdftoppm`; SVG inputs are rendered with ImageMagick when possible and fall back to a simple Pillow/XML renderer if local fonts prevent ImageMagick from drawing text. SVG structural checks are retained as supplemental evidence.

Useful options:

```bash
python3 scripts/visual-qa-rendered-image.py figure.pdf --out qa --dpi 300 --page 1
python3 scripts/visual-qa-rendered-image.py figure.svg --out qa --ocr auto
python3 scripts/visual-qa-rendered-image.py figure.png --out qa --expected-panels 2 --layout-profile equal
python3 scripts/visual-qa-rendered-image.py figure.pdf --out qa --strict-nature
```

OCR is optional. `--ocr auto` uses Tesseract if present and records `ocr.available=false` if not. `--ocr required` is for strict testing only.

## Raster checks

The engine records:

- image size and aspect ratio,
- content bounding box,
- blank margin fraction,
- content density,
- approximate text/mark density from connected components,
- dominant colors,
- saturation burden,
- grayscale contrast and color luminance risks,
- long-line/gridline burden,
- thumbnail readability risk,
- manuscript-readiness score.

## Panel Geometry Checks

When `--expected-panels` is provided, the engine estimates panel boxes from whitespace gutters and content masks. It records:

- detected panel count,
- panel box and content box for each panel,
- panel-area max/min ratio,
- content-area max/min ratio,
- panel and content area coefficient of variation,
- blank-space range across panels.

For `--layout-profile equal`, unequal panel boxes or data regions trigger `panel_size_imbalance` or `panel_data_region_imbalance`. For `--layout-profile hierarchical`, very strong size hierarchy triggers `unjustified_panel_hierarchy_risk` unless the layout is explicitly justified in notes.

## Nature Guardrails

Use `references/nature-figure-guardrails.md` for the ten final rendered-figure checks. With `--strict-nature`, hard guardrail hits return a non-zero exit status and set `nature_guardrails.status=fail` in `visual_qa.json`.

Strict mode is for final candidates, not early sketches. It catches exported-size problems, text overlap, excess whitespace, unreadable thumbnails, and multi-panel imbalance before the agent reports a figure as manuscript-ready.

## SVG checks

SVG structural checks are supplemental to raster QA. They record:

- canvas size,
- text count,
- min/median/max font sizes,
- large centered title risk,
- line count and light gridline count,
- rect/bar count,
- presentation-style risk.

## Hard rule

Do not claim manuscript-ready status from metadata alone. If visual QA returns `warn` or `fail`, report the top risks and either revise the figure or explicitly state why the risk is accepted.
