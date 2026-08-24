#!/usr/bin/env python3
"""Calibrate Nature-like detail QA from the local R replica figure library.

This script treats the R replica library as positive design evidence, not as
copyable source material. It runs rendered-image QA on one representative output
per case, aggregates detail-level metrics by figure family, and separates
generalizable examples from specialized or decorative cases.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

SUPPORTED_OUTPUTS = {".png", ".jpg", ".jpeg", ".svg", ".pdf"}
RASTER_PRIORITY = {".png": 0, ".jpg": 0, ".jpeg": 0, ".svg": 1, ".pdf": 2}

FAMILY_RULES: list[tuple[str, list[str]]] = [
    ("phylogenetic tree with annotation rings", ["系统发育", "phylo", "ggtree", "tree", "外圈"]),
    ("circos / chord / synteny-like plot", ["circos", "和弦", "chord", "桑基", "sankey", "环状"]),
    ("upset / venn-like set plot", ["upset", "venn"]),
    ("Manhattan plot", ["manhattan", "曼哈顿", "genomewide"]),
    ("volcano / MA / enrichment / GSEA", ["volcano", "火山", "gsea", "enrich", "富集", "ma"]),
    ("PCA / PCoA / NMDS / UMAP / t-SNE", ["pcoa", "pca", "nmds", "umap", "tsne", "permanova"]),
    ("heatmap / correlation heatmap / matrix dotplot", ["heatmap", "热图", "correlation", "相关", "matrix", "dotplot", "气泡热图"]),
    ("scatter / regression / marginal histogram", ["scatter", "散点", "regression", "回归", "拟合", "marginal", "残差", "histogram"]),
    ("boxplot / violin / raincloud / jitter", ["raincloud", "云雨", "violin", "小提琴", "boxplot", "箱", "jitter", "蜂群"]),
    ("grouped bar / stacked bar / errorbar", ["bar", "柱", "errorbar", "误差", "stacked", "堆积", "anova"]),
    ("dotplot / lollipop / dumbbell", ["lollipop", "棒棒糖", "dumbbell", "哑铃", "点线", "line_dot"]),
    ("map / spatial plot", ["map", "地图", "spatial", "geojson", "shp"]),
    ("ridgeline / density / contour", ["ridge", "山脊", "density", "密度", "contour", "等高线", "kde"]),
    ("radar / polar / circular bar", ["radar", "雷达", "polar", "极坐标", "circular", "圆环"]),
    ("network / chord / Sankey", ["network", "网络", "enrichnetwork"]),
    ("multi-panel manuscript figure", ["combine", "组合", "multi", "panel", "分面", "facet", "复合"]),
]

SPECIALIZED = {
    "phylogenetic tree with annotation rings",
    "circos / chord / synteny-like plot",
    "map / spatial plot",
    "network / chord / Sankey",
    "upset / venn-like set plot",
    "radar / polar / circular bar",
}

GENERALIZABLE = {
    "grouped bar / stacked bar / errorbar",
    "boxplot / violin / raincloud / jitter",
    "scatter / regression / marginal histogram",
    "heatmap / correlation heatmap / matrix dotplot",
    "PCA / PCoA / NMDS / UMAP / t-SNE",
    "volcano / MA / enrichment / GSEA",
    "ridgeline / density / contour",
    "dotplot / lollipop / dumbbell",
    "Manhattan plot",
}

DECORATIVE_TERMS = ["绝美", "渐变色背景", "雷达", "极坐标", "环状", "圆环", "withAI"]


def classify_family(case_dir: Path) -> str:
    text_parts = [case_dir.name]
    for path in list(case_dir.glob("*.R"))[:6]:
        try:
            text_parts.append(path.read_text(errors="ignore")[:8000])
        except Exception:
            pass
    haystack = "\n".join(text_parts).lower()
    scores = []
    for family, keys in FAMILY_RULES:
        score = 0
        for key in keys:
            if key.lower() in haystack:
                score += 6 if key.lower() in case_dir.name.lower() else 1
        if score:
            scores.append((score, family))
    if not scores:
        return "multi-panel manuscript figure"
    scores.sort(key=lambda x: (-x[0], x[1]))
    return scores[0][1]


def case_outputs(case_dir: Path) -> list[Path]:
    outputs = [p for p in case_dir.rglob("*") if p.is_file() and p.suffix.lower() in SUPPORTED_OUTPUTS]
    return sorted(outputs, key=lambda p: (RASTER_PRIORITY.get(p.suffix.lower(), 9), len(p.parts), str(p).lower()))


def sample_class(case_name: str, family: str, status: str) -> str:
    if status == "error":
        return "not_for_threshold_learning"
    if any(term.lower() in case_name.lower() for term in DECORATIVE_TERMS):
        return "decorative_or_caution"
    if family in SPECIALIZED:
        return "specialized_positive"
    if family in GENERALIZABLE:
        return "generalizable_positive"
    return "decorative_or_caution"


def run_visual_qa(script: Path, image: Path, out_dir: Path, family: str, dpi: int) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable,
        str(script),
        str(image),
        "--out",
        str(out_dir),
        "--family",
        family,
        "--dpi",
        str(dpi),
        "--ocr",
        "auto",
        "--journal-profile",
        "nature",
        "--target-width-mm",
        "89",
        "--allow-grid",
        "auto",
    ]
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        return {"status": "error", "error": proc.stderr or proc.stdout}
    return json.loads((out_dir / "visual_qa.json").read_text())["image_qa"]


def num(value: Any) -> float | None:
    try:
        if value is None:
            return None
        return float(value)
    except Exception:
        return None


def quantiles(values: list[float]) -> dict[str, float | None]:
    if not values:
        return {"min": None, "q25": None, "median": None, "q75": None, "max": None}
    ordered = sorted(values)
    return {
        "min": round(ordered[0], 4),
        "q25": round(ordered[int((len(ordered) - 1) * 0.25)], 4),
        "median": round(statistics.median(ordered), 4),
        "q75": round(ordered[int((len(ordered) - 1) * 0.75)], 4),
        "max": round(ordered[-1], 4),
    }


def metric(rows: list[dict[str, Any]], *path: str) -> dict[str, float | None]:
    values = []
    for row in rows:
        cur: Any = row
        for key in path:
            if not isinstance(cur, dict):
                cur = None
                break
            cur = cur.get(key)
        value = num(cur)
        if value is not None:
            values.append(value)
    return quantiles(values)


def risk_codes(row: dict[str, Any]) -> list[str]:
    return [item.get("code", "") for item in row.get("top_risks", []) if item.get("status") != "pass"]


def write_outputs(samples: list[dict[str, Any]], out_md: Path, out_json: Path, style_review: Path, library: Path) -> None:
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps({"library": str(library), "sample_count": len(samples), "samples": samples}, indent=2, ensure_ascii=False) + "\n")
    by_family: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for sample in samples:
        if sample.get("status") != "error":
            by_family[sample["figure_family"]].append(sample)
    class_counts = Counter(s["sample_class"] for s in samples)
    source_counts = Counter(s.get("source_type", "unknown") for s in samples)
    lines = [
        "# Nature Detail QA Calibration",
        "",
        "Generated by `scripts/calibrate-nature-detail-qa.py` from the local R replica library. These examples calibrate detail-level review rules; they are not copied or indexed as reusable code.",
        "",
        "## Scope",
        "",
        f"- Library: `{library}`",
        f"- Cases with representative outputs analyzed: {len(samples)}",
        f"- Sample classes: {', '.join(f'{k}={v}' for k, v in sorted(class_counts.items()))}",
        f"- Source types: {', '.join(f'{k}={v}' for k, v in sorted(source_counts.items()))}",
        "",
        "## Family Detail Ranges",
        "",
        "| family | n | class mix | readiness | text burden | edge text | line burden | grid lines | legend edge | panel content ratio | colors | main caution |",
        "|---|---:|---|---|---|---|---|---|---|---|---|---|",
    ]
    for family, rows in sorted(by_family.items()):
        mix = Counter(r["sample_class"] for r in rows)
        common_risks = Counter(code for r in rows for code in risk_codes(r)).most_common(3)
        caution = ", ".join(code for code, _ in common_risks) or "-"
        lines.append(
            f"| {family} | {len(rows)} | {', '.join(f'{k}={v}' for k, v in sorted(mix.items()))} | "
            f"{metric(rows, 'manuscript_readiness_score')} | {metric(rows, 'text_burden_score')} | "
            f"{metric(rows, 'text_geometry', 'edge_text_like_fraction')} | {metric(rows, 'line_burden', 'line_burden_score')} | "
            f"{metric(rows, 'grid_background', 'long_line_count')} | {metric(rows, 'legend_geometry', 'edge_content_fraction')} | "
            f"{metric(rows, 'panel_detail_geometry', 'content_area_ratio_max_min')} | {metric(rows, 'color_count_estimate')} | {caution} |"
        )
    lines += [
        "",
        "## Calibration Guidance",
        "",
        "- Use `generalizable_positive` examples to tune default statistical-figure detail thresholds.",
        "- Use `specialized_positive` examples only for family-specific interpretation; circular, tree, map, network, and set figures legitimately have unusual line and label structure.",
        "- Use `decorative_or_caution` examples to define boundaries: strong gradients, polar decorations, presentation titles, and heavy grid/cell structure should not become default manuscript style.",
        "- Text/data overlap, target-size font failure, severe panel mismatch, and unneeded grid backgrounds are detail-level review triggers even when the global manuscript score is acceptable.",
        "",
        "## Sample-Level Results",
        "",
        "| case | family | class | source | status | score | top risks | image |",
        "|---|---|---|---|---|---:|---|---|",
    ]
    for sample in samples:
        risks = ", ".join(risk_codes(sample)[:5]) or "-"
        lines.append(f"| {sample['case_dir']} | {sample['figure_family']} | {sample['sample_class']} | {sample.get('source_type')} | {sample.get('status')} | {sample.get('manuscript_readiness_score', '-')} | {risks} | `{sample.get('image')}` |")
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")

    review_lines = [
        "# Nature Style Commonality Review",
        "",
        "This report summarizes reusable visual-detail principles learned from the R replica library. It abstracts shared design behavior and excludes source-code copying.",
        "",
        "## Common High-Level Traits",
        "",
        "- Manuscript-style examples keep titles small or absent; panel labels and captions carry the narrative.",
        "- Axes and intervals are thin enough to remain secondary to data marks.",
        "- Raw points, uncertainty intervals, or matrix cells carry the evidence; annotations remain compact.",
        "- Legends are restrained, merged, moved outside repeated panels, or replaced by direct labels only when label burden stays low.",
        "- Equal-role panels use comparable data-region sizes; unequal panels need an explicit evidence hierarchy.",
        "",
        "## Detail Rules To Enforce",
        "",
        "- Flag text/data overlap before judging color or aesthetics.",
        "- Treat dense tick labels as a layout failure unless labels are the primary data.",
        "- Treat default gray ggplot grids as suspect in group, violin, bar, and small-multiple figures.",
        "- Allow grid/cell boundaries in heatmaps and tree/circular structures only through family-specific profiles.",
        "- Compare old and new figures on detail regressions: panel size, data-region balance, grid burden, legend dominance, target-size typography, and scientific information preservation.",
        "",
        "## What Remains Human-Reviewed",
        "",
        "- Whether a label is scientifically necessary or should move to a sidecar.",
        "- Whether a specialized circular/tree/network layout is justified by the data structure.",
        "- Whether a cleaner redraw preserved the main scientific argument.",
    ]
    style_review.write_text("\n".join(review_lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Calibrate Nature-like detail QA from the R replica library.")
    parser.add_argument("--library", required=True, help="R replica library root")
    parser.add_argument("--out", default="paperplotr/paperplot-skills/reports/nature-detail-qa-calibration.md")
    parser.add_argument("--out-json", default="paperplotr/paperplot-skills/reports/nature-detail-qa-calibration.json")
    parser.add_argument("--style-review", default="paperplotr/paperplot-skills/reports/nature-style-commonality-review.md")
    parser.add_argument("--qa-root", default="/tmp/paperplot-nature-detail-calibration")
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--limit", type=int, default=0, help="Optional case limit for quick debugging")
    args = parser.parse_args()

    library = Path(args.library).expanduser()
    if not library.exists():
        raise SystemExit(f"Library not found: {library}")
    script = Path(__file__).with_name("visual-qa-rendered-image.py")
    cases = sorted([p for p in library.iterdir() if p.is_dir()], key=lambda p: p.name.lower())
    if args.limit > 0:
        cases = cases[:args.limit]
    samples: list[dict[str, Any]] = []
    qa_root = Path(args.qa_root)
    qa_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="paperplot-nature-detail-") as tmp:
        tmp_root = Path(tmp)
        for i, case in enumerate(cases, start=1):
            outputs = case_outputs(case)
            if not outputs:
                continue
            image = outputs[0]
            family = classify_family(case)
            qa = run_visual_qa(script, image, tmp_root / f"case_{i:03d}", family, args.dpi)
            sample = dict(qa)
            sample["case_dir"] = case.name
            sample["figure_family"] = family
            sample["image"] = str(image)
            sample["source_type"] = image.suffix.lower().lstrip(".")
            sample["sample_class"] = sample_class(case.name, family, sample.get("status", "error"))
            samples.append(sample)
    write_outputs(samples, Path(args.out), Path(args.out_json), Path(args.style_review), library)
    print(f"calibrated {len(samples)} R replica cases")
    print(f"wrote {args.out}")
    print(f"wrote {args.out_json}")
    print(f"wrote {args.style_review}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
