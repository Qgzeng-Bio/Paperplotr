# Family-Specific QA Scoring

`scripts/family-qa-score.py` adds a deterministic figure-family score on top of `visual_qa.json`. It is not a vision model. When `references/gold-human-calibration-rules.json` exists, it also reports whether the family is supported by local human gold-set scores as a Nature-like positive calibration source.

## Why This Layer Exists

A single global visual threshold is too crude for manuscript figures. A heatmap, a volcano plot, a two-panel comparison, and a tree-ring figure can all be publication-quality while having very different line density, label density, and legend structure.

The family score keeps the global `manuscript_readiness_score` but adds:

- family-specific risk weights;
- family-specific blocking risks;
- optional local human-calibrated positive-sample status;
- notes that separate deterministic visual evidence from scientific metadata that still requires data/code review.

## CLI

```bash
python3 scripts/family-qa-score.py \
  --qa-json qa/visual_qa.json \
  --out qa/family_qa.json \
  --out-md qa/family_qa.md
```

Use `--family` only when the figure family was not detected or was supplied incorrectly to rendered-image QA.
Use `--calibration-json` to point to a different local gold calibration file. By default the script reads `references/gold-human-calibration-rules.json` when present.

## Output

```json
{
  "family_qa": {
    "family": "scatter/regression",
    "score": 8.1,
    "status": "pass",
    "positive_calibration_status": "positive_gold_supported",
    "calibrated_positive_score": 8.1,
    "human_calibration": {
      "n": 2,
      "mean_score_1_5": 4.0,
      "positive_count": 2
    },
    "subscores": {
      "typography": 8.5,
      "stroke_grid": 8.0,
      "label_collision": 9.0,
      "panel_balance": 9.0,
      "legend_color": 8.0,
      "scientific_semantics": 8.0
    },
    "blocking_risks": [],
    "family_specific_notes": []
  }
}
```

## Scoring Dimensions

- `typography`: target-size font risks, presentation titles, oversized SVG/PDF text, thumbnail readability.
- `stroke_grid`: stroke width, grid burden, long-line burden, missing structural line risk.
- `label_collision`: text/data overlap, OCR/vector overlap, tick collision, significance overcrowding.
- `panel_balance`: panel box size, data-region balance, internal padding, blank-space imbalance.
- `legend_color`: legend dominance, color burden, grayscale risk, saturated presentation palettes.
- `scientific_semantics`: image-visible scientific information plus conservative notes for metadata that pixels cannot prove.

## Family Rules

### Bar / Errorbar

Strict on default grey grids, missing errorbar semantics, legend dominance, and p-value bracket overcrowding. Raw points or clear n/error metadata should be present in the plotting notes or caption.

### Violin / Raincloud

Strict on raw point visibility, small-n interpretation, significance overcrowding, and tick-label collisions. Light background grids are usually unnecessary.

### Scatter / Regression

Allows light quantitative grids when they materially improve reading. Strict on direct label collision, fit/CI readability, axis transform/unit semantics, and legend/data-cloud balance.

### Heatmap

Allows high line density and cell structure. Strict on row/column label burden, colorbar semantics, continuous palette meaning, and unreadable dense labels.

### PCA / PCoA / UMAP

Strict on sample-label overload, legend/data-cloud ratio, color/shape mapping discipline, and axis method or variance semantics.

Current gold-set calibration: the scored PCA/PCoA/ordination examples were judged readable but visually generic. Ordinary ordination plots should therefore be treated as baseline/caution examples, not high-quality Nature-like positive exemplars, unless they add stronger visual hierarchy, marginal/statistical context, or refined manuscript layout.

### Volcano / Enrichment

Strict on threshold semantics, label collisions, red/green dependence, effect/significance separation, and term label burden.

### Multi-Panel

Strict on equal-role panel box and data-region balance, duplicated legends/titles, panel label consistency, and accidental hierarchy.

### Forest / Effect-Size

Allows a small number of CI and reference lines. Strict on effect axis semantics, reference/zero line visibility, subgroup label burden, and interval readability.

### Lollipop / Dumbbell / Dotplot

Strict on default background grids, ordering semantics, direct label collision, and point/interval visibility. `grid_background_burden` is a family-level blocking risk.

### Manhattan / Genomewide

Allows high point density and threshold lines. Strict on chromosome label burden, significance threshold semantics, saturated class colors, and axis readability.

### Ridgeline / Density

Allows repeated density outlines. Strict on excessive overlap, unclear scale, and label collisions.

### Upset / Set

Allows matrix dots, connectors, and bar structures. Strict on set labels, bar labels, and matrix readability.

### Specialized Families

Tree rings, circos/chord/Sankey, maps, networks, genome tracks/synteny, radar, and polar plots output cautions instead of applying ordinary statistical-plot thresholds. Dense line structure is not automatically a fail, but typography, label readability, legend semantics, and scientific metadata still matter.

## Blocking Rules

The family score cannot be `pass` when any of these appear in a standard statistical family:

- `text_data_overlap_risk`
- `vector_text_overlap`
- `font_too_small_at_target_width`
- `panel_data_region_mismatch`
- `panel_size_imbalance`
- `panel_data_region_imbalance`
- `vector_font_out_of_range`
- family-specific blockers such as `grid_background_burden` for lollipop/dumbbell/dotplot figures

Heatmaps and specialized families downgrade many stroke/grid risks to cautions, but text overlap, unreadable typography, and severe panel mismatch still require review.

## Limits

The family score is deterministic. Human gold calibration changes positive-sample interpretation, not the underlying scientific truth of a plot. It cannot prove that units, n, error type, transformations, or thresholds are scientifically correct unless those are visible in the image or encoded in metadata. Use it as a manuscript QA layer, not as a substitute for data-backed review.
