#!/usr/bin/env python3
"""Family-specific automatic QA scoring for PaperPlot rendered-image QA.

This layer consumes `visual_qa.json` and adds a deterministic 0-10 score that
interprets detail risks in a figure-family context. If a local gold human
calibration file exists, it also reports whether the family is supported as a
Nature-like positive calibration source. It does not use network services.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
from pathlib import Path
from typing import Any


STATUS_PASS = "pass"
STATUS_WARN = "warn"
STATUS_FAIL = "fail"
DEFAULT_CALIBRATION_PATH = Path(__file__).resolve().parent.parent / "references" / "gold-human-calibration-rules.json"


DEFAULT_WEIGHTS = {
    "typography": 1.25,
    "stroke_grid": 1.0,
    "label_collision": 1.35,
    "panel_balance": 1.25,
    "legend_color": 1.0,
    "scientific_semantics": 1.15,
}


RISK_TO_BUCKET = {
    "vector_font_out_of_range": "typography",
    "font_too_small_at_target_width": "typography",
    "font_too_large_for_manuscript": "typography",
    "presentation_title_risk": "typography",
    "vector_title_presentation_style": "typography",
    "oversized_svg_title_or_text": "typography",
    "huge_centered_title": "typography",
    "thumbnail_readability_risk": "typography",
    "high_text_or_tick_density": "typography",
    "vector_stroke_out_of_range": "stroke_grid",
    "stroke_too_heavy": "stroke_grid",
    "stroke_too_light": "stroke_grid",
    "grid_background_burden": "stroke_grid",
    "gridline_or_long_line_burden": "stroke_grid",
    "svg_gridline_burden": "stroke_grid",
    "text_data_overlap_risk": "label_collision",
    "vector_text_overlap": "label_collision",
    "ocr_text_overlap_risk": "label_collision",
    "label_overlap_or_large_annotation_risk": "label_collision",
    "tick_label_collision_risk": "label_collision",
    "vector_tick_collision": "label_collision",
    "axis_title_collision_risk": "label_collision",
    "significance_annotation_overcrowding": "label_collision",
    "panel_size_imbalance": "panel_balance",
    "panel_data_region_imbalance": "panel_balance",
    "panel_data_region_mismatch": "panel_balance",
    "panel_blank_space_imbalance": "panel_balance",
    "unjustified_panel_hierarchy_risk": "panel_balance",
    "excessive_panel_padding": "panel_balance",
    "legend_dominates_panel": "legend_color",
    "vector_legend_oversized": "legend_color",
    "saturated_presentation_palette": "legend_color",
    "decorative_background_risk": "legend_color",
    "grayscale_discrimination_risk": "legend_color",
    "low_grayscale_contrast": "legend_color",
    "low_content_density": "panel_balance",
    "excessive_blank_margin": "panel_balance",
}


BLOCKING_RISKS = {
    "text_data_overlap_risk",
    "vector_text_overlap",
    "ocr_text_overlap_risk",
    "font_too_small_at_target_width",
    "panel_data_region_mismatch",
    "panel_size_imbalance",
    "panel_data_region_imbalance",
    "vector_font_out_of_range",
}


GRID_STROKE_RISKS = {
    "grid_background_burden",
    "gridline_or_long_line_burden",
    "svg_gridline_burden",
    "stroke_too_heavy",
    "vector_stroke_out_of_range",
}


FAMILY_RULES: dict[str, dict[str, Any]] = {
    "bar/errorbar": {
        "aliases": ["bar", "grouped bar", "stacked bar", "errorbar", "column"],
        "weights": {"stroke_grid": 1.25, "scientific_semantics": 1.35, "label_collision": 1.1},
        "notes": [
            "Bar/errorbar figures are penalized for default-style background grids because bars and intervals already provide structure.",
            "Image-only QA cannot confirm n, raw points, or errorbar type; keep these in notes/caption/metadata.",
        ],
    },
    "violin/raincloud": {
        "aliases": ["boxplot", "violin", "raincloud", "jitter", "box", "beeswarm"],
        "weights": {"label_collision": 1.35, "stroke_grid": 1.15, "scientific_semantics": 1.25},
        "notes": ["Raw points, sample sizes, and significance annotations need data-backed confirmation beyond image-level QA."],
    },
    "scatter/regression": {
        "aliases": ["scatter", "regression", "marginal", "correlation scatter"],
        "weights": {"label_collision": 1.45, "stroke_grid": 0.8, "legend_color": 1.15},
        "downgrade_risks": {"grid_background_burden", "gridline_or_long_line_burden"},
        "notes": ["Light quantitative grids are allowed only when they improve reading without dominating marks."],
    },
    "heatmap": {
        "aliases": ["heatmap", "correlation", "matrix", "matrix dotplot", "cell matrix"],
        "weights": {"typography": 1.35, "stroke_grid": 0.55, "legend_color": 1.35, "scientific_semantics": 1.2},
        "downgrade_risks": GRID_STROKE_RISKS,
        "blocking_exemptions": GRID_STROKE_RISKS,
        "notes": ["High line density is interpreted as cell structure; colorbar semantics and row/column label burden remain strict."],
    },
    "ordination": {
        "aliases": ["pca", "pcoa", "nmds", "umap", "tsne", "t-sne", "ordination"],
        "weights": {"label_collision": 1.35, "legend_color": 1.3, "scientific_semantics": 1.3},
        "notes": ["Axis method and variance explained cannot be proven from pixels; verify labels/metadata."],
    },
    "volcano/enrichment": {
        "aliases": ["volcano", "ma", "enrichment", "gsea", "dot enrichment", "pathway"],
        "weights": {"label_collision": 1.45, "legend_color": 1.2, "scientific_semantics": 1.45},
        "notes": ["Threshold, effect-size, significance, and label-selection semantics must be explicit in the figure notes."],
    },
    "multi-panel": {
        "aliases": ["multi-panel", "manuscript", "panel", "facet", "composite"],
        "weights": {"panel_balance": 1.65, "typography": 1.15, "legend_color": 1.25},
        "notes": ["Equal-role panel size and data-region balance are heavily weighted."],
    },
    "model-validation": {
        "aliases": ["model", "validation", "prediction", "residual", "diagnostic"],
        "weights": {"panel_balance": 1.35, "scientific_semantics": 1.35, "typography": 1.1},
        "notes": ["Prediction accuracy, residual, calibration, and uncertainty semantics need data-backed confirmation."],
    },
    "forest/effect-size": {
        "aliases": ["forest", "effect-size", "effect size", "odds ratio", "hazard ratio"],
        "weights": {"stroke_grid": 0.85, "scientific_semantics": 1.55, "label_collision": 1.25},
        "downgrade_risks": {"gridline_or_long_line_burden"},
        "notes": ["Forest/effect-size figures should show CI intervals, a reference line, effect axis units, and subgroup labels clearly."],
    },
    "lollipop/dumbbell/dotplot": {
        "aliases": ["lollipop", "dumbbell", "dotplot", "rank", "rank plot", "point-range"],
        "weights": {"stroke_grid": 1.3, "label_collision": 1.3, "scientific_semantics": 1.25},
        "blocking_risks": {"grid_background_burden"},
        "notes": ["Ordering semantics and direct labels matter; default background grids should stay subordinate to point/interval marks."],
    },
    "manhattan/genomewide": {
        "aliases": ["manhattan", "genomewide", "genome-wide", "gwas"],
        "weights": {"typography": 1.2, "stroke_grid": 0.75, "scientific_semantics": 1.45},
        "downgrade_risks": {"gridline_or_long_line_burden", "thumbnail_readability_risk"},
        "notes": ["Manhattan plots may have high point density and threshold lines, but chromosome labels and significance thresholds must remain interpretable."],
    },
    "ridgeline/density": {
        "aliases": ["ridgeline", "ridge", "density", "kde", "contour"],
        "weights": {"stroke_grid": 0.8, "label_collision": 1.25, "scientific_semantics": 1.25},
        "downgrade_risks": {"gridline_or_long_line_burden", "stroke_too_heavy"},
        "notes": ["Repeated density outlines are expected; overlap amount, scale, and axis semantics are the review focus."],
    },
    "upset/set": {
        "aliases": ["upset", "set plot", "venn", "intersection"],
        "weights": {"typography": 1.35, "stroke_grid": 0.55, "label_collision": 1.35},
        "downgrade_risks": GRID_STROKE_RISKS,
        "blocking_exemptions": GRID_STROKE_RISKS,
        "specialized": True,
        "notes": ["Set matrices use dots/connectors/bars; dense structure is expected, while set labels and bar labels must remain readable."],
    },
    "phylo/tree": {
        "aliases": ["phylo", "phylogenetic", "tree", "ggtree", "cladogram", "dendrogram"],
        "weights": {"typography": 1.35, "stroke_grid": 0.35, "label_collision": 1.45},
        "downgrade_risks": GRID_STROKE_RISKS,
        "blocking_exemptions": GRID_STROKE_RISKS,
        "specialized": True,
        "notes": ["Tree layouts legitimately contain many branches; labels, annotation rings, and legends drive manuscript readability."],
    },
    "circos/chord/sankey": {
        "aliases": ["circos", "chord", "sankey", "circular", "alluvial"],
        "weights": {"stroke_grid": 0.3, "legend_color": 1.35, "label_collision": 1.35},
        "downgrade_risks": GRID_STROKE_RISKS,
        "blocking_exemptions": GRID_STROKE_RISKS,
        "specialized": True,
        "notes": ["Circular/chord/Sankey layouts are caution-only for line burden; color semantics and label placement are the key risks."],
    },
    "map/spatial": {
        "aliases": ["map", "spatial", "geo", "geographic", "choropleth"],
        "weights": {"legend_color": 1.45, "typography": 1.2, "scientific_semantics": 1.3},
        "downgrade_risks": {"gridline_or_long_line_burden", "stroke_too_heavy"},
        "blocking_exemptions": {"gridline_or_long_line_burden", "stroke_too_heavy"},
        "specialized": True,
        "notes": ["Map/spatial figures need scale/region/colorbar semantics; outlines and boundaries are not ordinary grid burden."],
    },
    "network": {
        "aliases": ["network", "graph", "node edge", "node-edge"],
        "weights": {"stroke_grid": 0.35, "label_collision": 1.55, "legend_color": 1.25},
        "downgrade_risks": GRID_STROKE_RISKS,
        "blocking_exemptions": GRID_STROKE_RISKS,
        "specialized": True,
        "notes": ["Network figures tolerate many edges but are strict on label collisions, node/edge legend clarity, and overplotting."],
    },
    "genome-track/synteny": {
        "aliases": ["genome track", "genome-track", "synteny", "genome browser", "track plot"],
        "weights": {"stroke_grid": 0.55, "typography": 1.3, "scientific_semantics": 1.4},
        "downgrade_risks": {"gridline_or_long_line_burden", "stroke_too_heavy"},
        "blocking_exemptions": {"gridline_or_long_line_burden"},
        "specialized": True,
        "notes": ["Genome tracks/synteny plots require coordinate scale, feature labels, and track hierarchy; repeated horizontal structure is expected."],
    },
    "specialized": {
        "aliases": ["radar", "polar", "schematic"],
        "weights": {"stroke_grid": 0.35, "panel_balance": 1.0, "scientific_semantics": 1.3},
        "downgrade_risks": GRID_STROKE_RISKS,
        "blocking_exemptions": GRID_STROKE_RISKS,
        "specialized": True,
        "notes": ["Specialized layouts use caution rules; dense line structure is not automatically a failure."],
    },
}


FAMILY_ALIASES = {alias: family for family, rule in FAMILY_RULES.items() for alias in rule.get("aliases", [])}
SPECIALIZED_FAMILIES = {family for family, rule in FAMILY_RULES.items() if rule.get("specialized")}
FAMILY_WEIGHT_OVERRIDES = {family: rule.get("weights", {}) for family, rule in FAMILY_RULES.items()}


SCIENTIFIC_SEMANTIC_RISKS = {
    "scientific_info_loss",
    "missing_units",
    "missing_errorbar_type",
    "missing_threshold_semantics",
    "missing_n",
    "ambiguous_color_scale",
}


def canonical_family(value: str | None) -> str:
    text = (value or "").strip().lower()
    if not text or text in {"none", "global", "generic"}:
        return "global"
    for token, family in FAMILY_ALIASES.items():
        if len(token) <= 2:
            if re.search(rf"(^|[^a-z0-9]){re.escape(token)}([^a-z0-9]|$)", text):
                return family
        elif token in text:
            return family
    for family in SPECIALIZED_FAMILIES:
        if family in text:
            return family
    return text.replace("_", "-")


def load_qa(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if "image_qa" in payload:
        return payload["image_qa"]
    return payload


def load_calibration(path: Path | None) -> dict[str, Any]:
    if path is None or not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def risk_codes(qa: dict[str, Any]) -> list[str]:
    codes = []
    for item in qa.get("top_risks", []) or []:
        code = item.get("code")
        status = item.get("status")
        if code and status != STATUS_PASS:
            codes.append(str(code))
    return codes


def severity_penalty(code: str, family: str) -> float:
    rule = FAMILY_RULES.get(family, {})
    if code in rule.get("downgrade_risks", set()):
        return 0.2
    if code in BLOCKING_RISKS:
        return 1.45
    if code in SCIENTIFIC_SEMANTIC_RISKS:
        return 1.35
    return 0.75


def merge_weights(family: str) -> dict[str, float]:
    weights = dict(DEFAULT_WEIGHTS)
    weights.update(FAMILY_WEIGHT_OVERRIDES.get(family, {}))
    return weights


def score_family(qa: dict[str, Any], family_override: str | None = None, calibration: dict[str, Any] | None = None) -> dict[str, Any]:
    family = canonical_family(family_override or qa.get("figure_family") or qa.get("threshold_profile"))
    weights = merge_weights(family)
    codes = risk_codes(qa)
    subscores = {bucket: 10.0 for bucket in DEFAULT_WEIGHTS}
    notes: list[str] = []
    blocking: list[str] = []
    rule = FAMILY_RULES.get(family, {})
    blocking_exemptions = set(rule.get("blocking_exemptions", set()))

    for code in codes:
        if (code in BLOCKING_RISKS or code in set(rule.get("blocking_risks", set()))) and code not in blocking_exemptions:
            blocking.append(code)
        bucket = RISK_TO_BUCKET.get(code)
        if bucket:
            subscores[bucket] = max(0.0, subscores[bucket] - severity_penalty(code, family) * weights.get(bucket, 1.0))

    notes.extend(rule.get("notes", []))

    if qa.get("input_type") in {"png", "jpg", "jpeg", "raster"} and not qa.get("vector_structure"):
        notes.append("Typography and stroke subscores are raster estimates, not exact point-size or stroke-width measurements.")

    manuscript_score = qa.get("manuscript_readiness_score")
    if isinstance(manuscript_score, (int, float)):
        base_from_global = float(manuscript_score)
    else:
        base_from_global = statistics.mean(subscores.values())
    weighted_score = sum(subscores[k] * weights.get(k, 1.0) for k in subscores) / sum(weights.get(k, 1.0) for k in subscores)
    family_tolerated = set(rule.get("downgrade_risks", set())) | set(rule.get("blocking_exemptions", set()))
    tolerated_only = bool(set(codes) & family_tolerated) and not blocking
    family_cap = base_from_global + (2.2 if tolerated_only else 0.8)
    score = round(max(0.0, min(10.0, min(weighted_score, family_cap))), 2)
    if blocking:
        score = min(score, 7.2)
    status = STATUS_PASS if score >= 8 and not blocking else STATUS_WARN if score >= 5 else STATUS_FAIL
    if blocking and any(code in {"text_data_overlap_risk", "vector_text_overlap", "panel_data_region_mismatch"} for code in blocking):
        status = STATUS_FAIL

    calibration = calibration or {}
    profile = (calibration.get("family_profiles") or {}).get(family)
    adjustment = (calibration.get("score_adjustments") or {}).get(family, {})
    human_notes = (calibration.get("family_notes") or {}).get(family, [])
    positive_status = "not_calibrated"
    calibrated_positive_score = score
    if profile:
        positive_status = "positive_gold_supported" if profile.get("positive_calibration_eligible") else "baseline_or_caution"
        if adjustment.get("positive_calibration_score_cap") is not None:
            calibrated_positive_score = min(score, float(adjustment["positive_calibration_score_cap"]))
        notes.extend(human_notes)

    return {
        "checked": True,
        "version": "family-qa-v1.1-human-calibrated",
        "family": family,
        "score": score,
        "status": status,
        "positive_calibration_status": positive_status,
        "calibrated_positive_score": round(calibrated_positive_score, 2),
        "human_calibration": profile or {"available": False},
        "subscores": {key: round(value, 2) for key, value in subscores.items()},
        "blocking_risks": sorted(set(blocking)),
        "family_specific_notes": notes,
        "global_manuscript_readiness_score": manuscript_score,
        "risk_codes_considered": codes,
        "rule_source": "deterministic visual QA + pattern-library family weights + optional local gold human calibration",
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    qa = payload["family_qa"]
    lines = [
        "# Family QA score",
        "",
        f"- family: `{qa['family']}`",
        f"- score: `{qa['score']}/10`",
        f"- status: `{qa['status']}`",
        f"- positive calibration status: `{qa.get('positive_calibration_status')}`",
        f"- calibrated positive score: `{qa.get('calibrated_positive_score')}/10`",
        f"- global manuscript readiness score: `{qa.get('global_manuscript_readiness_score')}`",
        f"- blocking risks: `{qa.get('blocking_risks')}`",
        "",
        "## Subscores",
        "",
        "| dimension | score |",
        "|---|---:|",
    ]
    for key, value in qa.get("subscores", {}).items():
        lines.append(f"| {key} | {value} |")
    lines += ["", "## Family-specific notes", ""]
    for note in qa.get("family_specific_notes", []):
        lines.append(f"- {note}")
    lines += ["", "## Risks considered", "", ", ".join(qa.get("risk_codes_considered", [])) or "None"]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Add family-specific QA score to a visual_qa.json file.")
    parser.add_argument("--qa-json", required=True, help="Path to visual_qa.json or a direct image_qa JSON payload.")
    parser.add_argument("--out", required=True, help="Output JSON path.")
    parser.add_argument("--out-md", default=None, help="Optional Markdown summary path.")
    parser.add_argument("--family", default=None, help="Override figure family.")
    parser.add_argument("--calibration-json", default=str(DEFAULT_CALIBRATION_PATH), help="Optional local gold human calibration rules JSON.")
    args = parser.parse_args()

    qa = load_qa(Path(args.qa_json).expanduser())
    calibration = load_calibration(Path(args.calibration_json).expanduser()) if args.calibration_json else {}
    payload = {"family_qa": score_family(qa, args.family, calibration)}
    out = Path(args.out).expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    if args.out_md:
        write_markdown(payload, Path(args.out_md).expanduser())
    print(f"family QA written: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
