# Image-level failure modes

The visual QA layer is designed to catch common low-quality scientific-figure patterns.

## Common failures

| failure | symptoms | action |
|---|---|---|
| oversized title | large centered title, presentation-style typography | move title to caption or reduce to panel label |
| excessive blank space | large unused margins or detached legends | crop, resize, or redesign layout |
| dense axis labels | many small components near axis | abbreviate, rank-index, rotate sparingly, or use sidecar |
| label overlap risk | high text component density or repeated labels | select key labels only; use sidecar |
| saturated palette | high-saturation dominant colors | use muted functional palette |
| poor grayscale robustness | colored classes have similar luminance | add shape/position/labels or adjust palette |
| gridline burden | many long line structures | remove or lighten gridlines |
| diagnostic-looking layout | high burden, large title, weak hierarchy | redesign as manuscript panel |
| old rhythm destroyed | new plot has worse burden/readiness than old | refine rather than rebuild |
| strict Nature failure | `nature_guardrails.status=fail` under `--strict-nature` | revise before reporting manuscript readiness |

## Limits

OCR is optional and may be unavailable, so exact text bounding-box overlap detection is environment-dependent. The QA layer provides stable quantitative signals that must be combined with metadata QA and human/agent visual review.
