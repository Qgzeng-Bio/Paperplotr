#!/usr/bin/env python3
"""Deterministic rendered-image QA for paperplot-skills.

Raster images are inspected directly. PDF and SVG inputs are rendered to PNG
first so the same pixel-level QA applies across formats. SVG structural checks
are retained as supplemental signals. OCR is optional: when Tesseract is
available it adds text-box diagnostics; otherwise the QA records the missing
engine and continues unless --ocr required is used.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import shutil
import statistics
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter, deque
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageChops, ImageDraw, ImageStat
except Exception as exc:  # pragma: no cover
    Image = None
    PIL_IMPORT_ERROR = exc
else:
    PIL_IMPORT_ERROR = None

STATUS_PASS = "pass"
STATUS_WARN = "warn"
STATUS_FAIL = "fail"

BASE_RASTER_THRESHOLDS = {
    "min_width_px": 900,
    "min_height_px": 500,
    "aspect_min": 0.45,
    "aspect_max": 3.0,
    "blank_margin_warn": 0.32,
    "content_density_min": 0.035,
    "text_density_warn": 420,
    "label_overlap_medium_count": 4,
    "label_overlap_content_density": 0.12,
    "high_saturation_fraction_warn": 0.45,
    "minimum_luminance_delta_warn": 18,
    "grayscale_std_min": 28,
    "line_burden_warn": 0.022,
    "thumbnail_density_warn": 0.23,
}

BASE_SVG_THRESHOLDS = {
    "max_font_warn": 18,
    "large_title_font_warn": 18,
    "light_gridline_warn": 5,
    "text_count_warn": 80,
    "aspect_min": 0.45,
    "aspect_max": 3.0,
}

FAMILY_ALIASES = {
    "rank": "rank-lollipop",
    "rank-plot": "rank-lollipop",
    "lollipop": "rank-lollipop",
    "dotplot": "rank-lollipop",
    "dumbbell": "rank-lollipop",
    "model-validation": "model-validation",
    "validation": "model-validation",
    "prediction": "model-validation",
    "heatmap": "heatmap",
    "correlation-heatmap": "heatmap",
    "matrix-dotplot": "heatmap",
    "manhattan": "manhattan",
    "genomewide": "manhattan",
    "genome-wide": "manhattan",
    "phylo": "phylo-annotation-ring",
    "phylogenetic": "phylo-annotation-ring",
    "tree": "phylo-annotation-ring",
    "phylo-annotation-ring": "phylo-annotation-ring",
}

FAMILY_RASTER_OVERRIDES = {
    "rank-lollipop": {
        "content_density_min": 0.02,
        "line_burden_warn": 0.055,
        "blank_margin_warn": 0.38,
    },
    "model-validation": {
        "content_density_min": 0.02,
        "line_burden_warn": 0.035,
        "thumbnail_density_warn": 0.28,
    },
    "heatmap": {
        "text_density_warn": 780,
        "line_burden_warn": 0.08,
        "thumbnail_density_warn": 0.55,
        "content_density_min": 0.025,
    },
    "manhattan": {
        "aspect_max": 3.6,
        "text_density_warn": 650,
        "line_burden_warn": 0.04,
        "thumbnail_density_warn": 0.42,
    },
    "phylo-annotation-ring": {
        "text_density_warn": 900,
        "line_burden_warn": 0.08,
        "thumbnail_density_warn": 0.55,
        "content_density_min": 0.02,
    },
}

FAMILY_SVG_OVERRIDES = {
    "phylo-annotation-ring": {
        "text_count_warn": 250,
        "light_gridline_warn": 20,
    },
    "heatmap": {
        "text_count_warn": 180,
        "light_gridline_warn": 30,
    },
    "manhattan": {
        "aspect_max": 3.6,
        "light_gridline_warn": 15,
    },
}


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


def normalize_family(figure_family: str | None) -> str | None:
    if not figure_family:
        return None
    cleaned = re.sub(r"[^a-z0-9]+", "-", figure_family.strip().lower()).strip("-")
    if not cleaned:
        return None
    if "heatmap" in cleaned or "matrix-dotplot" in cleaned:
        return "heatmap"
    if "manhattan" in cleaned or "genomewide" in cleaned or "genome-wide" in cleaned:
        return "manhattan"
    if "phylo" in cleaned or "tree" in cleaned:
        return "phylo-annotation-ring"
    if "lollipop" in cleaned or "dumbbell" in cleaned:
        return "rank-lollipop"
    if "dotplot" in cleaned and "matrix-dotplot" not in cleaned:
        return "rank-lollipop"
    if "model-validation" in cleaned or "prediction" in cleaned or "validation" in cleaned:
        return "model-validation"
    for alias, canonical in FAMILY_ALIASES.items():
        alias_clean = re.sub(r"[^a-z0-9]+", "-", alias).strip("-")
        if cleaned == alias_clean or alias_clean in cleaned:
            return canonical
    return cleaned


def threshold_profile(input_type: str, figure_family: str | None) -> tuple[str, dict[str, float]]:
    canonical = normalize_family(figure_family)
    base = dict(BASE_RASTER_THRESHOLDS if input_type == "raster" else BASE_SVG_THRESHOLDS)
    if not canonical:
        return "global", base
    overrides = FAMILY_RASTER_OVERRIDES if input_type == "raster" else FAMILY_SVG_OVERRIDES
    if canonical in overrides:
        base.update(overrides[canonical])
        return canonical, base
    return "global", base


def resolve_input(path: Path) -> Path:
    if path.is_dir():
        for ext in ("*.png", "*.jpg", "*.jpeg", "*.svg", "*.pdf"):
            matches = sorted(path.glob(ext))
            if matches:
                return matches[0]
        raise SystemExit(f"No PNG/JPG/JPEG/SVG/PDF found in directory: {path}")
    if not path.exists():
        raise SystemExit(f"Input not found: {path}")
    return path


def run_command(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True)


def style_value(style: str, key: str) -> str | None:
    for part in style.split(";"):
        if ":" not in part:
            continue
        k, v = part.split(":", 1)
        if k.strip() == key:
            return v.strip()
    return None


def svg_attr(el: ET.Element, key: str, default: str | None = None) -> str | None:
    return el.attrib.get(key) or style_value(el.attrib.get("style", ""), key) or default


def svg_color(value: str | None, default: str = "#333333") -> str | None:
    if value is None:
        return default
    value = value.strip()
    if value in {"none", "transparent"}:
        return None
    if value.startswith("#"):
        return value
    named = {
        "black": "#000000",
        "white": "#ffffff",
        "gray": "#808080",
        "grey": "#808080",
        "red": "#cc3333",
        "blue": "#3366aa",
        "green": "#339966",
    }
    return named.get(value.lower(), default)


def rasterize_svg_with_pillow(path: Path, out_path: Path) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for SVG fallback rasterization.")
    root = ET.fromstring(path.read_text(errors="ignore"))
    width = parse_length(root.attrib.get("width")) or 1200
    height = parse_length(root.attrib.get("height")) or 900
    if root.attrib.get("viewBox"):
        nums = [float(x) for x in re.findall(r"[-+]?[0-9]*\.?[0-9]+", root.attrib["viewBox"])]
        if len(nums) == 4:
            width = width or nums[2]
            height = height or nums[3]
    scale = min(1.0, 2400 / max(width, height, 1))
    canvas_w = max(1, int(width * scale))
    canvas_h = max(1, int(height * scale))
    img = Image.new("RGB", (canvas_w, canvas_h), "white")
    draw = ImageDraw.Draw(img)

    def sx(v: str | None, default: float = 0) -> int:
        return int(round((parse_length(v) if v is not None else default) * scale))

    for el in root.iter():
        name = local_name(el.tag)
        if name == "rect":
            x = sx(el.attrib.get("x"))
            y = sx(el.attrib.get("y"))
            w = sx(el.attrib.get("width"))
            h = sx(el.attrib.get("height"))
            fill = svg_color(svg_attr(el, "fill"), None)  # type: ignore[arg-type]
            stroke = svg_color(svg_attr(el, "stroke"), None)  # type: ignore[arg-type]
            draw.rectangle((x, y, x + w, y + h), fill=fill, outline=stroke)
        elif name == "line":
            stroke = svg_color(svg_attr(el, "stroke"), "#333333")
            if stroke:
                draw.line((sx(el.attrib.get("x1")), sx(el.attrib.get("y1")), sx(el.attrib.get("x2")), sx(el.attrib.get("y2"))), fill=stroke, width=max(1, sx(svg_attr(el, "stroke-width"), 1)))
        elif name == "circle":
            fill = svg_color(svg_attr(el, "fill"), "#333333")
            stroke = svg_color(svg_attr(el, "stroke"), None)  # type: ignore[arg-type]
            cx = sx(el.attrib.get("cx"))
            cy = sx(el.attrib.get("cy"))
            r = sx(el.attrib.get("r"), 3)
            draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=stroke)
        elif name == "text":
            text = "".join(el.itertext()).strip()
            if not text:
                continue
            x = sx(el.attrib.get("x"))
            y = sx(el.attrib.get("y"))
            fs = max(6, sx(svg_attr(el, "font-size"), 10))
            color = svg_color(svg_attr(el, "fill"), "#333333") or "#333333"
            # Draw a text proxy rectangle first so text burden is visible even
            # when platform fonts are unavailable.
            proxy_w = max(fs, int(len(text) * fs * 0.55))
            proxy_h = max(5, int(fs * 0.7))
            draw.rectangle((x, y - proxy_h, x + proxy_w, y), fill=color)
    img.save(out_path)


def rasterize_input(path: Path, out_dir: Path, dpi: int, page: int) -> tuple[Path, dict[str, Any]]:
    ext = path.suffix.lower()
    if ext in {".png", ".jpg", ".jpeg"}:
        return path, {
            "performed": False,
            "engine": "native",
            "source_type": "raster",
            "source_path": str(path),
            "raster_path": str(path),
            "dpi": None,
            "page": None,
        }

    if ext == ".pdf":
        exe = shutil.which("pdftoppm")
        if not exe:
            raise SystemExit("PDF visual QA requires pdftoppm on PATH.")
        stem = out_dir / "rasterized_input"
        cmd = [exe, "-singlefile", "-f", str(page), "-l", str(page), "-r", str(dpi), "-png", str(path), str(stem)]
        proc = run_command(cmd)
        out_path = stem.with_suffix(".png")
        if proc.returncode != 0 or not out_path.exists():
            raise SystemExit(f"PDF rasterization failed: {proc.stderr or proc.stdout}")
        return out_path, {
            "performed": True,
            "engine": "pdftoppm",
            "source_type": "pdf",
            "source_path": str(path),
            "raster_path": str(out_path),
            "dpi": dpi,
            "page": page,
            "command": cmd,
        }

    if ext == ".svg":
        exe = shutil.which("magick") or shutil.which("convert")
        if not exe:
            raise SystemExit("SVG visual QA requires ImageMagick `magick` or `convert` on PATH.")
        out_path = out_dir / "rasterized_input.png"
        cmd = [
            exe,
            "-density",
            str(dpi),
            str(path),
            "-background",
            "white",
            "-alpha",
            "remove",
            "-alpha",
            "off",
            str(out_path),
        ]
        proc = run_command(cmd)
        if proc.returncode != 0 or not out_path.exists():
            try:
                rasterize_svg_with_pillow(path, out_path)
            except Exception as exc:
                raise SystemExit(f"SVG rasterization failed: {proc.stderr or proc.stdout}; fallback failed: {exc}") from exc
            return out_path, {
                "performed": True,
                "engine": "svg-pillow-fallback",
                "fallback_from": Path(exe).name,
                "fallback_reason": (proc.stderr or proc.stdout).strip().splitlines()[0] if (proc.stderr or proc.stdout) else "unknown",
                "source_type": "svg",
                "source_path": str(path),
                "raster_path": str(out_path),
                "dpi": dpi,
                "page": None,
                "command": cmd,
            }
        return out_path, {
            "performed": True,
            "engine": Path(exe).name,
            "source_type": "svg",
            "source_path": str(path),
            "raster_path": str(out_path),
            "dpi": dpi,
            "page": None,
            "command": cmd,
        }

    raise SystemExit(f"Unsupported visual QA input type: {path}")


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


def find_segments(values: list[int], threshold: int, min_len: int, lo: int, hi: int) -> list[tuple[int, int]]:
    segments: list[tuple[int, int]] = []
    start: int | None = None
    for i, value in enumerate(values):
        is_gap = value <= threshold and lo <= i <= hi
        if is_gap and start is None:
            start = i
        elif not is_gap and start is not None:
            if i - start >= min_len:
                segments.append((start, i))
            start = None
    if start is not None and len(values) - start >= min_len:
        segments.append((start, len(values)))
    return segments


def best_split(mask: Image.Image, box: tuple[int, int, int, int]) -> tuple[str, int, int, float] | None:
    x0, y0, x1, y1 = box
    bw = x1 - x0
    bh = y1 - y0
    if bw < 100 or bh < 100:
        return None
    pix = mask.load()
    col_counts = [sum(1 for y in range(y0, y1) if pix[x0 + dx, y] != 0) for dx in range(bw)]
    row_counts = [sum(1 for x in range(x0, x1) if pix[x, y0 + dy] != 0) for dy in range(bh)]
    col_threshold = max(1, int(bh * 0.012))
    row_threshold = max(1, int(bw * 0.012))
    col_min = max(8, int(bw * 0.025))
    row_min = max(8, int(bh * 0.025))
    col_segments = find_segments(col_counts, col_threshold, col_min, int(bw * 0.12), int(bw * 0.88))
    row_segments = find_segments(row_counts, row_threshold, row_min, int(bh * 0.12), int(bh * 0.88))
    candidates: list[tuple[str, int, int, float]] = []
    for start, end in col_segments:
        score = (end - start) / max(bw, 1)
        candidates.append(("vertical", x0 + start, x0 + end, score))
    for start, end in row_segments:
        score = (end - start) / max(bh, 1)
        candidates.append(("horizontal", y0 + start, y0 + end, score))
    if not candidates:
        return None
    return max(candidates, key=lambda item: item[3])


def trim_to_content(mask: Image.Image, box: tuple[int, int, int, int], pad: int = 2) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = box
    crop = mask.crop((x0, y0, x1, y1))
    bbox = crop.getbbox()
    if not bbox:
        return box
    bx0, by0, bx1, by1 = bbox
    return (
        max(x0, x0 + bx0 - pad),
        max(y0, y0 + by0 - pad),
        min(x1, x0 + bx1 + pad),
        min(y1, y0 + by1 + pad),
    )


def scale_box(box: tuple[int, int, int, int], inv_scale: float, max_w: int, max_h: int) -> list[int]:
    x0, y0, x1, y1 = box
    return [
        max(0, min(max_w, int(round(x0 * inv_scale)))),
        max(0, min(max_h, int(round(y0 * inv_scale)))),
        max(0, min(max_w, int(round(x1 * inv_scale)))),
        max(0, min(max_h, int(round(y1 * inv_scale)))),
    ]


def ratio_max_min(values: list[float]) -> float | None:
    positive = [v for v in values if v > 0]
    if not positive:
        return None
    return max(positive) / max(min(positive), 1e-9)


def coeff_var(values: list[float]) -> float | None:
    if not values:
        return None
    mean = statistics.mean(values)
    if mean <= 0:
        return None
    return statistics.pstdev(values) / mean


def detect_panel_geometry(mask: Image.Image, expected_panels: int | None, layout_profile: str) -> dict[str, Any]:
    w, h = mask.size
    bbox = mask.getbbox()
    if not bbox:
        return {
            "checked": True,
            "method": "projection-gutter-v1",
            "expected_panels": expected_panels,
            "layout_profile": layout_profile,
            "panel_count_detected": 0,
            "panels": [],
            "risks": [risk(STATUS_WARN, "panel_detection_empty", "No visible content found for panel geometry QA.")],
        }

    max_dim = 1200
    scale = min(1.0, max_dim / max(w, h))
    small = mask.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.NEAREST) if scale < 1 else mask.copy()
    inv_scale = 1 / scale if scale else 1
    small_bbox = tuple(max(0, int(round(v * scale))) for v in bbox)
    boxes = [small_bbox]  # type: ignore[list-item]
    target = expected_panels if expected_panels and expected_panels > 1 else 1
    if layout_profile == "auto" and not expected_panels:
        target = 1
    while len(boxes) < target:
        split_options = []
        for idx, box in enumerate(boxes):
            split = best_split(small, box)
            if split:
                split_options.append((split[3], idx, split))
        if not split_options:
            break
        _, idx, split = max(split_options, key=lambda item: item[0])
        axis, start, end, _score = split
        x0, y0, x1, y1 = boxes.pop(idx)
        if axis == "vertical":
            left = (x0, y0, start, y1)
            right = (end, y0, x1, y1)
            boxes.extend([left, right])
        else:
            top = (x0, y0, x1, start)
            bottom = (x0, end, x1, y1)
            boxes.extend([top, bottom])
        boxes = [b for b in boxes if (b[2] - b[0]) * (b[3] - b[1]) > 1000]

    boxes = sorted(boxes, key=lambda b: (b[1], b[0]))
    panels = []
    panel_area_fracs = []
    content_area_fracs = []
    blank_fracs = []
    total_area = w * h
    for i, small_box in enumerate(boxes, start=1):
        trimmed_small = trim_to_content(small, small_box)
        panel_box = scale_box(small_box, inv_scale, w, h)
        content_box = scale_box(trimmed_small, inv_scale, w, h)
        px0, py0, px1, py1 = panel_box
        cx0, cy0, cx1, cy1 = content_box
        panel_area = max((px1 - px0) * (py1 - py0), 0)
        content_area = max((cx1 - cx0) * (cy1 - cy0), 0)
        blank_fraction = 1 - content_area / max(panel_area, 1)
        panel_area_frac = panel_area / max(total_area, 1)
        content_area_frac = content_area / max(total_area, 1)
        panel_area_fracs.append(panel_area_frac)
        content_area_fracs.append(content_area_frac)
        blank_fracs.append(blank_fraction)
        panels.append({
            "panel_id": i,
            "panel_box_px": panel_box,
            "content_bbox_px": content_box,
            "panel_area_fraction": round(panel_area_frac, 4),
            "content_area_fraction": round(content_area_frac, 4),
            "blank_fraction": round(blank_fraction, 4),
        })

    panel_ratio = ratio_max_min(panel_area_fracs)
    content_ratio = ratio_max_min(content_area_fracs)
    blank_range = max(blank_fracs) - min(blank_fracs) if blank_fracs else None
    risks = []
    if expected_panels and len(panels) != expected_panels:
        risks.append(risk(STATUS_WARN, "panel_count_mismatch", "Detected panel count does not match expected panel count.", {"expected": expected_panels, "detected": len(panels)}))
    if layout_profile == "equal" and len(panels) > 1:
        if panel_ratio and panel_ratio > 1.25:
            risks.append(risk(STATUS_WARN, "panel_size_imbalance", "Equal-role panels have materially different panel-box sizes.", round(panel_ratio, 3)))
        if content_ratio and content_ratio > 1.35:
            risks.append(risk(STATUS_WARN, "panel_data_region_imbalance", "Equal-role panels have materially different visible data-region sizes.", round(content_ratio, 3)))
        if blank_range and blank_range > 0.25:
            risks.append(risk(STATUS_WARN, "panel_blank_space_imbalance", "Panel blank-space fractions are inconsistent.", round(blank_range, 3)))
    if layout_profile == "hierarchical" and len(panels) > 1:
        if (panel_ratio and panel_ratio > 2.5) or (content_ratio and content_ratio > 2.5):
            risks.append(risk(STATUS_WARN, "unjustified_panel_hierarchy_risk", "Panel size hierarchy is very strong and requires explicit manuscript justification.", {"panel_ratio": round(panel_ratio or 0, 3), "content_ratio": round(content_ratio or 0, 3)}))

    return {
        "checked": True,
        "method": "projection-gutter-v1",
        "expected_panels": expected_panels,
        "layout_profile": layout_profile,
        "panel_count_detected": len(panels),
        "panel_area_ratio_max_min": None if panel_ratio is None else round(panel_ratio, 4),
        "panel_area_cv": None if coeff_var(panel_area_fracs) is None else round(coeff_var(panel_area_fracs) or 0, 4),
        "content_area_ratio_max_min": None if content_ratio is None else round(content_ratio, 4),
        "content_area_cv": None if coeff_var(content_area_fracs) is None else round(coeff_var(content_area_fracs) or 0, 4),
        "blank_fraction_range": None if blank_range is None else round(blank_range, 4),
        "panels": panels,
        "risks": risks,
    }


def run_optional_ocr(image_path: Path, image_size: tuple[int, int], mode: str) -> dict[str, Any]:
    exe = shutil.which("tesseract")
    if mode == "off":
        return {"checked": False, "available": bool(exe), "enabled": False, "mode": mode, "risks": []}
    if not exe:
        if mode == "required":
            raise SystemExit("OCR was required but Tesseract was not found on PATH.")
        return {"checked": True, "available": False, "enabled": False, "mode": mode, "risks": []}

    cmd = [exe, str(image_path), "stdout", "--psm", "6", "tsv"]
    proc = run_command(cmd)
    if proc.returncode != 0:
        if mode == "required":
            raise SystemExit(f"OCR failed: {proc.stderr or proc.stdout}")
        return {"checked": True, "available": True, "enabled": False, "mode": mode, "error": proc.stderr or proc.stdout, "risks": []}

    rows = []
    for row in csv.DictReader(proc.stdout.splitlines(), delimiter="\t"):
        text = (row.get("text") or "").strip()
        if not text:
            continue
        try:
            conf = float(row.get("conf", "-1"))
            x = int(float(row.get("left", 0)))
            y = int(float(row.get("top", 0)))
            bw = int(float(row.get("width", 0)))
            bh = int(float(row.get("height", 0)))
        except Exception:
            continue
        if bw <= 0 or bh <= 0 or conf < 0:
            continue
        rows.append({"text": text, "conf": conf, "box": [x, y, x + bw, y + bh]})

    w, h = image_size
    small_text = [r for r in rows if (r["box"][3] - r["box"][1]) < max(8, h * 0.012)]
    edge_boxes = []
    for r in rows:
        x0, y0, x1, y1 = r["box"]
        cx = (x0 + x1) / 2
        cy = (y0 + y1) / 2
        if cx < w * 0.15 or cx > w * 0.85 or cy < h * 0.15 or cy > h * 0.85:
            edge_boxes.append(r)
    overlap_count = 0
    limited = rows[:400]
    for i, a in enumerate(limited):
        ax0, ay0, ax1, ay1 = a["box"]
        a_area = max((ax1 - ax0) * (ay1 - ay0), 1)
        for b in limited[i + 1:]:
            bx0, by0, bx1, by1 = b["box"]
            ix = max(0, min(ax1, bx1) - max(ax0, bx0))
            iy = max(0, min(ay1, by1) - max(ay0, by0))
            inter = ix * iy
            if inter / min(a_area, max((bx1 - bx0) * (by1 - by0), 1)) > 0.2:
                overlap_count += 1
    text_count = len(rows)
    small_fraction = len(small_text) / max(text_count, 1)
    edge_fraction = len(edge_boxes) / max(text_count, 1)
    risks = []
    if text_count >= 30 and small_fraction > 0.55:
        risks.append(risk(STATUS_WARN, "ocr_small_text_burden", "OCR found many likely small text boxes.", round(small_fraction, 3)))
    if overlap_count > max(3, text_count * 0.03):
        risks.append(risk(STATUS_WARN, "ocr_text_overlap_risk", "OCR text boxes overlap enough to suggest label collision.", overlap_count))
    if text_count >= 20 and edge_fraction > 0.70:
        risks.append(risk(STATUS_WARN, "ocr_edge_text_concentration", "Most OCR text is concentrated near edges, suggesting legend/tick burden.", round(edge_fraction, 3)))
    return {
        "checked": True,
        "available": True,
        "enabled": True,
        "mode": mode,
        "engine": "tesseract",
        "text_box_count": text_count,
        "suspected_small_text_fraction": round(small_fraction, 4),
        "edge_text_fraction": round(edge_fraction, 4),
        "text_overlap_pair_count": overlap_count,
        "mean_confidence": None if not rows else round(statistics.mean(r["conf"] for r in rows), 2),
        "risks": risks,
    }


def analyze_raster(
    path: Path,
    out_dir: Path,
    figure_family: str | None = None,
    *,
    input_path: Path | None = None,
    input_type: str = "raster",
    rasterization: dict[str, Any] | None = None,
    svg_structure: dict[str, Any] | None = None,
    expected_panels: int | None = None,
    layout_profile: str = "auto",
    ocr_mode: str = "auto",
) -> dict[str, Any]:
    if Image is None:
        raise SystemExit(f"Pillow is required for visual QA: {PIL_IMPORT_ERROR}")
    ensure_dir(out_dir)
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
    panel_geometry = detect_panel_geometry(mask, expected_panels, layout_profile)
    ocr = run_optional_ocr(path, (w, h), ocr_mode)
    text_density_score = comp["small_component_count"] / max((w * h) / 1_000_000, 0.1)
    color_count_estimate = len([d for d in dominant if d["fraction"] > 0.001])
    risks: list[dict[str, Any]] = []
    score = 10
    aspect = w / max(h, 1)
    profile, thresholds = threshold_profile("raster", figure_family)
    if w < thresholds["min_width_px"] or h < thresholds["min_height_px"]:
        risks.append(risk(STATUS_WARN, "low_pixel_dimensions", "PNG preview is small for detailed manuscript QA.", [w, h])); score -= 1
    if aspect > thresholds["aspect_max"] or aspect < thresholds["aspect_min"]:
        risks.append(risk(STATUS_WARN, "extreme_aspect_ratio", "Aspect ratio is likely to create readability or layout problems.", round(aspect, 3))); score -= 1
    if blank_margin_fraction > thresholds["blank_margin_warn"]:
        risks.append(risk(STATUS_WARN, "excessive_blank_margin", "Large blank/unused margin detected.", round(blank_margin_fraction, 3))); score -= 1
    if content_density < thresholds["content_density_min"]:
        risks.append(risk(STATUS_WARN, "low_content_density", "Figure may be sparse or dominated by whitespace.", round(content_density, 3))); score -= 1
    if text_density_score > thresholds["text_density_warn"]:
        risks.append(risk(STATUS_WARN, "high_text_or_tick_density", "Many small dark components suggest dense labels, ticks, or annotations.", round(text_density_score, 1))); score -= 1
    if comp["medium_component_count"] >= thresholds["label_overlap_medium_count"] and content_density > thresholds["label_overlap_content_density"]:
        risks.append(risk(STATUS_WARN, "label_overlap_or_large_annotation_risk", "Several medium-sized text/annotation components suggest direct-label burden or overlap risk.", comp["medium_component_count"])); score -= 1
    if high_sat_fraction > thresholds["high_saturation_fraction_warn"] and color_count_estimate <= 6:
        risks.append(risk(STATUS_WARN, "saturated_presentation_palette", "Dominant colors are highly saturated and presentation-like.", round(high_sat_fraction, 3))); score -= 1
    if min_lum_delta < thresholds["minimum_luminance_delta_warn"]:
        risks.append(risk(STATUS_WARN, "grayscale_discrimination_risk", "Some colored classes may be hard to distinguish in grayscale.", round(min_lum_delta, 1))); score -= 1
    if gray_std < thresholds["grayscale_std_min"]:
        risks.append(risk(STATUS_WARN, "low_grayscale_contrast", "Overall grayscale contrast is low.", round(gray_std, 1))); score -= 1
    if lines["line_burden_score"] > thresholds["line_burden_warn"]:
        risks.append(risk(STATUS_WARN, "gridline_or_long_line_burden", "Many long horizontal/vertical line structures detected.", lines["line_burden_score"])); score -= 1
    if thumb_density > thresholds["thumbnail_density_warn"]:
        risks.append(risk(STATUS_WARN, "thumbnail_readability_risk", "Thumbnail view is visually dense; labels may fail at reduced size.", round(thumb_density, 3))); score -= 1
    for item in panel_geometry.get("risks", []):
        risks.append(item)
        score -= 2 if item.get("code") in {"panel_size_imbalance", "panel_data_region_imbalance"} else 1
    for item in ocr.get("risks", []):
        risks.append(item)
        score -= 1
    if svg_structure:
        for item in svg_structure.get("top_risks", []):
            if item.get("status") != STATUS_PASS:
                risks.append(item)
        struct_score = svg_structure.get("manuscript_readiness_score")
        if isinstance(struct_score, int):
            score = min(score, struct_score)
    if not risks:
        risks.append(risk(STATUS_PASS, "no_major_deterministic_risk", "No major deterministic visual QA risk detected."))
    score = max(0, min(10, score))
    status = status_from_score(score)
    if status == STATUS_PASS and any(item.get("status") == STATUS_WARN for item in risks):
        status = STATUS_WARN
    return {
        "checked": True,
        "engine": "pillow-raster",
        "input_type": input_type,
        "input_path": str(input_path or path),
        "analysis_image_path": str(path),
        "rasterization": rasterization or {},
        "svg_structure": svg_structure,
        "figure_family": normalize_family(figure_family),
        "threshold_profile": profile,
        "family_thresholds": thresholds,
        "image_size_px": [w, h],
        "file_size_bytes": (input_path or path).stat().st_size,
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
        "panel_geometry": panel_geometry,
        "ocr": ocr,
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


def analyze_svg_structure(path: Path, figure_family: str | None = None) -> dict[str, Any]:
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
    profile, thresholds = threshold_profile("svg", figure_family)
    if max_font and max_font >= thresholds["max_font_warn"]:
        risks.append(risk(STATUS_WARN, "oversized_svg_title_or_text", "SVG contains presentation-sized text.", max_font)); score -= 2
    if centered_large_titles:
        risks.append(risk(STATUS_WARN, "huge_centered_title", "Large centered title suggests presentation-style rather than manuscript panel style.", centered_large_titles[0].get("text", ""))); score -= 2
    if light_gridlines >= thresholds["light_gridline_warn"]:
        risks.append(risk(STATUS_WARN, "svg_gridline_burden", "Many light gridlines detected.", light_gridlines)); score -= 1
    if len(texts) > thresholds["text_count_warn"]:
        risks.append(risk(STATUS_WARN, "svg_text_burden", "Large number of text elements suggests dense labels/ticks.", len(texts))); score -= 1
    if width and height and (width / max(height, 1) > thresholds["aspect_max"] or width / max(height, 1) < thresholds["aspect_min"]):
        risks.append(risk(STATUS_WARN, "svg_extreme_aspect_ratio", "SVG aspect ratio may be hard to place in manuscript layout.", round(width / max(height, 1), 3))); score -= 1
    if not risks:
        risks.append(risk(STATUS_PASS, "no_major_svg_structure_risk", "No major SVG structure risk detected."))
    score = max(0, min(10, score))
    return {
        "checked": True,
        "engine": "svg-xml",
        "input_type": "svg",
        "input_path": str(path),
        "figure_family": normalize_family(figure_family),
        "threshold_profile": profile,
        "family_thresholds": thresholds,
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
        f"- input type: `{result.get('input_type')}`",
        f"- engine: `{result.get('engine')}`",
        f"- figure family: `{result.get('figure_family') or 'global'}`",
        f"- threshold profile: `{result.get('threshold_profile')}`",
        f"- status: `{result.get('status')}`",
        f"- manuscript readiness score: `{result.get('manuscript_readiness_score')}/10`",
        "",
        "## Rasterization",
        "",
    ]
    rasterization = result.get("rasterization") or {}
    lines.append(f"- performed: `{rasterization.get('performed')}`")
    lines.append(f"- engine: `{rasterization.get('engine')}`")
    if rasterization.get("raster_path"):
        lines.append(f"- raster path: `{rasterization.get('raster_path')}`")
    lines += ["", "## Key metrics", ""]
    for key in ("image_size_px", "canvas_size", "aspect_ratio", "blank_margin_fraction", "content_density", "text_burden_score", "color_count_estimate", "grayscale_std", "line_burden", "text_count", "font_size_max", "light_gridline_count"):
        if key in result:
            lines.append(f"- {key}: `{result[key]}`")
    panel = result.get("panel_geometry") or {}
    lines += [
        "",
        "## Panel geometry",
        "",
        f"- expected panels: `{panel.get('expected_panels')}`",
        f"- detected panels: `{panel.get('panel_count_detected')}`",
        f"- panel area ratio max/min: `{panel.get('panel_area_ratio_max_min')}`",
        f"- content area ratio max/min: `{panel.get('content_area_ratio_max_min')}`",
        f"- blank fraction range: `{panel.get('blank_fraction_range')}`",
    ]
    ocr = result.get("ocr") or {}
    lines += [
        "",
        "## OCR",
        "",
        f"- available: `{ocr.get('available')}`",
        f"- enabled: `{ocr.get('enabled')}`",
        f"- text boxes: `{ocr.get('text_box_count')}`",
    ]
    if result.get("svg_structure"):
        svg = result["svg_structure"]
        lines += [
            "",
            "## SVG structure",
            "",
            f"- text count: `{svg.get('text_count')}`",
            f"- max font size: `{svg.get('font_size_max')}`",
            f"- light gridlines: `{svg.get('light_gridline_count')}`",
        ]
    lines += ["", "## Top risks", ""]
    for item in result.get("top_risks", []):
        lines.append(f"- `{item.get('status')}` `{item.get('code')}`: {item.get('message')}" + (f" ({item.get('value')})" if "value" in item else ""))
    (out_dir / "visual_qa.md").write_text("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Rendered image visual QA for paperplot-skills.")
    parser.add_argument("input", help="PNG/JPG/JPEG/SVG/PDF file or output directory containing a rendered figure")
    parser.add_argument("--out", required=True, help="Output directory for visual_qa.json/md, previews, and rasterized intermediates")
    parser.add_argument("--family", default=None, help="Optional figure family for family-specific visual QA thresholds")
    parser.add_argument("--dpi", type=int, default=300, help="Rasterization DPI for PDF/SVG inputs")
    parser.add_argument("--page", type=int, default=1, help="PDF page number to rasterize")
    parser.add_argument("--ocr", choices=["auto", "off", "required"], default="auto", help="Optional OCR mode")
    parser.add_argument("--expected-panels", type=int, default=None, help="Expected panel count for panel geometry QA")
    parser.add_argument("--layout-profile", choices=["auto", "equal", "hierarchical"], default="auto", help="Panel layout interpretation")
    args = parser.parse_args()
    in_path = resolve_input(Path(args.input).expanduser())
    out_dir = Path(args.out).expanduser()
    ensure_dir(out_dir)
    ext = in_path.suffix.lower()
    svg_structure = analyze_svg_structure(in_path, args.family) if ext == ".svg" else None
    raster_path, rasterization = rasterize_input(in_path, out_dir, args.dpi, args.page)
    input_type = "raster" if ext in {".png", ".jpg", ".jpeg"} else ext.lstrip(".")
    result = analyze_raster(
        raster_path,
        out_dir,
        args.family,
        input_path=in_path,
        input_type=input_type,
        rasterization=rasterization,
        svg_structure=svg_structure,
        expected_panels=args.expected_panels,
        layout_profile=args.layout_profile,
        ocr_mode=args.ocr,
    )
    (out_dir / "visual_qa.json").write_text(json.dumps({"image_qa": result}, indent=2, ensure_ascii=False) + "\n")
    write_markdown(result, out_dir)
    print(f"visual QA written: {out_dir / 'visual_qa.json'}")
    return 0 if result.get("checked") else 1


if __name__ == "__main__":
    raise SystemExit(main())
