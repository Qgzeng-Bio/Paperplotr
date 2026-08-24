# Visual Detail QA Spec

`scripts/visual-qa-rendered-image.py` performs deterministic detail QA in addition to global raster QA. Detail QA is a review trigger, not a replacement for scientific judgment.

## CLI

```bash
python3 scripts/visual-qa-rendered-image.py figure.pdf --out qa \
  --target-width-mm 89 \
  --journal-profile nature \
  --strict-detail-qa \
  --allow-grid auto \
  --expected-font-range 5,7
```

## Output Nodes

- `text_geometry`: connected-component and optional OCR signals for text burden, edge label burden, tick-label collision, and text/data overlap.
- `stroke_geometry`: long-line projection and vector stroke-width signals for heavy or missing structural strokes.
- `grid_background`: interpretation of long horizontal/vertical structures as acceptable family structure or grid burden.
- `legend_geometry`: edge-ink concentration used to detect legends, titles, or labels dominating the data region.
- `panel_detail_geometry`: data-region equality, median internal blank fraction, and panel padding risks.
- `vector_structure`: SVG or PDF vector-side evidence when extractable.
- `vector_text_geometry`: true SVG/PDF text boxes when available, including overlap count and data-region intrusion.
- `vector_stroke_geometry`: true SVG stroke-width distribution and PDF content-stream stroke-width distribution when available.
- `vector_layout_geometry`: edge text, right legend text, top title text, and data-region text intrusion from vector boxes.
- `font_size_pt_distribution`: true SVG/PDF text-size distribution when available.
- `stroke_width_pt_distribution`: true SVG stroke-width distribution or effective PDF stroke-width distribution when available.
- `font_assessment`: vector font-size review when SVG/PDF text structure is available; raster inputs report heuristic-only status.
- `nature_detail_rubric`: combined detail status, strictness settings, and hard-fail risk codes.

## Risk Codes

- `text_data_overlap_risk`: labels or annotations likely collide with data marks.
- `tick_label_collision_risk`: tick/category labels are likely crowded or colliding.
- `axis_title_collision_risk`: edge text burden suggests axes, ticks, or legends are competing for space.
- `significance_annotation_overcrowding`: brackets/stars/top labels compress the data region.
- `presentation_title_risk`: centered title-like text is too large for a manuscript panel.
- `font_too_small_at_target_width`: vector text is below manuscript target readability.
- `font_too_large_for_manuscript`: vector text is presentation-sized.
- `vector_text_overlap`: true vector text boxes overlap enough to suggest label collision.
- `vector_tick_collision`: true vector text boxes concentrate at plot edges enough to suggest tick/axis collision.
- `vector_font_out_of_range`: true vector font sizes are outside manuscript-style range.
- `vector_stroke_out_of_range`: true vector stroke widths are outside manuscript-style range.
- `vector_legend_oversized`: right-edge vector text suggests an oversized legend or side label block.
- `vector_title_presentation_style`: centered/large vector title looks like a slide title rather than a manuscript panel label.
- `stroke_too_heavy`: strokes, grids, borders, or connectors dominate the data layer.
- `stroke_too_light`: structural strokes are likely too faint or absent.
- `grid_background_burden`: background or structural long lines burden the figure.
- `legend_dominates_panel`: edge legend/title/label ink competes with the data region.
- `panel_data_region_mismatch`: equal-role panels have materially different data-region sizes.
- `excessive_panel_padding`: panel content is too small relative to available panel area.
- `decorative_background_risk`: reserved for future detection of gradients, shadows, and decorative backgrounds.

## Interpretation

- `--strict-detail-qa` promotes severe overlap and panel mismatch problems to hard failures.
- Heatmaps, Manhattan plots, tree rings, maps, and circular plots require family-specific interpretation before failing line/grid density.
- For PNG, font and stroke results are estimates. For SVG, font-size and stroke-width values are direct structural evidence. For PDF, text bbox/font-size extraction uses `pdftotext -bbox` when available, and stroke/path evidence uses `pypdf` content-stream parsing when available.
- PDF stroke parsing records `pdf_stroke_event_count`, `grid_candidate_count`, `rect_stroke_count`, `line_stroke_count`, and `curve_stroke_count`. Effective PDF stroke width is estimated from the current line width and graphics transform scale.
- Run `scripts/family-qa-score.py` after rendered-image QA when a figure-family interpretation is needed. The family score prevents heatmaps, tree rings, and other specialized layouts from being failed by ordinary statistical-plot thresholds.
- Old-vs-new comparison must treat detail regressions as blocking evidence unless a human review JSON documents a deliberate hierarchy or scientific reason.
