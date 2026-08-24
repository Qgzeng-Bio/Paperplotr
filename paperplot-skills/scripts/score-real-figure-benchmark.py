#!/usr/bin/env python3
"""Score and summarize the real-figure benchmark manifest.

This script is lightweight by default: it summarizes coverage and records which
cases are ready for executable redraw, diagnostic review, or human-gold-set
scoring. It can consume rendered benchmark outputs when they exist.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def rendered_index_default() -> Path:
    return Path("paperplot-skills/reports/real-figure-benchmark/rendered/real-figure-render-index.csv")


def case_status(case: dict, rendered_by_family: dict[str, list[dict[str, str]]]) -> str:
    if case.get("benchmark_mode") == "executable_recipe_candidate":
        family_rows = rendered_by_family.get(case.get("figure_family", ""), [])
        return "rendered_family_available" if family_rows else "needs_recipe_mapping"
    if case.get("benchmark_mode") == "specialized_diagnostic":
        return "specialized_diagnostic_ready"
    if case.get("benchmark_mode") == "caution_diagnostic":
        return "caution_reference_ready"
    return "diagnostic_ready"


def write_report(payload: dict, rendered: list[dict[str, str]], out: Path) -> None:
    cases = list(payload.get("cases", []))
    rendered_by_family: dict[str, list[dict[str, str]]] = {}
    for row in rendered:
        rendered_by_family.setdefault(row.get("family", ""), []).append(row)

    modes = Counter(case.get("benchmark_mode", "") for case in cases)
    families = Counter(case.get("figure_family", "") for case in cases)
    statuses = Counter(case_status(case, rendered_by_family) for case in cases)
    executable = [case for case in cases if case.get("benchmark_mode") == "executable_recipe_candidate"]
    executable_with_family_render = [case for case in executable if rendered_by_family.get(case.get("figure_family", ""))]
    with_image = sum(1 for case in cases if case.get("source_image"))
    with_data = sum(1 for case in cases if case.get("data_file"))

    lines = [
        "# Real Figure Benchmark Score",
        "",
        f"Benchmark cases: {len(cases)}",
        f"Cases with source image: {with_image}/{len(cases)}",
        f"Cases with data file: {with_data}/{len(cases)}",
        f"Executable-family cases with rendered recipe family: {len(executable_with_family_render)}/{len(executable)}",
        "",
        "## Status Summary",
        "",
    ]
    for key, value in sorted(statuses.items()):
        lines.append(f"- `{key}`: {value}")
    lines += ["", "## Benchmark Mode Summary", ""]
    for key, value in sorted(modes.items()):
        lines.append(f"- `{key}`: {value}")
    lines += ["", "## Family Summary", ""]
    for key, value in families.most_common():
        lines.append(f"- {key}: {value}")
    lines += [
        "",
        "## Case-Level Review Queue",
        "",
        "| ID | Family | Mode | Status | Source image | Data |",
        "|---|---|---|---|---|---|",
    ]
    for case in cases:
        status = case_status(case, rendered_by_family)
        lines.append(
            f"| `{case.get('benchmark_id')}` | {case.get('figure_family')} | `{case.get('benchmark_mode')}` | `{status}` | "
            f"{'yes' if case.get('source_image') else 'no'} | {'yes' if case.get('data_file') else 'no'} |"
        )
    lines += [
        "",
        "## 9.0 Interpretation",
        "",
        "- This report proves coverage and review readiness, not final human aesthetic calibration.",
        "- Cases with `needs_recipe_mapping` should be prioritized for the next recipe/template promotion pass.",
        "- Specialized cases should be judged by family-specific QA and optional backend availability.",
        "- Final `improved` verdicts still require old-vs-new review or completed human rubric JSON.",
    ]
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--benchmark", required=True, help="real-figure-benchmark.json")
    parser.add_argument("--rendered-index", default=str(rendered_index_default()))
    parser.add_argument("--out", required=True, help="Markdown report")
    args = parser.parse_args()

    payload = load_json(Path(args.benchmark))
    rendered = read_csv(Path(args.rendered_index))
    write_report(payload, rendered, Path(args.out))
    print(f"Wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
