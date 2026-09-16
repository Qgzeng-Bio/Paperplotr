# Use the installed skill

Run scripts through `~/.agents/skills/paperplot-skills/scripts/paperplot-run`. With no argument it diagnoses the isolated runtime; no activation or global R changes are needed.

## One real plot

Save this in your research workspace and pass it to paperplot-run:

```r
source(Sys.getenv("PAPERPLOT_HELPER"))
source(file.path(pp_helper_script_dir, "..", "recipes", "paperplot_code_recipes.R"))
d <- read.csv("effects.csv") # metric, estimate, lower, upper; optional group/subgroup/n
p <- pp_recipe_plot("forest_effect_size", d,
  params=list(interval_label="Effect estimate (95% CI)"))
files <- pp_save_all_with_qa_loop(p, "outputs/effects",
  render_spec=pp_render_spec(width_mm=89,height_mm=62))
print(attr(files, "qa_contract"))
```

Use “95% CI” only when the supplied bounds really are CIs. Outputs include PDF/SVG/600-dpi PNG, source evidence, candidate history and production QA. Existing files are protected unless overwrite is explicit.

Inspect the final-size image and unresolved checks, then inspect `pp_effective_export_qa("outputs/effects")`. After an actual review:

```r
pp_review_export("outputs/effects", decision="pass", reviewer="actual reviewer",
  checks=c("source_semantics"), reason="Record the tables, units, intervals and evidence inspected.")
```

Only the named item is resolved. Other pending checks still block manuscript-ready; precise failures cannot be overridden.

## Inputs and statistics

`pp_recipe_entry(id)` returns schema roles, handler, variant, dimensions and backend. [Input contract](references/code-recipe-contract.md) defines conditional parameters.

Raw summary: `pp_summary_statistics(d, method="mean", interval="ci", unit_id="sample")`.
Explicit test: `pp_statistical_test(d, method="welch_t")`.
Requested correction: `pp_adjust_pvalues(p, method="BH")`.
Record returned methods, n, missingness and intervals. No statistics are requested implicitly.

Explicit demo only:

```r
d <- pp_recipe_mock_data("lollipop_ranked")
p <- pp_recipe_plot("lollipop_ranked", d, mode="demo")
```

## Main figure

[Project workflow](references/figure-project-workflow.md): create → inspect sketch → confirm layout → build → assemble → review. Read fresh status before resuming. Use `pp_project_revise_panel()` for B-only edits; scientific changes require a reason. Unchanged data builds are reused.

Schema-1 projects are read-only until backed-up `pp_project_migrate(project,dry_run=FALSE)`; first inspect the default dry run. Raw data are not moved. Old approvals require fresh validation.
