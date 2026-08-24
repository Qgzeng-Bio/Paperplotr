#!/usr/bin/env python3
"""Old-vs-new visual comparison for paperplot-skills.

The deterministic comparison now uses the same rasterized QA layer for PNG,
SVG, and PDF inputs, and it generates a structured human-review rubric. A new
figure is not allowed to be called improved unless deterministic checks and the
review rubric both support that verdict.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

RUBRIC_DIMENSIONS = [
    ("message_clarity", "Main scientific message is clearer."),
    ("scientific_completeness", "Units, denominators, transforms, uncertainty, and statistical semantics are preserved."),
    ("visual_hierarchy", "Primary evidence is visually dominant and supporting elements are secondary."),
    ("proportional_balance", "Panel boxes, data regions, legends, and whitespace are proportionally balanced."),
    ("readability_at_target_size", "Text, marks, and annotations remain readable at manuscript size."),
    ("statistical_expression", "Effect sizes, uncertainty, thresholds, and tests are expressed more honestly."),
    ("color_legend_discipline", "Colors and legends are functional, consistent, and not excessive."),
    ("data_preservation", "The redraw does not remove or distort required scientific information."),
]

SEVERE_PANEL_RISKS = {
    "panel_size_imbalance",
    "panel_data_region_imbalance",
    "panel_data_region_mismatch",
    "unjustified_panel_hierarchy_risk",
}

SEVERE_DETAIL_RISKS = {
    "text_data_overlap_risk",
    "vector_text_overlap",
    "vector_tick_collision",
    "vector_font_out_of_range",
    "font_too_small_at_target_width",
    "panel_data_region_mismatch",
    "grid_background_burden",
}


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def run_visual_qa(
    image: Path,
    out_dir: Path,
    *,
    family: str | None = None,
    dpi: int = 300,
    page: int = 1,
    ocr: str = "auto",
    expected_panels: int | None = None,
    layout_profile: str = "auto",
    strict_nature: bool = False,
    target_width_mm: float | None = None,
    journal_profile: str = "generic",
    strict_detail_qa: bool = False,
    allow_grid: str = "auto",
    expected_font_range: str = "5,7",
) -> dict[str, Any]:
    script = Path(__file__).with_name("visual-qa-rendered-image.py")
    ensure_dir(out_dir)
    cmd = [
        sys.executable,
        str(script),
        str(image),
        "--out",
        str(out_dir),
        "--dpi",
        str(dpi),
        "--page",
        str(page),
        "--ocr",
        ocr,
        "--layout-profile",
        layout_profile,
        "--journal-profile",
        journal_profile,
        "--allow-grid",
        allow_grid,
        "--expected-font-range",
        expected_font_range,
    ]
    if target_width_mm:
        cmd.extend(["--target-width-mm", str(target_width_mm)])
    if strict_detail_qa:
        cmd.append("--strict-detail-qa")
    if family:
        cmd.extend(["--family", family])
    if expected_panels:
        cmd.extend(["--expected-panels", str(expected_panels)])
    if strict_nature:
        cmd.append("--strict-nature")
    proc = subprocess.run(cmd, text=True, capture_output=True)
    qa_path = out_dir / "visual_qa.json"
    if proc.returncode != 0 and not (strict_nature and qa_path.exists()):
        raise SystemExit(f"visual QA failed for {image}: {proc.stderr or proc.stdout}")
    payload = json.loads(qa_path.read_text())
    qa = payload["image_qa"]
    qa["_returncode"] = proc.returncode
    return qa


def num(x: Any, default: float = 0.0) -> float:
    try:
        return float(x)
    except Exception:
        return default


def media_kind(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".svg":
        return "svg"
    if suffix == ".pdf":
        return "pdf"
    return "raster"


def metric_delta(old: float, new: float, lower_is_better: bool = True, tolerance: float = 0.04) -> str:
    if old == 0 and new == 0:
        return "same"
    denom = max(abs(old), 1e-9)
    rel = (new - old) / denom
    if abs(rel) <= tolerance:
        return "same"
    if lower_is_better:
        return "improved" if rel < 0 else "worse"
    return "improved" if rel > 0 else "worse"


def score_delta(old_score: int, new_score: int) -> str:
    if new_score >= old_score + 1:
        return "improved"
    if new_score <= old_score - 1:
        return "worse"
    return "same"


def verdict_from_deltas(deltas: list[str]) -> str:
    worse = deltas.count("worse")
    improved = deltas.count("improved")
    if worse == 0 and improved > 0:
        return "improved"
    if improved == 0 and worse > 0:
        return "worse"
    if improved == 0 and worse == 0:
        return "same"
    return "mixed"


def risk_codes(qa: dict[str, Any]) -> set[str]:
    return {item.get("code", "") for item in qa.get("top_risks", [])}


def panel_value(qa: dict[str, Any], key: str) -> float:
    panel = qa.get("panel_geometry") or {}
    return num(panel.get(key))


def write_review_template(out_dir: Path) -> Path:
    template = {
        "rubric_version": "1.0",
        "instructions": "Fill old_score and new_score from 1 (poor) to 5 (excellent). A final improved verdict requires total new score > old score and no deterministic hard gate failure.",
        "dimensions": {
            key: {"description": description, "old_score": None, "new_score": None, "notes": ""}
            for key, description in RUBRIC_DIMENSIONS
        },
    }
    path = out_dir / "old_vs_new_review_template.json"
    path.write_text(json.dumps(template, indent=2, ensure_ascii=False) + "\n")
    return path


def load_review(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {
            "provided": False,
            "status": "requires_human_review",
            "message": "No review JSON was provided; final improvement cannot be claimed from deterministic metrics alone.",
        }
    payload = json.loads(path.read_text())
    dims = payload.get("dimensions", {})
    rows = []
    old_total = 0
    new_total = 0
    missing = []
    for key, description in RUBRIC_DIMENSIONS:
        item = dims.get(key, {})
        try:
            old_score = int(item.get("old_score"))
            new_score = int(item.get("new_score"))
        except Exception:
            missing.append(key)
            continue
        if not (1 <= old_score <= 5 and 1 <= new_score <= 5):
            missing.append(key)
            continue
        old_total += old_score
        new_total += new_score
        rows.append({
            "dimension": key,
            "description": description,
            "old_score": old_score,
            "new_score": new_score,
            "delta": new_score - old_score,
            "notes": item.get("notes", ""),
        })
    if missing:
        return {
            "provided": True,
            "status": "invalid",
            "message": "Review JSON is missing valid 1-5 scores for required dimensions.",
            "missing_dimensions": missing,
            "rows": rows,
        }
    delta = new_total - old_total
    if delta > 0:
        status = "improved"
    elif delta < 0:
        status = "worse"
    else:
        status = "same"
    return {
        "provided": True,
        "status": status,
        "old_total": old_total,
        "new_total": new_total,
        "delta": delta,
        "rows": rows,
        "message_clarity_delta": next((r["delta"] for r in rows if r["dimension"] == "message_clarity"), None),
    }


def final_verdict(
    deterministic_verdict: str,
    old_score: int,
    new_score: int,
    new_status: str,
    new_nature_failed: bool,
    severe_panel_risk: bool,
    severe_detail_risk: bool,
    review: dict[str, Any],
) -> tuple[str, str]:
    if new_nature_failed or new_status == "fail" or new_score < old_score or deterministic_verdict == "worse":
        return "worse", "fail"
    if severe_panel_risk or severe_detail_risk:
        return "human-review-required", "warn"
    if not review.get("provided"):
        if deterministic_verdict == "improved" and new_score >= 8 and new_status != "fail":
            return "deterministic_better_pending_human_review", "warn"
        return "human-review-required", "warn"
    if review.get("status") == "invalid":
        return "human-review-required", "warn"
    if review.get("status") == "worse":
        return "worse", "fail"
    if review.get("status") == "improved" and new_score >= 8 and new_status != "fail" and deterministic_verdict != "worse":
        return "improved", "pass"
    return "mixed", "warn"


def write_md(payload: dict[str, Any], out_dir: Path) -> None:
    lines = [
        "# Old-vs-new visual QA",
        "",
        f"- old: `{payload['old_image']}`",
        f"- new: `{payload['new_image']}`",
        f"- media: `{payload.get('old_media', 'unknown')}` -> `{payload.get('new_media', 'unknown')}`",
        f"- threshold profiles: `{payload.get('old_threshold_profile', 'global')}` -> `{payload.get('new_threshold_profile', 'global')}`",
        f"- deterministic verdict: `{payload['deterministic_verdict']}`",
        f"- review rubric status: `{payload['review_rubric_status']}`",
        f"- final verdict: `{payload['final_verdict']}`",
        f"- status: `{payload['status']}`",
        f"- review template: `{payload['review_template']}`",
        "",
        "## Metric deltas",
        "",
        "| metric | old | new | delta |",
        "|---|---:|---:|---|",
    ]
    for row in payload["metric_deltas"]:
        lines.append(f"| {row['metric']} | {row['old']} | {row['new']} | {row['delta']} |")
    lines += [
        "",
        "## Panel geometry",
        "",
        f"- panel geometry delta: `{payload['panel_geometry_delta']}`",
        f"- severe new panel risk: `{payload['severe_new_panel_risk']}`",
        "",
        "## Nature detail QA",
        "",
        f"- detail QA delta: `{payload.get('detail_qa_delta')}`",
        f"- severe new detail risk: `{payload.get('severe_new_detail_risk')}`",
        "",
        "## Review rubric",
        "",
    ]
    review = payload.get("review_rubric", {})
    lines.append(f"- provided: `{review.get('provided')}`")
    lines.append(f"- status: `{review.get('status')}`")
    if "old_total" in review:
        lines.append(f"- total: `{review.get('old_total')}` -> `{review.get('new_total')}`")
    lines += ["", "## Remaining risks", ""]
    if payload["remaining_risks"]:
        for item in payload["remaining_risks"]:
            lines.append(f"- {item}")
    else:
        lines.append("- No major deterministic worsening detected.")
    (out_dir / "old_vs_new_visual_qa.md").write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare old and new rendered figures using deterministic visual QA metrics and a structured review rubric.")
    parser.add_argument("old_image")
    parser.add_argument("new_image")
    parser.add_argument("--out", required=True)
    parser.add_argument("--family", default=None, help="Optional family profile applied to both old and new figures")
    parser.add_argument("--old-family", default=None, help="Optional family profile for the old figure")
    parser.add_argument("--new-family", default=None, help="Optional family profile for the new figure")
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--page", type=int, default=1)
    parser.add_argument("--ocr", choices=["auto", "off", "required"], default="auto")
    parser.add_argument("--expected-panels", type=int, default=None)
    parser.add_argument("--old-expected-panels", type=int, default=None)
    parser.add_argument("--new-expected-panels", type=int, default=None)
    parser.add_argument("--layout-profile", choices=["auto", "equal", "hierarchical"], default="auto")
    parser.add_argument("--old-layout-profile", choices=["auto", "equal", "hierarchical"], default=None)
    parser.add_argument("--new-layout-profile", choices=["auto", "equal", "hierarchical"], default=None)
    parser.add_argument("--strict-nature", action="store_true", help="Apply strict Nature guardrails to both figures")
    parser.add_argument("--old-strict-nature", action="store_true", help="Apply strict Nature guardrails to the old figure")
    parser.add_argument("--new-strict-nature", action="store_true", help="Apply strict Nature guardrails to the new figure")
    parser.add_argument("--review-json", default=None)
    parser.add_argument("--target-width-mm", type=float, default=None)
    parser.add_argument("--journal-profile", choices=["nature", "cell", "science", "generic"], default="generic")
    parser.add_argument("--strict-detail-qa", action="store_true")
    parser.add_argument("--allow-grid", choices=["auto", "off", "light", "required"], default="auto")
    parser.add_argument("--expected-font-range", default="5,7")
    args = parser.parse_args()

    old_path = Path(args.old_image).expanduser()
    new_path = Path(args.new_image).expanduser()
    out_dir = Path(args.out).expanduser()
    ensure_dir(out_dir)
    review_template = write_review_template(out_dir)
    with tempfile.TemporaryDirectory(prefix="paperplot-old-new-") as tmp:
        tmp_path = Path(tmp)
        old = run_visual_qa(
            old_path,
            tmp_path / "old",
            family=args.old_family or args.family,
            dpi=args.dpi,
            page=args.page,
            ocr=args.ocr,
            expected_panels=args.old_expected_panels or args.expected_panels,
            layout_profile=args.old_layout_profile or args.layout_profile,
            strict_nature=args.strict_nature or args.old_strict_nature,
            target_width_mm=args.target_width_mm,
            journal_profile=args.journal_profile,
            strict_detail_qa=args.strict_detail_qa,
            allow_grid=args.allow_grid,
            expected_font_range=args.expected_font_range,
        )
        new = run_visual_qa(
            new_path,
            tmp_path / "new",
            family=args.new_family or args.family,
            dpi=args.dpi,
            page=args.page,
            ocr=args.ocr,
            expected_panels=args.new_expected_panels or args.expected_panels,
            layout_profile=args.new_layout_profile or args.layout_profile,
            strict_nature=args.strict_nature or args.new_strict_nature,
            target_width_mm=args.target_width_mm,
            journal_profile=args.journal_profile,
            strict_detail_qa=args.strict_detail_qa,
            allow_grid=args.allow_grid,
            expected_font_range=args.expected_font_range,
        )

    metric_specs = [
        ("blank_margin_fraction", True),
        ("text_burden_score", True),
        ("content_density", False),
        ("color_count_estimate", True),
        ("thumbnail_content_density", True),
    ]
    deltas = []
    for metric, lower_is_better in metric_specs:
        old_v = num(old.get(metric))
        new_v = num(new.get(metric))
        deltas.append({"metric": metric, "old": round(old_v, 4), "new": round(new_v, 4), "delta": metric_delta(old_v, new_v, lower_is_better=lower_is_better)})
    old_line = old.get("line_burden", {}).get("line_burden_score", 0)
    new_line = new.get("line_burden", {}).get("line_burden_score", 0)
    deltas.append({"metric": "line_burden_score", "old": old_line, "new": new_line, "delta": metric_delta(num(old_line), num(new_line), lower_is_better=True)})
    for panel_metric in ("panel_area_ratio_max_min", "content_area_ratio_max_min", "blank_fraction_range"):
        old_v = panel_value(old, panel_metric)
        new_v = panel_value(new, panel_metric)
        deltas.append({"metric": panel_metric, "old": round(old_v, 4), "new": round(new_v, 4), "delta": metric_delta(old_v, new_v, lower_is_better=True)})
    detail_metric_specs = [
        ("text_geometry", "ocr_overlap_pair_count", True),
        ("text_geometry", "edge_text_like_fraction", True),
        ("vector_text_geometry", "text_box_overlap_count", True),
        ("vector_text_geometry", "text_box_data_region_intrusion", True),
        ("vector_layout_geometry", "right_edge_text_fraction", True),
        ("grid_background", "long_line_count", True),
        ("legend_geometry", "edge_content_fraction", True),
        ("stroke_geometry", "line_burden_score", True),
    ]
    for outer, inner, lower_is_better in detail_metric_specs:
        old_v = num((old.get(outer) or {}).get(inner))
        new_v = num((new.get(outer) or {}).get(inner))
        deltas.append({"metric": f"{outer}.{inner}", "old": round(old_v, 4), "new": round(new_v, 4), "delta": metric_delta(old_v, new_v, lower_is_better=lower_is_better)})
    old_detail_fail = num((old.get("nature_detail_rubric") or {}).get("hard_fail_count"))
    new_detail_fail = num((new.get("nature_detail_rubric") or {}).get("hard_fail_count"))
    deltas.append({"metric": "nature_detail_hard_fail_count", "old": int(old_detail_fail), "new": int(new_detail_fail), "delta": metric_delta(old_detail_fail, new_detail_fail, lower_is_better=True, tolerance=0.0)})
    old_score = int(old.get("manuscript_readiness_score", 0))
    new_score = int(new.get("manuscript_readiness_score", 0))
    deltas.append({"metric": "manuscript_readiness_score", "old": old_score, "new": new_score, "delta": score_delta(old_score, new_score)})

    deterministic_verdict = verdict_from_deltas([d["delta"] for d in deltas])
    panel_deltas = [d["delta"] for d in deltas if d["metric"] in {"panel_area_ratio_max_min", "content_area_ratio_max_min", "blank_fraction_range"}]
    panel_geometry_delta = verdict_from_deltas(panel_deltas)
    remaining = []
    if deterministic_verdict in {"worse", "mixed"}:
        for d in deltas:
            if d["delta"] == "worse":
                remaining.append(f"{d['metric']} worsened from {d['old']} to {d['new']}")
    old_media = media_kind(old_path)
    new_media = media_kind(new_path)
    comparison_limitation = None
    if old_media != new_media:
        comparison_limitation = (
            "Original media differ, but both figures were rasterized before pixel QA. "
            "SVG structural metrics remain supplemental and should not be compared as pixel-equivalent evidence."
        )
        remaining.insert(0, comparison_limitation)

    new_risks = risk_codes(new)
    severe_panel_risk = bool(new_risks.intersection(SEVERE_PANEL_RISKS))
    new_nature_failed = (new.get("nature_guardrails") or {}).get("status") == "fail"
    severe_detail_risk = bool(new_risks.intersection(SEVERE_DETAIL_RISKS)) or bool((new.get("nature_detail_rubric") or {}).get("hard_fail_count"))
    review = load_review(Path(args.review_json).expanduser() if args.review_json else None)
    final, status = final_verdict(
        deterministic_verdict,
        old_score,
        new_score,
        new.get("status", ""),
        new_nature_failed,
        severe_panel_risk,
        severe_detail_risk,
        review,
    )
    if final == "human-review-required":
        remaining.append("Final improvement requires completed old_vs_new_review_template.json or --review-json.")
    if severe_panel_risk:
        remaining.append("New figure has severe panel geometry risk; do not claim manuscript improvement before fixing layout.")
    if new_nature_failed:
        remaining.append("New figure failed strict Nature guardrails; revise before claiming final manuscript readiness.")
    if severe_detail_risk:
        remaining.append("New figure has severe Nature-detail QA risk; inspect text overlap, target-size fonts, grid burden, and data-region balance before claiming improvement.")

    payload = {
        "old_vs_new_visual_qa": {
            "checked": True,
            "old_image": str(old_path),
            "new_image": str(new_path),
            "old_media": old_media,
            "new_media": new_media,
            "old_family": old.get("figure_family"),
            "new_family": new.get("figure_family"),
            "old_threshold_profile": old.get("threshold_profile"),
            "new_threshold_profile": new.get("threshold_profile"),
            "comparison_limitation": comparison_limitation,
            "deterministic_verdict": deterministic_verdict,
            "panel_geometry_delta": panel_geometry_delta,
            "review_rubric_status": review.get("status"),
            "final_verdict": final,
            "verdict": deterministic_verdict,
            "status": status,
            "message_clarity_delta": review.get("message_clarity_delta", "requires_human_review"),
            "visual_burden_delta": deterministic_verdict,
            "metric_deltas": deltas,
            "old_score": old_score,
            "new_score": new_score,
            "severe_new_panel_risk": severe_panel_risk,
            "new_nature_guardrails_failed": new_nature_failed,
            "severe_new_detail_risk": severe_detail_risk,
            "detail_qa_delta": verdict_from_deltas([d["delta"] for d in deltas if d["metric"].startswith(("text_geometry.", "grid_background.", "legend_geometry.", "stroke_geometry.", "nature_detail_"))]),
            "review_template": str(review_template),
            "review_rubric": review,
            "old_qa_summary": {
                "input_type": old.get("input_type"),
                "rasterization": old.get("rasterization"),
                "panel_geometry": old.get("panel_geometry"),
                "nature_guardrails": old.get("nature_guardrails"),
            },
            "new_qa_summary": {
                "input_type": new.get("input_type"),
                "rasterization": new.get("rasterization"),
                "panel_geometry": new.get("panel_geometry"),
                "nature_guardrails": new.get("nature_guardrails"),
            },
            "remaining_risks": remaining,
        }
    }
    (out_dir / "old_vs_new_visual_qa.json").write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    write_md(payload["old_vs_new_visual_qa"], out_dir)
    print(f"old-vs-new visual QA written: {out_dir / 'old_vs_new_visual_qa.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
