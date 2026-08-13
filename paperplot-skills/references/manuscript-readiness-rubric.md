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

Final manuscript candidates must also have QA status `pass` recomputed from the complete common QA gate set, structurally valid and decoder-tested PDF/PNG media, and current-schema rendered-image QA using strict Nature guardrails. Strict validation verifies the tool fingerprint and reruns the bundled analysis against the current pixels; an edited/re-signed JSON record is not sufficient. `nature_guardrails.status=pass` is accepted directly; `warn` requires `visual_qa_review.status=accepted_warn`, `exception_recorded=true`, and a non-empty reason. A strict Nature `fail` is never manuscript-ready.

Candidate validator PASS proves output integrity only. It is not a manuscript-readiness score or warning. For bioinformatics figures, manuscript-ready also requires real-file/checksum/checklist-backed provenance `pass`; when a real old figure is declared, checksum-matched completed old-vs-new evidence must conclude `improved`.

## Hard Failure Examples

- Missing design brief.
- Missing design plan.
- Missing label key for rank-index label strategy.
- Visible figure is dominated by lookup labels.
- Paired or connecting lines used without pairing/order semantics.
- Palette semantics are inconsistent across panels.
- Strict Nature guardrails fail for text/element overlap, excessive blank space, unreadable thumbnail structure, or multi-panel imbalance.
