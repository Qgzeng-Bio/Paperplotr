# Old-vs-new figure comparison

Use this whenever the user provides an existing figure to optimize.

## Redesign modes

| mode | use when | action |
|---|---|---|
| preserve_structure | old figure has strong rhythm; issues are labels, legend, palette, export | keep layout, fix details |
| refine_structure | message is clear but layout density or labels need improvement | keep main encoding, adjust structure |
| recompose | panel hierarchy or figure story is weak | reorganize panels |
| rebuild | chart type/statistics are misleading | redesign from data |
| diagnostic_only | goal is data checking | prioritize complete labels over aesthetics |

## Comparison table

Record:

| item | old | new | verdict |
|---|---|---|---|
| scientific message | | | better/same/worse |
| label burden | | | |
| legend burden | | | |
| panel hierarchy | | | |
| statistical expression | | | |
| color semantics | | | |
| visual rhythm | | | |
| text/data overlap | | | |
| target-size typography | | | |
| stroke and grid burden | | | |
| legend discipline | | | |
| manuscript readiness | | | |

## Hard rules

- Do not preserve connecting lines unless they encode paired, repeated, ordered, or trajectory semantics.
- Do not convert dense x labels into a y-axis label dump unless identity is the primary message.
- Do not destroy useful rhythm just to satisfy a mechanical QA rule.
- If old figure is aesthetically stronger, say so and iterate.
- If the new figure has severe `nature_detail_rubric` failures, do not call it improved.
- If the new figure has family-specific blocking risks from `scripts/family-qa-score.py`, do not call it improved until the blocking risk is fixed or explicitly justified as a deliberate specialized layout.
- If the new figure reduces clutter but removes units, n, error type, thresholds, normalization, or transformation, do not call it improved.
- If the new figure makes equal-role panels less comparable in data-region size, do not call it improved unless a human review JSON documents deliberate hierarchy.
- Without `--review-json`, old-vs-new can at most return `deterministic_better_pending_human_review`; it cannot prove final scientific improvement.

## Detail QA Deltas

`compare-old-new-figures.py` compares these detail metrics when available:

- `text_geometry.ocr_overlap_pair_count`
- `text_geometry.edge_text_like_fraction`
- `grid_background.long_line_count`
- `legend_geometry.edge_content_fraction`
- `stroke_geometry.line_burden_score`
- `vector_text_geometry.text_box_overlap_count`
- `vector_layout_geometry.text_box_data_region_intrusion`
- `font_size_pt_distribution`
- `stroke_width_pt_distribution`
- `nature_detail_hard_fail_count`

Improvement requires the new figure to avoid hard detail failures while preserving scientific completeness.

## Recommended Non-Human QA Sequence

```bash
python3 scripts/visual-qa-rendered-image.py old.png --out qa/old --target-width-mm 89 --journal-profile nature
python3 scripts/visual-qa-rendered-image.py new.png --out qa/new --target-width-mm 89 --journal-profile nature
python3 scripts/family-qa-score.py --qa-json qa/new/visual_qa.json --out qa/new/family_qa.json
python3 scripts/compare-old-new-figures.py old.png new.png --out qa/compare
```

The family score is especially important when the old and new plots belong to heatmap, ordination, enrichment, multi-panel, or specialized families, where global thresholds alone can misread legitimate structure.
