# Nature-Like Style Principles

Nature-like means restrained scientific hierarchy, not copying Nature figures. The style is quiet, information-dense when needed, and strongly documented.

## Core Principles

- Evidence first: raw data, uncertainty, or matrix structure should be visible where it matters.
- Hierarchy over decoration: size, position, and contrast show importance.
- Typography discipline: small but readable text, consistent panel labels, no presentation-scale titles.
- Palette economy: few stable colors; neutral background marks; continuous scales with interpretable direction.
- Export fidelity: vector PDF plus rendered PNG QA.

## Common Positive Patterns From The Replica Libraries

- Grouped comparisons look more credible when bars are paired with raw dots or clear intervals.
- Raincloud/violin figures work when raw points remain visible and density is secondary.
- Scatter composites work when marginal or residual panels support the main relationship rather than compete with it.
- Heatmaps work when ordering, scale, and annotation strips are intentional.
- Ordination figures work when method, distance, explained variance/stress, and group semantics are explicit.
- Volcano/enrichment panels work when background features are muted and highlighted labels are selective.
- Multi-panel figures work when one panel is clearly primary and legends are shared.

## Anti-Patterns To Avoid

- Decorative circular layouts without circular data semantics.
- Gradient backgrounds behind statistical displays.
- Direct labels for every sample, gene, term, or row.
- Dual y-axes used only to save space.
- Repeated legends or titles in every panel.
- P-value stars replacing effect size and uncertainty.
- One plot mixing heterogeneous metric units.

## Family-Specific Tolerance

- Heatmaps, Manhattan plots, and tree rings may have high deterministic density; evaluate them against their family pattern.
- Distribution plots should not have high text burden; if they do, labels or annotations are wrong.
- Scatter/regression plots should keep line burden low unless error bars are central evidence.
- Multi-panel figures can be dense, but the primary panel must remain readable at thumbnail scale.

## Redraw Standard

A redraw is successful only when it:

- preserves the scientific data roles;
- follows the selected pattern-library document;
- improves or justifiably trades off visual QA metrics;
- passes old-vs-new review or records the remaining failure honestly;
- writes notes, metadata, and sidecars for all simplifications.
