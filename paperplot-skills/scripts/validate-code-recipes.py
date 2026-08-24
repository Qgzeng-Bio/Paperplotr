#!/usr/bin/env python3
"""Validate rendered code recipe gallery outputs and write a markdown report."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


def read_csv(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def file_ok(path_text: str | None, min_bytes: int = 50) -> bool:
    if not path_text:
        return False
    path = Path(path_text)
    return path.exists() and path.stat().st_size >= min_bytes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gallery", required=True, help="Rendered recipe gallery directory")
    parser.add_argument("--manifest", default="paperplot-skills/recipes/recipe_manifest.csv")
    parser.add_argument("--out", required=True, help="Markdown report path")
    args = parser.parse_args()

    gallery = Path(args.gallery)
    manifest = read_csv(Path(args.manifest))
    index_path = gallery / "recipe-gallery-index.csv"
    index = read_csv(index_path) if index_path.exists() else []
    by_id = {row["recipe_id"]: row for row in index}

    rows = []
    failures = []
    for recipe in manifest:
        rid = recipe["recipe_id"]
        rendered = by_id.get(rid, {})
        pdf = rendered.get("pdf") or str(gallery / rid / f"{rid}.pdf")
        png = rendered.get("png") or str(gallery / rid / f"{rid}.png")
        metadata = rendered.get("metadata") or str(gallery / rid / f"{rid}_metadata.json")
        qa = rendered.get("qa") or str(gallery / rid / f"{rid}_qa.md")
        notes = rendered.get("notes") or str(gallery / rid / f"{rid}_notes.md")
        visual_json = gallery / rid / "visual_qa" / "visual_qa.json"
        family_json = gallery / rid / "visual_qa" / "family_qa.json"
        checks = {
            "pdf": file_ok(pdf, 1000),
            "png": file_ok(png, 1000),
            "metadata": file_ok(metadata, 100),
            "qa": file_ok(qa, 50),
            "notes": file_ok(notes, 50),
        }
        visual_status = "missing"
        score = ""
        risks = ""
        if visual_json.exists():
            payload = load_json(visual_json)
            qa_payload = payload.get("image_qa", payload)
            visual_status = str(qa_payload.get("status", "unknown"))
            score = str(qa_payload.get("manuscript_readiness_score", qa_payload.get("score", "")))
            risks_obj = qa_payload.get("risk_flags") or qa_payload.get("risks") or qa_payload.get("top_risks") or []
            if isinstance(risks_obj, list):
                risk_codes = []
                for risk in risks_obj[:5]:
                    if isinstance(risk, dict):
                        risk_codes.append(str(risk.get("code", risk.get("message", risk))))
                    else:
                        risk_codes.append(str(risk))
                risks = ", ".join(risk_codes)
            else:
                risks = str(risks_obj)
        family_status = "missing"
        if family_json.exists():
            family_payload = load_json(family_json)
            family_status = str((family_payload.get("family_qa") or {}).get("status", family_payload.get("status", "unknown")))
        ok = all(checks.values())
        if not ok:
            failures.append(rid)
        rows.append({
            "recipe_id": rid,
            "family": recipe["figure_family"],
            "status": recipe["status"],
            "ok": ok,
            "visual_status": visual_status,
            "family_status": family_status,
            "score": score,
            "risks": risks,
            "png": png,
        })

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Code Recipe Gallery Validation",
        "",
        f"Gallery: `{gallery}`",
        f"Recipes expected: {len(manifest)}",
        f"Recipes with required outputs: {sum(1 for r in rows if r['ok'])}/{len(rows)}",
        "",
        "## Gallery Index",
        "",
        "| Recipe | Family | Status | Outputs | Visual QA | Family QA | Score | Top risks |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for row in rows:
        outputs = "pass" if row["ok"] else "fail"
        lines.append(
            f"| `{row['recipe_id']}` | {row['family']} | `{row['status']}` | {outputs} | "
            f"{row['visual_status']} | {row['family_status']} | {row['score']} | {row['risks']} |"
        )
    lines += [
        "",
        "## Interpretation",
        "",
        "- `production_recipe` and `template_candidate` outputs should be readable at target manuscript size.",
        "- `specialized_reference` outputs are boundary examples; high line density is a caution, not automatic failure.",
        "- Visual QA warnings are review triggers. They do not replace scientific metadata checks.",
    ]
    if failures:
        lines += ["", "## Failures", ""]
        lines.extend(f"- `{rid}` missing required output sidecars" for rid in failures)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out}")
    if failures:
        print("Missing outputs:", ", ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
