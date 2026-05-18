# Cross-backend workflows

The core implementation is R/ggplot2, but users may ask for Python or editing workflows.

## R / ggplot2

Default backend. Use `scripts/paperplot_helpers.R`, specs, metadata, notes, QA, PDF and PNG export.

## Python / matplotlib / seaborn

Use only when the user explicitly asks for Python or the analysis pipeline is already Python-native. Preserve the same design contract: design brief, metric semantics, visible-vs-metadata split, PDF/PNG, notes, metadata, QA.

Recommended matplotlib settings:

```python
import matplotlib as mpl
mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42
mpl.rcParams['font.family'] = 'Arial'
```

Use seaborn as a convenience layer, not as a style authority. Override default palettes, grids, font sizes, and legends to match manuscript standards.

## Illustrator / SVG / PDF finishing

Use vector PDF/SVG for final editing. Keep text editable, preserve layers when possible, avoid outlined text, and do not use Illustrator to hide scientific uncertainty. Any manual edits must be documented in notes.

## When to advise but not redraw

Only give advice when:

- the user provides an image but no data/code and asks for critique,
- specialized data structures are missing,
- statistical assumptions are unknown,
- redraw would risk scientific misrepresentation.
