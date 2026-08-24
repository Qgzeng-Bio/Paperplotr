#!/usr/bin/env python3
"""Mine automatic QA examples from Nature-detail calibration output.

The script creates weak labels without human scoring:

- auto_positive: high-quality generalizable calibration images.
- auto_caution: specialized/decorative images used for boundary rules.
- auto_negative: synthetic degradations of positives, with transparent
  degradation metadata and expected risks.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw, ImageEnhance, ImageFilter
except Exception as exc:  # pragma: no cover - surfaced in runtime report
    Image = None
    ImageDraw = None
    ImageEnhance = None
    ImageFilter = None
    PIL_ERROR = exc
else:
    PIL_ERROR = None


ROOT = Path(__file__).resolve().parents[1]
VISUAL_QA = ROOT / "scripts" / "visual-qa-rendered-image.py"


def load_samples(path: Path) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return list(payload.get("samples", []))


def risk_codes(sample: dict[str, Any]) -> set[str]:
    return {item.get("code", "") for item in sample.get("top_risks", []) if item.get("status") != "pass"}


def is_positive(sample: dict[str, Any]) -> bool:
    return (
        sample.get("sample_class") == "generalizable_positive"
        and sample.get("status") in {"pass", "warn"}
        and float(sample.get("manuscript_readiness_score") or 0) >= 7
        and not risk_codes(sample).intersection({"text_data_overlap_risk", "panel_data_region_mismatch", "font_too_small_at_target_width"})
    )


def is_caution(sample: dict[str, Any]) -> bool:
    return sample.get("sample_class") in {"specialized_positive", "decorative_or_caution", "not_for_threshold_learning"}


def image_path(sample: dict[str, Any]) -> Path | None:
    value = sample.get("image") or sample.get("input_path")
    if not value:
        return None
    path = Path(value).expanduser()
    if path.exists() and path.suffix.lower() in {".png", ".jpg", ".jpeg"}:
        return path
    return None


def degradation_specs() -> list[dict[str, Any]]:
    return [
        {"name": "heavy_grid", "expected_risks": ["grid_background_burden", "gridline_or_long_line_burden"]},
        {"name": "oversized_title", "expected_risks": ["significance_annotation_overcrowding", "high_text_or_tick_density", "thumbnail_readability_risk"]},
        {"name": "text_overlap", "expected_risks": ["text_data_overlap_risk", "label_overlap_or_large_annotation_risk", "significance_annotation_overcrowding"]},
        {"name": "low_resolution", "expected_risks": ["low_pixel_dimensions", "thumbnail_readability_risk"]},
        {"name": "high_saturation", "expected_risks": ["saturated_presentation_palette", "decorative_background_risk", "grayscale_discrimination_risk"]},
    ]


def draw_text_blocks(draw: Any, w: int, h: int) -> None:
    for i in range(18):
        x = int(w * (0.18 + 0.038 * i))
        y = int(h * (0.28 + 0.03 * (i % 5)))
        draw.rectangle((x, y, min(w - 8, x + int(w * 0.065)), min(h - 8, y + int(h * 0.028))), fill="#111111")
        draw.text((x, min(h - 8, y + int(h * 0.033))), "label", fill="#111111")


def degrade_image(src: Path, dst: Path, operation: str) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError(f"Pillow is required for synthetic negatives: {PIL_ERROR}")
    img = Image.open(src).convert("RGB")
    w, h = img.size
    if operation == "heavy_grid":
        draw = ImageDraw.Draw(img)
        step_x = max(24, w // 22)
        step_y = max(20, h // 20)
        for x in range(step_x, w, step_x):
            draw.line((x, 0, x, h), fill="#d6d6d6", width=max(1, w // 550))
        for y in range(step_y, h, step_y):
            draw.line((0, y, w, y), fill="#d6d6d6", width=max(1, h // 550))
    elif operation == "oversized_title":
        canvas = Image.new("RGB", (w, int(h * 1.16)), "white")
        canvas.paste(img, (0, int(h * 0.16)))
        draw = ImageDraw.Draw(canvas)
        draw.text((int(w * 0.08), int(h * 0.03)), "Large presentation-style figure title", fill="#111111")
        for i in range(10):
            x0 = int(w * (0.18 + 0.055 * i))
            draw.rectangle((x0, int(h * 0.055), x0 + int(w * 0.10), int(h * 0.095)), fill="#111111")
        img = canvas
    elif operation == "text_overlap":
        draw = ImageDraw.Draw(img)
        draw_text_blocks(draw, w, h)
    elif operation == "low_resolution":
        img = img.resize((min(620, max(180, w // 4)), min(420, max(140, h // 4))), Image.Resampling.BILINEAR)
        if ImageFilter:
            img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    elif operation == "high_saturation":
        img = ImageEnhance.Color(img).enhance(2.8) if ImageEnhance else img
        draw = ImageDraw.Draw(img)
        overlay_h = max(30, h // 10)
        for i, color in enumerate(["#ff0054", "#e60073", "#cc0088", "#aa00aa"]):
            draw.rectangle((int(w * 0.03) + i * int(w * 0.13), int(h * 0.03), int(w * 0.13) + i * int(w * 0.13), int(h * 0.03) + overlay_h), fill=color)
    else:
        raise ValueError(operation)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst)


def run_visual_qa(path: Path, out_dir: Path, family: str | None = None) -> set[str]:
    cmd = [
        sys.executable,
        str(VISUAL_QA),
        str(path),
        "--out",
        str(out_dir),
        "--ocr",
        "off",
        "--target-width-mm",
        "89",
        "--journal-profile",
        "nature",
        "--allow-grid",
        "auto",
    ]
    if family:
        cmd.extend(["--family", family])
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        return set()
    payload = json.loads((out_dir / "visual_qa.json").read_text(encoding="utf-8"))["image_qa"]
    return risk_codes(payload)


def mine_examples(samples: list[dict[str, Any]], image_out_dir: Path, max_negatives: int, run_qa: bool) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    positives = [s for s in samples if is_positive(s)]
    caution = [s for s in samples if is_caution(s)]
    examples: list[dict[str, Any]] = []
    for sample in positives:
        examples.append({
            "image": sample.get("image") or sample.get("input_path"),
            "label": "auto_positive",
            "source": "nature_detail_calibration",
            "case_dir": sample.get("case_dir"),
            "figure_family": sample.get("figure_family"),
            "score": sample.get("manuscript_readiness_score"),
            "risks": sorted(risk_codes(sample)),
        })
    for sample in caution:
        examples.append({
            "image": sample.get("image") or sample.get("input_path"),
            "label": "auto_caution",
            "source": "nature_detail_calibration_boundary_rule",
            "case_dir": sample.get("case_dir"),
            "figure_family": sample.get("figure_family"),
            "sample_class": sample.get("sample_class"),
            "score": sample.get("manuscript_readiness_score"),
            "risks": sorted(risk_codes(sample)),
        })

    generated = 0
    expected_total = 0
    detected_total = 0
    specs = degradation_specs()
    for sample in positives:
        src = image_path(sample)
        if not src:
            continue
        for spec in specs:
            if generated >= max_negatives:
                break
            stem = f"negative_{generated + 1:03d}_{spec['name']}_{src.stem}.png"
            dst = image_out_dir / stem
            try:
                degrade_image(src, dst, spec["name"])
            except Exception:
                continue
            detected = run_visual_qa(dst, image_out_dir / f"{dst.stem}_qa", sample.get("figure_family")) if run_qa else set()
            expected = set(spec["expected_risks"])
            expected_total += 1
            detected_total += 1 if expected.intersection(detected) else 0
            examples.append({
                "image": str(dst),
                "label": "auto_negative",
                "source": "synthetic_degradation",
                "parent_image": str(src),
                "case_dir": sample.get("case_dir"),
                "figure_family": sample.get("figure_family"),
                "degradation": [spec["name"]],
                "expected_risks": spec["expected_risks"],
                "detected_risks": sorted(detected),
                "expected_risks_detected": sorted(expected.intersection(detected)),
            })
            generated += 1
        if generated >= max_negatives:
            break
    stats = {
        "auto_positive_count": len(positives),
        "auto_caution_count": len(caution),
        "auto_negative_count": generated,
        "expected_risk_detection_fraction": None if expected_total == 0 else round(detected_total / expected_total, 4),
        "pillow_available": Image is not None,
        "visual_qa_run_on_synthetic_negatives": run_qa,
    }
    return examples, stats


def write_markdown(examples: list[dict[str, Any]], stats: dict[str, Any], out: Path, out_json: Path, image_dir: Path) -> None:
    lines = [
        "# Auto-Mined QA Examples",
        "",
        "Generated by `scripts/mine-auto-qa-examples.py`. Labels are weak labels produced from calibration metadata and transparent synthetic degradations; they are not human annotations.",
        "",
        "## Summary",
        "",
        f"- auto positives: {stats['auto_positive_count']}",
        f"- auto cautions: {stats['auto_caution_count']}",
        f"- synthetic negatives: {stats['auto_negative_count']}",
        f"- expected synthetic risk detection fraction: `{stats['expected_risk_detection_fraction']}`",
        f"- synthetic image directory: `{image_dir}`",
        f"- JSON manifest: `{out_json}`",
        "",
        "## Label Semantics",
        "",
        "- `auto_positive`: generalizable Nature-like calibration samples with acceptable deterministic QA.",
        "- `auto_caution`: specialized/decorative/boundary samples used to avoid wrong global thresholds.",
        "- `auto_negative`: generated degradations such as heavy grid, oversized title, text overlap, low resolution, or high saturation.",
        "",
        "## Synthetic Negatives",
        "",
        "| image | parent | degradation | expected risks | detected risks |",
        "|---|---|---|---|---|",
    ]
    for item in examples:
        if item.get("label") != "auto_negative":
            continue
        lines.append(
            f"| `{item.get('image')}` | `{item.get('parent_image')}` | {', '.join(item.get('degradation', []))} | "
            f"{', '.join(item.get('expected_risks', []))} | {', '.join(item.get('detected_risks', [])) or '-'} |"
        )
    lines += [
        "",
        "## Positive/Caution Counts By Family",
        "",
        "| label | family | n |",
        "|---|---|---:|",
    ]
    counts: dict[tuple[str, str], int] = {}
    for item in examples:
        if item.get("label") == "auto_negative":
            continue
        key = (item.get("label", ""), item.get("figure_family", "unknown"))
        counts[key] = counts.get(key, 0) + 1
    for (label, family), count in sorted(counts.items()):
        lines.append(f"| {label} | {family} | {count} |")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Mine weak-label QA examples and synthetic negative figures.")
    parser.add_argument("--calibration-json", required=True, help="Path to nature-detail-qa-calibration.json")
    parser.add_argument("--out", required=True, help="Markdown report output path")
    parser.add_argument("--out-json", default=None, help="JSON manifest path; defaults beside --out")
    parser.add_argument("--image-out-dir", default=None, help="Directory for generated synthetic negative images")
    parser.add_argument("--max-negatives", type=int, default=30, help="Maximum synthetic negatives to generate")
    parser.add_argument("--skip-qa", action="store_true", help="Skip visual QA on generated synthetic negatives")
    args = parser.parse_args()

    out = Path(args.out).expanduser()
    out_json = Path(args.out_json).expanduser() if args.out_json else out.with_suffix(".json")
    image_dir = Path(args.image_out_dir).expanduser() if args.image_out_dir else out.with_suffix("").parent / "auto-mined-qa-examples"
    samples = load_samples(Path(args.calibration_json).expanduser())
    examples, stats = mine_examples(samples, image_dir, args.max_negatives, not args.skip_qa)
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps({"stats": stats, "examples": examples}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_markdown(examples, stats, out, out_json, image_dir)
    print(f"auto-mined QA examples written: {out}")
    print(f"auto-mined QA manifest written: {out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
