#!/usr/bin/env python3
"""Index local Nature/Cell/Science-style replica plotting libraries.

The script reads file names, light-weight code snippets, and output metadata.
It does not copy figure code into the skill. The output is a design-intelligence
index used to decide which figure families deserve reusable pattern docs,
template upgrades, and visual-QA calibration.
"""

from __future__ import annotations

import argparse
import json
import os
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable

# No hardcoded machine-specific paths. Point the indexer at your replica
# libraries via --r-root/--python-root or the PAPERPLOT_R_ROOT/PAPERPLOT_PY_ROOT
# environment variables.
DEFAULT_R_ROOT = os.environ.get("PAPERPLOT_R_ROOT")
DEFAULT_PY_ROOT = os.environ.get("PAPERPLOT_PY_ROOT")

CODE_EXT = {".r", ".rmd", ".qmd", ".py", ".ipynb"}
OUTPUT_EXT = {".png", ".jpg", ".jpeg", ".pdf", ".svg", ".ai", ".eps", ".tif", ".tiff"}
DATA_EXT = {".csv", ".tsv", ".txt", ".xls", ".xlsx", ".rds", ".rda", ".nwk", ".tree", ".geojson", ".shp", ".dbf", ".h5ad", ".mtx"}

FAMILY_RULES: list[tuple[str, list[str]]] = [
    ("phylogenetic tree with annotation rings", ["系统发育", "phylo", "ggtree", "tree", "annotation ring", "外圈"]),
    ("circos / chord / synteny-like plot", ["circos", "和弦", "chord", "sankey", "桑基", "synteny", "circlize"]),
    ("upset / venn-like set plot", ["upset", "venn", "set plot", "ComplexUpset", "UpSetR"]),
    ("Manhattan plot", ["manhattan", "曼哈顿", "genomewide", "chromosome", "chr"]),
    ("volcano / MA / enrichment / GSEA", ["volcano", "火山", "gsea", "enrichment", "富集", "msigdb", "ma plot", "差异基因"]),
    ("PCA / PCoA / NMDS / UMAP / t-SNE", ["pcoa", "pca", "nmds", "umap", "tsne", "t-sne", "ordination", "permanova"]),
    ("heatmap / correlation heatmap / matrix dotplot", ["heatmap", "热图", "correlation", "相关", "matrix", "矩阵", "corrplot", "clustermap", "dotplot", "气泡热图"]),
    ("scatter / regression / marginal histogram", ["scatter", "散点", "regression", "回归", "fit", "拟合", "marginal", "边缘", "histogram", "直方图", "residual", "残差"]),
    ("boxplot / violin / raincloud / jitter", ["raincloud", "云雨", "violin", "小提琴", "boxplot", "箱", "jitter", "蜂群", "swarm"]),
    ("grouped bar / stacked bar / errorbar", ["bar", "柱", "errorbar", "误差", "stacked", "堆积", "anova"]),
    ("dotplot / lollipop / dumbbell", ["lollipop", "棒棒糖", "dumbbell", "哑铃", "点线", "line_dot"]),
    ("model validation / prediction accuracy / residual diagnostics", ["model", "模型", "validation", "prediction", "accuracy", "residual", "验证", "诊断"]),
    ("map / spatial plot", ["map", "地图", "spatial", "空间", "geojson", "shp", "sf", "scanpy"]),
    ("ridgeline / density / contour", ["ridge", "山脊", "density", "密度", "contour", "等高线", "kde"]),
    ("radar / polar / circular bar", ["radar", "雷达", "polar", "极坐标", "环形", "circular", "圆环"]),
    ("network / chord / Sankey", ["network", "网络", "enrichnetwork", "sankey", "桑基"]),
    ("multi-panel manuscript figure", ["combine", "组合", "multi", "panel", "分面", "facet", "复合"]),
    ("schematic / workflow / conceptual figure", ["workflow", "schematic", "concept", "流程", "示意"]),
]

APPLICATION_HINTS = {
    "grouped bar / stacked bar / errorbar": "group comparison, treatment-response summaries, repeated-category composition",
    "dotplot / lollipop / dumbbell": "ranked comparisons, before-after deltas, compact categorical contrasts",
    "boxplot / violin / raincloud / jitter": "distribution comparison with raw-sample evidence",
    "scatter / regression / marginal histogram": "relationship testing, calibration, regression, residual diagnostics",
    "heatmap / correlation heatmap / matrix dotplot": "matrix relationships, multi-feature signatures, correlation or abundance grids",
    "PCA / PCoA / NMDS / UMAP / t-SNE": "ordination, sample clustering, community/omics structure",
    "volcano / MA / enrichment / GSEA": "differential analysis and pathway/signature summarization",
    "Manhattan plot": "genome-wide association or ordered locus-level signal",
    "phylogenetic tree with annotation rings": "tree-structured evolutionary comparison plus metadata rings",
    "circos / chord / synteny-like plot": "many-to-many links, circular genomic/network summaries",
    "upset / venn-like set plot": "set intersections with scalable matrix encoding",
    "network / chord / Sankey": "relationship topology, pathway networks, flow or transition summaries",
    "map / spatial plot": "geographic/spatial sample distribution",
    "ridgeline / density / contour": "distribution shifts over ordered groups or 2D density structure",
    "radar / polar / circular bar": "compact multivariate profile when circular form is justified",
    "multi-panel manuscript figure": "integrated evidence across panels with hierarchy",
    "model validation / prediction accuracy / residual diagnostics": "prediction performance, residuals, calibration, model checking",
    "schematic / workflow / conceptual figure": "methods overview or conceptual workflow",
}

HIGH_DEPENDENCY_PATTERNS = {
    "circlize", "ggtree", "treeio", "ComplexHeatmap", "ComplexUpset", "UpSetR", "sf",
    "ggmap", "scanpy", "squidpy", "networkx", "plotly", "seaborn.clustermap"
}
MEDIUM_DEPENDENCY_PATTERNS = {
    "ggpubr", "ggsignif", "ggridges", "ggbeeswarm", "cowplot", "patchwork", "ggrepel",
    "pheatmap", "corrplot", "FactoMineR", "factoextra", "vegan", "statannotations",
    "seaborn", "matplotlib", "sklearn", "scipy"
}


@dataclass
class CaseIndex:
    case_dir: str
    relative_path: str
    language: str
    output_types: list[str]
    code_files: list[str]
    data_types: list[str]
    data_files: list[str]
    figure_family: str
    secondary_families: list[str]
    application_scene: str
    skill_fit: str
    visual_qa_positive_sample: str
    template_reference: str
    dependency_complexity: str
    dependency_hints: list[str]
    risks: list[str]
    output_examples: list[str]


def read_text_sample(path: Path, limit: int = 18000) -> str:
    try:
        return path.read_text(errors="ignore")[:limit]
    except Exception:
        return ""


def first_level_cases(root: Path) -> list[Path]:
    return sorted([p for p in root.iterdir() if p.is_dir()], key=lambda p: p.name.lower())


def compact_paths(paths: Iterable[Path], case_root: Path, limit: int = 8) -> list[str]:
    out = [str(p.relative_to(case_root)) for p in sorted(paths, key=lambda x: str(x).lower())]
    if len(out) > limit:
        return out[:limit] + [f"...(+{len(out) - limit} more)"]
    return out


def extension_list(paths: Iterable[Path]) -> list[str]:
    return sorted({p.suffix.lower().lstrip(".") or "none" for p in paths})


def collect_dependencies(code_paths: list[Path]) -> list[str]:
    deps: set[str] = set()
    for path in code_paths[:12]:
        text = read_text_sample(path, limit=26000)
        for match in re.findall(r"\blibrary\s*\(\s*['\"]?([A-Za-z0-9_.]+)", text):
            deps.add(match)
        for match in re.findall(r"\brequire\s*\(\s*['\"]?([A-Za-z0-9_.]+)", text):
            deps.add(match)
        for match in re.findall(r"\b([A-Za-z][A-Za-z0-9_.]+)::", text):
            deps.add(match)
        for match in re.findall(r"^\s*(?:import|from)\s+([A-Za-z0-9_.]+)", text, flags=re.MULTILINE):
            deps.add(match.split(".")[0])
    return sorted(deps)


def classify_family(name: str, file_names: str, snippets: str) -> tuple[str, list[str]]:
    haystack = f"{name}\n{file_names}\n{snippets}".lower()
    scores: list[tuple[int, str]] = []
    for family, keys in FAMILY_RULES:
        score = 0
        for key in keys:
            if key.lower() in haystack:
                score += 6 if key.lower() in name.lower() else 1
        if family == "PCA / PCoA / NMDS / UMAP / t-SNE" and re.search(r"\b(pca|pcoa|nmds|umap|t-?sne)\b", name.lower()):
            score += 4
        if family == "heatmap / correlation heatmap / matrix dotplot" and any(x in name.lower() for x in ["热图", "heatmap", "correlation", "相关"]):
            score += 4
        if score:
            scores.append((score, family))
    if not scores:
        return "multi-panel manuscript figure", []
    scores.sort(key=lambda item: (-item[0], item[1]))
    primary = scores[0][1]
    secondary = [family for _, family in scores[1:4] if family != primary]
    return primary, secondary


def dependency_complexity(deps: list[str], family: str) -> tuple[str, list[str]]:
    dep_text = " ".join(deps)
    high = sorted([d for d in deps if d in HIGH_DEPENDENCY_PATTERNS or any(x in d for x in ("scanpy", "circlize"))])
    medium = sorted([d for d in deps if d in MEDIUM_DEPENDENCY_PATTERNS])
    specialized_families = {
        "phylogenetic tree with annotation rings",
        "circos / chord / synteny-like plot",
        "map / spatial plot",
        "upset / venn-like set plot",
        "network / chord / Sankey",
    }
    if high or family in specialized_families:
        return "high", high[:8] or [family]
    if medium or len(deps) >= 6:
        return "medium", medium[:8] or deps[:8]
    if dep_text:
        return "low", deps[:8]
    return "unknown", []


def suitability(family: str, output_paths: list[Path], dep_complexity: str, name: str) -> tuple[str, str, str, list[str]]:
    risks: list[str] = []
    lower_name = name.lower()
    if any(x in lower_name for x in ["绝美", "渐变色背景", "环状", "极坐标", "雷达"]):
        risks.append("may contain decorative or presentation-heavy styling; extract structure, not ornament")
    if family in {
        "circos / chord / synteny-like plot",
        "phylogenetic tree with annotation rings",
        "map / spatial plot",
        "network / chord / Sankey",
    }:
        skill_fit = "specialized reference: useful for boundaries and data requirements, not a default template"
    elif family in {"radar / polar / circular bar", "schematic / workflow / conceptual figure"}:
        skill_fit = "caution: use only when the scientific structure truly requires this encoding"
    else:
        skill_fit = "high: suitable for reusable design principles"

    has_raster_or_svg = any(p.suffix.lower() in {".png", ".jpg", ".jpeg", ".svg"} for p in output_paths)
    if has_raster_or_svg and dep_complexity != "high":
        visual = "yes: positive-sample candidate"
    elif has_raster_or_svg:
        visual = "with caution: family-specific thresholds needed"
    else:
        visual = "no direct raster/SVG sample"

    if dep_complexity == "high":
        template = "reference only unless a dedicated data structure and optional backend are provided"
    elif family in {"grouped bar / stacked bar / errorbar", "boxplot / violin / raincloud / jitter", "scatter / regression / marginal histogram", "heatmap / correlation heatmap / matrix dotplot", "PCA / PCoA / NMDS / UMAP / t-SNE", "volcano / MA / enrichment / GSEA", "model validation / prediction accuracy / residual diagnostics"}:
        template = "yes: should influence existing templates"
    else:
        template = "partial: extract layout and QA rules before adding templates"
    return skill_fit, visual, template, risks


def index_case(root: Path, case: Path, language_hint: str) -> CaseIndex:
    files = [p for p in case.rglob("*") if p.is_file() and p.name != ".DS_Store"]
    code_paths = [p for p in files if p.suffix.lower() in CODE_EXT]
    output_paths = [p for p in files if p.suffix.lower() in OUTPUT_EXT]
    data_paths = [p for p in files if p.suffix.lower() in DATA_EXT]
    snippets = "\n".join(read_text_sample(p, limit=8000) for p in code_paths[:8])
    file_names = "\n".join(p.name for p in files)
    primary, secondary = classify_family(case.name, file_names, snippets)
    deps = collect_dependencies(code_paths)
    dep_complexity, dep_hints = dependency_complexity(deps, primary)
    skill_fit, visual, template, risks = suitability(primary, output_paths, dep_complexity, case.name)
    language = language_hint
    if any(p.suffix.lower() == ".ipynb" for p in code_paths) or any(p.suffix.lower() == ".py" for p in code_paths):
        language = "Python" if language_hint == "Python" else "R + Python/notebook"
    return CaseIndex(
        case_dir=case.name,
        relative_path=str(case.relative_to(root)),
        language=language,
        output_types=extension_list(output_paths),
        code_files=compact_paths(code_paths, case),
        data_types=extension_list(data_paths),
        data_files=compact_paths(data_paths, case),
        figure_family=primary,
        secondary_families=secondary,
        application_scene=APPLICATION_HINTS.get(primary, "general manuscript figure design reference"),
        skill_fit=skill_fit,
        visual_qa_positive_sample=visual,
        template_reference=template,
        dependency_complexity=dep_complexity,
        dependency_hints=dep_hints,
        risks=risks,
        output_examples=compact_paths(output_paths, case, limit=6),
    )


def md_list(items: list[str]) -> str:
    return ", ".join(f"`{x}`" for x in items) if items else "-"


def write_report(cases: list[CaseIndex], out_md: Path, out_json: Path, roots: dict[str, str]) -> None:
    out_md.parent.mkdir(parents=True, exist_ok=True)
    payload = {"roots": roots, "case_count": len(cases), "cases": [asdict(c) for c in cases]}
    out_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")

    family_counts = Counter(c.figure_family for c in cases)
    language_counts = Counter(c.language for c in cases)
    dep_counts = Counter(c.dependency_complexity for c in cases)
    visual_counts = Counter(c.visual_qa_positive_sample for c in cases)

    lines = [
        "# Nature/Cell/Science Replica Pattern Index",
        "",
        "Generated by `scripts/index-replica-patterns.py` from local replica libraries. This report indexes file structure, figure-family signals, and reusable design value; it does not copy protected figure content or source code.",
        "",
        "## Source Libraries",
        "",
        *[f"- {label} library: `{path}`" for label, path in roots.items()],
        "",
        "## Summary",
        "",
        f"- Cases indexed: {len(cases)}",
        f"- Languages: {', '.join(f'{k}={v}' for k, v in sorted(language_counts.items()))}",
        f"- Dependency complexity: {', '.join(f'{k}={v}' for k, v in sorted(dep_counts.items()))}",
        f"- Visual QA sample suitability: {', '.join(f'{k}={v}' for k, v in sorted(visual_counts.items()))}",
        "",
        "## Figure Family Coverage",
        "",
        "| figure family | cases |",
        "|---|---:|",
    ]
    for family, count in family_counts.most_common():
        lines.append(f"| {family} | {count} |")
    lines += [
        "",
        "## High-Value Generalizable Families",
        "",
        "- Distribution and group-comparison cases provide the clearest reusable grammar: raw points, intervals, restrained group colors, explicit sample size, and careful significance annotation.",
        "- Scatter/regression and model-validation cases are valuable for composite layout principles: main relationship panel first, marginal/residual diagnostics second, and statistics reported as text rather than decorative labels.",
        "- Heatmap/correlation cases are useful for matrix ordering, annotation-strip economy, and colorbar discipline; they also show why family-specific visual-QA thresholds are needed for dense but legitimate matrices.",
        "- Ordination cases are useful for axis semantics, confidence hull/ellipse restraint, and keeping PERMANOVA/NMDS/PCA metadata outside the main data cloud when possible.",
        "- Specialized circular, phylogenetic, map, and network examples should train boundary rules and data-structure requirements more than default templates.",
        "",
        "## Case Index",
        "",
        "| case | language | outputs | code | data | figure family | scene | skill fit | visual QA positive | template reference | dependency | risks |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for c in cases:
        risks = "; ".join(c.risks) if c.risks else "-"
        dep = c.dependency_complexity
        if c.dependency_hints:
            dep += " (" + ", ".join(c.dependency_hints[:4]) + ")"
        lines.append(
            "| "
            + " | ".join([
                c.case_dir.replace("|", "/"),
                c.language,
                md_list(c.output_types),
                md_list(c.code_files),
                md_list(c.data_types),
                c.figure_family,
                c.application_scene,
                c.skill_fit,
                c.visual_qa_positive_sample,
                c.template_reference,
                dep,
                risks,
            ])
            + " |"
        )
    by_family: dict[str, list[CaseIndex]] = defaultdict(list)
    for c in cases:
        by_family[c.figure_family].append(c)
    lines += ["", "## Pattern Extraction Notes", ""]
    for family in sorted(by_family):
        examples = by_family[family][:6]
        lines.append(f"### {family}")
        lines.append("")
        lines.append(f"- Representative cases: {', '.join('`' + e.case_dir + '`' for e in examples)}")
        lines.append(f"- Reusable value: {APPLICATION_HINTS.get(family, 'general figure design reference')}.")
        if any(e.dependency_complexity == "high" for e in examples):
            lines.append("- Boundary note: at least one representative uses specialized dependencies; extract data requirements and layout logic before treating it as a template.")
        lines.append("")
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Index local high-quality scientific plotting replica libraries.")
    parser.add_argument("--r-root", default=DEFAULT_R_ROOT, required=DEFAULT_R_ROOT is None,
                        help="Root of the R replica library (or set PAPERPLOT_R_ROOT).")
    parser.add_argument("--python-root", default=DEFAULT_PY_ROOT,
                        help="Root of the Python replica library (or set PAPERPLOT_PY_ROOT). Optional.")
    parser.add_argument("--out-md", default="paperplot-skills/reports/nature-replica-pattern-index.md")
    parser.add_argument("--out-json", default="paperplot-skills/reports/nature-replica-pattern-index.json")
    args = parser.parse_args()

    roots = {}
    if args.r_root:
        roots["R"] = str(Path(args.r_root).expanduser())
    if args.python_root:
        roots["Python"] = str(Path(args.python_root).expanduser())
    if not roots:
        raise SystemExit("No replica library root given. Use --r-root/--python-root or set PAPERPLOT_R_ROOT/PAPERPLOT_PY_ROOT.")
    cases: list[CaseIndex] = []
    for label, root_text in roots.items():
        root = Path(root_text)
        if not root.exists():
            raise SystemExit(f"Library root not found: {root}")
        for case in first_level_cases(root):
            cases.append(index_case(root, case, label))
    write_report(cases, Path(args.out_md), Path(args.out_json), roots)
    print(f"indexed {len(cases)} cases")
    print(f"wrote {args.out_md}")
    print(f"wrote {args.out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
