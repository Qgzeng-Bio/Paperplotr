# Visual QA

- input: `paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png`
- engine: `pillow`
- status: `warn`
- manuscript readiness score: `9/10`

## Key metrics

- image_size_px: `[2102, 1937]`
- aspect_ratio: `1.0852`
- blank_margin_fraction: `0.0739`
- content_density: `0.0736`
- text_burden_score: `35.37`
- color_count_estimate: `8`
- grayscale_std: `33.32`
- line_burden: `{'horizontal_line_rows': 65, 'vertical_line_cols': 3, 'line_burden_score': 0.0393}`

## Top risks

- `warn` `gridline_or_long_line_burden`: Many long horizontal/vertical line structures detected. (0.0393)
