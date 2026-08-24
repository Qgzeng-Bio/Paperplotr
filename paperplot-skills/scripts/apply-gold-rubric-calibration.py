#!/usr/bin/env python3
"""Convert completed human gold-rubric scores into QA calibration rules."""

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


def canonical_family(value: str) -> str:
    text = (value or "").lower()
    if "pca" in text or "pcoa" in text or "ordination" in text or "nmds" in text or "umap" in text or "t-sne" in text:
        return "ordination"
    if "heatmap" in text or "matrix" in text:
        return "heatmap"
    if "bar" in text or "errorbar" in text:
        return "bar/errorbar"
    if "raincloud" in text or "violin" in text or "boxplot" in text or "jitter" in text:
        return "violin/raincloud"
    if "scatter" in text or "regression" in text:
        return "scatter/regression"
    if "volcano" in text or "enrichment" in text or "gsea" in text:
        return "volcano/enrichment"
    if "lollipop" in text or "dumbbell" in text or "dotplot" in text:
        return "lollipop/dumbbell/dotplot"
    if "ridgeline" in text or "density" in text:
        return "ridgeline/density"
    if "upset" in text or "set plot" in text:
        return "upset/set"
    if "circos" in text or "chord" in text or "sankey" in text:
        return "circos/chord/sankey"
    if "map" in text or "spatial" in text:
        return "map/spatial"
    if "network" in text:
        return "network"
    if "phylo" in text or "tree" in text:
        return "phylo/tree"
    if "multi-panel" in text or "manuscript" in text:
        return "multi-panel"
    return text.strip().replace(" ", "-") or "unknown"


def parse_score(value: str) -> float | None:
    try:
        score = float(str(value).strip())
    except ValueError:
        return None
    if 1 <= score <= 5:
        return score
    return None


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def case_mean(row: dict[str, str]) -> float | None:
    values = [parse_score(row.get(col, "")) for col in SCORE_COLUMNS]
    if any(value is None for value in values):
        return None
    return sum(values) / len(values)


def build_rules(rows: list[dict[str, str]], source: str) -> dict:
    completed = []
    grouped: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        mean = case_mean(row)
        if mean is None:
            continue
        excluded = str(row.get("exclude_from_positive_calibration", "")).strip().upper() == "TRUE"
        family = canonical_family(row.get("figure_family", ""))
        entry = {
            "benchmark_id": row.get("benchmark_id", ""),
            "case": row.get("case", ""),
            "source_family": row.get("figure_family", ""),
            "canonical_family": family,
            "mean_score": round(mean, 3),
            "excluded": excluded,
            "exclusion_reason": row.get("exclusion_reason", ""),
            "overall_notes": row.get("overall_notes", ""),
        }
        completed.append(entry)
        grouped[family].append(entry)

    family_profiles = {}
    family_notes = {}
    score_adjustments = {}
    for family, entries in sorted(grouped.items()):
        means = [entry["mean_score"] for entry in entries]
        positive = [entry for entry in entries if not entry["excluded"] and entry["mean_score"] >= 4.0]
        caution = [entry for entry in entries if entry["excluded"] or entry["mean_score"] < 3.5]
        profile = {
            "n": len(entries),
            "mean_score_1_5": round(sum(means) / len(means), 3),
            "positive_count": len(positive),
            "caution_count": len(caution),
            "positive_calibration_eligible": len(positive) > 0,
            "source_families": sorted({entry["source_family"] for entry in entries}),
        }
        family_profiles[family] = profile
        notes = []
        if not profile["positive_calibration_eligible"]:
            notes.append("Human gold scores did not support this family as a high-quality positive calibration source.")
            score_adjustments[family] = {
                "positive_calibration_status": "baseline_or_caution",
                "positive_calibration_score_cap": 7.0,
            }
        if family == "ordination":
            notes.append(
                "User judged the current PCA/PCoA/ordination gold examples as readable but visually generic; ordinary ordination plots should not be treated as Nature-like positive exemplars without stronger hierarchy, marginal/statistical context, or refined layout."
            )
            score_adjustments[family] = {
                "positive_calibration_status": "baseline_or_caution",
                "positive_calibration_score_cap": 7.0,
            }
        if notes:
            family_notes[family] = notes

    global_mean = round(sum(entry["mean_score"] for entry in completed) / len(completed), 3) if completed else None
    return {
        "version": "gold-human-calibration-v1",
        "source_scores": source,
        "completed_count": len(completed),
        "global_mean_score_1_5": global_mean,
        "positive_case_count": sum(1 for entry in completed if not entry["excluded"] and entry["mean_score"] >= 4.0),
        "caution_case_count": sum(1 for entry in completed if entry["excluded"] or entry["mean_score"] < 3.5),
        "family_profiles": family_profiles,
        "family_notes": family_notes,
        "score_adjustments": score_adjustments,
        "cases": completed,
    }


def write_markdown(rules: dict, out: Path) -> None:
    lines = [
        "# Gold Human Rubric Calibration",
        "",
        f"Source scores: `{rules['source_scores']}`",
        f"Completed cases: {rules['completed_count']}",
        f"Global mean score: {rules['global_mean_score_1_5']}",
        f"Positive calibration cases: {rules['positive_case_count']}",
        f"Caution/baseline cases: {rules['caution_case_count']}",
        "",
        "## Family Profiles",
        "",
        "| Family | n | Mean | Positive | Caution | Positive eligible |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for family, profile in rules["family_profiles"].items():
        lines.append(
            f"| `{family}` | {profile['n']} | {profile['mean_score_1_5']} | {profile['positive_count']} | {profile['caution_count']} | {profile['positive_calibration_eligible']} |"
        )
    lines += ["", "## Human Calibration Notes", ""]
    if rules["family_notes"]:
        for family, notes in rules["family_notes"].items():
            lines.append(f"### {family}")
            for note in notes:
                lines.append(f"- {note}")
            lines.append("")
    else:
        lines.append("- No family-specific human calibration notes.")
    lines += [
        "## Skill Behavior",
        "",
        "- Families with positive examples can be used as positive visual calibration sources.",
        "- Families without positive examples should remain baseline/caution references until better examples are scored.",
        "- For ordination, ordinary PCA/PCoA layouts should not be scored as high Nature-like exemplars merely because they are readable.",
    ]
    out.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scores", default="paperplot-skills/reports/gold-human-rubric-pack/gold-human-rubric-scoring.csv")
    parser.add_argument("--out-json", default="paperplot-skills/references/gold-human-calibration-rules.json")
    parser.add_argument("--out-md", default="paperplot-skills/reports/gold-human-rubric-calibration.md")
    args = parser.parse_args()

    rows = read_rows(Path(args.scores))
    rules = build_rules(rows, args.scores)
    out_json = Path(args.out_json)
    out_md = Path(args.out_md)
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(rules, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_markdown(rules, out_md)
    print(f"Wrote {out_json}")
    print(f"Wrote {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
