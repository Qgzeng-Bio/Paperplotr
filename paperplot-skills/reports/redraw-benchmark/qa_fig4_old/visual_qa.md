# Visual QA

- input: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/10-GS/final_results/figures/fig4_quality_traits.png`
- engine: `pillow`
- status: `warn`
- manuscript readiness score: `6/10`

## Key metrics

- image_size_px: `[2055, 649]`
- aspect_ratio: `3.1664`
- blank_margin_fraction: `0.0759`
- content_density: `0.2417`
- text_burden_score: `74.98`
- color_count_estimate: `11`
- grayscale_std: `65.94`
- line_burden: `{'horizontal_line_rows': 83, 'vertical_line_cols': 293, 'line_burden_score': 0.3176}`

## Top risks

- `warn` `extreme_aspect_ratio`: Aspect ratio is likely to create readability or layout problems. (3.166)
- `warn` `grayscale_discrimination_risk`: Some colored classes may be hard to distinguish in grayscale. (3.9)
- `warn` `gridline_or_long_line_burden`: Many long horizontal/vertical line structures detected. (0.3176)
- `warn` `thumbnail_readability_risk`: Thumbnail view is visually dense; labels may fail at reduced size. (0.299)
