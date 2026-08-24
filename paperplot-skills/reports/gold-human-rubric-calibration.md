# Gold Human Rubric Calibration

Source scores: `paperplot-skills/reports/gold-human-rubric-pack/gold-human-rubric-scoring.csv`
Completed cases: 30
Global mean score: 3.8
Positive calibration cases: 24
Caution/baseline cases: 6

## Family Profiles

| Family | n | Mean | Positive | Caution | Positive eligible |
|---|---:|---:|---:|---:|---|
| `bar/errorbar` | 2 | 4.0 | 2 | 0 | True |
| `circos/chord/sankey` | 2 | 4.0 | 2 | 0 | True |
| `heatmap` | 5 | 4.0 | 5 | 0 | True |
| `lollipop/dumbbell/dotplot` | 1 | 4.0 | 1 | 0 | True |
| `map/spatial` | 4 | 4.0 | 4 | 0 | True |
| `multi-panel` | 1 | 4.0 | 1 | 0 | True |
| `ordination` | 6 | 3.0 | 0 | 6 | False |
| `phylo/tree` | 1 | 4.0 | 1 | 0 | True |
| `ridgeline/density` | 1 | 4.0 | 1 | 0 | True |
| `scatter/regression` | 1 | 4.0 | 1 | 0 | True |
| `upset/set` | 1 | 4.0 | 1 | 0 | True |
| `violin/raincloud` | 2 | 4.0 | 2 | 0 | True |
| `volcano/enrichment` | 3 | 4.0 | 3 | 0 | True |

## Human Calibration Notes

### ordination
- Human gold scores did not support this family as a high-quality positive calibration source.
- User judged the current PCA/PCoA/ordination gold examples as readable but visually generic; ordinary ordination plots should not be treated as Nature-like positive exemplars without stronger hierarchy, marginal/statistical context, or refined layout.

## Skill Behavior

- Families with positive examples can be used as positive visual calibration sources.
- Families without positive examples should remain baseline/caution references until better examples are scored.
- For ordination, ordinary PCA/PCoA layouts should not be scored as high Nature-like exemplars merely because they are readable.
