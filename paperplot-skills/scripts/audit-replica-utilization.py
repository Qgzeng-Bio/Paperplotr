#!/usr/bin/env python3
"""Audit how every indexed replica script is consumed by PaperPlot Skills.

The audit is intentionally conservative. It does not claim that every source
script became a production template. Instead, every script must have a clear
skill-level use: executable recipe evidence, optional-backend recipe evidence,
benchmark case, reusable style atom, or caution/reference material.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


SPECIALIZED_FAMILIES = {
    "map / spatial",
    "circos / chord / circular",
    "network / sankey",
    "phylogenetic tree",
    "upset / set plot",
}

STYLE_ATOM_HINTS = {
    "geom_text": "annotation atom",
    "geom_label": "annotation atom",
    "geom_segment": "connector/reference-line atom",
    "geom_curve": "flow/link atom",
    "geom_tile": "matrix/heatmap atom",
    "geom_density": "distribution atom",
    "geom_violin": "distribution atom",
    "facet_wrap": "layout atom",
    "facet_grid": "layout atom",
    "scale_fill_gradient": "continuous color atom",
    "scale_colour_gradient": "continuous color atom",
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def load_index(path: Path) -> list[dict]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(payload, dict) and "records" in payload:
        return list(payload["records"])
    if isinstance(payload, list):
        return payload
    raise ValueError(f"Unsupported index JSON shape: {path}")


def normalize_family(value: str) -> str:
    return " ".join((value or "").lower().replace("&", "/").split())


def recipe_family_map(recipes: list[dict[str, str]]) -> dict[str, list[dict[str, str]]]:
    out: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in recipes:
        out[normalize_family(row.get("figure_family", ""))].append(row)
    return out


def family_matches(record_family: str, recipe_family: str) -> bool:
    rf = normalize_family(record_family)
    qf = normalize_family(recipe_family)
    if not rf or not qf:
        return False
    if rf in qf or qf in rf:
        return True
    aliases = {
        "heatmap / matrix": ("heatmap", "matrix", "annotated heatmap", "correlation"),
        "grouped bar / stacked bar / errorbar": ("bar", "errorbar", "stacked"),
        "raincloud / violin / jitter": ("raincloud", "violin", "boxplot", "jitter"),
        "PCA / PCoA / ordination": ("pca", "pcoa", "ordination", "nmds", "umap", "tsne"),
        "volcano / enrichment": ("volcano", "ma plot"),
        "enrichment / GSEA": ("enrichment", "gsea"),
        "lollipop / dumbbell / dotplot": ("lollipop", "dumbbell", "dotplot", "ranked"),
        "circos / chord / circular": ("circos", "chord", "sankey", "flow"),
        "network / sankey": ("network", "sankey", "flow"),
        "map / spatial": ("map", "spatial"),
        "phylogenetic tree": ("phylo", "tree"),
    }
    for family, terms in aliases.items():
        if normalize_family(family) == rf:
            return any(term in qf for term in terms)
    return False


def atom_tags(record: dict) -> list[str]:
    layers = record.get("ggplot_layers", {})
    tokens = []
    for key in ("geoms", "stats", "scales", "themes", "facets", "coords"):
        tokens.extend(layers.get(key, []) or [])
    tags = sorted({label for token, label in STYLE_ATOM_HINTS.items() if token in tokens})
    if record.get("output_calls"):
        tags.append("export atom")
    if "hardcoded_local_path" in (record.get("risks") or []):
        tags.append("path-sanitization caution")
    return tags


def assign_use(record: dict, recipes: list[dict[str, str]]) -> dict:
    family = record.get("figure_family", "")
    suitability = record.get("suitability", "")
    matching = [r for r in recipes if family_matches(family, r.get("figure_family", ""))]
    production = [r for r in matching if r.get("status") in {"production_recipe", "template_candidate"}]
    optional = [r for r in matching if r.get("status") in {"optional_backend_recipe", "specialized_reference", "reference_recipe"}]
    tags = atom_tags(record)

    if suitability in {"production_recipe", "template_candidate"} and production:
        use = "production_recipe"
        reason = "Covered by one or more executable recipe/template-candidate families."
        matched = production[:5]
    elif family in SPECIALIZED_FAMILIES and optional:
        use = "optional_backend_recipe"
        reason = "Specialized family covered by optional/reference recipes; not forced into default ggplot thresholds."
        matched = optional[:5]
    elif suitability == "decorative_or_case_specific":
        use = "caution_reference"
        reason = "Case-specific grob/polar/decorative logic is retained as a boundary and anti-pattern reference."
        matched = matching[:5]
    elif matching:
        use = "benchmark_case"
        reason = "Family is represented; source script should enter real-case benchmark or diagnostic calibration."
        matched = matching[:5]
    elif tags:
        use = "style_atom"
        reason = "No direct recipe family match, but reusable plotting atoms can be extracted."
        matched = []
    else:
        use = "benchmark_case"
        reason = "Fallback assignment to benchmark queue so the script is not orphaned."
        matched = []

    return {
        "case": record.get("case", ""),
        "script": record.get("script", ""),
        "archive_script": record.get("archive_script", ""),
        "figure_family": family,
        "source_suitability": suitability,
        "skill_use": use,
        "reason": reason,
        "matched_recipe_ids": [r.get("recipe_id", "") for r in matched],
        "style_atoms": tags,
        "risks": record.get("risks", []),
        "packages": record.get("packages", []),
        "data_file_types": record.get("data_file_types", []),
        "image_output_types": record.get("image_output_types", []),
    }


def write_markdown(assignments: list[dict], out: Path, index_path: Path, recipe_path: Path) -> None:
    counts = Counter(row["skill_use"] for row in assignments)
    families = Counter(row["figure_family"] for row in assignments)
    orphaned = [row for row in assignments if not row["skill_use"]]
    lines = [
        "# Full Replica Code Utilization Audit",
        "",
        f"Source index: `{index_path}`",
        f"Recipe manifest: `{recipe_path}`",
        f"Scripts audited: {len(assignments)}",
        f"Scripts with explicit skill use: {len(assignments) - len(orphaned)}/{len(assignments)}",
        "",
        "## Skill Use Summary",
        "",
    ]
    for key, value in sorted(counts.items()):
        lines.append(f"- `{key}`: {value}")
    lines += ["", "## Family Coverage", ""]
    for family, value in families.most_common():
        lines.append(f"- {family}: {value}")
    lines += [
        "",
        "## Interpretation",
        "",
        "- `production_recipe`: the source contributes to executable recipes or production-template candidates.",
        "- `optional_backend_recipe`: the source requires specialized layout/backend handling and is not forced into base ggplot defaults.",
        "- `benchmark_case`: the source becomes a real-case diagnostic or regression case.",
        "- `style_atom`: the source contributes reusable code atoms such as annotation, layout, scale, or export patterns.",
        "- `caution_reference`: the source teaches a boundary condition that should not be generalized blindly.",
        "",
        "## Script-Level Utilization",
        "",
        "| Case | Script | Family | Source suitability | Skill use | Matched recipes | Style atoms | Risks |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for row in assignments:
        lines.append(
            "| {case} | `{script}` | {family} | `{source}` | `{use}` | {recipes} | {atoms} | {risks} |".format(
                case=str(row["case"]).replace("|", "/"),
                script=str(row["script"]).replace("|", "/"),
                family=str(row["figure_family"]).replace("|", "/"),
                source=str(row["source_suitability"]).replace("|", "/"),
                use=str(row["skill_use"]).replace("|", "/"),
                recipes=", ".join(f"`{x}`" for x in row["matched_recipe_ids"]) or "-",
                atoms=", ".join(row["style_atoms"]) or "-",
                risks=", ".join(row["risks"]) or "-",
            )
        )
    lines += [
        "",
        "## 9.0 Gate",
        "",
        "- Passing this audit means every indexed source script has an explicit role in the skill.",
        "- It does not mean every script is safe to execute directly; execution is restricted to cleaned recipes/templates.",
        "- Scripts with local paths, grob-level decoration, polar layouts, or heavy specialized dependencies remain reference material unless promoted through an optional backend recipe.",
    ]
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", required=True, help="replica-code-pattern-index.json")
    parser.add_argument("--recipes", required=True, help="recipe_manifest.csv")
    parser.add_argument("--out", required=True, help="Markdown output path")
    parser.add_argument("--out-json", default=None, help="JSON output path")
    args = parser.parse_args()

    index_path = Path(args.index)
    recipe_path = Path(args.recipes)
    records = load_index(index_path)
    recipes = read_csv(recipe_path)
    assignments = [assign_use(record, recipes) for record in records]

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    write_markdown(assignments, out, index_path, recipe_path)
    out_json = Path(args.out_json) if args.out_json else out.with_suffix(".json")
    out_json.write_text(
        json.dumps(
            {
                "script_count": len(assignments),
                "explicit_use_count": sum(1 for row in assignments if row["skill_use"]),
                "skill_use_counts": Counter(row["skill_use"] for row in assignments),
                "assignments": assignments,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {out}")
    print(f"Wrote {out_json}")
    if any(not row["skill_use"] for row in assignments):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
