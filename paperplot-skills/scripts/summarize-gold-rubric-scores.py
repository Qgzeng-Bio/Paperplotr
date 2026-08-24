#!/usr/bin/env python3
"""Summarize completed human gold-rubric scores."""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path


SCORE_COLUMNS = [
    "message_clarity",
    "scientific_completeness",
    "visual_hierarchy",
    "proportional_balance",
    "readability_at_target_size",
    "statistical_expression",
    "color_legend_discipline",
    "data_preservation",
]


def parse_score(value: str) -> float | None:
    value = (value or "").strip()
    if not value:
        return None
    try:
        score = float(value)
    except ValueError:
        return None
    if 1 <= score <= 5:
        return score
    return None


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def summarize(rows: list[dict[str, str]]) -> dict:
    completed = []
    incomplete = []
    dim_values: dict[str, list[float]] = defaultdict(list)
    family_values: dict[str, list[float]] = defaultdict(list)
    for row in rows:
        scores = {col: parse_score(row.get(col, "")) for col in SCORE_COLUMNS}
        if all(value is not None for value in scores.values()):
            mean_score = sum(scores.values()) / len(scores)
            row_summary = {
                "benchmark_id": row.get("benchmark_id", ""),
                "case": row.get("case", ""),
                "figure_family": row.get("figure_family", ""),
                "mean_score": round(mean_score, 3),
                "scores": scores,
                "exclude_from_positive_calibration": str(row.get("exclude_from_positive_calibration", "")).strip().upper() == "TRUE",
                "exclusion_reason": row.get("exclusion_reason", ""),
            }
            completed.append(row_summary)
            for col, value in scores.items():
                dim_values[col].append(value)
            family_values[row.get("figure_family", "")].append(mean_score)
        else:
            missing = [col for col, value in scores.items() if value is None]
            incomplete.append({"benchmark_id": row.get("benchmark_id", ""), "missing": missing})
    positive = [row for row in completed if not row["exclude_from_positive_calibration"] and row["mean_score"] >= 4.0]
    caution = [row for row in completed if row["exclude_from_positive_calibration"] or row["mean_score"] < 3.5]
    return {
        "case_count": len(rows),
        "completed_count": len(completed),
        "incomplete_count": len(incomplete),
        "overall_mean": round(sum(row["mean_score"] for row in completed) / len(completed), 3) if completed else None,
        "dimension_means": {col: round(sum(values) / len(values), 3) for col, values in dim_values.items()},
        "family_means": {family: round(sum(values) / len(values), 3) for family, values in family_values.items()},
        "positive_calibration_count": len(positive),
        "caution_or_negative_count": len(caution),
        "completed": completed,
        "incomplete": incomplete,
    }


def write_md(summary: dict, out: Path) -> None:
    lines = [
        "# Gold Human Rubric Score Summary",
        "",
        f"Cases: {summary['case_count']}",
        f"Completed: {summary['completed_count']}",
        f"Incomplete: {summary['incomplete_count']}",
        f"Overall mean: {summary['overall_mean'] if summary['overall_mean'] is not None else 'pending'}",
        f"Positive calibration candidates: {summary['positive_calibration_count']}",
        f"Caution/negative candidates: {summary['caution_or_negative_count']}",
        "",
        "## Dimension Means",
        "",
    ]
    if summary["dimension_means"]:
        for key, value in summary["dimension_means"].items():
            lines.append(f"- `{key}`: {value}")
    else:
        lines.append("- pending")
    lines += ["", "## Family Means", ""]
    if summary["family_means"]:
        for key, value in sorted(summary["family_means"].items()):
            lines.append(f"- {key}: {value}")
    else:
        lines.append("- pending")
    lines += [
        "",
        "## Interpretation",
        "",
        "- Mean score >= 4.0 and not excluded: usable as positive calibration.",
        "- Mean score 3.5-4.0: useful but should be checked before threshold learning.",
        "- Mean score < 3.5 or excluded: use as caution/reference, not positive threshold learning.",
    ]
    if summary["incomplete"]:
        lines += ["", "## Incomplete Cases", ""]
        for row in summary["incomplete"]:
            lines.append(f"- `{row['benchmark_id']}` missing: {', '.join(row['missing'])}")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scores", required=True, help="Filled gold-human-rubric-scoring.csv")
    parser.add_argument("--out", default="paperplot-skills/reports/gold-human-rubric-score-summary.md")
    parser.add_argument("--out-json", default=None)
    args = parser.parse_args()

    rows = read_rows(Path(args.scores))
    summary = summarize(rows)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    write_md(summary, out)
    out_json = Path(args.out_json) if args.out_json else out.with_suffix(".json")
    out_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out}")
    print(f"Wrote {out_json}")
    if summary["completed_count"] == 0:
        print("No completed scores yet.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
