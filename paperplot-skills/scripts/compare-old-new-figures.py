#!/usr/bin/env python3
"""Old-vs-new visual comparison for paperplot-skills."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def run_visual_qa(image: Path, out_dir: Path, family: str | None = None) -> dict[str, Any]:
    script = Path(__file__).with_name("visual-qa-rendered-image.py")
    ensure_dir(out_dir)
    cmd = [sys.executable, str(script), str(image), "--out", str(out_dir)]
    if family:
        cmd.extend(["--family", family])
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        raise SystemExit(f"visual QA failed for {image}: {proc.stderr or proc.stdout}")
    payload = json.loads((out_dir / "visual_qa.json").read_text())
    return payload["image_qa"]


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


def write_md(payload: dict[str, Any], out_dir: Path) -> None:
    lines = [
        "# Old-vs-new visual QA",
        "",
        f"- old: `{payload['old_image']}`",
        f"- new: `{payload['new_image']}`",
        f"- media: `{payload.get('old_media', 'unknown')}` -> `{payload.get('new_media', 'unknown')}`",
        f"- threshold profiles: `{payload.get('old_threshold_profile', 'global')}` -> `{payload.get('new_threshold_profile', 'global')}`",
        f"- verdict: `{payload['verdict']}`",
        f"- status: `{payload['status']}`",
        "",
        "## Metric deltas",
        "",
        "| metric | old | new | delta |",
        "|---|---:|---:|---|",
    ]
    for row in payload["metric_deltas"]:
        lines.append(f"| {row['metric']} | {row['old']} | {row['new']} | {row['delta']} |")
    lines += ["", "## Remaining risks", ""]
    if payload["remaining_risks"]:
        for item in payload["remaining_risks"]:
            lines.append(f"- {item}")
    else:
        lines.append("- No major deterministic worsening detected.")
    (out_dir / "old_vs_new_visual_qa.md").write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare old and new rendered figures using deterministic visual QA metrics.")
    parser.add_argument("old_image")
    parser.add_argument("new_image")
    parser.add_argument("--out", required=True)
    parser.add_argument("--family", default=None, help="Optional family profile applied to both old and new figures")
    parser.add_argument("--old-family", default=None, help="Optional family profile for the old figure")
    parser.add_argument("--new-family", default=None, help="Optional family profile for the new figure")
    args = parser.parse_args()
    old_path = Path(args.old_image).expanduser()
    new_path = Path(args.new_image).expanduser()
    out_dir = Path(args.out).expanduser()
    ensure_dir(out_dir)
    with tempfile.TemporaryDirectory(prefix="paperplot-old-new-") as tmp:
        tmp_path = Path(tmp)
        old = run_visual_qa(old_path, tmp_path / "old", args.old_family or args.family)
        new = run_visual_qa(new_path, tmp_path / "new", args.new_family or args.family)
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
    deltas.append({"metric": "manuscript_readiness_score", "old": old.get("manuscript_readiness_score"), "new": new.get("manuscript_readiness_score"), "delta": score_delta(int(old.get("manuscript_readiness_score", 0)), int(new.get("manuscript_readiness_score", 0)))})
    verdict = verdict_from_deltas([d["delta"] for d in deltas])
    remaining = []
    if verdict in {"worse", "mixed"}:
        for d in deltas:
            if d["delta"] == "worse":
                remaining.append(f"{d['metric']} worsened from {d['old']} to {d['new']}")
    new_score = int(new.get("manuscript_readiness_score", 0))
    old_score = int(old.get("manuscript_readiness_score", 0))
    old_media = media_kind(old_path)
    new_media = media_kind(new_path)
    comparison_limitation = None
    if old_media != new_media and "svg" in {old_media, new_media}:
        comparison_limitation = (
            "Mixed SVG/raster comparison: SVG structural QA does not expose the same raster "
            "density, text, and color metrics. Treat deterministic deltas as a review prompt."
        )
        remaining.insert(0, comparison_limitation)
    status = "pass"
    if new_score < old_score or verdict == "worse":
        status = "fail"
    elif verdict == "mixed":
        status = "warn"
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
            "verdict": verdict,
            "status": status,
            "message_clarity_delta": "unknown",
            "visual_burden_delta": verdict,
            "metric_deltas": deltas,
            "old_score": old_score,
            "new_score": new_score,
            "remaining_risks": remaining,
        }
    }
    (out_dir / "old_vs_new_visual_qa.json").write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    write_md(payload["old_vs_new_visual_qa"], out_dir)
    print(f"old-vs-new visual QA written: {out_dir / 'old_vs_new_visual_qa.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
