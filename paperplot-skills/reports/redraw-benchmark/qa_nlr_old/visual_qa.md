# Visual QA

- input: `<redacted-project-path>/high_nlr_count_by_sample.svg`
- engine: `svg-xml`
- status: `warn`
- manuscript readiness score: `5/10`

## Key metrics

- canvas_size: `[1100.0, 650.0]`
- text_count: `47`
- font_size_max: `22.0`
- light_gridline_count: `6`

## Top risks

- `warn` `oversized_svg_title_or_text`: SVG contains presentation-sized text. (22.0)
- `warn` `huge_centered_title`: Large centered title suggests presentation-style rather than manuscript panel style. (High-confidence NLR count by sample)
- `warn` `svg_gridline_burden`: Many light gridlines detected. (6)
