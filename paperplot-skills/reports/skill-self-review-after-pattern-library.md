# Skill self-review after pattern-library upgrade

## What Is More Professional Now

- The skill now has a concrete pattern library instead of only general style rules. The figure-type selector can route data and scientific questions to pattern-specific design documents.
- The replica-library index records case language, output types, code/data formats, likely figure family, template suitability, visual-QA suitability, dependency complexity, and generalization risks.
- Visual QA is calibrated against positive examples from the replica libraries. The calibration report shows that many high-quality figures still trigger `warn`, so warnings are treated as review prompts rather than automatic failure.
- `SKILL.md` now requires a full redraw workflow: detect figure family, consult pattern docs, generate design brief/plan, render, run visual QA, run old-vs-new comparison, and iterate when the new result is not better.
- Templates and helper metadata now carry pattern references, making figure outputs auditable back to reusable design guidance.
- Real benchmark redraws were produced for two user-flagged figures, including old QA, new QA, old-vs-new comparison, human aesthetic review, and residual risks.

## Rules Still Too Vague

- The boundary between "clean low-density manuscript panel" and "too sparse to communicate enough evidence" is still partly subjective.
- The current selector can detect common column-role patterns, but it cannot fully infer scientific intent when dataset names are ambiguous.
- Multi-panel hierarchy rules define panel label and spacing norms, but they still need more concrete examples for figure assemblies with mixed heatmap/tree/scatter panels.
- Statistical-expression guidance is stronger than before, but it still depends on users or upstream code to clarify whether intervals represent SD, SE, CI, posterior intervals, or bootstrap ranges.

## Patterns Not Fully Absorbed Yet

- Phylogenetic annotation rings and circos/chord/sankey patterns are documented, but no standalone template was added because they need specialized data structures and dependencies.
- Manhattan plots are documented but still lack a template in this iteration.
- UpSet/set summaries are documented but not yet implemented as a stable base-R/ggplot2 template.
- Model validation has a stronger pattern document and one benchmark redraw, but the skill would benefit from a dedicated composite template for calibration/residual/performance views.
- Spatial/map examples were indexed but not promoted into first-class pattern docs because this round focused on plot families most relevant to existing templates.

## Templates Still Too Ordinary

- `comparison-boxplot-template.R` and `grouped-boxplot-jitter-template.R` are better after style tightening, but they still read as conventional ggplot panels rather than fully composed manuscript panels when used alone.
- `heatmap-template.R` now reduces tile-border burden, but it still lacks dendrogram/annotation-strip strategy and family-specific label compression.
- `pca-scatter-template.R` is cleaner, but confidence ellipse, marginal, and loading/vector variants remain out of scope.
- `bio-genome-quality-overview-template.R` and `bio-duplication-mode-comparison-template.R` still need stronger pattern-document links in their output notes and clearer main-vs-supplement density defaults.

## Visual QA Misjudgments

- Positive-library calibration produced mostly `warn`, not `pass`, showing that deterministic QA is deliberately conservative but can over-warn on high-quality dense panels.
- Heatmaps, Manhattan plots, phylogenetic trees, UpSet matrices, and multi-panel figures need family-specific interpretation; global thresholds alone will misclassify legitimate density.
- Old-vs-new comparison can mislead when SVG structural QA is compared against raster QA. A correction was added to flag mixed SVG/raster comparisons as a limitation.
- Content density can be a false negative for minimal point-range or lollipop redesigns: less ink can be an improvement even when deterministic density decreases.

## Old-vs-New Evidence

- The genomic selection benchmark improved manuscript-readiness from 6 to 10 and reduced text/line burden substantially, but deterministic verdict remained `mixed` because blank margin and content density worsened.
- The NLR benchmark improved manuscript-readiness from 5 SVG / 6 PNG to 9 and reduced grid/line/color burden, but deterministic verdict remained `mixed` because label burden and density metrics are not universally aligned with aesthetic quality.
- The old-vs-new tool is useful as a gate against obvious regressions, but it cannot prove scientific correctness or decide all composition tradeoffs without human review.

## Unsuitable Replica Cases

- Cases that mainly reproduce decorative circular layouts, highly bespoke annotations, or journal-specific visual effects are useful as inspiration but unsuitable as direct templates.
- Cases requiring large specialized dependency stacks should remain references unless the data structure and dependency contract can be made explicit.
- Cases with presentation-like titles, ornamental gradients, excessive annotation, or hard-coded image geometry should not be promoted as positive style examples.
- PDF-only cases need a rasterization path before they can contribute reliable calibration metrics.

## Highest-Priority Next Iteration

1. Add family-specific QA thresholds for heatmap, rank/lollipop, model-validation, tree, and Manhattan families.
2. Add a Manhattan template and a model-validation composite template before attempting specialized circos/tree templates.
3. Improve template output notes so each generated figure records pattern family, statistical interval meaning, intended manuscript role, and old-vs-new verdict.
4. Add a PDF rasterization backend to visual QA calibration so PDF-only positive examples are not excluded.
5. Add a compact human-review rubric for `mixed` old-vs-new cases so users know exactly what must be checked manually.

## Correction Applied After Review

- `compare-old-new-figures.py` now records `old_media`, `new_media`, and `comparison_limitation` for mixed SVG/raster comparisons. This prevents a structural SVG QA result from being interpreted as directly equivalent to raster density/text/color metrics.
- `references/old-vs-new-visual-scoring.md` and `references/visual-qa-gates.md` now explicitly say that density and mixed-media comparisons require family-specific and human review.

## Remaining Risk

The skill is now more design-system-like than rule-list-like, but it is not a fully learned visual model. The pattern library gives stronger defaults and QA discipline; final manuscript judgment still requires scientific context, caption semantics, and sometimes human visual review.
