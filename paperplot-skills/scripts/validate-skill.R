#!/usr/bin/env Rscript

fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)

root <- normalizePath(file.path(getwd(), "paperplot-skills"), mustWork = FALSE)
if (!dir.exists(root)) fail("paperplot-skills directory not found from working directory: ", getwd())
rel <- function(...) file.path(root, ...)

template_files <- c(
  "single-panel-template.R",
  "multi-panel-template.R",
  "comparison-boxplot-template.R",
  "violin-dot-template.R",
  "correlation-scatter-template.R",
  "heatmap-template.R",
  "pca-scatter-template.R",
  "barplot-template.R",
  "multi-metric-small-multiples-template.R",
  "rank-plus-key-metrics-template.R",
  "manuscript-four-panel-template.R",
  "grouped-boxplot-jitter-template.R",
  "paired-comparison-template.R",
  "effect-size-forest-template.R",
  "bio-genome-quality-overview-template.R",
  "bio-duplication-mode-comparison-template.R",
  "volcano-plot-template.R",
  "ma-plot-template.R",
  "enrichment-dotplot-template.R"
)

required_files <- c(
  "SKILL.md",
  file.path("scripts", "paperplot_helpers.R"),
  file.path("scripts", "validate-skill.R"),
  file.path("scripts", "smoke-test-templates.R"),
  file.path("scripts", "validate-figure-output.R"),
  file.path("scripts", "visual-qa-report.R"),
  file.path("scripts", "visual-qa-rendered-image.py"),
  file.path("scripts", "compare-old-new-figures.py"),
  file.path("scripts", "index-replica-patterns.py"),
  file.path("scripts", "calibrate-visual-qa.py"),
  file.path("scripts", "run-visual-pressure-scenarios.py"),
  file.path("scripts", "lib", "design-brief.R"),
  file.path("scripts", "lib", "label-strategy.R"),
  file.path("scripts", "lib", "design-qa.R"),
  file.path("references", "figure-design-brief.md"),
  file.path("references", "label-burden-strategies.md"),
  file.path("references", "main-vs-supplement-density.md"),
  file.path("references", "manuscript-readiness-rubric.md"),
  file.path("references", "visual-qa-gates.md"),
  file.path("references", "template-selection-guide.md"),
  file.path("references", "metadata-schema.md"),
  file.path("references", "optional-dependencies.md"),
  file.path("references", "publication-visual-standards.md"),
  file.path("references", "manuscript-aesthetics-rules.md"),
  file.path("references", "nature-like-style-principles.md"),
  file.path("references", "image-level-qa.md"),
  file.path("references", "old-vs-new-comparison.md"),
  file.path("references", "visual-perception-qa.md"),
  file.path("references", "old-vs-new-visual-scoring.md"),
  file.path("references", "image-level-failure-modes.md"),
  file.path("references", "figure-type-quality-rubric.md"),
  file.path("references", "cross-backend-workflows.md"),
  file.path("references", "pattern-library", "grouped-bar-errorbar.md"),
  file.path("references", "pattern-library", "raincloud-violin-jitter.md"),
  file.path("references", "pattern-library", "scatter-regression-marginal.md"),
  file.path("references", "pattern-library", "correlation-heatmap.md"),
  file.path("references", "pattern-library", "pca-pcoa-ordination.md"),
  file.path("references", "pattern-library", "volcano-ma-enrichment.md"),
  file.path("references", "pattern-library", "manhattan-genomewide.md"),
  file.path("references", "pattern-library", "phylo-annotation-ring.md"),
  file.path("references", "pattern-library", "upset-set-plot.md"),
  file.path("references", "pattern-library", "circos-chord-sankey.md"),
  file.path("references", "pattern-library", "multi-panel-manuscript-layout.md"),
  file.path("references", "pattern-library", "model-validation-figures.md"),
  file.path("templates", "notes-template.md"),
  file.path("examples", "pressure-scenarios.md"),
  "USAGE.md",
  file.path("reports", "final-skill-test-report.md"),
  file.path("reports", "visual-qa-real-figure-test-report.md"),
  file.path("reports", "nature-replica-pattern-index.md"),
  file.path("reports", "visual-qa-calibration-from-replica-library.md"),
  file.path("reports", "end-to-end-redraw-benchmark.md"),
  file.path("reports", "skill-self-review-after-pattern-library.md"),
  file.path("templates", template_files)
)
missing_required <- required_files[!file.exists(file.path(root, required_files))]
if (length(missing_required) > 0) fail("Missing required files: ", paste(missing_required, collapse = ", "))

skill_lines <- readLines(rel("SKILL.md"), warn = FALSE)
if (length(skill_lines) < 5 || !identical(skill_lines[[1]], "---")) fail("SKILL.md must start with --- frontmatter")
frontmatter_end <- which(skill_lines[-1] == "---")
if (length(frontmatter_end) == 0) fail("SKILL.md frontmatter closing --- not found")
frontmatter_end <- frontmatter_end[[1]] + 1L
frontmatter <- skill_lines[2:(frontmatter_end - 1L)]
description_line <- frontmatter[grepl("^description:\\s*", frontmatter)]
if (!any(grepl("^name:\\s*paperplot-skills\\s*$", frontmatter))) fail("SKILL.md frontmatter must contain name: paperplot-skills")
if (length(description_line) != 1) fail("SKILL.md frontmatter must contain exactly one description field")
if (nchar(sub("^description:\\s*", "", description_line), type = "chars") > 350) fail("SKILL.md description is too long")
if (length(skill_lines) > 230) fail("SKILL.md is too long for a concise skill entrypoint: ", length(skill_lines), " lines")

helper_text <- readLines(rel("scripts", "paperplot_helpers.R"), warn = FALSE)
module_text <- unlist(lapply(c("design-brief.R", "label-strategy.R", "design-qa.R"), function(x) readLines(rel("scripts", "lib", x), warn = FALSE)))
all_helper_text <- c(helper_text, module_text)
required_helper_patterns <- c(
  "pp_theme <- function",
  "pp_figure_spec <- function",
  "pp_metric_spec <- function",
  "pp_design_brief <- function",
  "pp_validate_design_brief <- function",
  "pp_data_profile <- function",
  "pp_design_plan <- function",
  "pp_label_burden_score <- function",
  "pp_label_strategy_v2 <- function",
  "pp_rank_index_map <- function",
  "pp_write_label_key <- function",
  "pp_visual_budget <- function",
  "pp_qa_design_preflight <- function",
  "pp_qa_manuscript_readiness <- function",
  "pp_save_all <- function",
  "pp_write_metadata <- function",
  "pp_write_qa_report <- function"
)
missing_helper <- required_helper_patterns[!vapply(required_helper_patterns, function(x) any(grepl(x, all_helper_text, fixed = TRUE)), logical(1))]
if (length(missing_helper) > 0) fail("Missing helper patterns: ", paste(missing_helper, collapse = ", "))

forbidden_dependency_patterns <- c(
  "library(PaperPlotR)", "requireNamespace(\"PaperPlotR\"", "PaperPlotR::",
  "theme_lab(", "save_lab(", "save_lab_plot(", "layout_lab(",
  "scale_color_lab(", "scale_fill_lab(", "library(patchwork)", "library(ragg)",
  "library(svglite)", "library(ggrepel)", "library(cli)", "library(rlang)", "library(scales)"
)
check_forbidden <- function(text, path) {
  for (pattern in forbidden_dependency_patterns) {
    if (any(grepl(pattern, text, fixed = TRUE))) fail("Forbidden dependency/API pattern in ", path, ": ", pattern)
  }
}
check_forbidden(all_helper_text, "helper/modules")

template_paths <- file.path(rel("templates"), template_files)
if (length(list.files(rel("templates"), pattern = "\\.R$")) != length(template_files)) fail("Unexpected number of R templates in templates/")
required_template_patterns <- c("library(ggplot2)", "paperplot_helpers.R", "source(helper_path)", "figure_spec <- pp_figure_spec", "metric_spec", "pp_save_all", "pp_write_notes", "pp_write_metadata", "pp_write_qa_report")
for (path in template_paths) {
  rel_path <- sub(paste0("^", root, "/?"), "", path)
  text <- readLines(path, warn = FALSE)
  for (pattern in required_template_patterns) {
    if (!any(grepl(pattern, text, fixed = TRUE))) fail("Missing required pattern in ", rel_path, ": ", pattern)
  }
  check_forbidden(text, rel_path)
  cat("checked template: ", rel_path, "\n", sep = "")
}

for (path in c(
  "figure-design-brief.md",
  "label-burden-strategies.md",
  "manuscript-readiness-rubric.md",
  "publication-visual-standards.md",
  "manuscript-aesthetics-rules.md",
  "nature-like-style-principles.md",
  "image-level-qa.md",
  "old-vs-new-comparison.md",
  "visual-perception-qa.md",
  "old-vs-new-visual-scoring.md",
  "image-level-failure-modes.md",
  "figure-type-quality-rubric.md",
  "cross-backend-workflows.md"
)) {
  text <- readLines(rel("references", path), warn = FALSE)
  if (length(text) < 5) fail("Reference doc too short: ", path)
}

pattern_docs <- c(
  "grouped-bar-errorbar.md",
  "raincloud-violin-jitter.md",
  "scatter-regression-marginal.md",
  "correlation-heatmap.md",
  "pca-pcoa-ordination.md",
  "volcano-ma-enrichment.md",
  "manhattan-genomewide.md",
  "phylo-annotation-ring.md",
  "upset-set-plot.md",
  "circos-chord-sankey.md",
  "multi-panel-manuscript-layout.md",
  "model-validation-figures.md"
)
required_pattern_sections <- c(
  "## Applies When",
  "## Does Not Apply When",
  "## Input Data Structure",
  "## Visual Encoding",
  "## QA Checklist",
  "## Visual QA Focus",
  "## Old-vs-New Criteria"
)
for (path in pattern_docs) {
  text <- readLines(rel("references", "pattern-library", path), warn = FALSE)
  missing_sections <- required_pattern_sections[!vapply(required_pattern_sections, function(pattern) any(grepl(pattern, text, fixed = TRUE)), logical(1))]
  if (length(missing_sections) > 0) fail("Pattern doc missing sections in ", path, ": ", paste(missing_sections, collapse = ", "))
}

cat("paperplot-skills standalone validation passed\n")
