#!/usr/bin/env python3
"""Deterministic rendered-image QA for paperplot-skills.

Requires Pillow for raster images. SVG is inspected structurally with the
Python standard library and is not rasterized in v1.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import statistics
import sys
import xml.etree.ElementTree as ET
from collections import Counter, deque
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageChops, ImageStat
except Exception as exc:  # pragma: no cover
    Image = None
    PIL_IMPORT_ERROR = exc
else:
    PIL_IMPORT_ERROR = None

STATUS_PASS = "pass"
STATUS_WARN = "warn"
STATUS_FAIL = "fail"


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def status_from_score(score: int) -> str:
    if score <= 4:
        return STATUS_FAIL
    if score < 8:
        return STATUS_WARN
    return STATUS_PASS


def risk(status: str, code: str, message: str, value: Any = None) -> dict[str, Any]:
    out = {"status": status, "code": code, "message": message}
    if value is not None:
        out["value"] = value
    return out


def resolve_input(path: Path) -> Path:
    if path.is_dir():
        for ext in ("*.png", "*.jpg", "*.jpeg", "*.svg"):
            matches = sorted(path.glob(ext))
            if matches:
                return matches[0]
        raise SystemExit(f"No PNG/JPG/JPEG/SVG found in directory: {path}")
    if not path.exists():
        raise SystemExit(f"Input not found: {path}")
    return path


def luminance(rgb: tuple[int, int, int]) -> float:
    r, g, b = rgb
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def saturation(rgb: tuple[int, int, int]) -> float:
    r, g, b = [x / 255.0 for x in rgb]
    mx, mn = max(r, g, b), min(r, g, b)
    return 0.0 if mx == 0 else (mx - mn) / mx


def nonwhite_mask(img: Image.Image, threshold: int = 18) -> Image.Image:
    bg = Image.new("RGB", img.size, (255, 255, 255))
    diff = ImageChops.difference(img.convert("RGB"), bg).convert("L")
    return diff.point(lambda p: 255 if p > threshold else 0)


def component_summary(mask: Image.Image, max_dim: int = 720) -> dict[str, Any]:
    w, h = mask.size
    scale = min(1.0, max_dim / max(w, h))
    if scale < 1:
        small = mask.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.NEAREST)
    else:
        small = mask.copy()
    sw, sh = small.size
    pix = small.load()
    seen = bytearray(sw * sh)
    comps: list[tuple[int, int, int, int, int]] = []
    for y in range(sh):
        for x in range(sw):
            idx = y * sw + x
            if seen[idx] or pix[x, y] == 0:
                continue
            q = deque([(x, y)])
            seen[idx] = 1
            area = 0
            minx = maxx = x
            miny = maxy = y
            while q:
                cx, cy = q.popleft()
                area += 1
                minx, maxx = min(minx, cx), max(maxx, cx)
                miny, maxy = min(miny, cy), max(maxy, cy)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < sw and 0 <= ny < sh:
                        nidx = ny * sw + nx
                        if not seen[nidx] and pix[nx, ny] != 0:
                            seen[nidx] = 1
                            q.append((nx, ny))
            comps.append((area, minx, miny, maxx, maxy))
    small_components = []
    medium_components = []
    for area, minx, miny, maxx, maxy in comps:
        cw = maxx - minx + 1
        ch = maxy - miny + 1
        if 2 <= area <= 260 and 2 <= cw <= 80 and 3 <= ch <= 40:
            small_components.append((area, cw, ch))
        if 260 < area <= 6000:
            medium_components.append((area, cw, ch))
    return {
        "component_count": len(comps),
        "small_component_count": len(small_components),
        "medium_component_count": len(medium_components),
        "analysis_size_px": [sw, sh],
    }


def line_burden(mask: Image.Image) -> dict[str, Any]:
    w, h = mask.size
    max_dim = 900
    scale = min(1.0, max_dim / max(w, h))
    small = mask.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.NEAREST) if scale < 1 else mask
    sw, sh = small.size
    pix = small.load()
    horizontal = 0
    vertical = 0
    for y in range(sh):
        count = sum(1 for x in range(sw) if pix[x, y] != 0)
        if count / sw > 0.35:
            horizontal += 1
    for x in range(sw):
        count = sum(1 for y in range(sh) if pix[x, y] != 0)
        if count / sh > 0.35:
            vertical += 1
    burden = (horizontal + vertical) / max(sw + sh, 1)
    return {"horizontal_line_rows": horizontal, "vertical_line_cols": vertical, "line_burden_score": round(burden, 4)}


def analyze_raster(path: Path, out_dir: Path) -> dict[str, Any]:
    if Image is None:
        raise SystemExit(f"Pillow is required for visual QA v1: {PIL_IMPORT_ERROR}")
    img0 = Image.open(path)
    if img0.mode in ("RGBA", "LA"):
        bg = Image.new("RGBA", img0.size, (255, 255, 255, 255))
        bg.alpha_composite(img0.convert("RGBA"))
        img = bg.convert("RGB")
    else:
        img = img0.convert("RGB")
    w, h = img.size
    area = w * h
    mask = nonwhite_mask(img)
    bbox = mask.getbbox()
    nonwhite = sum(1 for p in mask.getdata() if p)
    content_density = nonwhite / max(area, 1)
    if bbox:
        bx0, by0, bx1, by1 = bbox
        bbox_area = (bx1 - bx0) * (by1 - by0)
        blank_margin_fraction = 1 - bbox_area / max(area, 1)
    else:
        bx0 = by0 = bx1 = by1 = 0
        bbox_area = 0
        blank_margin_fraction = 1.0
    gray = img.convert("L")
    grayscale_path = out_dir / "grayscale_preview.png"
    gray.save(grayscale_path)
    stat = ImageStat.Stat(gray)
    gray_mean = stat.mean[0]
    gray_std = stat.stddev[0]
    thumb = img.copy()
    thumb.thumbnail((360, 240))
    thumb_mask = nonwhite_mask(thumb)
    thumb_density = sum(1 for p in thumb_mask.getdata() if p) / max(thumb.size[0] * thumb.size[1], 1)
    q = img.resize((max(1, w // 4), max(1, h // 4))).quantize(colors=32, method=Image.Quantize.MEDIANCUT).convert("RGB")
    counts = Counter(q.getdata())
    dominant = []
    high_sat_pixels = 0
    content_pixels = 0
    for rgb, count in counts.most_common(12):
        if max(abs(c - 255) for c in rgb) <= 10:
            continue
        sat = saturation(rgb)
        lum = luminance(rgb)
        dominant.append({"rgb": list(rgb), "fraction": round(count / max(q.size[0] * q.size[1], 1), 4), "saturation": round(sat, 3), "luminance": round(lum, 1)})
        if sat > 0.55:
            high_sat_pixels += count
        content_pixels += count
    high_sat_fraction = high_sat_pixels / max(content_pixels, 1) if content_pixels else 0
    luminances = [d["luminance"] for d in dominant if d["saturation"] > 0.35]
    min_lum_delta = min([abs(a - b) for i, a in enumerate(luminances) for b in luminances[i + 1:]], default=999)
    comp = component_summary(mask)
    lines = line_burden(mask)
    text_density_score = comp["small_component_count"] / max((w * h) / 1_000_000, 0.1)
    color_count_estimate = len([d for d in dominant if d["fraction"] > 0.001])
    risks: list[dict[str, Any]] = []
    score = 10
    aspect = w / max(h, 1)
    if w < 900 or h < 500:
        risks.append(risk(STATUS_WARN, "low_pixel_dimensions", "PNG preview is small for detailed manuscript QA.", [w, h])); score -= 1
    if aspect > 3.0 or aspect < 0.45:
        risks.append(risk(STATUS_WARN, "extreme_aspect_ratio", "Aspect ratio is likely to create readability or layout problems.", round(aspect, 3))); score -= 1
    if blank_margin_fraction > 0.32:
        risks.append(risk(STATUS_WARN, "excessive_blank_margin", "Large blank/unused margin detected.", round(blank_margin_fraction, 3))); score -= 1
    if content_density < 0.035:
        risks.append(risk(STATUS_WARN, "low_content_density", "Figure may be sparse or dominated by whitespace.", round(content_density, 3))); score -= 1
    if text_density_score > 420:
        risks.append(risk(STATUS_WARN, "high_text_or_tick_density", "Many small dark components suggest dense labels, ticks, or annotations.", round(text_density_score, 1))); score -= 1
    if comp["medium_component_count"] >= 4 and content_density > 0.12:
        risks.append(risk(STATUS_WARN, "label_overlap_or_large_annotation_risk", "Several medium-sized text/annotation components suggest direct-label burden or overlap risk.", comp["medium_component_count"])); score -= 1
    if high_sat_fraction > 0.45 and color_count_estimate <= 6:
        risks.append(risk(STATUS_WARN, "saturated_presentation_palette", "Dominant colors are highly saturated and presentation-like.", round(high_sat_fraction, 3))); score -= 1
    if min_lum_delta < 18:
        risks.append(risk(STATUS_WARN, "grayscale_discrimination_risk", "Some colored classes may be hard to distinguish in grayscale.", round(min_lum_delta, 1))); score -= 1
    if gray_std < 28:
        risks.append(risk(STATUS_WARN, "low_grayscale_contrast", "Overall grayscale contrast is low.", round(gray_std, 1))); score -= 1
    if lines["line_burden_score"] > 0.022:
        risks.append(risk(STATUS_WARN, "gridline_or_long_line_burden", "Many long horizontal/vertical line structures detected.", lines["line_burden_score"])); score -= 1
    if thumb_density > 0.23:
        risks.append(risk(STATUS_WARN, "thumbnail_readability_risk", "Thumbnail view is visually dense; labels may fail at reduced size.", round(thumb_density, 3))); score -= 1
    if not risks:
        risks.append(risk(STATUS_PASS, "no_major_deterministic_risk", "No major deterministic visual QA risk detected."))
    score = max(0, min(10, score))
    status = status_from_score(score)
    if status == STATUS_PASS and any(item.get("status") == STATUS_WARN for item in risks):
        status = STATUS_WARN
    return {
        "checked": True,
        "engine": "pillow",
        "input_type": "raster",
        "input_path": str(path),
        "image_size_px": [w, h],
        "file_size_bytes": path.stat().st_size,
        "aspect_ratio": round(aspect, 4),
        "content_bbox_px": [bx0, by0, bx1, by1],
        "content_bbox_area_fraction": round(bbox_area / max(area, 1), 4),
        "blank_margin_fraction": round(blank_margin_fraction, 4),
        "content_density": round(content_density, 4),
        "thumbnail_content_density": round(thumb_density, 4),
        "grayscale_mean": round(gray_mean, 2),
        "grayscale_std": round(gray_std, 2),
        "color_count_estimate": color_count_estimate,
        "dominant_colors": dominant,
        "high_saturation_content_fraction": round(high_sat_fraction, 4),
        "minimum_colored_luminance_delta": None if min_lum_delta == 999 else round(min_lum_delta, 2),
        "component_summary": comp,
        "text_burden_score": round(text_density_score, 2),
        "line_burden": lines,
        "grayscale_preview": str(grayscale_path),
        "manuscript_readiness_score": score,
        "status": status,
        "top_risks": risks,
    }


def parse_length(value: str | None) -> float | None:
    if value is None:
        return None
    m = re.search(r"[-+]?[0-9]*\.?[0-9]+", value)
    return float(m.group(0)) if m else None


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def analyze_svg(path: Path, out_dir: Path) -> dict[str, Any]:
    text = path.read_text(errors="ignore")
    try:
        root = ET.fromstring(text)
    except ET.ParseError as exc:
        return {"checked": False, "engine": "svg-xml", "input_type": "svg", "input_path": str(path), "status": STATUS_FAIL, "top_risks": [risk(STATUS_FAIL, "svg_parse_error", str(exc))]}
    width = parse_length(root.attrib.get("width"))
    height = parse_length(root.attrib.get("height"))
    texts = []
    lines = []
    rects = []
    all_elements = list(root.iter())
    for el in all_elements:
        name = local_name(el.tag)
        if name == "text":
            fs = parse_length(el.attrib.get("font-size") or el.attrib.get("style", ""))
            x = parse_length(el.attrib.get("x"))
            y = parse_length(el.attrib.get("y"))
            weight = el.attrib.get("font-weight", "") or el.attrib.get("style", "")
            content = "".join(el.itertext()).strip()
            texts.append({"font_size": fs, "x": x, "y": y, "weight": weight, "text": content, "anchor": el.attrib.get("text-anchor", "")})
        elif name == "line":
            stroke = (el.attrib.get("stroke") or el.attrib.get("style", "")).lower()
            lines.append({"stroke": stroke})
        elif name == "rect":
            rects.append(dict(el.attrib))
    font_sizes = [t["font_size"] for t in texts if t["font_size"] is not None]
    max_font = max(font_sizes) if font_sizes else None
    min_font = min(font_sizes) if font_sizes else None
    median_font = statistics.median(font_sizes) if font_sizes else None
    light_gridlines = sum(1 for ln in lines if any(x in ln["stroke"] for x in ("#eee", "#eeeeee", "#e5e5e5", "#ddd", "#dddddd")))
    centered_large_titles = [t for t in texts if (t["font_size"] or 0) >= 18 and ("middle" in t["anchor"] or (width and t["x"] and abs(t["x"] - width / 2) < width * 0.12))]
    risks: list[dict[str, Any]] = []
    score = 10
    if max_font and max_font >= 18:
        risks.append(risk(STATUS_WARN, "oversized_svg_title_or_text", "SVG contains presentation-sized text.", max_font)); score -= 2
    if centered_large_titles:
        risks.append(risk(STATUS_WARN, "huge_centered_title", "Large centered title suggests presentation-style rather than manuscript panel style.", centered_large_titles[0].get("text", ""))); score -= 2
    if light_gridlines >= 5:
        risks.append(risk(STATUS_WARN, "svg_gridline_burden", "Many light gridlines detected.", light_gridlines)); score -= 1
    if len(texts) > 80:
        risks.append(risk(STATUS_WARN, "svg_text_burden", "Large number of text elements suggests dense labels/ticks.", len(texts))); score -= 1
    if width and height and (width / max(height, 1) > 3.0 or width / max(height, 1) < 0.45):
        risks.append(risk(STATUS_WARN, "svg_extreme_aspect_ratio", "SVG aspect ratio may be hard to place in manuscript layout.", round(width / max(height, 1), 3))); score -= 1
    if not risks:
        risks.append(risk(STATUS_PASS, "no_major_svg_structure_risk", "No major SVG structure risk detected."))
    score = max(0, min(10, score))
    return {
        "checked": True,
        "engine": "svg-xml",
        "input_type": "svg",
        "input_path": str(path),
        "canvas_size": [width, height],
        "file_size_bytes": path.stat().st_size,
        "text_count": len(texts),
        "line_count": len(lines),
        "rect_count": len(rects),
        "font_size_min": min_font,
        "font_size_median": median_font,
        "font_size_max": max_font,
        "light_gridline_count": light_gridlines,
        "centered_large_title_count": len(centered_large_titles),
        "manuscript_readiness_score": score,
        "status": STATUS_WARN if status_from_score(score) == STATUS_PASS and any(item.get("status") == STATUS_WARN for item in risks) else status_from_score(score),
        "top_risks": risks,
    }


def write_markdown(result: dict[str, Any], out_dir: Path) -> None:
    lines = [
        "# Visual QA",
        "",
        f"- input: `{result.get('input_path')}`",
        f"- engine: `{result.get('engine')}`",
        f"- status: `{result.get('status')}`",
        f"- manuscript readiness score: `{result.get('manuscript_readiness_score')}/10`",
        "",
        "## Key metrics",
        "",
    ]
    for key in ("image_size_px", "canvas_size", "aspect_ratio", "blank_margin_fraction", "content_density", "text_burden_score", "color_count_estimate", "grayscale_std", "line_burden", "text_count", "font_size_max", "light_gridline_count"):
        if key in result:
            lines.append(f"- {key}: `{result[key]}`")
    lines += ["", "## Top risks", ""]
    for item in result.get("top_risks", []):
        lines.append(f"- `{item.get('status')}` `{item.get('code')}`: {item.get('message')}" + (f" ({item.get('value')})" if "value" in item else ""))
    (out_dir / "visual_qa.md").write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Pillow-based rendered image visual QA for paperplot-skills.")
    parser.add_argument("input", help="PNG/JPG/JPEG/SVG file or output directory containing a rendered figure")
    parser.add_argument("--out", required=True, help="Output directory for visual_qa.json/md and grayscale preview when applicable")
    args = parser.parse_args()
    in_path = resolve_input(Path(args.input).expanduser())
    out_dir = Path(args.out).expanduser()
    ensure_dir(out_dir)
    ext = in_path.suffix.lower()
    if ext == ".svg":
        result = analyze_svg(in_path, out_dir)
    elif ext in {".png", ".jpg", ".jpeg"}:
        result = analyze_raster(in_path, out_dir)
    else:
        raise SystemExit(f"Unsupported visual QA input type: {in_path}")
    (out_dir / "visual_qa.json").write_text(json.dumps({"image_qa": result}, indent=2, ensure_ascii=False) + "\n")
    write_markdown(result, out_dir)
    print(f"visual QA written: {out_dir / 'visual_qa.json'}")
    return 0 if result.get("checked") else 1


if __name__ == "__main__":
    raise SystemExit(main())
