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

try:
    from pypdf import PdfReader
    from pypdf.generic import ContentStream
except Exception as exc:  # pragma: no cover
    PdfReader = None
    ContentStream = None
    PYPDF_IMPORT_ERROR = exc
else:
    PYPDF_IMPORT_ERROR = None

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
    "legend_edge_fraction_warn": 0.28,
    "gridline_count_warn": 18,
    "panel_padding_warn": 0.55,
}

BASE_SVG_THRESHOLDS = {
    "max_font_warn": 18,
    "large_title_font_warn": 18,
    "light_gridline_warn": 5,
    "text_count_warn": 80,
    "aspect_min": 0.45,
    "aspect_max": 3.0,
    "manuscript_text_max_warn": 12,
    "stroke_width_max_warn": 1.2,
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
        "gridline_count_warn": 60,
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
        "gridline_count_warn": 90,
    },
}

FAMILY_SVG_OVERRIDES = {
    "genome-track/synteny": {
        "aspect_max": 4.5,
        "stroke_width_max_warn": 2.0,
        "light_gridline_warn": 20,
    },
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

# Canonical families we actually have tuned behavior for. Used to guard
# filename-based family inference so a random filename slug is not treated as a
# real family.
KNOWN_FAMILIES = (
    set(FAMILY_ALIASES.values())
    | set(FAMILY_RASTER_OVERRIDES)
    | set(FAMILY_SVG_OVERRIDES)
)

# Risk-code -> concrete remediation. Binds each "audit" signal to the matching
# "how to fix" reference doc, so the QA output itself tells Codex/Claude what to
# change. `doc` paths are relative to the skill root. Codes intentionally without
# a fix (informational / pass markers) are listed in REMEDIATION_NONE.
REMEDIATION = {
    "low_pixel_dimensions": ("references/publication-visual-standards.md", "Re-export at >=300 dpi or a larger output preset so detail survives at print size."),
    "extreme_aspect_ratio": ("references/multi-panel-layout-rules.md", "Rebalance width:height toward ~0.6-2.0; split or reflow panels instead of one extreme strip."),
    "svg_extreme_aspect_ratio": ("references/multi-panel-layout-rules.md", "Rebalance the SVG width:height toward ~0.6-2.0; avoid one extreme strip."),
    "excessive_blank_margin": ("references/manuscript-aesthetics-rules.md", "Trim plot margins / scale expansion and crop dead whitespace around the data region."),
    "low_content_density": ("references/manuscript-aesthetics-rules.md", "Raise data-ink: enlarge the data region or shrink the canvas so content fills the frame."),
    "high_text_or_tick_density": ("references/label-burden-strategies.md", "Thin ticks/labels; move dense lookup labels to a rank index + key labels + label-key sidecar."),
    "label_overlap_or_large_annotation_risk": ("references/label-burden-strategies.md", "Use ggrepel or fewer direct labels; offload collisions to a key/sidecar."),
    "saturated_presentation_palette": ("references/color-and-style-policy.md", "Desaturate to a functional manuscript palette; drop presentation-style saturated colors."),
    "grayscale_discrimination_risk": ("references/color-and-style-policy.md", "Separate classes by luminance, not hue alone, so they survive grayscale printing."),
    "low_grayscale_contrast": ("references/color-and-style-policy.md", "Increase value range / contrast between marks and background."),
    "gridline_or_long_line_burden": ("references/nature-like-style-principles.md", "Drop gridlines by default and thin axis/border strokes (~0.25-0.6 pt)."),
    "thumbnail_readability_risk": ("references/publication-visual-standards.md", "Increase text size and reduce density so the figure still reads at column width."),
    "panel_count_mismatch": ("references/pattern-library/multi-panel-manuscript-layout.md", "Reconcile expected vs detected panels; fix outer stitching/missing panel."),
    "panel_size_imbalance": ("references/pattern-library/multi-panel-manuscript-layout.md", "Equalize panel-box sizes for equal-role panels (export sub-plots at matched dimensions)."),
    "panel_data_region_imbalance": ("references/pattern-library/multi-panel-manuscript-layout.md", "Align visible data-region sizes across panels; equalize legend space."),
    "panel_blank_space_imbalance": ("references/pattern-library/multi-panel-manuscript-layout.md", "Even out per-panel margins so blank-space fractions match."),
    "unjustified_panel_hierarchy_risk": ("references/pattern-library/multi-panel-manuscript-layout.md", "Either justify the size hierarchy (primary/secondary roles) or equalize panels."),
    "ocr_small_text_burden": ("references/label-burden-strategies.md", "Increase font size and reduce raw text count; many tiny labels read as texture."),
    "ocr_text_overlap_risk": ("references/label-burden-strategies.md", "Resolve label collisions with repel/offset or a key sidecar."),
    "ocr_edge_text_concentration": ("references/multi-panel-layout-rules.md", "Reduce legend/tick edge burden; consolidate or move legends."),
    "oversized_svg_title_or_text": ("references/manuscript-aesthetics-rules.md", "Shrink title/text to manuscript scale; remove presentation-sized headings."),
    "huge_centered_title": ("references/manuscript-aesthetics-rules.md", "Remove or shrink the large centered title to a small panel/figure label."),
    "svg_gridline_burden": ("references/nature-like-style-principles.md", "Remove decorative gridlines; keep only quantitatively useful guides."),
    "svg_text_burden": ("references/label-burden-strategies.md", "Reduce text element count; move dense labels to a sidecar/key."),
}
REMEDIATION_NONE = {
    "no_major_deterministic_risk",
    "no_major_svg_structure_risk",
    "panel_detection_empty",
    "svg_parse_error",
}

NATURE_GUARDRAIL_REFERENCE = "references/nature-figure-guardrails.md"

NATURE_GUARDRAILS = [
    {
        "id": "export_size_aspect",
        "label": "Export size and aspect ratio",
        "hard_codes": {"low_pixel_dimensions", "extreme_aspect_ratio", "svg_extreme_aspect_ratio"},
        "review_codes": set(),
        "fix": "Re-export at the target manuscript size or split/reflow the canvas.",
    },
    {
        "id": "readable_typography",
        "label": "Readable typography at target size",
        "hard_codes": {"ocr_small_text_burden", "oversized_svg_title_or_text", "huge_centered_title"},
        "review_codes": {"high_text_or_tick_density", "svg_text_burden"},
        "fix": "Use manuscript-scale text, reduce tick/label count, and remove presentation titles.",
    },
    {
        "id": "no_visible_overlap",
        "label": "No text or annotation overlap",
        "hard_codes": {"ocr_text_overlap_risk", "label_overlap_or_large_annotation_risk"},
        "review_codes": set(),
        "fix": "Resolve collisions with repel/offsets, fewer direct labels, or a label-key sidecar.",
    },
    {
        "id": "controlled_whitespace",
        "label": "Controlled whitespace and filled data region",
        "hard_codes": {"excessive_blank_margin", "low_content_density"},
        "review_codes": set(),
        "fix": "Trim margins, reduce scale expansion, enlarge the data region, or shrink the canvas.",
    },
    {
        "id": "panel_balance",
        "label": "Balanced multi-panel geometry",
        "hard_codes": {
            "panel_count_mismatch",
            "panel_size_imbalance",
            "panel_data_region_imbalance",
            "panel_blank_space_imbalance",
            "unjustified_panel_hierarchy_risk",
        },
        "review_codes": {"panel_detection_empty"},
        "fix": "Equalize equal-role panel boxes/data regions or document an intentional hierarchy.",
    },
    {
        "id": "thumbnail_readability",
        "label": "Thumbnail readability",
        "hard_codes": {"thumbnail_readability_risk"},
        "review_codes": set(),
        "fix": "Reduce visible burden so the main structure survives small preview review.",
    },
    {
        "id": "color_grayscale_safety",
        "label": "Color and grayscale safety",
        "hard_codes": set(),
        "review_codes": {
            "saturated_presentation_palette",
            "grayscale_discrimination_risk",
            "low_grayscale_contrast",
        },
        "fix": "Use a muted accessible palette and separate important classes by luminance/shape.",
    },
    {
        "id": "gridline_stroke_discipline",
        "label": "Gridline and stroke discipline",
        "hard_codes": set(),
        "review_codes": {"gridline_or_long_line_burden", "svg_gridline_burden"},
        "fix": "Remove decorative gridlines and keep axes, borders, and intervals thin.",
    },
    {
        "id": "legend_edge_burden",
        "label": "Legend and edge burden",
        "hard_codes": set(),
        "review_codes": {"ocr_edge_text_concentration"},
        "fix": "Consolidate guides, reserve legend space, and avoid edge-dominated layouts.",
    },
    {
        "id": "actionable_remediation",
        "label": "Actionable remediation",
        "hard_codes": set(),
        "review_codes": set(),
        "fix": "Every risk code must include a remediation and reference document.",
    },
]


def attach_remediation(risks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    for item in risks:
        code = item.get("code")
        if code in REMEDIATION:
            doc, fix = REMEDIATION[code]
            item["remediation"] = {"doc": doc, "fix": fix}
    return risks


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def status_from_score(score: int) -> str:
    if score <= 4:
        return STATUS_FAIL
    if score < 8:
        return STATUS_WARN
    return STATUS_PASS


def evaluate_nature_guardrails(result: dict[str, Any], *, strict: bool = False) -> dict[str, Any]:
    code_to_risk = {
        item.get("code"): item
        for item in result.get("top_risks", [])
        if item.get("status") != STATUS_PASS and item.get("code")
    }
    rows = []
    for gate in NATURE_GUARDRAILS:
        hard_hits = sorted(code for code in gate["hard_codes"] if code in code_to_risk)
        review_hits = sorted(code for code in gate["review_codes"] if code in code_to_risk)
        if strict and hard_hits:
            gate_status = STATUS_FAIL
        elif hard_hits or review_hits:
            gate_status = STATUS_WARN
        else:
            gate_status = STATUS_PASS
        rows.append({
            "id": gate["id"],
            "label": gate["label"],
            "status": gate_status,
            "hard_hits": hard_hits,
            "review_hits": review_hits,
            "fix": gate["fix"],
            "doc": NATURE_GUARDRAIL_REFERENCE,
        })

    statuses = [row["status"] for row in rows]
    summary_status = STATUS_FAIL if STATUS_FAIL in statuses else STATUS_WARN if STATUS_WARN in statuses else STATUS_PASS
    return {
        "checked": True,
        "strict": strict,
        "reference": NATURE_GUARDRAIL_REFERENCE,
        "status": summary_status,
        "hard_risk_codes": sorted({code for row in rows for code in row["hard_hits"]}),
        "review_risk_codes": sorted({code for row in rows for code in row["review_hits"]}),
        "checks": rows,
    }


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


def _family_from_metadata(meta_dir: Path) -> tuple[str | None, str | None]:
    if not meta_dir.is_dir():
        return None, None
    for mp in sorted(meta_dir.glob("*metadata*.json")) + sorted(meta_dir.glob("*_metadata.json")):
        try:
            data = json.loads(mp.read_text())
        except Exception:
            continue
        for getter in (
            lambda d: (d.get("figure_spec") or {}).get("plot_type"),
            lambda d: d.get("plot_type"),
            lambda d: d.get("chart_family"),
            lambda d: (d.get("design_plan") or {}).get("chart_family"),
        ):
            try:
                value = getter(data)
            except Exception:
                value = None
            if value:
                return str(value), mp.name
    return None, None


def infer_figure_family(in_path: Path) -> tuple[str | None, str | None]:
    """Best-effort figure family when --family is not supplied.

    1) Authoritative: a sibling ``*_metadata.json`` written by the templates
       (figure_spec.plot_type / chart_family).
    2) Fallback: filename keywords, but only when they map to a known family so
       a random slug is not mistaken for one.
    Returns (family_or_None, source_label).
    """
    search_dir = in_path if in_path.is_dir() else in_path.parent
    fam, src = _family_from_metadata(search_dir)
    if fam:
        return fam, f"metadata:{src}"
    stem = in_path.name if in_path.is_dir() else in_path.stem
    candidate = normalize_family(stem)
    if candidate in KNOWN_FAMILIES:
        return candidate, "filename"
    return None, None


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
        out_path = out_dir / "rasterized_input.png"
        cmd = None
        proc = None
        if exe:
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
        # Fall back to the built-in Pillow rasterizer when ImageMagick is absent
        # OR when it failed. Pillow has no system dependency, so SVG QA stays
        # available on machines without ImageMagick.
        if exe is None or proc.returncode != 0 or not out_path.exists():
            magick_output = (proc.stderr or proc.stdout) if proc is not None else ""
            try:
                rasterize_svg_with_pillow(path, out_path)
            except Exception as exc:
                detail = magick_output or "ImageMagick not found"
                raise SystemExit(f"SVG rasterization failed: {detail}; Pillow fallback failed: {exc}") from exc
            return out_path, {
                "performed": True,
                "engine": "svg-pillow-fallback",
                "fallback_from": Path(exe).name if exe else "none",
                "fallback_reason": (
                    magick_output.strip().splitlines()[0] if magick_output.strip()
                    else "imagemagick_not_available"
                ),
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


def component_boxes(mask: Image.Image, max_dim: int = 720, limit: int = 1500) -> list[dict[str, Any]]:
    """Return connected-component boxes used for detail-level raster heuristics."""
    w, h = mask.size
    scale = min(1.0, max_dim / max(w, h))
    small = mask.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.NEAREST) if scale < 1 else mask.copy()
    inv_scale = 1 / scale if scale else 1
    sw, sh = small.size
    pix = small.load()
    seen = bytearray(sw * sh)
    comps: list[dict[str, Any]] = []
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
            bw = maxx - minx + 1
            bh = maxy - miny + 1
            if area < 2:
                continue
            comps.append({
                "area_px_scaled": area,
                "box_px": scale_box((minx, miny, maxx + 1, maxy + 1), inv_scale, w, h),
                "width_px_scaled": bw,
                "height_px_scaled": bh,
                "aspect": round(bw / max(bh, 1), 3),
            })
            if len(comps) >= limit:
                return comps
    return comps


def box_area(box: list[int]) -> int:
    return max(box[2] - box[0], 0) * max(box[3] - box[1], 0)


def box_center(box: list[int]) -> tuple[float, float]:
    return ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2)


def analyze_text_geometry(
    comps: list[dict[str, Any]],
    image_size: tuple[int, int],
    content_bbox: list[int],
    text_density_score: float,
    ocr: dict[str, Any],
    thresholds: dict[str, float],
    strict_detail_qa: bool,
) -> dict[str, Any]:
    w, h = image_size
    small = [c for c in comps if 2 <= c["area_px_scaled"] <= 260 and 2 <= c["width_px_scaled"] <= 80 and 3 <= c["height_px_scaled"] <= 40]
    medium = [c for c in comps if 260 < c["area_px_scaled"] <= 6000]
    edge = []
    bottom = []
    left = []
    top_content = []
    cx0, cy0, cx1, cy1 = content_bbox
    for c in small + medium:
        x, y = box_center(c["box_px"])
        if x < w * 0.16 or x > w * 0.84 or y < h * 0.16 or y > h * 0.84:
            edge.append(c)
        if y > h * 0.78:
            bottom.append(c)
        if x < w * 0.18:
            left.append(c)
        if cy0 <= y <= cy0 + max((cy1 - cy0) * 0.28, 1) and cx0 <= x <= cx1:
            top_content.append(c)
    text_like_count = len(small) + len(medium)
    edge_fraction = len(edge) / max(text_like_count, 1)
    bottom_fraction = len(bottom) / max(text_like_count, 1)
    left_fraction = len(left) / max(text_like_count, 1)
    ocr_overlap = int(ocr.get("text_overlap_pair_count") or 0)
    risks: list[dict[str, Any]] = []
    if ocr_overlap > 3 or (len(medium) >= 5 and text_density_score > thresholds["text_density_warn"] * 0.55) or (len(medium) >= 8 and edge_fraction < 0.65):
        risks.append(risk(STATUS_FAIL if strict_detail_qa else STATUS_WARN, "text_data_overlap_risk", "Text/annotation components likely collide with data marks or dense labels.", {"medium_components": len(medium), "ocr_overlap_pairs": ocr_overlap}))
    if len(small) >= 35 and (bottom_fraction > 0.38 or left_fraction > 0.38):
        risks.append(risk(STATUS_WARN, "tick_label_collision_risk", "Dense edge text suggests tick-label collision or overcrowded category labels.", {"bottom_fraction": round(bottom_fraction, 3), "left_fraction": round(left_fraction, 3)}))
    if len(small) >= 25 and edge_fraction > 0.78:
        risks.append(risk(STATUS_WARN, "axis_title_collision_risk", "Most text-like components sit at plot edges; axis titles, tick labels, or legends may be crowded.", round(edge_fraction, 3)))
    if len(top_content) >= 5 and len(medium) >= 2:
        risks.append(risk(STATUS_WARN, "significance_annotation_overcrowding", "Top-of-panel annotations may compress the data region.", len(top_content)))
    return {
        "checked": True,
        "method": "connected-components-plus-ocr",
        "text_like_component_count": text_like_count,
        "small_text_like_component_count": len(small),
        "medium_annotation_component_count": len(medium),
        "edge_text_like_fraction": round(edge_fraction, 4),
        "bottom_text_like_fraction": round(bottom_fraction, 4),
        "left_text_like_fraction": round(left_fraction, 4),
        "ocr_overlap_pair_count": ocr_overlap,
        "risks": risks,
    }


def analyze_stroke_geometry(lines: dict[str, Any], vector_structure: dict[str, Any] | None, thresholds: dict[str, float], strict_detail_qa: bool) -> dict[str, Any]:
    line_score = float(lines.get("line_burden_score") or 0)
    total_long_lines = int(lines.get("horizontal_line_rows") or 0) + int(lines.get("vertical_line_cols") or 0)
    vector_widths = []
    if vector_structure:
        vector_widths = vector_structure.get("stroke_width_values") or []
    risks: list[dict[str, Any]] = []
    max_vector_width = max(vector_widths) if vector_widths else None
    if max_vector_width is not None and max_vector_width > thresholds.get("stroke_width_max_warn", 1.2):
        risks.append(risk(STATUS_WARN, "stroke_too_heavy", "Vector stroke width is heavy for manuscript-scale figure elements.", round(max_vector_width, 3)))
    elif line_score > thresholds["line_burden_warn"] * 2.2 and total_long_lines >= 12:
        risks.append(risk(STATUS_WARN, "stroke_too_heavy", "Long-line burden suggests overly heavy axes, grids, cell borders, or connectors.", {"line_burden_score": line_score, "long_line_count": total_long_lines}))
    if strict_detail_qa and line_score < 0.0005 and total_long_lines == 0:
        risks.append(risk(STATUS_WARN, "stroke_too_light", "No stable axis or structural line signal was detected; strokes may be too light or absent.", line_score))
    return {
        "checked": True,
        "method": "line-projection-plus-vector-stroke",
        "line_burden_score": line_score,
        "long_line_count": total_long_lines,
        "vector_stroke_width_min": min(vector_widths) if vector_widths else None,
        "vector_stroke_width_median": statistics.median(vector_widths) if vector_widths else None,
        "vector_stroke_width_max": max_vector_width,
        "risks": risks,
    }


def analyze_grid_background(lines: dict[str, Any], allow_grid: str, figure_family: str | None, thresholds: dict[str, float]) -> dict[str, Any]:
    canonical = normalize_family(figure_family)
    total_long_lines = int(lines.get("horizontal_line_rows") or 0) + int(lines.get("vertical_line_cols") or 0)
    line_score = float(lines.get("line_burden_score") or 0)
    dense_family = canonical in {"heatmap", "phylo-annotation-ring", "manhattan"}
    allowed = allow_grid == "required" or (allow_grid == "light" and total_long_lines <= thresholds["gridline_count_warn"]) or (allow_grid == "auto" and dense_family)
    risks: list[dict[str, Any]] = []
    if allow_grid == "off" and total_long_lines > 5:
        risks.append(risk(STATUS_WARN, "grid_background_burden", "Gridlines were disallowed but long horizontal/vertical structures are present.", total_long_lines))
    elif not allowed and total_long_lines > thresholds["gridline_count_warn"] and line_score > thresholds["line_burden_warn"]:
        risks.append(risk(STATUS_WARN, "grid_background_burden", "Background grid or repeated structural lines may dominate the data layer.", {"long_line_count": total_long_lines, "line_burden_score": line_score}))
    return {
        "checked": True,
        "method": "long-line-projection",
        "allow_grid": allow_grid,
        "long_line_count": total_long_lines,
        "line_burden_score": line_score,
        "family_grid_context": "dense-structure" if dense_family else "standard-statistical",
        "risks": risks,
    }


def analyze_legend_geometry(mask: Image.Image, thresholds: dict[str, float]) -> dict[str, Any]:
    w, h = mask.size
    pix = mask.load()
    total = sum(1 for p in mask.getdata() if p)
    if total <= 0:
        return {"checked": True, "method": "edge-ink-concentration", "edge_content_fraction": 0, "risks": []}
    right = top = 0
    for y in range(h):
        for x in range(w):
            if pix[x, y] == 0:
                continue
            if x >= int(w * 0.80):
                right += 1
            if y <= int(h * 0.18):
                top += 1
    right_fraction = right / total
    top_fraction = top / total
    edge_fraction = max(right_fraction, top_fraction)
    risks: list[dict[str, Any]] = []
    if edge_fraction > thresholds["legend_edge_fraction_warn"] and total / max(w * h, 1) > 0.03:
        risks.append(risk(STATUS_WARN, "legend_dominates_panel", "Edge ink concentration suggests a legend, labels, or title may dominate the data region.", {"right_fraction": round(right_fraction, 3), "top_fraction": round(top_fraction, 3)}))
    return {
        "checked": True,
        "method": "edge-ink-concentration",
        "right_edge_content_fraction": round(right_fraction, 4),
        "top_edge_content_fraction": round(top_fraction, 4),
        "edge_content_fraction": round(edge_fraction, 4),
        "risks": risks,
    }


def analyze_panel_detail_geometry(panel_geometry: dict[str, Any], thresholds: dict[str, float], strict_detail_qa: bool) -> dict[str, Any]:
    risks: list[dict[str, Any]] = []
    content_ratio = panel_geometry.get("content_area_ratio_max_min")
    panel_ratio = panel_geometry.get("panel_area_ratio_max_min")
    blank_values = [p.get("blank_fraction", 0) for p in panel_geometry.get("panels", [])]
    median_blank = statistics.median(blank_values) if blank_values else None
    if content_ratio and content_ratio > 1.25:
        risks.append(risk(STATUS_FAIL if strict_detail_qa and content_ratio > 1.6 else STATUS_WARN, "panel_data_region_mismatch", "Panel data regions are materially different in size.", round(content_ratio, 3)))
    if median_blank is not None and median_blank > thresholds["panel_padding_warn"]:
        risks.append(risk(STATUS_WARN, "excessive_panel_padding", "Panels contain excessive internal blank space relative to visible content.", round(median_blank, 3)))
    return {
        "checked": True,
        "method": "panel-geometry-derived",
        "panel_area_ratio_max_min": panel_ratio,
        "content_area_ratio_max_min": content_ratio,
        "median_panel_blank_fraction": None if median_blank is None else round(median_blank, 4),
        "risks": risks,
    }


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
    vector_structure: dict[str, Any] | None = None,
    expected_panels: int | None = None,
    layout_profile: str = "auto",
    ocr_mode: str = "auto",
    strict_nature: bool = False,
    target_width_mm: float | None = None,
    journal_profile: str = "generic",
    strict_detail_qa: bool = False,
    allow_grid: str = "auto",
    expected_font_range: tuple[float, float] = (5.0, 7.0),
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
    comps = component_boxes(mask)
    text_geometry = analyze_text_geometry(comps, (w, h), [bx0, by0, bx1, by1], text_density_score, ocr, thresholds, strict_detail_qa)
    vector_structure = vector_structure or svg_structure
    stroke_geometry = analyze_stroke_geometry(lines, vector_structure, thresholds, strict_detail_qa)
    grid_background = analyze_grid_background(lines, allow_grid, figure_family, thresholds)
    legend_geometry = analyze_legend_geometry(mask, thresholds)
    panel_detail_geometry = analyze_panel_detail_geometry(panel_geometry, thresholds, strict_detail_qa)
    font_risks: list[dict[str, Any]] = []
    font_assessment = {
        "checked": True,
        "method": "vector-fonts" if vector_structure else "raster-heuristic-no-exact-font-size",
        "target_width_mm": target_width_mm,
        "expected_font_range_pt": list(expected_font_range),
        "journal_profile": journal_profile,
        "font_size_min": None,
        "font_size_median": None,
        "font_size_max": None,
        "risks": font_risks,
    }
    if vector_structure:
        font_assessment["font_size_min"] = vector_structure.get("font_size_min")
        font_assessment["font_size_median"] = vector_structure.get("font_size_median")
        font_assessment["font_size_max"] = vector_structure.get("font_size_max")
        font_assessment["font_size_pt_distribution"] = vector_structure.get("font_size_pt_distribution")
        min_font = vector_structure.get("font_size_min")
        max_font = vector_structure.get("font_size_max")
        low, high = expected_font_range
        if min_font and min_font < max(3.0, low - 1.0):
            font_risks.append(risk(STATUS_WARN, "font_too_small_at_target_width", "Vector text includes font sizes below the manuscript target range.", min_font))
        if max_font and max_font > max(high + 4.0, 12.0):
            font_risks.append(risk(STATUS_WARN, "font_too_large_for_manuscript", "Vector text includes presentation-sized labels or titles.", max_font))
        if vector_structure.get("centered_large_title_count", 0) or vector_structure.get("presentation_title_count", 0):
            font_risks.append(risk(STATUS_WARN, "presentation_title_risk", "Centered title-like text suggests slide/report styling rather than manuscript panel styling.", vector_structure.get("centered_large_title_count") or vector_structure.get("presentation_title_count")))
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
    if high_sat_fraction > 0.62 and content_density > 0.18 and color_count_estimate <= 8:
        risks.append(risk(STATUS_WARN, "decorative_background_risk", "High-saturation content covers enough of the canvas to suggest decorative background or over-styled fills.", round(high_sat_fraction, 3))); score -= 1
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
    detail_nodes = [text_geometry, stroke_geometry, grid_background, legend_geometry, panel_detail_geometry, font_assessment]
    for node in detail_nodes:
        for item in node.get("risks", []):
            risks.append(item)
            if item.get("status") == STATUS_FAIL:
                score -= 2
            elif item.get("code") in {"text_data_overlap_risk", "panel_data_region_mismatch", "grid_background_burden", "legend_dominates_panel"}:
                score -= 1
    if vector_structure:
        for item in vector_structure.get("top_risks", []):
            if item.get("status") != STATUS_PASS:
                risks.append(item)
        struct_score = vector_structure.get("manuscript_readiness_score")
        if isinstance(struct_score, int):
            score = min(score, struct_score)
    if not risks:
        risks.append(risk(STATUS_PASS, "no_major_deterministic_risk", "No major deterministic visual QA risk detected."))
    attach_remediation(risks)
    score = max(0, min(10, score))
    status = status_from_score(score)
    if status == STATUS_PASS and any(item.get("status") == STATUS_WARN for item in risks):
        status = STATUS_WARN
    if any(item.get("status") == STATUS_FAIL for item in risks):
        status = STATUS_FAIL
    detail_failures = [item.get("code") for item in risks if item.get("status") == STATUS_FAIL]
    nature_detail_rubric = {
        "checked": True,
        "version": "nature-detail-v1",
        "journal_profile": journal_profile,
        "target_width_mm": target_width_mm,
        "strict_detail_qa": strict_detail_qa,
        "allow_grid": allow_grid,
        "expected_font_range_pt": list(expected_font_range),
        "detail_risk_count": len([item for item in risks if item.get("status") != STATUS_PASS]),
        "hard_fail_count": len(detail_failures),
        "hard_fail_codes": detail_failures,
        "status": STATUS_FAIL if detail_failures else (STATUS_WARN if any(node.get("risks") for node in detail_nodes) else STATUS_PASS),
    }
    result = {
        "checked": True,
        "engine": "pillow-raster",
        "input_type": input_type,
        "input_path": str(input_path or path),
        "analysis_image_path": str(path),
        "rasterization": rasterization or {},
        "svg_structure": svg_structure,
        "vector_structure": vector_structure,
        "vector_text_geometry": (vector_structure or {}).get("vector_text_geometry"),
        "vector_stroke_geometry": (vector_structure or {}).get("vector_stroke_geometry"),
        "vector_layout_geometry": (vector_structure or {}).get("vector_layout_geometry"),
        "font_size_pt_distribution": (vector_structure or {}).get("font_size_pt_distribution"),
        "stroke_width_pt_distribution": (vector_structure or {}).get("stroke_width_pt_distribution"),
        "text_box_overlap_count": (vector_structure or {}).get("text_box_overlap_count"),
        "text_box_data_region_intrusion": (vector_structure or {}).get("text_box_data_region_intrusion"),
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
        "text_geometry": text_geometry,
        "stroke_geometry": stroke_geometry,
        "grid_background": grid_background,
        "legend_geometry": legend_geometry,
        "panel_geometry": panel_geometry,
        "panel_detail_geometry": panel_detail_geometry,
        "ocr": ocr,
        "font_assessment": font_assessment,
        "nature_detail_rubric": nature_detail_rubric,
        "grayscale_preview": str(grayscale_path),
        "manuscript_readiness_score": score,
        "status": status,
        "top_risks": risks,
    }
    nature_guardrails = evaluate_nature_guardrails(result, strict=strict_nature)
    result["nature_guardrails"] = nature_guardrails
    if strict_nature and nature_guardrails["status"] == STATUS_FAIL:
        result["status"] = STATUS_FAIL
        result["manuscript_readiness_score"] = min(result["manuscript_readiness_score"], 4)
    return result


def parse_length(value: str | None) -> float | None:
    if value is None:
        return None
    m = re.search(r"[-+]?[0-9]*\.?[0-9]+", value)
    return float(m.group(0)) if m else None


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def distribution(values: list[float]) -> dict[str, float | None]:
    if not values:
        return {"count": 0, "min": None, "median": None, "max": None}
    return {
        "count": len(values),
        "min": round(min(values), 4),
        "median": round(statistics.median(values), 4),
        "max": round(max(values), 4),
    }


def transform_translate(value: str | None) -> tuple[float, float]:
    if not value:
        return (0.0, 0.0)
    match = re.search(r"translate\(([-+0-9.eE]+)[,\s]+([-+0-9.eE]+)\)", value)
    if match:
        return (float(match.group(1)), float(match.group(2)))
    match = re.search(r"translate\(([-+0-9.eE]+)\)", value)
    if match:
        return (float(match.group(1)), 0.0)
    return (0.0, 0.0)


def rect_overlap_fraction(a: list[float], b: list[float]) -> float:
    ax0, ay0, ax1, ay1 = a
    bx0, by0, bx1, by1 = b
    ix = max(0.0, min(ax1, bx1) - max(ax0, bx0))
    iy = max(0.0, min(ay1, by1) - max(ay0, by0))
    inter = ix * iy
    if inter <= 0:
        return 0.0
    return inter / max(min((ax1 - ax0) * (ay1 - ay0), (bx1 - bx0) * (by1 - by0)), 1e-9)


def summarize_vector_text_boxes(
    boxes: list[dict[str, Any]],
    canvas_size: tuple[float | None, float | None],
    thresholds: dict[str, float],
) -> tuple[dict[str, Any], dict[str, Any], list[dict[str, Any]]]:
    width, height = canvas_size
    overlap_count = 0
    limited = boxes[:500]
    for i, a in enumerate(limited):
        abox = a.get("box")
        if not abox:
            continue
        for b in limited[i + 1:]:
            bbox = b.get("box")
            if bbox and rect_overlap_fraction(abox, bbox) > 0.18:
                overlap_count += 1
    edge_count = 0
    right_count = 0
    top_count = 0
    data_intrusion = 0
    if width and height:
        for item in boxes:
            box = item.get("box")
            if not box:
                continue
            x = (box[0] + box[2]) / 2
            y = (box[1] + box[3]) / 2
            if x < width * 0.16 or x > width * 0.84 or y < height * 0.16 or y > height * 0.84:
                edge_count += 1
            if x > width * 0.78:
                right_count += 1
            if y < height * 0.18:
                top_count += 1
            if width * 0.18 <= x <= width * 0.82 and height * 0.18 <= y <= height * 0.82:
                data_intrusion += 1
    count = len(boxes)
    edge_fraction = edge_count / max(count, 1)
    right_fraction = right_count / max(count, 1)
    top_fraction = top_count / max(count, 1)
    intrusion_fraction = data_intrusion / max(count, 1)
    risks: list[dict[str, Any]] = []
    if overlap_count > max(3, count * 0.03):
        risks.append(risk(STATUS_WARN, "vector_text_overlap", "Vector text boxes overlap enough to suggest label collision.", overlap_count))
    if count >= 25 and edge_fraction > 0.72:
        risks.append(risk(STATUS_WARN, "vector_tick_collision", "Vector text is heavily concentrated at plot edges; tick labels or axis labels may collide.", round(edge_fraction, 3)))
    if count >= 8 and right_fraction > 0.36:
        risks.append(risk(STATUS_WARN, "vector_legend_oversized", "Right-edge vector text suggests an oversized legend or side labels.", round(right_fraction, 3)))
    layout = {
        "checked": True,
        "method": "vector-text-box-layout",
        "canvas_size": [width, height],
        "right_edge_text_fraction": round(right_fraction, 4),
        "top_edge_text_fraction": round(top_fraction, 4),
        "edge_text_fraction": round(edge_fraction, 4),
        "text_box_data_region_intrusion": round(intrusion_fraction, 4),
        "risks": [item for item in risks if item["code"] == "vector_legend_oversized"],
    }
    text_geometry = {
        "checked": True,
        "method": "vector-text-boxes",
        "text_box_count": count,
        "text_box_overlap_count": overlap_count,
        "edge_text_box_fraction": round(edge_fraction, 4),
        "text_box_data_region_intrusion": round(intrusion_fraction, 4),
        "text_box_examples": boxes[:12],
        "risks": [item for item in risks if item["code"] != "vector_legend_oversized"],
    }
    return text_geometry, layout, risks


def vector_stroke_summary(stroke_widths: list[float], thresholds: dict[str, float]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    risks: list[dict[str, Any]] = []
    if stroke_widths and max(stroke_widths) > thresholds.get("stroke_width_max_warn", 1.2):
        risks.append(risk(STATUS_WARN, "vector_stroke_out_of_range", "Vector stroke width exceeds manuscript-style range.", round(max(stroke_widths), 3)))
    return {
        "checked": True,
        "method": "vector-stroke-widths",
        "stroke_width_pt_distribution": distribution(stroke_widths),
        "stroke_width_values": stroke_widths[:200],
        "risks": risks,
    }, risks


def as_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def pdf_matrix_multiply(left: list[float], right: list[float]) -> list[float]:
    a, b, c, d, e, f = left
    g, h, i, j, k, l = right
    return [
        a * g + c * h,
        b * g + d * h,
        a * i + c * j,
        b * i + d * j,
        a * k + c * l + e,
        b * k + d * l + f,
    ]


def pdf_transform_point(matrix: list[float], x: float, y: float) -> tuple[float, float]:
    a, b, c, d, e, f = matrix
    return (a * x + c * y + e, b * x + d * y + f)


def pdf_ctm_scale(matrix: list[float]) -> float:
    a, b, c, d, _e, _f = matrix
    sx = math.sqrt(a * a + b * b)
    sy = math.sqrt(c * c + d * d)
    values = [v for v in (sx, sy) if v > 0]
    return statistics.mean(values) if values else 1.0


def pdf_color_is_light_gray(color: tuple[float, ...] | None) -> bool:
    if not color:
        return False
    channels = tuple(max(0.0, min(1.0, float(v))) for v in color[:3])
    if len(channels) == 1:
        return channels[0] >= 0.68
    return min(channels) >= 0.68 and (max(channels) - min(channels)) <= 0.16


def pdf_path_bbox(points: list[tuple[float, float]]) -> list[float] | None:
    if not points:
        return None
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return [min(xs), min(ys), max(xs), max(ys)]


def pdf_bbox_is_long_line(bbox: list[float] | None) -> bool:
    if not bbox:
        return False
    width = abs(bbox[2] - bbox[0])
    height = abs(bbox[3] - bbox[1])
    long_side = max(width, height)
    short_side = min(width, height)
    return long_side >= 80 and short_side <= max(2.0, long_side * 0.025)


def pdf_stroke_summary_from_events(events: list[dict[str, Any]], thresholds: dict[str, float]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    widths = [round(as_float(e.get("stroke_width_pt")), 4) for e in events if e.get("stroke_width_pt") is not None]
    grid_candidates = [e for e in events if e.get("grid_candidate")]
    rect_count = sum(1 for e in events if e.get("shape") == "rect")
    line_count = sum(1 for e in events if e.get("shape") == "line")
    curve_count = sum(1 for e in events if e.get("shape") == "curve")
    summary, risks = vector_stroke_summary(widths, thresholds)
    summary.update({
        "checked": True,
        "method": "pypdf-content-stream-strokes",
        "pdf_stroke_event_count": len(events),
        "grid_candidate_count": len(grid_candidates),
        "rect_stroke_count": rect_count,
        "line_stroke_count": line_count,
        "curve_stroke_count": curve_count,
        "stroke_width_values": widths[:200],
        "stroke_event_examples": events[:20],
    })
    if widths and max(widths) > thresholds.get("stroke_width_max_warn", 1.2):
        risks.append(risk(STATUS_WARN, "stroke_too_heavy", "PDF content stream contains heavy vector strokes for manuscript-scale figures.", round(max(widths), 3)))
    summary["risks"] = risks
    return summary, risks


def analyze_pdf_strokes_with_pypdf(path: Path, figure_family: str | None = None, page: int = 1) -> dict[str, Any]:
    profile, thresholds = threshold_profile("svg", figure_family)
    if PdfReader is None or ContentStream is None:
        return {
            "checked": False,
            "available": False,
            "engine": "pypdf-content-stream",
            "reason": f"pypdf unavailable: {PYPDF_IMPORT_ERROR}",
            "stroke_width_values": [],
            "stroke_width_pt_distribution": distribution([]),
            "top_risks": [],
        }
    try:
        reader = PdfReader(str(path))
        if page < 1 or page > len(reader.pages):
            raise ValueError(f"page {page} is outside PDF page range 1-{len(reader.pages)}")
        pdf_page = reader.pages[page - 1]
        contents = pdf_page.get_contents()
        if contents is None:
            raise ValueError("PDF page has no content stream")
        stream = ContentStream(contents, reader)
    except Exception as exc:
        return {
            "checked": False,
            "available": True,
            "engine": "pypdf-content-stream",
            "reason": f"PDF stroke parsing failed: {exc}",
            "stroke_width_values": [],
            "stroke_width_pt_distribution": distribution([]),
            "top_risks": [risk(STATUS_WARN, "pdf_stroke_parse_unavailable", "PDF stroke extraction failed; raster QA still applies.", str(exc))],
        }

    state = {
        "ctm": [1.0, 0.0, 0.0, 1.0, 0.0, 0.0],
        "line_width": 1.0,
        "stroke_color": (0.0,),
        "dash": [],
    }
    stack: list[dict[str, Any]] = []
    path_points: list[tuple[float, float]] = []
    path_segments = 0
    path_curves = 0
    path_rects = 0
    current_point: tuple[float, float] | None = None
    events: list[dict[str, Any]] = []

    def reset_path() -> None:
        nonlocal path_points, path_segments, path_curves, path_rects, current_point
        path_points = []
        path_segments = 0
        path_curves = 0
        path_rects = 0
        current_point = None

    def add_point(x: float, y: float) -> tuple[float, float]:
        point = pdf_transform_point(state["ctm"], x, y)
        path_points.append(point)
        return point

    def stroke_path(operator: str) -> None:
        nonlocal events
        bbox = pdf_path_bbox(path_points)
        effective_width = as_float(state["line_width"], 1.0) * pdf_ctm_scale(state["ctm"])
        shape = "curve" if path_curves else "rect" if path_rects and path_segments <= max(5, path_rects * 5) else "line" if pdf_bbox_is_long_line(bbox) else "path"
        light_grid = (
            shape == "line"
            and effective_width <= thresholds.get("stroke_width_max_warn", 1.2)
            and pdf_color_is_light_gray(state.get("stroke_color"))
        )
        events.append({
            "operator": operator,
            "stroke_width_pt": round(effective_width, 4),
            "raw_line_width": round(as_float(state["line_width"], 1.0), 4),
            "ctm_scale": round(pdf_ctm_scale(state["ctm"]), 4),
            "stroke_color": list(state.get("stroke_color") or []),
            "dash": list(state.get("dash") or []),
            "bbox": None if bbox is None else [round(v, 3) for v in bbox],
            "segment_count": path_segments,
            "curve_count": path_curves,
            "rect_count": path_rects,
            "shape": shape,
            "grid_candidate": light_grid,
        })
        reset_path()

    stroke_ops = {"S", "s", "B", "B*", "b", "b*"}
    reset_ops = {"n", "f", "F", "f*"}
    for operands, operator_raw in stream.operations:
        operator = operator_raw.decode("latin1") if isinstance(operator_raw, bytes) else str(operator_raw)
        try:
            if operator == "q":
                stack.append({
                    "ctm": list(state["ctm"]),
                    "line_width": state["line_width"],
                    "stroke_color": state["stroke_color"],
                    "dash": list(state["dash"]),
                })
            elif operator == "Q":
                if stack:
                    state = stack.pop()
            elif operator == "cm" and len(operands) >= 6:
                matrix = [as_float(v) for v in operands[:6]]
                state["ctm"] = pdf_matrix_multiply(state["ctm"], matrix)
            elif operator == "w" and operands:
                state["line_width"] = max(as_float(operands[0], state["line_width"]), 0.0)
            elif operator == "RG" and len(operands) >= 3:
                state["stroke_color"] = tuple(as_float(v) for v in operands[:3])
            elif operator == "G" and operands:
                state["stroke_color"] = (as_float(operands[0]),)
            elif operator in {"SC", "SCN"} and operands:
                numeric = [as_float(v) for v in operands if not isinstance(v, str) and not str(v).startswith("/")]
                if numeric:
                    state["stroke_color"] = tuple(numeric[:3])
            elif operator == "d" and operands:
                dash_array = operands[0]
                try:
                    state["dash"] = [as_float(v) for v in dash_array]
                except Exception:
                    state["dash"] = []
            elif operator == "m" and len(operands) >= 2:
                current_point = add_point(as_float(operands[0]), as_float(operands[1]))
            elif operator == "l" and len(operands) >= 2:
                current_point = add_point(as_float(operands[0]), as_float(operands[1]))
                path_segments += 1
            elif operator in {"c", "v", "y"}:
                vals = [as_float(v) for v in operands]
                for x, y in zip(vals[::2], vals[1::2]):
                    current_point = add_point(x, y)
                path_segments += 1
                path_curves += 1
            elif operator == "h":
                path_segments += 1
            elif operator == "re" and len(operands) >= 4:
                x = as_float(operands[0])
                y = as_float(operands[1])
                width = as_float(operands[2])
                height = as_float(operands[3])
                for px, py in [(x, y), (x + width, y), (x + width, y + height), (x, y + height)]:
                    add_point(px, py)
                current_point = path_points[-1] if path_points else current_point
                path_segments += 4
                path_rects += 1
            elif operator in stroke_ops:
                stroke_path(operator)
            elif operator in reset_ops:
                reset_path()
        except Exception:
            continue

    vector_stroke_geometry, risks = pdf_stroke_summary_from_events(events, thresholds)
    return {
        "checked": True,
        "available": True,
        "engine": "pypdf-content-stream",
        "input_type": "pdf",
        "input_path": str(path),
        "page": page,
        "figure_family": normalize_family(figure_family),
        "threshold_profile": profile,
        "family_thresholds": thresholds,
        "stroke_width_values": vector_stroke_geometry.get("stroke_width_values", []),
        "stroke_width_min": (vector_stroke_geometry.get("stroke_width_pt_distribution") or {}).get("min"),
        "stroke_width_median": (vector_stroke_geometry.get("stroke_width_pt_distribution") or {}).get("median"),
        "stroke_width_max": (vector_stroke_geometry.get("stroke_width_pt_distribution") or {}).get("max"),
        "stroke_width_pt_distribution": vector_stroke_geometry.get("stroke_width_pt_distribution"),
        "vector_stroke_geometry": vector_stroke_geometry,
        "pdf_stroke_event_count": vector_stroke_geometry.get("pdf_stroke_event_count", 0),
        "grid_candidate_count": vector_stroke_geometry.get("grid_candidate_count", 0),
        "rect_stroke_count": vector_stroke_geometry.get("rect_stroke_count", 0),
        "line_stroke_count": vector_stroke_geometry.get("line_stroke_count", 0),
        "curve_stroke_count": vector_stroke_geometry.get("curve_stroke_count", 0),
        "top_risks": risks,
    }


def vector_font_summary(font_sizes: list[float], thresholds: dict[str, float]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    risks: list[dict[str, Any]] = []
    if font_sizes:
        if min(font_sizes) < 4:
            risks.append(risk(STATUS_WARN, "vector_font_out_of_range", "Vector font size is below manuscript target readability.", round(min(font_sizes), 3)))
        if max(font_sizes) > thresholds.get("manuscript_text_max_warn", 12):
            risks.append(risk(STATUS_WARN, "vector_font_out_of_range", "Vector font size is above manuscript panel typography range.", round(max(font_sizes), 3)))
    return {
        "checked": True,
        "method": "vector-font-sizes",
        "font_size_pt_distribution": distribution(font_sizes),
        "risks": risks,
    }, risks


def analyze_svg_structure(path: Path, figure_family: str | None = None, target_width_mm: float | None = None) -> dict[str, Any]:
    text = path.read_text(errors="ignore")
    try:
        root = ET.fromstring(text)
    except ET.ParseError as exc:
        return {"checked": False, "engine": "svg-xml", "input_type": "svg", "input_path": str(path), "status": STATUS_FAIL, "top_risks": [risk(STATUS_FAIL, "svg_parse_error", str(exc))]}
    width = parse_length(root.attrib.get("width"))
    height = parse_length(root.attrib.get("height"))
    viewbox_width = None
    if root.attrib.get("viewBox"):
        nums = [float(x) for x in re.findall(r"[-+]?[0-9]*\.?[0-9]+", root.attrib["viewBox"])]
        if len(nums) == 4:
            viewbox_width = nums[2]
            width = width or nums[2]
            height = height or nums[3]
    user_unit_to_pt = 1.0
    if target_width_mm and viewbox_width and viewbox_width > 0:
        user_unit_to_pt = (target_width_mm / 25.4 * 72.0) / viewbox_width
    texts = []
    lines = []
    rects = []
    stroke_widths = []
    all_elements = list(root.iter())
    for el in all_elements:
        name = local_name(el.tag)
        if name == "text":
            style = el.attrib.get("style", "")
            fs = parse_length(el.attrib.get("font-size") or style_value(style, "font-size") or "")
            x = parse_length(el.attrib.get("x"))
            y = parse_length(el.attrib.get("y"))
            if (x is None or y is None):
                first_tspan = next((child for child in el if local_name(child.tag) == "tspan"), None)
                if first_tspan is not None:
                    x = x if x is not None else parse_length(first_tspan.attrib.get("x"))
                    y = y if y is not None else parse_length(first_tspan.attrib.get("y"))
                    fs = fs if fs is not None else parse_length(first_tspan.attrib.get("font-size") or style_value(first_tspan.attrib.get("style", ""), "font-size") or "")
            tx, ty = transform_translate(el.attrib.get("transform"))
            if x is not None:
                x += tx
            if y is not None:
                y += ty
            weight = el.attrib.get("font-weight", "") or style_value(style, "font-weight") or style
            family = el.attrib.get("font-family") or style_value(style, "font-family")
            content = "".join(el.itertext()).strip()
            anchor = el.attrib.get("text-anchor", "") or style_value(style, "text-anchor") or ""
            box = None
            if content and x is not None and y is not None:
                size = fs or 10.0
                width_est = max(size * 0.45 * len(content), size)
                height_est = max(size * 1.2, 1)
                x0 = x
                if "middle" in anchor:
                    x0 = x - width_est / 2
                elif "end" in anchor:
                    x0 = x - width_est
                box = [round(x0, 3), round(y - height_est, 3), round(x0 + width_est, 3), round(y + height_est * 0.25, 3)]
            texts.append({"font_size": fs, "x": x, "y": y, "weight": weight, "font_family": family, "text": content, "anchor": anchor, "transform": el.attrib.get("transform", ""), "box": box})
        elif name in {"line", "path", "polyline", "polygon", "circle", "ellipse"}:
            stroke = (el.attrib.get("stroke") or style_value(el.attrib.get("style", ""), "stroke") or "").lower()
            sw = parse_length(el.attrib.get("stroke-width") or style_value(el.attrib.get("style", ""), "stroke-width") or "")
            if sw is not None:
                stroke_widths.append(sw)
            lines.append({"stroke": stroke, "stroke_width": sw})
        elif name == "rect":
            sw = parse_length(el.attrib.get("stroke-width") or style_value(el.attrib.get("style", ""), "stroke-width") or "")
            if sw is not None:
                stroke_widths.append(sw)
            rects.append(dict(el.attrib))
    raw_font_sizes = [t["font_size"] for t in texts if t["font_size"] is not None]
    font_sizes = [v * user_unit_to_pt for v in raw_font_sizes]
    raw_stroke_widths = list(stroke_widths)
    stroke_widths = [v * user_unit_to_pt for v in raw_stroke_widths]
    max_font = max(font_sizes) if font_sizes else None
    min_font = min(font_sizes) if font_sizes else None
    median_font = statistics.median(font_sizes) if font_sizes else None
    light_gridlines = sum(1 for ln in lines if any(x in ln["stroke"] for x in ("#eee", "#eeeeee", "#e5e5e5", "#ddd", "#dddddd")))
    profile, thresholds = threshold_profile("svg", figure_family)
    vector_text_geometry, vector_layout_geometry, vector_text_risks = summarize_vector_text_boxes(texts, (width, height), thresholds)
    vector_stroke_geometry, vector_stroke_risks = vector_stroke_summary(stroke_widths, thresholds)
    vector_font_geometry, vector_font_risks = vector_font_summary(font_sizes, thresholds)
    centered_large_titles = [
        t for t in texts
        if ((t["font_size"] or 0) * user_unit_to_pt) >= 18
        and ("middle" in t["anchor"] or (width and t["x"] and abs(t["x"] - width / 2) < width * 0.12))
    ]
    presentation_titles = [
        t for t in texts
        if ((t["font_size"] or 0) * user_unit_to_pt) >= thresholds.get("manuscript_text_max_warn", 12)
        and ("middle" in t["anchor"] or (width and t["x"] and abs(t["x"] - width / 2) < width * 0.18))
    ]
    risks: list[dict[str, Any]] = []
    score = 10
    for item in vector_text_risks + vector_stroke_risks + vector_font_risks:
        risks.append(item)
        score -= 1
    if max_font and max_font >= thresholds["max_font_warn"]:
        risks.append(risk(STATUS_WARN, "oversized_svg_title_or_text", "SVG contains presentation-sized text.", max_font)); score -= 2
    if presentation_titles:
        risks.append(risk(STATUS_WARN, "vector_title_presentation_style", "Vector title-like text is too large or centered for a manuscript panel.", presentation_titles[0].get("text", ""))); score -= 1
        risks.append(risk(STATUS_WARN, "presentation_title_risk", "SVG contains centered title-like text larger than manuscript panel typography.", presentation_titles[0].get("text", ""))); score -= 1
    if centered_large_titles:
        risks.append(risk(STATUS_WARN, "huge_centered_title", "Large centered title suggests presentation-style rather than manuscript panel style.", centered_large_titles[0].get("text", ""))); score -= 2
    if max_font and max_font > thresholds.get("manuscript_text_max_warn", 12):
        risks.append(risk(STATUS_WARN, "font_too_large_for_manuscript", "SVG has text above manuscript figure typography range.", max_font)); score -= 1
    if min_font and min_font < 4:
        risks.append(risk(STATUS_WARN, "font_too_small_at_target_width", "SVG has very small text that may fail at target manuscript width.", min_font)); score -= 1
    if stroke_widths and max(stroke_widths) > thresholds.get("stroke_width_max_warn", 1.2):
        risks.append(risk(STATUS_WARN, "stroke_too_heavy", "SVG contains thick strokes for a manuscript panel.", round(max(stroke_widths), 3))); score -= 1
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
        "target_width_mm": target_width_mm,
        "viewbox_width": viewbox_width,
        "user_unit_to_pt": round(user_unit_to_pt, 6),
        "file_size_bytes": path.stat().st_size,
        "text_count": len(texts),
        "line_count": len(lines),
        "rect_count": len(rects),
        "raw_font_size_min": min(raw_font_sizes) if raw_font_sizes else None,
        "raw_font_size_median": statistics.median(raw_font_sizes) if raw_font_sizes else None,
        "raw_font_size_max": max(raw_font_sizes) if raw_font_sizes else None,
        "font_size_min": min_font,
        "font_size_median": median_font,
        "font_size_max": max_font,
        "raw_stroke_width_values": raw_stroke_widths[:200],
        "stroke_width_values": stroke_widths[:200],
        "raw_stroke_width_min": min(raw_stroke_widths) if raw_stroke_widths else None,
        "raw_stroke_width_median": statistics.median(raw_stroke_widths) if raw_stroke_widths else None,
        "raw_stroke_width_max": max(raw_stroke_widths) if raw_stroke_widths else None,
        "stroke_width_min": min(stroke_widths) if stroke_widths else None,
        "stroke_width_median": statistics.median(stroke_widths) if stroke_widths else None,
        "stroke_width_max": max(stroke_widths) if stroke_widths else None,
        "vector_text_geometry": vector_text_geometry,
        "vector_stroke_geometry": vector_stroke_geometry,
        "vector_layout_geometry": vector_layout_geometry,
        "font_size_pt_distribution": vector_font_geometry["font_size_pt_distribution"],
        "stroke_width_pt_distribution": vector_stroke_geometry["stroke_width_pt_distribution"],
        "text_box_overlap_count": vector_text_geometry["text_box_overlap_count"],
        "text_box_data_region_intrusion": vector_text_geometry["text_box_data_region_intrusion"],
        "light_gridline_count": light_gridlines,
        "centered_large_title_count": len(centered_large_titles),
        "presentation_title_count": len(presentation_titles),
        "manuscript_readiness_score": score,
        "status": STATUS_WARN if status_from_score(score) == STATUS_PASS and any(item.get("status") == STATUS_WARN for item in risks) else status_from_score(score),
        "top_risks": risks,
    }


def analyze_pdf_structure(path: Path, figure_family: str | None = None, page: int = 1) -> dict[str, Any]:
    exe = shutil.which("pdftotext")
    profile, thresholds = threshold_profile("svg", figure_family)
    pdf_strokes = analyze_pdf_strokes_with_pypdf(path, figure_family, page)
    if not exe:
        stroke_risks = pdf_strokes.get("top_risks", [])
        return {
            "checked": True,
            "available": False,
            "engine": "pdftotext-bbox+pypdf-content-stream",
            "input_type": "pdf",
            "input_path": str(path),
            "figure_family": normalize_family(figure_family),
            "threshold_profile": profile,
            "family_thresholds": thresholds,
            "top_risks": stroke_risks,
            "vector_text_geometry": {"checked": False, "reason": "pdftotext not found"},
            "vector_stroke_geometry": pdf_strokes.get("vector_stroke_geometry", {"checked": False, "reason": "PDF stroke extraction unavailable"}),
            "vector_layout_geometry": {"checked": False, "reason": "pdftotext not found"},
            "font_size_pt_distribution": distribution([]),
            "stroke_width_values": pdf_strokes.get("stroke_width_values", []),
            "stroke_width_min": pdf_strokes.get("stroke_width_min"),
            "stroke_width_median": pdf_strokes.get("stroke_width_median"),
            "stroke_width_max": pdf_strokes.get("stroke_width_max"),
            "stroke_width_pt_distribution": pdf_strokes.get("stroke_width_pt_distribution", distribution([])),
            "text_box_overlap_count": None,
            "text_box_data_region_intrusion": None,
            "pdf_stroke_event_count": pdf_strokes.get("pdf_stroke_event_count", 0),
            "grid_candidate_count": pdf_strokes.get("grid_candidate_count", 0),
            "rect_stroke_count": pdf_strokes.get("rect_stroke_count", 0),
            "line_stroke_count": pdf_strokes.get("line_stroke_count", 0),
            "curve_stroke_count": pdf_strokes.get("curve_stroke_count", 0),
            "manuscript_readiness_score": 10 if not stroke_risks else 8,
            "status": STATUS_WARN if stroke_risks else STATUS_PASS,
        }
    proc = run_command([exe, "-bbox", "-f", str(page), "-l", str(page), str(path), "-"])
    if proc.returncode != 0:
        stroke_risks = pdf_strokes.get("top_risks", [])
        return {
            "checked": True,
            "available": True,
            "engine": "pdftotext-bbox+pypdf-content-stream",
            "input_type": "pdf",
            "input_path": str(path),
            "status": STATUS_WARN,
            "top_risks": [risk(STATUS_WARN, "pdf_bbox_parse_unavailable", "PDF text bbox extraction failed; raster QA still applies.", proc.stderr or proc.stdout)] + stroke_risks,
            "vector_stroke_geometry": pdf_strokes.get("vector_stroke_geometry", {"checked": False, "reason": "PDF stroke extraction unavailable"}),
            "stroke_width_values": pdf_strokes.get("stroke_width_values", []),
            "stroke_width_pt_distribution": pdf_strokes.get("stroke_width_pt_distribution", distribution([])),
            "pdf_stroke_event_count": pdf_strokes.get("pdf_stroke_event_count", 0),
            "grid_candidate_count": pdf_strokes.get("grid_candidate_count", 0),
        }
    try:
        root = ET.fromstring(proc.stdout)
    except ET.ParseError as exc:
        stroke_risks = pdf_strokes.get("top_risks", [])
        return {
            "checked": True,
            "available": True,
            "engine": "pdftotext-bbox+pypdf-content-stream",
            "input_type": "pdf",
            "input_path": str(path),
            "status": STATUS_WARN,
            "top_risks": [risk(STATUS_WARN, "pdf_bbox_parse_error", "PDF bbox output could not be parsed; raster QA still applies.", str(exc))] + stroke_risks,
            "vector_stroke_geometry": pdf_strokes.get("vector_stroke_geometry", {"checked": False, "reason": "PDF stroke extraction unavailable"}),
            "stroke_width_values": pdf_strokes.get("stroke_width_values", []),
            "stroke_width_pt_distribution": pdf_strokes.get("stroke_width_pt_distribution", distribution([])),
            "pdf_stroke_event_count": pdf_strokes.get("pdf_stroke_event_count", 0),
            "grid_candidate_count": pdf_strokes.get("grid_candidate_count", 0),
        }
    width = height = None
    boxes: list[dict[str, Any]] = []
    for el in root.iter():
        name = local_name(el.tag)
        if name == "page":
            width = parse_length(el.attrib.get("width")) or width
            height = parse_length(el.attrib.get("height")) or height
        if name != "word":
            continue
        try:
            x0 = float(el.attrib.get("xMin", "0"))
            y0 = float(el.attrib.get("yMin", "0"))
            x1 = float(el.attrib.get("xMax", "0"))
            y1 = float(el.attrib.get("yMax", "0"))
        except Exception:
            continue
        text = "".join(el.itertext()).strip()
        if not text or x1 <= x0 or y1 <= y0:
            continue
        fs = max(y1 - y0, 0.0)
        boxes.append({"font_size": fs, "x": x0, "y": y1, "weight": "", "font_family": None, "text": text, "anchor": "", "transform": "", "box": [x0, y0, x1, y1]})
    font_sizes = [float(item["font_size"]) for item in boxes if item.get("font_size")]
    vector_text_geometry, vector_layout_geometry, vector_text_risks = summarize_vector_text_boxes(boxes, (width, height), thresholds)
    vector_font_geometry, vector_font_risks = vector_font_summary(font_sizes, thresholds)
    risks: list[dict[str, Any]] = []
    score = 10
    stroke_risks = [item for item in pdf_strokes.get("top_risks", []) if item.get("status") != STATUS_PASS]
    for item in vector_text_risks + vector_font_risks + stroke_risks:
        risks.append(item)
        score -= 1
    if not boxes:
        risks.append(risk(STATUS_WARN, "pdf_no_extractable_text", "No extractable PDF text boxes found; text may be outlined or rasterized."))
        score -= 1
    if not risks:
        risks.append(risk(STATUS_PASS, "no_major_pdf_vector_text_risk", "No major PDF vector text risk detected."))
    score = max(0, min(10, score))
    return {
        "checked": True,
        "available": True,
        "engine": "pdftotext-bbox+pypdf-content-stream",
        "input_type": "pdf",
        "input_path": str(path),
        "figure_family": normalize_family(figure_family),
        "threshold_profile": profile,
        "family_thresholds": thresholds,
        "canvas_size": [width, height],
        "file_size_bytes": path.stat().st_size,
        "text_count": len(boxes),
        "line_count": None,
        "rect_count": None,
        "font_size_min": min(font_sizes) if font_sizes else None,
        "font_size_median": statistics.median(font_sizes) if font_sizes else None,
        "font_size_max": max(font_sizes) if font_sizes else None,
        "stroke_width_values": pdf_strokes.get("stroke_width_values", []),
        "stroke_width_min": pdf_strokes.get("stroke_width_min"),
        "stroke_width_median": pdf_strokes.get("stroke_width_median"),
        "stroke_width_max": pdf_strokes.get("stroke_width_max"),
        "vector_text_geometry": vector_text_geometry,
        "vector_stroke_geometry": pdf_strokes.get("vector_stroke_geometry", {"checked": False, "reason": "PDF stroke extraction unavailable", "stroke_width_pt_distribution": distribution([]), "risks": []}),
        "vector_layout_geometry": vector_layout_geometry,
        "font_size_pt_distribution": vector_font_geometry["font_size_pt_distribution"],
        "stroke_width_pt_distribution": pdf_strokes.get("stroke_width_pt_distribution", distribution([])),
        "text_box_overlap_count": vector_text_geometry["text_box_overlap_count"],
        "text_box_data_region_intrusion": vector_text_geometry["text_box_data_region_intrusion"],
        "pdf_stroke_event_count": pdf_strokes.get("pdf_stroke_event_count", 0),
        "grid_candidate_count": pdf_strokes.get("grid_candidate_count", 0),
        "rect_stroke_count": pdf_strokes.get("rect_stroke_count", 0),
        "line_stroke_count": pdf_strokes.get("line_stroke_count", 0),
        "curve_stroke_count": pdf_strokes.get("curve_stroke_count", 0),
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
        f"- figure family: `{result.get('figure_family') or 'global'}` (source: `{result.get('figure_family_source') or 'none'}`)",
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
    detail = result.get("nature_detail_rubric") or {}
    lines += [
        "",
        "## Nature detail QA",
        "",
        f"- journal profile: `{detail.get('journal_profile')}`",
        f"- target width mm: `{detail.get('target_width_mm')}`",
        f"- strict detail QA: `{detail.get('strict_detail_qa')}`",
        f"- allow grid: `{detail.get('allow_grid')}`",
        f"- detail status: `{detail.get('status')}`",
        f"- hard fail codes: `{detail.get('hard_fail_codes')}`",
    ]
    text = result.get("text_geometry") or {}
    stroke = result.get("stroke_geometry") or {}
    grid = result.get("grid_background") or {}
    legend = result.get("legend_geometry") or {}
    font = result.get("font_assessment") or {}
    lines += [
        "",
        "## Detail metrics",
        "",
        f"- text-like components: `{text.get('text_like_component_count')}`",
        f"- edge text-like fraction: `{text.get('edge_text_like_fraction')}`",
        f"- stroke line burden: `{stroke.get('line_burden_score')}`",
        f"- vector stroke max: `{stroke.get('vector_stroke_width_max')}`",
        f"- grid long-line count: `{grid.get('long_line_count')}`",
        f"- legend edge fraction: `{legend.get('edge_content_fraction')}`",
        f"- font range observed: `{font.get('font_size_min')}` / `{font.get('font_size_median')}` / `{font.get('font_size_max')}`",
    ]
    vector = result.get("vector_structure") or {}
    if vector:
        vtext = result.get("vector_text_geometry") or {}
        vstroke = result.get("vector_stroke_geometry") or {}
        vlayout = result.get("vector_layout_geometry") or {}
        lines += [
            "",
            "## Vector geometry",
            "",
            f"- vector engine: `{vector.get('engine')}`",
            f"- vector text boxes: `{vtext.get('text_box_count')}`",
            f"- vector text overlaps: `{vtext.get('text_box_overlap_count')}`",
            f"- vector text data-region intrusion: `{vtext.get('text_box_data_region_intrusion')}`",
            f"- vector right-edge text fraction: `{vlayout.get('right_edge_text_fraction')}`",
            f"- vector font distribution: `{result.get('font_size_pt_distribution')}`",
            f"- vector stroke distribution: `{result.get('stroke_width_pt_distribution')}`",
            f"- vector stroke max: `{(vstroke.get('stroke_width_pt_distribution') or {}).get('max')}`",
        ]
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
    nature = result.get("nature_guardrails") or {}
    if nature:
        lines += [
            "",
            "## Nature guardrails",
            "",
            f"- strict mode: `{nature.get('strict')}`",
            f"- status: `{nature.get('status')}`",
            f"- reference: `{nature.get('reference')}`",
            "",
            "| guardrail | status | triggered codes | fix |",
            "|---|---|---|---|",
        ]
        for item in nature.get("checks", []):
            codes = ", ".join(item.get("hard_hits", []) + item.get("review_hits", [])) or "-"
            lines.append(f"| {item.get('label')} | {item.get('status')} | {codes} | {item.get('fix')} |")
    lines += ["", "## Top risks", ""]
    for item in result.get("top_risks", []):
        lines.append(f"- `{item.get('status')}` `{item.get('code')}`: {item.get('message')}" + (f" ({item.get('value')})" if "value" in item else ""))
        rem = item.get("remediation")
        if rem:
            lines.append(f"  - fix: {rem.get('fix')} (see `{rem.get('doc')}`)")
    (out_dir / "visual_qa.md").write_text("\n".join(lines) + "\n")


def parse_font_range(value: str) -> tuple[float, float]:
    parts = [p.strip() for p in value.split(",") if p.strip()]
    if len(parts) != 2:
        raise SystemExit("--expected-font-range must be formatted like 5,7")
    try:
        low, high = float(parts[0]), float(parts[1])
    except Exception as exc:
        raise SystemExit(f"--expected-font-range must contain numeric values: {value}") from exc
    if low <= 0 or high <= 0 or low > high:
        raise SystemExit("--expected-font-range must be positive and ordered low,high")
    return low, high


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
    parser.add_argument("--strict-nature", action="store_true", help="Fail the command when hard Nature guardrails are triggered")
    parser.add_argument("--target-width-mm", type=float, default=None, help="Target manuscript figure width in millimeters for detail QA interpretation")
    parser.add_argument("--journal-profile", choices=["nature", "cell", "science", "generic"], default="generic", help="Journal-style profile for detail QA reporting")
    parser.add_argument("--strict-detail-qa", action="store_true", help="Promote severe detail-level problems to hard manuscript QA failures")
    parser.add_argument("--allow-grid", choices=["auto", "off", "light", "required"], default="auto", help="Interpretation of background/grid lines")
    parser.add_argument("--expected-font-range", default="5,7", help="Expected manuscript text range in points, formatted low,high")
    args = parser.parse_args()
    in_path = resolve_input(Path(args.input).expanduser())
    out_dir = Path(args.out).expanduser()
    ensure_dir(out_dir)
    ext = in_path.suffix.lower()
    # Auto-resolve figure family so family-specific thresholds actually fire even
    # when the caller forgets --family (otherwise QA silently uses global ones).
    if args.family:
        figure_family, family_source = args.family, "cli"
    else:
        figure_family, family_source = infer_figure_family(in_path)
    svg_structure = analyze_svg_structure(in_path, figure_family, args.target_width_mm) if ext == ".svg" else None
    pdf_structure = analyze_pdf_structure(in_path, figure_family, args.page) if ext == ".pdf" else None
    vector_structure = svg_structure or pdf_structure
    raster_path, rasterization = rasterize_input(in_path, out_dir, args.dpi, args.page)
    input_type = "raster" if ext in {".png", ".jpg", ".jpeg"} else ext.lstrip(".")
    result = analyze_raster(
        raster_path,
        out_dir,
        figure_family,
        input_path=in_path,
        input_type=input_type,
        rasterization=rasterization,
        svg_structure=svg_structure,
        vector_structure=vector_structure,
        expected_panels=args.expected_panels,
        layout_profile=args.layout_profile,
        ocr_mode=args.ocr,
        strict_nature=args.strict_nature,
        target_width_mm=args.target_width_mm,
        journal_profile=args.journal_profile,
        strict_detail_qa=args.strict_detail_qa,
        allow_grid=args.allow_grid,
        expected_font_range=parse_font_range(args.expected_font_range),
    )
    result["figure_family_source"] = family_source
    (out_dir / "visual_qa.json").write_text(json.dumps({"image_qa": result}, indent=2, ensure_ascii=False) + "\n")
    write_markdown(result, out_dir)
    print(f"visual QA written: {out_dir / 'visual_qa.json'}")
    if not result.get("checked"):
        return 1
    if args.strict_nature and (result.get("nature_guardrails") or {}).get("status") == STATUS_FAIL:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
