#!/usr/bin/env python3
"""Build a real-figure benchmark manifest from the R replica library.

The benchmark is source-backed: it keeps script/image/data provenance and
selects a small gold-set queue for later human rubric scoring. It does not
copy large source images or data into the skill.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".pdf", ".svg", ".tif", ".tiff"}
DATA_EXTS = {".csv", ".tsv", ".txt", ".xls", ".xlsx", ".nwk", ".geojson", ".json"}


def load_index(index_path: Path) -> list[dict]:
    payload = json.loads(index_path.read_text(encoding="utf-8"))
    return list(payload.get("records", payload if isinstance(payload, list) else []))


def find_default_index() -> Path | None:
    candidates = [
        Path("paperplot-skills/reports/replica-code-pattern-index.json"),
        Path("paperplotr/paperplot-skills/reports/replica-code-pattern-index.json"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def case_dir_for_record(library: Path, record: dict) -> Path:
    script_rel = record.get("script") or ""
    if script_rel:
        parts = Path(script_rel).parts
        if parts:
            return library / parts[0]
    return library / str(record.get("case", ""))


def first_existing(paths: list[Path]) -> str:
    for path in paths:
        if path.exists():
            return str(path)
    return ""


def collect_case_files(case_dir: Path) -> tuple[list[Path], list[Path]]:
    images = sorted(p for p in case_dir.rglob("*") if p.is_file() and p.suffix.lower() in IMAGE_EXTS)
    data = sorted(p for p in case_dir.rglob("*") if p.is_file() and p.suffix.lower() in DATA_EXTS)
    return images, data


def benchmark_mode(record: dict) -> str:
    suitability = record.get("suitability", "")
    family = record.get("figure_family", "")
    if suitability in {"production_recipe", "template_candidate"}:
        return "executable_recipe_candidate"
    if suitability == "specialized_reference" or family in {"map / spatial", "circos / chord / circular", "network / sankey", "phylogenetic tree"}:
        return "specialized_diagnostic"
    if suitability == "decorative_or_case_specific":
        return "caution_diagnostic"
    return "diagnostic"


def make_case(case_id: int, library: Path, record: dict) -> dict:
    case_dir = case_dir_for_record(library, record)
    images, data = collect_case_files(case_dir) if case_dir.exists() else ([], [])
    role_keys = sorted((record.get("input_schema_roles") or {}).keys())
    return {
        "benchmark_id": f"r_replica_{case_id:03d}",
        "case": record.get("case", ""),
        "script": record.get("script", ""),
        "archive_script": record.get("archive_script", ""),
        "case_dir": str(case_dir),
        "source_image": str(images[0]) if images else "",
        "source_image_count": len(images),
        "data_file": str(data[0]) if data else "",
        "data_file_count": len(data),
        "figure_family": record.get("figure_family", ""),
        "source_suitability": record.get("suitability", ""),
        "benchmark_mode": benchmark_mode(record),
        "dependency_tier": "optional_backend" if record.get("suitability") == "specialized_reference" else "core_or_light",
        "input_roles": role_keys,
        "packages": record.get("packages", []),
        "risks": record.get("risks", []),
        "expected_qa_profile": qa_profile_for(record),
    }


def qa_profile_for(record: dict) -> str:
    family = record.get("figure_family", "")
    if "heatmap" in family.lower():
        return "matrix_density_allowed"
    if family in {"map / spatial", "circos / chord / circular", "network / sankey", "phylogenetic tree"}:
        return "specialized_line_density_caution"
    if "bar" in family.lower():
        return "grid_and_legend_strict"
    if "scatter" in family.lower() or "ordination" in family.lower():
        return "label_collision_and_light_grid"
    return "nature_detail_default"


def select_gold_set(cases: list[dict], target: int = 30) -> list[dict]:
    by_family: dict[str, list[dict]] = defaultdict(list)
    for case in cases:
        by_family[case["figure_family"]].append(case)
    selected: list[dict] = []
    for family in sorted(by_family):
        selected.append(by_family[family][0])
        if len(selected) >= target:
            return selected
    remaining = [case for case in cases if case not in selected]
    for case in remaining:
        selected.append(case)
        if len(selected) >= target:
            break
    return selected


def write_csv(cases: list[dict], out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "benchmark_id",
        "case",
        "script",
        "source_image",
        "data_file",
        "figure_family",
        "source_suitability",
        "benchmark_mode",
        "dependency_tier",
        "expected_qa_profile",
    ]
    with out.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for case in cases:
            writer.writerow({field: case.get(field, "") for field in fields})


def write_gold_set(gold: list[dict], out_md: Path, out_json: Path) -> None:
    rubric = [
        "message_clarity",
        "scientific_completeness",
        "visual_hierarchy",
        "proportional_balance",
        "readability_at_target_size",
        "statistical_expression",
        "color_legend_discipline",
        "data_preservation",
    ]
    out_json.write_text(
        json.dumps({"rubric": rubric, "cases": gold}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    lines = [
        "# Gold Human Rubric Set",
        "",
        "This is a 30-case queue for laboratory scoring. Scores are not required for deterministic QA; they calibrate the 9.0 plotting score.",
        "",
        "Rubric dimensions: " + ", ".join(f"`{x}`" for x in rubric),
        "",
        "| Benchmark | Family | Source image | Score status |",
        "|---|---|---|---|",
    ]
    for case in gold:
        source = case.get("source_image") or "-"
        lines.append(f"| `{case['benchmark_id']}` | {case['figure_family']} | `{source}` | pending |")
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_markdown(cases: list[dict], out: Path, library: Path) -> None:
    modes = Counter(case["benchmark_mode"] for case in cases)
    families = Counter(case["figure_family"] for case in cases)
    with_image = sum(1 for case in cases if case["source_image"])
    with_data = sum(1 for case in cases if case["data_file"])
    lines = [
        "# Real Figure Benchmark",
        "",
        f"Library: `{library}`",
        f"Benchmark cases: {len(cases)}",
        f"Cases with source image: {with_image}/{len(cases)}",
        f"Cases with data file: {with_data}/{len(cases)}",
        "",
        "## Benchmark Modes",
        "",
    ]
    for key, value in sorted(modes.items()):
        lines.append(f"- `{key}`: {value}")
    lines += ["", "## Family Coverage", ""]
    for key, value in families.most_common():
        lines.append(f"- {key}: {value}")
    lines += [
        "",
        "## Case Manifest",
        "",
        "| ID | Case | Family | Mode | Image | Data | QA profile |",
        "|---|---|---|---|---|---|---|",
    ]
    for case in cases:
        lines.append(
            f"| `{case['benchmark_id']}` | {case['case']} | {case['figure_family']} | `{case['benchmark_mode']}` | "
            f"{'yes' if case['source_image'] else 'no'} | {'yes' if case['data_file'] else 'no'} | `{case['expected_qa_profile']}` |"
        )
    lines += [
        "",
        "## Interpretation",
        "",
        "- Executable cases should be rendered through cleaned recipes/templates and scored by visual QA plus family QA.",
        "- Specialized diagnostic cases calibrate boundaries; dense lines in trees/circos/maps are not ordinary grid failures.",
        "- Caution cases are retained to prevent over-generalizing decorative or case-specific layouts.",
    ]
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, help="R replica library root")
    parser.add_argument("--index", default=None, help="replica-code-pattern-index.json")
    parser.add_argument("--out", required=True, help="Benchmark JSON output")
    args = parser.parse_args()

    library = Path(args.library).expanduser().resolve()
    index_path = Path(args.index) if args.index else find_default_index()
    if index_path is None or not index_path.exists():
        raise SystemExit("Missing replica-code-pattern-index.json. Run index-replica-code-patterns.py first.")
    records = load_index(index_path)
    cases = [make_case(i + 1, library, record) for i, record in enumerate(records)]
    out_json = Path(args.out)
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(
        json.dumps({"library": str(library), "index": str(index_path), "case_count": len(cases), "cases": cases}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    write_csv(cases, out_json.with_suffix(".csv"))
    write_markdown(cases, out_json.with_suffix(".md"), library)
    gold = select_gold_set(cases, 30)
    write_gold_set(gold, out_json.parent / "gold-human-rubric-set.md", out_json.parent / "gold-human-rubric-set.json")
    print(f"Wrote {out_json}")
    print(f"Wrote {out_json.with_suffix('.md')}")
    print(f"Wrote {out_json.parent / 'gold-human-rubric-set.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
