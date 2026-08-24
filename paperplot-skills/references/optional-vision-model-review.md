# Optional Vision Model Review

The default PaperPlot QA pipeline is deterministic and must run without network access, API keys, OCR engines, or human scoring. A vision model can be used only as an optional second opinion.

## Adapter

```bash
python3 scripts/vision-review-adapter.py \
  --image figure.png \
  --qa-json qa/visual_qa.json \
  --out qa/vision_review.json
```

Default output when no provider is enabled:

```json
{
  "vision_review": {
    "available": false,
    "enabled": false,
    "reason": "provider is none; deterministic QA remains authoritative",
    "can_override_deterministic_hard_fail": false
  }
}
```

## Required Rubric Schema

Any future model connector must return only structured output with these dimensions, scored 1-5 with brief evidence:

- message clarity
- scientific completeness
- visual hierarchy
- proportional balance
- readability at target size
- statistical expression
- color/legend discipline
- data preservation

Free-form critique is not acceptable as a machine-readable QA signal.

## Authority Rules

- Vision review is a `second_opinion`, not the source of truth.
- It cannot override deterministic hard failures such as severe text overlap, unreadable target-size typography, or panel data-region mismatch.
- It cannot call a redesign improved if scientific information is removed.
- It must be recorded separately from `visual_qa.json`, `family_qa.json`, and `old_vs_new_visual_qa.json`.

## When To Use

Use the optional adapter only when deterministic QA reports a borderline result or when a researcher specifically wants a visual-review second opinion. Do not make it a required dependency for routine figure generation or validation.
