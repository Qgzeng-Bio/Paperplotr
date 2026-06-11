# Manuscript Readiness Rubric

A manuscript-ready figure needs no hard failures and enough design quality to support the scientific message.

## Score Dimensions

| Dimension | Points |
|---|---:|
| Scientific message clarity | 0-2 |
| Data and metric semantics | 0-2 |
| Visual hierarchy | 0-2 |
| Label and legend burden | 0-2 |
| Statistical expression | 0-1 |
| Reproducibility metadata | 0-1 |

## Thresholds

| Figure role | Requirement |
|---|---|
| Main | no hard fail and score >= 8 |
| Supplement | no hard fail and score >= 7 |
| Diagnostic | no hard fail; role must be explicit |

Final manuscript candidates must also pass rendered-image QA with `nature_guardrails.status` equal to `pass`, or `warn` only when the accepted risk is justified in notes and metadata. A `--strict-nature` failure is not manuscript-ready.

## Hard Failure Examples

- Missing design brief.
- Missing design plan.
- Missing label key for rank-index label strategy.
- Visible figure is dominated by lookup labels.
- Paired or connecting lines used without pairing/order semantics.
- Palette semantics are inconsistent across panels.
- Strict Nature guardrails fail for text/element overlap, excessive blank space, unreadable thumbnail structure, or multi-panel imbalance.
