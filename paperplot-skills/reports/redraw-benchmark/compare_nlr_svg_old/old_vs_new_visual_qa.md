# Old-vs-new visual QA

- old: `/Users/qingguozeng/Documents/1-博士课题/1-藜麦泛基因组/7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_count_by_sample.svg`
- new: `paperplot-skills/reports/redraw-benchmark/high_nlr_count_by_sample_pattern_redraw.png`
- media: `svg` -> `raster`
- verdict: `mixed`
- status: `warn`

## Metric deltas

| metric | old | new | delta |
|---|---:|---:|---|
| blank_margin_fraction | 0.0 | 0.0739 | worse |
| text_burden_score | 0.0 | 35.37 | worse |
| content_density | 0.0 | 0.0736 | improved |
| color_count_estimate | 0.0 | 8.0 | worse |
| thumbnail_content_density | 0.0 | 0.1322 | worse |
| line_burden_score | 0 | 0.0393 | worse |
| manuscript_readiness_score | 5 | 9 | improved |

## Remaining risks

- Mixed SVG/raster comparison: SVG structural QA does not expose the same raster density, text, and color metrics. Treat deterministic deltas as a review prompt.
- blank_margin_fraction worsened from 0.0 to 0.0739
- text_burden_score worsened from 0.0 to 35.37
- color_count_estimate worsened from 0.0 to 8.0
- thumbnail_content_density worsened from 0.0 to 0.1322
- line_burden_score worsened from 0 to 0.0393
