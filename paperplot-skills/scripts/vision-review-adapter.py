#!/usr/bin/env python3
"""Optional vision-model review adapter for PaperPlot visual QA.

The deterministic QA pipeline must work without network access or API keys.
This adapter defines the schema and safe fallback behavior for a future second
opinion layer. It never overrides deterministic hard failures.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any


RUBRIC_DIMENSIONS = [
    "message_clarity",
    "scientific_completeness",
    "visual_hierarchy",
    "proportional_balance",
    "readability_at_target_size",
    "statistical_expression",
    "color_legend_discipline",
    "data_preservation",
]


def load_json(path: str | None) -> dict[str, Any]:
    if not path:
        return {}
    p = Path(path).expanduser()
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def unavailable(reason: str, provider: str, model: str | None, image: str | None, qa_json: str | None) -> dict[str, Any]:
    return {
        "vision_review": {
            "available": False,
            "enabled": False,
            "provider": provider,
            "model": model,
            "image": image,
            "qa_json": qa_json,
            "reason": reason,
            "second_opinion": None,
            "can_override_deterministic_hard_fail": False,
            "rubric_schema": {
                "score_range": [1, 5],
                "dimensions": RUBRIC_DIMENSIONS,
                "required_output": {
                    "dimension_scores": {dim: {"score": "integer 1-5", "notes": "short evidence"} for dim in RUBRIC_DIMENSIONS},
                    "blocking_concerns": [],
                    "summary": "short structured judgment",
                },
            },
        }
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Optional vision-model second-opinion adapter for deterministic figure QA.")
    parser.add_argument("--image", default=None, help="Rendered image path.")
    parser.add_argument("--qa-json", default=None, help="Deterministic visual_qa.json path.")
    parser.add_argument("--out", required=True, help="Output JSON path.")
    parser.add_argument("--provider", choices=["none", "openai", "anthropic", "gemini"], default="none", help="Optional provider. Default disables network/API use.")
    parser.add_argument("--model", default=None, help="Optional model name.")
    parser.add_argument("--config-json", default=None, help="Optional local config. This adapter does not make network calls by default.")
    args = parser.parse_args()

    config = load_json(args.config_json)
    provider = args.provider
    out = Path(args.out).expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)

    if provider == "none":
        payload = unavailable("provider is none; deterministic QA remains authoritative", provider, args.model, args.image, args.qa_json)
    else:
        key_env = {
            "openai": "OPENAI_API_KEY",
            "anthropic": "ANTHROPIC_API_KEY",
            "gemini": "GEMINI_API_KEY",
        }[provider]
        if not os.environ.get(key_env) and not config.get("api_key"):
            payload = unavailable(f"{key_env} is not configured; vision review is skipped", provider, args.model, args.image, args.qa_json)
        else:
            payload = unavailable(
                "API credentials are present, but this deterministic skill runtime ships only the adapter/schema; enable a project-specific connector before making network calls.",
                provider,
                args.model,
                args.image,
                args.qa_json,
            )
            payload["vision_review"]["available"] = True
            payload["vision_review"]["enabled"] = False

    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"vision review adapter output written: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
