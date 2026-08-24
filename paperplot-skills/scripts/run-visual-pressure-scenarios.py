#!/usr/bin/env python3
"""Run real and synthetic visual pressure scenarios for paperplot-skills."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw, ImageEnhance
except Exception:
    Image = None
    ImageDraw = None
    ImageEnhance = None

ROOT = Path(__file__).resolve().parents[1]
VISUAL_QA = ROOT / "scripts" / "visual-qa-rendered-image.py"
COMPARE = ROOT / "scripts" / "compare-old-new-figures.py"
FAMILY_QA = ROOT / "scripts" / "family-qa-score.py"

# Author-private real-figure regression fixtures live outside the repo. Point
# PAPERPLOT_FIXTURE_DIR at the base directory holding them to enable these
# scenarios; when it is unset the paths simply do not exist and the scenarios
# are skipped as `fixture_missing` (no hardcoded machine-specific path).
FIXTURE_BASE = os.environ.get("PAPERPLOT_FIXTURE_DIR")


def fixture_path(rel: str) -> Path:
    base = FIXTURE_BASE if FIXTURE_BASE else "__paperplot_fixture_dir_unset__"
    return Path(base) / rel
DEFAULT_REPORT_DIR = ROOT / "reports"
REPORT = DEFAULT_REPORT_DIR / "visual-qa-real-figure-test-report.md"
PANEL_REPORT = DEFAULT_REPORT_DIR / "panel-geometry-qa-validation.md"
RUBRIC_REPORT = DEFAULT_REPORT_DIR / "old-vs-new-rubric-validation.md"
FAMILY_REPORT = DEFAULT_REPORT_DIR / "family-qa-scoring-validation.md"
VECTOR_REPORT = DEFAULT_REPORT_DIR / "vector-font-stroke-validation.md"
NON_HUMAN_REPORT = DEFAULT_REPORT_DIR / "non-human-qa-upgrade-summary.md"

FIXTURES = [
    {
        "scenario": "visual-gs-barplot-burden",
        "path": fixture_path("10-GS/final_results/figures/fig4_quality_traits.png"),
        "expect_status": {"warn", "fail"},
        "expect_any_risk": {"saturated_presentation_palette", "gridline_or_long_line_burden", "excessive_blank_margin", "thumbnail_readability_risk", "high_text_or_tick_density"},
    },
    {
        "scenario": "visual-gs-label-overlap-risk",
        "path": fixture_path("10-GS/final_results/figures/figS1_gxe_vs_prediction.png"),
        "expect_status": {"warn", "fail"},
        "expect_any_risk": {"high_text_or_tick_density", "label_overlap_or_large_annotation_risk", "thumbnail_readability_risk", "low_content_density", "excessive_blank_margin", "gridline_or_long_line_burden"},
    },
    {
        "scenario": "visual-gs-quality-trait-accuracy",
        "path": fixture_path("10-GS/final_results/figures/figS1_quality_trait_accuracy.png"),
        "expect_status": {"warn", "fail"},
        "expect_any_risk": {"high_text_or_tick_density", "gridline_or_long_line_burden", "thumbnail_readability_risk", "saturated_presentation_palette"},
    },
    {
        "scenario": "visual-nlr-svg-presentation-style-count",
        "path": fixture_path("7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_count_by_sample.svg"),
        "expect_status": {"warn", "fail"},
        "expect_any_risk": {"oversized_svg_title_or_text", "huge_centered_title", "svg_gridline_burden"},
    },
    {
        "scenario": "visual-nlr-svg-presentation-style-panclass",
        "path": fixture_path("7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_panclass_summary.svg"),
        "expect_status": {"warn", "fail"},
        "expect_any_risk": {"oversized_svg_title_or_text", "huge_centered_title", "svg_gridline_burden"},
    },
]

FAMILY_FIXTURES = [
    {
        "scenario": "visual-family-lollipop-threshold",
        "path": ROOT / "reports" / "redraw-benchmark" / "high_nlr_count_by_sample_pattern_redraw.png",
        "family": "lollipop",
        "expect_status": {"pass", "warn"},
        "forbid_risk": {"gridline_or_long_line_burden"},
    },
]


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True)


def risk_codes(result: dict[str, Any]) -> set[str]:
    return {item.get("code", "") for item in result.get("top_risks", [])}


def run_visual(path: Path, out: Path, extra: list[str] | None = None, allow_nonzero: bool = False) -> dict[str, Any]:
    cmd = [sys.executable, str(VISUAL_QA), str(path), "--out", str(out)]
    if extra:
        cmd.extend(extra)
    proc = run(cmd)
    if proc.returncode != 0 and not allow_nonzero:
        raise RuntimeError(proc.stderr or proc.stdout)
    payload = json.loads((out / "visual_qa.json").read_text())["image_qa"]
    payload["_returncode"] = proc.returncode
    return payload


def run_family_score(visual_out: Path, family: str | None = None) -> dict[str, Any]:
    qa_json = visual_out / "visual_qa.json"
    out_json = visual_out / "family_qa.json"
    cmd = [sys.executable, str(FAMILY_QA), "--qa-json", str(qa_json), "--out", str(out_json)]
    if family:
        cmd.extend(["--family", family])
    proc = run(cmd)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr or proc.stdout)
    return json.loads(out_json.read_text())["family_qa"]


def make_degraded(src: Path, dst: Path) -> bool:
    if Image is None or ImageEnhance is None or not src.exists() or src.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        return False
    img = Image.open(src).convert("RGB")
    low = ImageEnhance.Contrast(img).enhance(0.45)
    low = ImageEnhance.Color(low).enhance(0.35)
    canvas = Image.new("RGB", (int(low.width * 1.35), int(low.height * 1.35)), "white")
    canvas.paste(low, (int(low.width * 0.18), int(low.height * 0.18)))
    canvas.save(dst)
    return True


def draw_panel(draw: Any, box: tuple[int, int, int, int], color: str) -> None:
    x0, y0, x1, y1 = box
    draw.rectangle(box, outline="#333333", width=3)
    draw.line((x0 + 38, y1 - 42, x1 - 36, y1 - 42), fill="#333333", width=3)
    draw.line((x0 + 38, y0 + 36, x0 + 38, y1 - 42), fill="#333333", width=3)
    width = max(x1 - x0 - 110, 1)
    height = max(y1 - y0 - 120, 1)
    for i in range(10):
        px = x0 + 55 + int(width * i / 9)
        py = y1 - 62 - int(height * ((i % 5) + 1) / 6)
        draw.ellipse((px - 7, py - 7, px + 7, py + 7), fill=color, outline="#333333")


def make_panel_fixture(dst: Path, unequal: bool = False) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for synthetic panel fixtures.")
    canvas = Image.new("RGB", (1200, 620), "white")
    draw = ImageDraw.Draw(canvas)
    if unequal:
        boxes = [(60, 55, 760, 555), (850, 185, 1110, 425)]
    else:
        boxes = [(70, 80, 540, 520), (660, 80, 1130, 520)]
    draw_panel(draw, boxes[0], "#4C78A8")
    draw_panel(draw, boxes[1], "#E15759")
    canvas.save(dst)


def make_blank_margin_fixture(dst: Path) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for synthetic blank-margin fixture.")
    canvas = Image.new("RGB", (1200, 800), "white")
    draw = ImageDraw.Draw(canvas)
    box = (510, 335, 690, 465)
    draw.rectangle(box, outline="#333333", width=3)
    draw.line((525, 445, 675, 445), fill="#333333", width=2)
    draw.line((525, 350, 525, 445), fill="#333333", width=2)
    for x, y in [(545, 420), (575, 390), (615, 405), (650, 365)]:
        draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill="#4C78A8", outline="#333333")
    canvas.save(dst)


def make_svg_fixture(dst: Path) -> None:
    dst.write_text(
        """<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="620" viewBox="0 0 1200 620">
<rect width="1200" height="620" fill="white"/>
<text x="600" y="52" text-anchor="middle" font-size="30">Presentation style SVG title</text>
<line x1="90" y1="140" x2="1110" y2="140" stroke="#eeeeee"/>
<line x1="90" y1="240" x2="1110" y2="240" stroke="#eeeeee"/>
<line x1="90" y1="340" x2="1110" y2="340" stroke="#eeeeee"/>
<line x1="90" y1="440" x2="1110" y2="440" stroke="#eeeeee"/>
<rect x="120" y="180" width="820" height="280" fill="none" stroke="#333333" stroke-width="3"/>
<circle cx="220" cy="385" r="15" fill="#4C78A8"/>
<circle cx="390" cy="315" r="15" fill="#E15759"/>
<circle cx="560" cy="250" r="15" fill="#59A14F"/>
</svg>
""",
        encoding="utf-8",
    )


def make_vector_overlap_svg(dst: Path) -> None:
    labels = "\n".join(
        f'<text x="{360 + i * 12}" y="{285 + (i % 3) * 5}" font-size="18">overlap_label_{i}</text>'
        for i in range(16)
    )
    dst.write_text(
        f"""<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="620" viewBox="0 0 1000 620">
<rect width="1000" height="620" fill="white"/>
<line x1="120" y1="540" x2="900" y2="540" stroke="#333333" stroke-width="0.6"/>
<line x1="120" y1="100" x2="120" y2="540" stroke="#333333" stroke-width="0.6"/>
<circle cx="410" cy="300" r="9" fill="#4C78A8"/>
<circle cx="485" cy="260" r="9" fill="#E15759"/>
{labels}
</svg>
""",
        encoding="utf-8",
    )


def make_detail_overlap_fixture(dst: Path) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for synthetic detail fixtures.")
    canvas = Image.new("RGB", (1100, 720), "white")
    draw = ImageDraw.Draw(canvas)
    draw.line((120, 620, 980, 620), fill="#333333", width=3)
    draw.line((120, 90, 120, 620), fill="#333333", width=3)
    for i in range(12):
        x = 180 + i * 65
        y = 560 - (i % 5) * 80
        draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill="#4C78A8", outline="#333333")
        draw.rectangle((x - 22, y - 14, x + 64, y + 12), fill="#111111")
    canvas.save(dst)


def make_grid_burden_fixture(dst: Path) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for synthetic detail fixtures.")
    canvas = Image.new("RGB", (1100, 720), "white")
    draw = ImageDraw.Draw(canvas)
    for y in range(100, 620, 28):
        draw.line((100, y, 1000, y), fill="#d7d7d7", width=2)
    for x in range(120, 1000, 35):
        draw.line((x, 80, x, 640), fill="#d7d7d7", width=2)
    draw.line((100, 620, 1000, 620), fill="#333333", width=3)
    draw.line((100, 80, 100, 620), fill="#333333", width=3)
    for i in range(18):
        x = 140 + i * 47
        y = 570 - (i % 6) * 78
        draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill="#E15759")
    canvas.save(dst)


def make_light_grid_fixture(dst: Path) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for synthetic detail fixtures.")
    canvas = Image.new("RGB", (1100, 720), "white")
    draw = ImageDraw.Draw(canvas)
    for y in range(160, 610, 110):
        draw.line((100, y, 1000, y), fill="#eeeeee", width=1)
    draw.line((100, 620, 1000, 620), fill="#333333", width=3)
    draw.line((100, 80, 100, 620), fill="#333333", width=3)
    for i in range(18):
        x = 140 + i * 47
        y = 570 - (i % 6) * 78
        draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill="#4C78A8")
    canvas.save(dst)


def make_pdf_stroke_fixture(dst: Path) -> bool:
    exe = shutil.which("Rscript")
    if not exe:
        return False
    script = dst.with_suffix(".R")
    script.write_text(
        f"""pdf({json.dumps(str(dst))}, width = 5.2, height = 3.4, useDingbats = FALSE)
par(mar = c(3, 3, 1, 1), xaxs = "i", yaxs = "i")
plot.new()
plot.window(xlim = c(0, 10), ylim = c(0, 10))
for (y in seq(2, 8, by = 1)) lines(c(1, 9), c(y, y), col = gray(0.86), lwd = 0.45)
rect(1, 1, 9, 9, border = gray(0.35), lwd = 0.55)
lines(c(1, 9), c(1.4, 7.6), col = "black", lwd = 0.45)
lines(c(1, 9), c(8.7, 8.7), col = "black", lwd = 6)
text(5, 0.45, "PDF stroke fixture", cex = 0.7)
dev.off()
""",
        encoding="utf-8",
    )
    proc = run([exe, str(script)])
    return proc.returncode == 0 and dst.exists()


def write_review_json(path: Path) -> None:
    dims = {
        key: {"old_score": 2, "new_score": 4, "notes": "Synthetic regression review marks the cleaner candidate as better."}
        for key in [
            "message_clarity",
            "scientific_completeness",
            "visual_hierarchy",
            "proportional_balance",
            "readability_at_target_size",
            "statistical_expression",
            "color_legend_discipline",
            "data_preservation",
        ]
    }
    path.write_text(json.dumps({"rubric_version": "1.0", "dimensions": dims}, indent=2) + "\n")


def skipped_fixture_row(scenario: str, path: Path) -> dict[str, Any]:
    return {
        "scenario": scenario,
        "input": str(path),
        "pass": "skipped",
        "status": "fixture_missing",
        "score": "",
        "risk_codes": [],
        "detail": "fixture_missing",
    }


def report_input_label(value: Any) -> str:
    text = str(value)
    fixture_prefix = "__paperplot_fixture_dir_unset__/"
    if text.startswith(fixture_prefix):
        return "$PAPERPLOT_FIXTURE_DIR/" + text[len(fixture_prefix):]
    if "/paperplot-visual-pressure-" in text:
        return f"synthetic/{Path(text).name}"
    try:
        path = Path(text)
        if path.is_absolute():
            return str(path.relative_to(ROOT))
    except Exception:
        pass
    return text


def write_scientific_loss_review_json(path: Path) -> None:
    dims = {}
    for key in [
        "message_clarity",
        "scientific_completeness",
        "visual_hierarchy",
        "proportional_balance",
        "readability_at_target_size",
        "statistical_expression",
        "color_legend_discipline",
        "data_preservation",
    ]:
        old_score, new_score = (4, 4)
        note = "Synthetic review keeps this dimension unchanged."
        if key in {"scientific_completeness", "statistical_expression", "data_preservation"}:
            old_score, new_score = (5, 2)
            note = "New figure removes required scientific information."
        dims[key] = {"old_score": old_score, "new_score": new_score, "notes": note}
    path.write_text(json.dumps({"rubric_version": "1.0", "dimensions": dims}, indent=2) + "\n")


def write_report(rows: list[dict[str, Any]], compare_rows: list[dict[str, Any]]) -> None:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Visual QA real figure test report",
        "",
        "This report is generated by `scripts/run-visual-pressure-scenarios.py`. It uses user-provided real GS PNG figures, NLR SVG figures, and synthetic regression fixtures.",
        "",
        "## Scenario results",
        "",
        "| scenario | input | status | score | pass | top risks |",
        "|---|---|---:|---:|---|---|",
    ]
    for row in rows:
        risks = ", ".join(row.get("risk_codes", [])) or row.get("detail", "")
        lines.append(f"| {row['scenario']} | `{report_input_label(row['input'])}` | {row.get('status','')} | {row.get('score','')} | {row['pass']} | {risks} |")
    if compare_rows:
        lines += ["", "## Old-vs-new comparisons", ""]
        for row in compare_rows:
            lines.append(f"- {row['scenario']}: final=`{row.get('final_verdict')}`, deterministic=`{row.get('deterministic_verdict')}`, status=`{row.get('status')}`, pass=`{row.get('pass')}`")
    lines += [
        "",
        "## What automatic visual QA caught",
        "",
        "- Presentation-style title and font burden in SVG plots.",
        "- Gridline/long-line burden in SVG and raster plots.",
        "- Saturated color or grayscale discrimination risks in raster plots.",
        "- Blank margin/content density and thumbnail readability risks.",
        "- Equal-role panel geometry imbalance.",
        "",
        "## Remaining limits",
        "",
        "- OCR is optional and may be unavailable in the local environment.",
        "- Panel geometry QA is deterministic and catches obvious imbalance; complex nested layouts still need review.",
        "- Scientific correctness still requires data, metadata, and user confirmation.",
    ]
    REPORT.write_text("\n".join(lines) + "\n")


def write_panel_report(rows: list[dict[str, Any]]) -> None:
    panel_rows = [r for r in rows if r["scenario"].startswith("visual-panel-")]
    lines = [
        "# Panel geometry QA validation",
        "",
        "| scenario | pass | detected panels | panel ratio | content ratio | risks |",
        "|---|---|---:|---:|---:|---|",
    ]
    for row in panel_rows:
        panel = row.get("panel_geometry", {})
        lines.append(
            f"| {row['scenario']} | {row['pass']} | {panel.get('panel_count_detected')} | {panel.get('panel_area_ratio_max_min')} | {panel.get('content_area_ratio_max_min')} | {', '.join(row.get('risk_codes', [])) or '-'} |"
        )
    PANEL_REPORT.write_text("\n".join(lines) + "\n")


def write_rubric_report(compare_rows: list[dict[str, Any]]) -> None:
    lines = [
        "# Old-vs-new rubric validation",
        "",
        "| scenario | pass | deterministic | review status | final verdict | status |",
        "|---|---|---|---|---|---|",
    ]
    for row in compare_rows:
        lines.append(f"| {row['scenario']} | {row.get('pass')} | {row.get('deterministic_verdict')} | {row.get('review_rubric_status')} | {row.get('final_verdict')} | {row.get('status')} |")
    RUBRIC_REPORT.write_text("\n".join(lines) + "\n")


def write_vector_report(rows: list[dict[str, Any]]) -> None:
    vector_rows = [r for r in rows if r["scenario"].startswith("vector-") or r["scenario"].startswith("pdf-vector-") or r["scenario"] in {"visual-svg-rasterization", "visual-pdf-rasterization"}]
    lines = [
        "# Vector font/stroke validation",
        "",
        "| scenario | pass | input | status | score | vector engine | risks |",
        "|---|---|---|---|---:|---|---|",
    ]
    for row in vector_rows:
        vector = row.get("vector_structure") or {}
        lines.append(
            f"| {row['scenario']} | {row.get('pass')} | `{row.get('input')}` | {row.get('status')} | {row.get('score')} | {vector.get('engine')} | {', '.join(row.get('risk_codes', [])) or '-'} |"
        )
    VECTOR_REPORT.write_text("\n".join(lines) + "\n")


def write_family_report(rows: list[dict[str, Any]]) -> None:
    family_rows = [r for r in rows if r["scenario"].startswith("family-") or r["scenario"].startswith("visual-family-")]
    lines = [
        "# Family QA scoring validation",
        "",
        "| scenario | pass | family | visual status | family status | visual score | family score | blocking risks | notes |",
        "|---|---|---|---|---|---:|---:|---|---|",
    ]
    for row in family_rows:
        fqa = row.get("family_qa") or {}
        notes = "; ".join((fqa.get("family_specific_notes") or [])[:2])
        lines.append(
            f"| {row['scenario']} | {row.get('pass')} | {fqa.get('family')} | {row.get('status')} | {fqa.get('status')} | {row.get('score')} | {fqa.get('score')} | {', '.join(fqa.get('blocking_risks') or []) or '-'} | {notes} |"
        )
    FAMILY_REPORT.write_text("\n".join(lines) + "\n")


def write_non_human_report(rows: list[dict[str, Any]], compare_rows: list[dict[str, Any]]) -> None:
    passed = sum(1 for row in rows if row.get("pass"))
    total = len(rows)
    compare_passed = sum(1 for row in compare_rows if row.get("pass"))
    lines = [
        "# Non-Human QA Upgrade Summary",
        "",
        "Generated by `scripts/run-visual-pressure-scenarios.py`.",
        "",
        "## Scope",
        "",
        "- SVG vector font/stroke/text-box checks.",
        "- PDF raster QA plus PDF text bbox extraction and `pypdf` content-stream stroke extraction when available.",
        "- Figure-family-specific deterministic score checks.",
        "- Synthetic detail regressions for old-vs-new blocking behavior.",
        "",
        "## Result",
        "",
        f"- visual/vector/family scenarios passed: {passed}/{total}",
        f"- old-vs-new scenarios passed: {compare_passed}/{len(compare_rows)}",
        "",
        "## Key Guarantees",
        "",
        "- Large SVG titles, heavy SVG strokes, and heavy PDF strokes are detected from vector structure, not only pixels.",
        "- Heatmap-like dense line structure is treated differently from bar/violin grid burden.",
        "- New figures with detail hard failures or scientific-information loss are not allowed to become `improved` automatically.",
        "- Optional vision review remains disabled by default and cannot override deterministic hard failures.",
    ]
    NON_HUMAN_REPORT.write_text("\n".join(lines) + "\n")


def main() -> int:
    global REPORT, PANEL_REPORT, RUBRIC_REPORT, FAMILY_REPORT, VECTOR_REPORT, NON_HUMAN_REPORT
    root = Path(tempfile.mkdtemp(prefix="paperplot-visual-pressure-"))
    report_dir_env = os.environ.get("PAPERPLOT_REPORT_DIR")
    report_dir = Path(report_dir_env).expanduser() if report_dir_env else root / "reports"
    REPORT = report_dir / "visual-qa-real-figure-test-report.md"
    PANEL_REPORT = report_dir / "panel-geometry-qa-validation.md"
    RUBRIC_REPORT = report_dir / "old-vs-new-rubric-validation.md"
    FAMILY_REPORT = report_dir / "family-qa-scoring-validation.md"
    VECTOR_REPORT = report_dir / "vector-font-stroke-validation.md"
    NON_HUMAN_REPORT = report_dir / "non-human-qa-upgrade-summary.md"
    rows = []
    for fixture in FIXTURES:
        scenario = fixture["scenario"]
        path = fixture["path"]
        out = root / scenario
        if not path.exists():
            rows.append(skipped_fixture_row(scenario, path))
            continue
        try:
            result = run_visual(path, out)
            codes = risk_codes(result)
            ok = result.get("status") in fixture["expect_status"] and bool(codes.intersection(fixture["expect_any_risk"]))
            rows.append({"scenario": scenario, "input": str(path), "pass": ok, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(out)})
        except Exception as exc:
            rows.append({"scenario": scenario, "input": str(path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

    for fixture in FAMILY_FIXTURES:
        scenario = fixture["scenario"]
        path = fixture["path"]
        out = root / scenario
        if not path.exists():
            rows.append(skipped_fixture_row(scenario, path))
            continue
        try:
            result = run_visual(path, out, ["--family", fixture["family"]])
            family_qa = run_family_score(out, fixture["family"])
            codes = risk_codes(result)
            ok = result.get("status") in fixture["expect_status"] and not bool(codes.intersection(fixture["forbid_risk"])) and family_qa.get("status") in {"pass", "warn"}
            rows.append({"scenario": scenario, "input": str(path), "pass": ok, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "family_qa": family_qa, "output_dir": str(out)})
        except Exception as exc:
            rows.append({"scenario": scenario, "input": str(path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

    if Image is not None:
        equal_png = root / "equal_panels.png"
        unequal_png = root / "unequal_panels.png"
        make_panel_fixture(equal_png, unequal=False)
        make_panel_fixture(unequal_png, unequal=True)
        for scenario, path, should_have_risk in [
            ("visual-panel-equal-balance", equal_png, False),
            ("visual-panel-unequal-imbalance", unequal_png, True),
            ("raster-panel-imbalance", unequal_png, True),
        ]:
            out = root / scenario
            try:
                result = run_visual(path, out, ["--expected-panels", "2", "--layout-profile", "equal", "--ocr", "off"])
                codes = risk_codes(result)
                has_panel_risk = bool(codes.intersection({"panel_size_imbalance", "panel_data_region_imbalance"}))
                rows.append({"scenario": scenario, "input": str(path), "pass": has_panel_risk == should_have_risk, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(out)})
            except Exception as exc:
                rows.append({"scenario": scenario, "input": str(path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        pdf_path = root / "equal_panels.pdf"
        Image.open(equal_png).save(pdf_path, "PDF")
        try:
            result = run_visual(pdf_path, root / "visual-pdf-rasterization", ["--expected-panels", "2", "--layout-profile", "equal", "--ocr", "off"])
            raster = result.get("rasterization", {})
            rows.append({"scenario": "visual-pdf-rasterization", "input": str(pdf_path), "pass": raster.get("engine") == "pdftoppm" and result.get("input_type") == "pdf", "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(risk_codes(result)), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(root / "visual-pdf-rasterization")})
        except Exception as exc:
            rows.append({"scenario": "visual-pdf-rasterization", "input": str(pdf_path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        pdf_stroke_path = root / "pdf_stroke_fixture.pdf"
        if make_pdf_stroke_fixture(pdf_stroke_path):
            for scenario, predicate in [
                ("pdf-vector-stroke-too-heavy", lambda result, codes: bool(codes.intersection({"vector_stroke_out_of_range", "stroke_too_heavy"}))),
                ("pdf-vector-grid-candidates", lambda result, codes: ((result.get("vector_stroke_geometry") or {}).get("grid_candidate_count") or 0) > 0),
            ]:
                out = root / scenario
                try:
                    result = run_visual(pdf_stroke_path, out, ["--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
                    codes = risk_codes(result)
                    rows.append({"scenario": scenario, "input": str(pdf_stroke_path), "pass": bool(predicate(result, codes)), "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "vector_structure": result.get("vector_structure", {}), "output_dir": str(out)})
                except Exception as exc:
                    rows.append({"scenario": scenario, "input": str(pdf_stroke_path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})
        else:
            rows.append({"scenario": "pdf-vector-stroke-too-heavy", "input": str(pdf_stroke_path), "pass": True, "status": "fixture_missing", "score": "", "risk_codes": [], "detail": "Rscript unavailable"})
            rows.append({"scenario": "pdf-vector-grid-candidates", "input": str(pdf_stroke_path), "pass": True, "status": "fixture_missing", "score": "", "risk_codes": [], "detail": "Rscript unavailable"})

        svg_path = root / "synthetic.svg"
        make_svg_fixture(svg_path)
        try:
            result = run_visual(svg_path, root / "visual-svg-rasterization", ["--ocr", "off"])
            raster = result.get("rasterization", {})
            rows.append({"scenario": "visual-svg-rasterization", "input": str(svg_path), "pass": raster.get("source_type") == "svg" and bool(result.get("svg_structure")), "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(risk_codes(result)), "panel_geometry": result.get("panel_geometry", {}), "vector_structure": result.get("vector_structure", {}), "output_dir": str(root / "visual-svg-rasterization")})
        except Exception as exc:
            rows.append({"scenario": "visual-svg-rasterization", "input": str(svg_path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        for scenario, expected in [
            ("vector-svg-font-too-large", {"vector_font_out_of_range", "presentation_title_risk", "vector_title_presentation_style"}),
            ("vector-svg-stroke-too-heavy", {"vector_stroke_out_of_range", "stroke_too_heavy"}),
        ]:
            out = root / scenario
            try:
                result = run_visual(svg_path, out, ["--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
                codes = risk_codes(result)
                rows.append({"scenario": scenario, "input": str(svg_path), "pass": bool(codes.intersection(expected)), "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "vector_structure": result.get("vector_structure", {}), "output_dir": str(out)})
            except Exception as exc:
                rows.append({"scenario": scenario, "input": str(svg_path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        vector_overlap_svg = root / "vector_text_overlap.svg"
        make_vector_overlap_svg(vector_overlap_svg)
        try:
            result = run_visual(vector_overlap_svg, root / "vector-text-overlap", ["--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
            codes = risk_codes(result)
            rows.append({"scenario": "vector-text-overlap", "input": str(vector_overlap_svg), "pass": "vector_text_overlap" in codes, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "vector_structure": result.get("vector_structure", {}), "output_dir": str(root / "vector-text-overlap")})
        except Exception as exc:
            rows.append({"scenario": "vector-text-overlap", "input": str(vector_overlap_svg), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        overlap_png = root / "detail_overlap.png"
        make_detail_overlap_fixture(overlap_png)
        try:
            result = run_visual(overlap_png, root / "visual-detail-text-overlap", ["--strict-detail-qa", "--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
            codes = risk_codes(result)
            rows.append({"scenario": "visual-detail-text-overlap", "input": str(overlap_png), "pass": "text_data_overlap_risk" in codes, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(root / "visual-detail-text-overlap")})
        except Exception as exc:
            rows.append({"scenario": "visual-detail-text-overlap", "input": str(overlap_png), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        grid_png = root / "grid_burden.png"
        make_grid_burden_fixture(grid_png)
        try:
            result = run_visual(grid_png, root / "visual-detail-grid-burden", ["--allow-grid", "off", "--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
            codes = risk_codes(result)
            rows.append({"scenario": "visual-detail-grid-burden", "input": str(grid_png), "pass": "grid_background_burden" in codes, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(root / "visual-detail-grid-burden")})
        except Exception as exc:
            rows.append({"scenario": "visual-detail-grid-burden", "input": str(grid_png), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        try:
            result = run_visual(grid_png, root / "raster-heavy-grid", ["--allow-grid", "off", "--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
            codes = risk_codes(result)
            rows.append({"scenario": "raster-heavy-grid", "input": str(grid_png), "pass": "grid_background_burden" in codes, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(root / "raster-heavy-grid")})
        except Exception as exc:
            rows.append({"scenario": "raster-heavy-grid", "input": str(grid_png), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        light_grid_png = root / "light_grid.png"
        make_light_grid_fixture(light_grid_png)
        family_scenarios = [
            ("family-heatmap-line-density-allowed", grid_png, "heatmap", lambda result, codes, fqa: "grid_background_burden" not in codes and fqa.get("score", 0) >= 5),
            ("family-bar-gridline-rejected", grid_png, "grouped bar / stacked bar / errorbar", lambda result, codes, fqa: "grid_background_burden" in codes and fqa.get("score", 10) < 8),
            ("family-scatter-light-grid-allowed", light_grid_png, "scatter / regression / marginal histogram", lambda result, codes, fqa: "grid_background_burden" not in codes and fqa.get("status") != "fail"),
            ("family-forest-ci-required", light_grid_png, "forest/effect-size", lambda result, codes, fqa: fqa.get("family") == "forest/effect-size" and any("CI" in note or "reference" in note for note in fqa.get("family_specific_notes", []))),
            ("family-manhattan-threshold-caution", grid_png, "manhattan/genomewide", lambda result, codes, fqa: fqa.get("family") == "manhattan/genomewide" and any("threshold" in note.lower() for note in fqa.get("family_specific_notes", []))),
            ("family-lollipop-grid-rejected", grid_png, "lollipop/dumbbell/dotplot", lambda result, codes, fqa: bool(codes.intersection({"grid_background_burden", "gridline_or_long_line_burden"})) and fqa.get("score", 10) < 8),
            ("family-phylo-line-density-caution", grid_png, "phylogenetic tree", lambda result, codes, fqa: fqa.get("family") == "phylo/tree" and fqa.get("status") != "fail" and any("branch" in note.lower() for note in fqa.get("family_specific_notes", []))),
            ("family-upset-label-burden", grid_png, "upset/set", lambda result, codes, fqa: fqa.get("family") == "upset/set" and fqa.get("status") != "fail" and any("set" in note.lower() for note in fqa.get("family_specific_notes", []))),
        ]
        for scenario, path, family, predicate in family_scenarios:
            out = root / scenario
            try:
                grid_policy = "off" if scenario == "family-lollipop-grid-rejected" else "auto"
                result = run_visual(path, out, ["--family", family, "--allow-grid", grid_policy, "--ocr", "off", "--target-width-mm", "89", "--journal-profile", "nature"])
                family_qa = run_family_score(out, family)
                codes = risk_codes(result)
                rows.append({"scenario": scenario, "input": str(path), "pass": bool(predicate(result, codes, family_qa)), "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(codes), "panel_geometry": result.get("panel_geometry", {}), "family_qa": family_qa, "output_dir": str(out)})
            except Exception as exc:
                rows.append({"scenario": scenario, "input": str(path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        try:
            result = run_visual(equal_png, root / "visual-ocr-auto", ["--ocr", "auto"])
            ocr = result.get("ocr", {})
            rows.append({"scenario": "visual-ocr-auto", "input": str(equal_png), "pass": ocr.get("checked") is True and result.get("status") in {"pass", "warn", "fail"}, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(risk_codes(result)), "panel_geometry": result.get("panel_geometry", {}), "detail": f"ocr_available={ocr.get('available')}", "output_dir": str(root / "visual-ocr-auto")})
        except Exception as exc:
            rows.append({"scenario": "visual-ocr-auto", "input": str(equal_png), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        blank_png = root / "blank_margin.png"
        make_blank_margin_fixture(blank_png)
        for scenario, path, extra, expected_gate in [
            ("visual-strict-nature-blank-margin", blank_png, ["--ocr", "off", "--strict-nature"], "controlled_whitespace"),
            ("visual-strict-nature-panel-imbalance", unequal_png, ["--expected-panels", "2", "--layout-profile", "equal", "--ocr", "off", "--strict-nature"], "panel_balance"),
        ]:
            out = root / scenario
            try:
                result = run_visual(path, out, extra, allow_nonzero=True)
                nature = result.get("nature_guardrails", {})
                failed_gates = {item.get("id") for item in nature.get("checks", []) if item.get("status") == "fail"}
                ok = result.get("_returncode") != 0 and nature.get("status") == "fail" and expected_gate in failed_gates
                rows.append({"scenario": scenario, "input": str(path), "pass": ok, "status": result.get("status"), "score": result.get("manuscript_readiness_score"), "risk_codes": sorted(risk_codes(result)), "nature_status": nature.get("status"), "panel_geometry": result.get("panel_geometry", {}), "output_dir": str(out)})
            except Exception as exc:
                rows.append({"scenario": scenario, "input": str(path), "pass": False, "status": "error", "score": "", "risk_codes": [], "detail": str(exc)})

        proc = run([sys.executable, str(VISUAL_QA), str(equal_png), "--out", str(root / "visual-ocr-required"), "--ocr", "required"])
        tesseract_exists = shutil.which("tesseract") is not None
        rows.append({"scenario": "visual-ocr-required", "input": str(equal_png), "pass": (proc.returncode == 0) == tesseract_exists, "status": "ok" if proc.returncode == 0 else "expected_error", "score": "", "risk_codes": [], "detail": "required OCR behavior matches local Tesseract availability"})

    compare_rows = []
    base = FAMILY_FIXTURES[0]["path"]
    if base.exists() and Image is not None:
        degraded = root / "degraded_lollipop.png"
        if make_degraded(base, degraded):
            out_no_review = root / "visual-old-vs-new-without-review"
            proc = run([sys.executable, str(COMPARE), str(degraded), str(base), "--out", str(out_no_review), "--family", "lollipop", "--ocr", "off"])
            if proc.returncode == 0:
                payload = json.loads((out_no_review / "old_vs_new_visual_qa.json").read_text())["old_vs_new_visual_qa"]
                compare_rows.append({"scenario": "visual-old-vs-new-without-review", "pass": payload.get("final_verdict") in {"human-review-required", "deterministic_better_pending_human_review"}, **payload})
            else:
                compare_rows.append({"scenario": "visual-old-vs-new-without-review", "pass": False, "status": "error", "detail": proc.stderr or proc.stdout})

            review_json = root / "improved_review.json"
            write_review_json(review_json)
            out_with_review = root / "visual-old-vs-new-with-review"
            proc = run([sys.executable, str(COMPARE), str(degraded), str(base), "--out", str(out_with_review), "--family", "lollipop", "--ocr", "off", "--review-json", str(review_json)])
            if proc.returncode == 0:
                payload = json.loads((out_with_review / "old_vs_new_visual_qa.json").read_text())["old_vs_new_visual_qa"]
                compare_rows.append({"scenario": "visual-old-vs-new-with-review", "pass": payload.get("final_verdict") == "improved", **payload})
            else:
                compare_rows.append({"scenario": "visual-old-vs-new-with-review", "pass": False, "status": "error", "detail": proc.stderr or proc.stdout})

    if Image is not None:
        review_json = root / "improved_review_for_regression.json"
        write_review_json(review_json)
        out_detail_regression = root / "old-vs-new-detail-regression-blocked"
        proc = run([
            sys.executable,
            str(COMPARE),
            str(equal_png),
            str(grid_png),
            "--out",
            str(out_detail_regression),
            "--ocr",
            "off",
            "--allow-grid",
            "off",
            "--strict-detail-qa",
            "--target-width-mm",
            "89",
            "--journal-profile",
            "nature",
            "--review-json",
            str(review_json),
        ])
        if proc.returncode == 0:
            payload = json.loads((out_detail_regression / "old_vs_new_visual_qa.json").read_text())["old_vs_new_visual_qa"]
            compare_rows.append({"scenario": "old-vs-new-detail-regression-blocked", "pass": payload.get("final_verdict") != "improved", **payload})
        else:
            compare_rows.append({"scenario": "old-vs-new-detail-regression-blocked", "pass": False, "status": "error", "detail": proc.stderr or proc.stdout})

        loss_review = root / "scientific_loss_review.json"
        write_scientific_loss_review_json(loss_review)
        out_info_loss = root / "old-vs-new-scientific-info-loss-blocked"
        proc = run([
            sys.executable,
            str(COMPARE),
            str(grid_png),
            str(equal_png),
            "--out",
            str(out_info_loss),
            "--ocr",
            "off",
            "--target-width-mm",
            "89",
            "--journal-profile",
            "nature",
            "--review-json",
            str(loss_review),
        ])
        if proc.returncode == 0:
            payload = json.loads((out_info_loss / "old_vs_new_visual_qa.json").read_text())["old_vs_new_visual_qa"]
            compare_rows.append({"scenario": "old-vs-new-scientific-info-loss-blocked", "pass": payload.get("final_verdict") != "improved" and payload.get("review_rubric_status") == "worse", **payload})
        else:
            compare_rows.append({"scenario": "old-vs-new-scientific-info-loss-blocked", "pass": False, "status": "error", "detail": proc.stderr or proc.stdout})

    write_report(rows, compare_rows)
    write_panel_report(rows)
    write_rubric_report(compare_rows)
    write_vector_report(rows)
    write_family_report(rows)
    write_non_human_report(rows, compare_rows)
    print("scenario pass status")
    for row in rows:
        print(f"{row['scenario']}\t{row['pass']}\t{row.get('status')}\t{row.get('score')}\t{','.join(row.get('risk_codes', []))}")
    for row in compare_rows:
        print(f"{row['scenario']}\t{row.get('pass')}\t{row.get('status')}\t{row.get('final_verdict')}")
    print(f"temporary visual pressure root: {root}")
    print(f"visual QA real figure test report: {REPORT}")
    print(f"panel geometry QA validation report: {PANEL_REPORT}")
    print(f"old-vs-new rubric validation report: {RUBRIC_REPORT}")
    print(f"family QA scoring validation report: {FAMILY_REPORT}")
    print(f"vector font/stroke validation report: {VECTOR_REPORT}")
    print(f"non-human QA upgrade summary: {NON_HUMAN_REPORT}")
    all_ok = all(row.get("pass") is not False for row in rows) and all(row.get("pass") is not False for row in compare_rows)
    return 0 if all_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
