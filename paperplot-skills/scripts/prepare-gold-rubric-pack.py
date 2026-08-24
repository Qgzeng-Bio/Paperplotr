#!/usr/bin/env python3
"""Prepare a fillable human rubric scoring pack for the gold benchmark set."""

from __future__ import annotations

import argparse
import csv
import html
import json
import shutil
import subprocess
from pathlib import Path
from urllib.parse import quote


SCORE_COLUMNS = [
    "message_clarity",
    "scientific_completeness",
    "visual_hierarchy",
    "proportional_balance",
    "readability_at_target_size",
    "statistical_expression",
    "color_legend_discipline",
    "data_preservation",
]

SCORE_DEFINITIONS = {
    1: "严重不足：作为正样本或 manuscript reference 不成立。",
    2: "明显有问题：可学习局部元素，但不适合默认阈值或模板学习。",
    3: "可接受：有可学习价值，但存在明显可改进点。",
    4: "较好：接近高水平论文图，可作为多数规则的正样本。",
    5: "优秀：非常适合作为 Nature-like 细节和审美校准正样本。",
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def file_url(path: str) -> str:
    return "file://" + quote(str(Path(path).expanduser().resolve()))


def run_checked(cmd: list[str]) -> bool:
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return False


def make_preview(source: str, benchmark_id: str, preview_dir: Path, dpi: int = 150) -> str:
    if not source or source == "-":
        return ""
    src = Path(source)
    if not src.exists():
        return ""
    preview_dir.mkdir(parents=True, exist_ok=True)
    ext = src.suffix.lower()
    out_png = preview_dir / f"{benchmark_id}.png"
    if ext == ".pdf":
        stem = preview_dir / benchmark_id
        if run_checked(["pdftoppm", "-singlefile", "-png", "-r", str(dpi), str(src), str(stem)]):
            return str(out_png)
    if ext == ".svg":
        if run_checked(["magick", "-density", str(dpi), str(src), str(out_png)]):
            return str(out_png)
    if ext in {".png", ".jpg", ".jpeg", ".tif", ".tiff"}:
        target = preview_dir / f"{benchmark_id}{ext}"
        try:
            shutil.copy2(src, target)
            return str(target)
        except Exception:
            return ""
    return ""


def write_csv_template(cases: list[dict], csv_path: Path) -> None:
    fields = [
        "benchmark_id",
        "case",
        "figure_family",
        "source_image",
        "preview_image",
        "reviewer",
        "reviewed_at",
        *SCORE_COLUMNS,
        *(f"{col}_notes" for col in SCORE_COLUMNS),
        "overall_notes",
        "exclude_from_positive_calibration",
        "exclusion_reason",
    ]
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for case in cases:
            row = {field: "" for field in fields}
            row.update(
                {
                    "benchmark_id": case.get("benchmark_id", ""),
                    "case": case.get("case", ""),
                    "figure_family": case.get("figure_family", ""),
                    "source_image": case.get("source_image", ""),
                    "preview_image": case.get("preview_image", ""),
                    "exclude_from_positive_calibration": "FALSE",
                }
            )
            writer.writerow(row)


def write_guide(path: Path) -> None:
    lines = [
        "# Gold Human Rubric Scoring Guide",
        "",
        "Use this guide to score the 30-case gold set. Scores calibrate PaperPlot Skills; they are not a judgment of the original author.",
        "",
        "## Scale",
        "",
    ]
    for score, definition in SCORE_DEFINITIONS.items():
        lines.append(f"- `{score}`: {definition}")
    lines += [
        "",
        "## Dimensions",
        "",
        "- `message_clarity`: one clear scientific message can be read without decoding clutter.",
        "- `scientific_completeness`: units, n, uncertainty, thresholds, transforms, or test semantics are visible or inferable from figure context.",
        "- `visual_hierarchy`: primary data, secondary annotation, legend, and labels have clear priority.",
        "- `proportional_balance`: panel boxes, data regions, legend size, and blank space feel intentional.",
        "- `readability_at_target_size`: text, ticks, points, and lines remain readable at manuscript width.",
        "- `statistical_expression`: intervals, p-values, effect sizes, model metrics, or enrichment semantics are expressed responsibly.",
        "- `color_legend_discipline`: color count, saturation, colorbar/legend, and grayscale/colorblind risks are controlled.",
        "- `data_preservation`: simplification does not remove essential data structure or scientific meaning.",
        "",
        "## How To Fill The CSV",
        "",
        "- Fill each score column with an integer `1` to `5`.",
        "- Add short notes only when a score needs explanation.",
        "- Mark `exclude_from_positive_calibration=TRUE` when the image is useful as caution/reference but should not teach default positive thresholds.",
        "- Leave source paths unchanged.",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_html(cases: list[dict], html_path: Path, csv_path: Path, guide_path: Path) -> None:
    cards = []
    for case in cases:
        preview = case.get("preview_image", "")
        source = case.get("source_image", "")
        if preview:
            img = f'<img src="{html.escape(Path(preview).name)}" alt="{html.escape(case["benchmark_id"])} preview">'
        else:
            img = '<div class="missing">No preview available</div>'
        source_link = f'<a href="{html.escape(file_url(source))}">open source</a>' if source and source != "-" else "source missing"
        cards.append(
            f"""
            <article class="card">
              <div class="media">{img}</div>
              <div class="body">
                <div class="id">{html.escape(case.get("benchmark_id", ""))}</div>
                <h2>{html.escape(case.get("figure_family", ""))}</h2>
                <p>{html.escape(case.get("case", ""))}</p>
                <p class="link">{source_link}</p>
              </div>
            </article>
            """
        )
    html_text = f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PaperPlot Gold Rubric Scoring Pack</title>
  <style>
    :root {{ color-scheme: light; --ink: #17212b; --muted: #64717f; --line: #dce3e8; --bg: #f7f8f8; --panel: #ffffff; --accent: #315f86; }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; font-family: Arial, Helvetica, sans-serif; color: var(--ink); background: var(--bg); }}
    header {{ padding: 28px 36px 18px; border-bottom: 1px solid var(--line); background: var(--panel); }}
    h1 {{ margin: 0 0 8px; font-size: 24px; letter-spacing: 0; }}
    header p {{ margin: 0; color: var(--muted); line-height: 1.55; max-width: 960px; }}
    .tools {{ display: flex; gap: 12px; flex-wrap: wrap; margin-top: 16px; }}
    .tools a {{ color: var(--accent); text-decoration: none; border: 1px solid var(--line); padding: 8px 10px; border-radius: 6px; background: #fff; }}
    main {{ padding: 24px 36px 48px; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 18px; }}
    .card {{ background: var(--panel); border: 1px solid var(--line); border-radius: 8px; overflow: hidden; display: flex; flex-direction: column; min-height: 100%; }}
    .media {{ height: 230px; display: flex; align-items: center; justify-content: center; background: #eef2f4; border-bottom: 1px solid var(--line); }}
    .media img {{ max-width: 100%; max-height: 100%; object-fit: contain; display: block; }}
    .missing {{ color: var(--muted); font-size: 13px; }}
    .body {{ padding: 14px 16px 16px; }}
    .id {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace; color: var(--muted); font-size: 12px; margin-bottom: 8px; }}
    h2 {{ margin: 0 0 8px; font-size: 16px; line-height: 1.25; }}
    p {{ margin: 0 0 8px; line-height: 1.45; color: var(--muted); }}
    .link a {{ color: var(--accent); }}
    @media (max-width: 1100px) {{ main {{ grid-template-columns: repeat(2, minmax(0, 1fr)); }} }}
    @media (max-width: 720px) {{ header, main {{ padding-left: 18px; padding-right: 18px; }} main {{ grid-template-columns: 1fr; }} }}
  </style>
</head>
<body>
  <header>
    <h1>PaperPlot Gold Rubric Scoring Pack</h1>
    <p>请打开 CSV 填写 8 个维度的 1-5 分。这个页面用于快速查看 30 张 gold set 候选图，评分结果会用于校准 PaperPlot Skills 的 9 分绘图能力。</p>
    <div class="tools">
      <a href="{html.escape(csv_path.name)}">scoring CSV</a>
      <a href="{html.escape(guide_path.name)}">scoring guide</a>
    </div>
  </header>
  <main>
    {''.join(cards)}
  </main>
</body>
</html>
"""
    html_path.write_text(html_text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gold-json", default="paperplot-skills/reports/gold-human-rubric-set.json")
    parser.add_argument("--out-dir", default="paperplot-skills/reports/gold-human-rubric-pack")
    parser.add_argument("--dpi", type=int, default=150)
    args = parser.parse_args()

    payload = load_json(Path(args.gold_json))
    out_dir = Path(args.out_dir)
    preview_dir = out_dir / "previews"
    out_dir.mkdir(parents=True, exist_ok=True)
    cases = payload.get("cases", [])
    enriched = []
    for case in cases:
        row = dict(case)
        row["preview_image"] = make_preview(row.get("source_image", ""), row.get("benchmark_id", "case"), preview_dir, args.dpi)
        if row["preview_image"]:
            # Copy preview beside the HTML for simple relative display.
            preview = Path(row["preview_image"])
            flat = out_dir / preview.name
            if preview.resolve() != flat.resolve():
                shutil.copy2(preview, flat)
            row["preview_image"] = str(flat)
        enriched.append(row)

    csv_path = out_dir / "gold-human-rubric-scoring.csv"
    guide_path = out_dir / "gold-human-rubric-scoring-guide.md"
    html_path = out_dir / "index.html"
    write_csv_template(enriched, csv_path)
    write_guide(guide_path)
    write_html(enriched, html_path, csv_path, guide_path)
    (out_dir / "gold-human-rubric-pack.json").write_text(json.dumps({"cases": enriched, "rubric": SCORE_COLUMNS}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {html_path}")
    print(f"Wrote {csv_path}")
    print(f"Wrote {guide_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
