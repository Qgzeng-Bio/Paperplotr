# Visual perception QA

Rendered-image QA is mandatory after a figure is generated. Code, metadata, and sidecars can prove reproducibility, but they cannot prove that the rendered figure is readable.

## Visual QA v1 engine

Use `scripts/visual-qa-rendered-image.py` for deterministic image checks.

```bash
python3 scripts/visual-qa-rendered-image.py <image_or_output_dir> --out <qa_dir>
```

V1 requires Pillow for raster images and uses Python standard XML parsing for SVG. OpenCV, OCR, Tesseract, and vision models are future optional enhancements.

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

## SVG checks

SVG v1 is structural, not rasterized. It records:

- canvas size,
- text count,
- min/median/max font sizes,
- large centered title risk,
- line count and light gridline count,
- rect/bar count,
- presentation-style risk.

## Hard rule

Do not claim manuscript-ready status from metadata alone. If visual QA returns `warn` or `fail`, report the top risks and either revise the figure or explicitly state why the risk is accepted.
