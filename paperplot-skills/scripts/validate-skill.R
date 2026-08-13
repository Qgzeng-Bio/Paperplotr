#!/usr/bin/env Rscript

fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)

root <- normalizePath(file.path(getwd(), "paperplot-skills"), mustWork = FALSE)
if (!dir.exists(root)) fail("paperplot-skills directory not found from working directory: ", getwd())
rel <- function(...) file.path(root, ...)
parser_path <- rel("scripts", "lib", "contract-parsers.R")
if (!file.exists(parser_path)) fail("Missing contract parser: ", parser_path)
source(parser_path, local = TRUE)

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
  "enrichment-dotplot-template.R",
  "model-validation-composite-template.R"
)

required_files <- c(
  "SKILL.md",
  file.path("agents", "openai.yaml"),
  file.path("scripts", "paperplot_helpers.R"),
  file.path("scripts", "validate-skill.R"),
  file.path("scripts", "smoke-test-templates.R"),
  file.path("scripts", "validate-figure-output.R"),
  file.path("scripts", "test-contract-regressions.R"),
  file.path("scripts", "visual-qa-report.R"),
  file.path("scripts", "visual-qa-rendered-image.py"),
  file.path("scripts", "compare-old-new-figures.py"),
  file.path("scripts", "index-replica-patterns.py"),
  file.path("scripts", "calibrate-visual-qa.py"),
  file.path("scripts", "run-visual-pressure-scenarios.py"),
  file.path("scripts", "validate-qa-coverage.py"),
  file.path("scripts", "lib", "design-brief.R"),
  file.path("scripts", "lib", "label-strategy.R"),
  file.path("scripts", "lib", "design-qa.R"),
  file.path("scripts", "lib", "contract-parsers.R"),
  file.path("references", "figure-design-brief.md"),
  file.path("references", "label-burden-strategies.md"),
  file.path("references", "main-vs-supplement-density.md"),
  file.path("references", "manuscript-readiness-rubric.md"),
  file.path("references", "visual-qa-gates.md"),
  file.path("references", "template-selection-guide.md"),
  file.path("references", "metadata-schema.md"),
  file.path("references", "optional-dependencies.md"),
  file.path("references", "publication-visual-standards.md"),
  file.path("references", "journal-specs-matrix.md"),
  file.path("references", "multi-panel-layout-rules.md"),
  file.path("references", "bioinformatics-figure-validation.md"),
  file.path("references", "manuscript-aesthetics-rules.md"),
  file.path("references", "nature-like-style-principles.md"),
  file.path("references", "image-level-qa.md"),
  file.path("references", "nature-figure-guardrails.md"),
  file.path("references", "old-vs-new-comparison.md"),
  file.path("references", "visual-perception-qa.md"),
  file.path("references", "visual-qa-calibration-summary.md"),
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

frontmatter_contract <- pp_parse_skill_frontmatter(rel("SKILL.md"))
skill_lines <- frontmatter_contract$lines
frontmatter <- frontmatter_contract$values
if (!identical(frontmatter$name, "paperplot-skills")) fail("SKILL.md frontmatter must contain name: paperplot-skills")
if (!is.character(frontmatter$description) || length(frontmatter$description) != 1L || !nzchar(trimws(frontmatter$description))) fail("SKILL.md frontmatter must contain exactly one non-empty description field")
if (nchar(frontmatter$description, type = "chars") > 350) fail("SKILL.md description is too long")
if ("disable-model-invocation" %in% names(frontmatter)) fail("paperplot-skills must remain auto-discoverable for Bioflow delegation")
if (length(skill_lines) > 230) fail("SKILL.md is too long for a concise skill entrypoint: ", length(skill_lines), " lines")

skill_text <- paste(skill_lines, collapse = "\n")
reference_tokens <- regmatches(skill_text, gregexpr("`references/[^`]+\\.md`", skill_text, perl = TRUE))[[1]]
reference_tokens <- unique(gsub("`", "", reference_tokens, fixed = TRUE))
for (token in reference_tokens) {
  matches <- if (grepl("*", token, fixed = TRUE)) Sys.glob(file.path(root, token)) else file.path(root, token)
  if (length(matches) == 0 || !all(file.exists(matches))) fail("SKILL.md references missing resource: ", token)
}

helper_text <- readLines(rel("scripts", "paperplot_helpers.R"), warn = FALSE)
module_text <- unlist(lapply(c("design-brief.R", "label-strategy.R", "design-qa.R"), function(x) readLines(rel("scripts", "lib", x), warn = FALSE)))
all_helper_text <- c(helper_text, module_text)
required_helper_patterns <- c(
  "pp_theme <- function",
  "pp_text_size_mm <- function",
  "pp_journal_profile <- function",
  "pp_profile_for_preset <- function",
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
  "pp_cognitive_load_review <- function",
  "pp_bioinformatics_validation <- function",
  "pp_qa_cognitive_load_review <- function",
  "pp_qa_bioinformatics_validation <- function",
  "pp_qa_design_preflight <- function",
  "pp_qa_manuscript_readiness <- function",
  "pp_save_all <- function",
  "pp_write_metadata <- function",
  "pp_write_qa_report <- function"
)
missing_helper <- required_helper_patterns[!vapply(required_helper_patterns, function(x) any(grepl(x, all_helper_text, fixed = TRUE)), logical(1))]
if (length(missing_helper) > 0) fail("Missing helper patterns: ", paste(missing_helper, collapse = ", "))

helper_blob <- paste(helper_text, collapse = "\n")
for (pattern in c(
  "pp_helper_version <- \"standalone-0.5.0\"",
  "pp_profile_last_checked <- \"2026-08-12\"",
  "pp_validate_profile_geometry <- function",
  "pp_write_plotting_data <- function",
  "pp_bioinformatics_scaffold <- function",
  "pp_write_review_sidecar <- function",
  "pp_figure_spec_schema_version <- 2L",
  "pp_theme <- function(base_size = 9",
  "pp_theme base_size must be one numeric value at or above the 6 pt absolute floor",
  "target_text_pt = 9",
  "compact_text_pt = 8",
  "panel_label_pt = 12",
  "min_text_pt = 6",
  "general_scientific = list(",
  "nature_like = list(",
  "nature_communications = list(",
  "cell_press = list(",
  "medical_radiology = list("
)) {
  if (!grepl(pattern, helper_blob, fixed = TRUE)) fail("Typography/journal helper contract missing: ", pattern)
}

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
  text_blob <- paste(text, collapse = "\n")
  for (pattern in required_template_patterns) {
    if (!any(grepl(pattern, text, fixed = TRUE))) fail("Missing required pattern in ", rel_path, ": ", pattern)
  }
  if (grepl("pp_theme\\(base_size\\s*=\\s*[0-8](?:\\D|$)", text_blob, perl = TRUE)) fail("Template uses below-target pp_theme base size in ", rel_path)
  if (grepl("geom_(text|label)\\s*\\(", text_blob, perl = TRUE) && !grepl("pp_text_size_mm\\(", text_blob, perl = TRUE)) fail("Template text geometry must use explicit pt-to-mm conversion in ", rel_path)
  check_forbidden(text, rel_path)
  cat("checked template: ", rel_path, "\n", sep = "")
}

bio_template_files <- c(
  "bio-genome-quality-overview-template.R",
  "bio-duplication-mode-comparison-template.R",
  "volcano-plot-template.R",
  "ma-plot-template.R",
  "enrichment-dotplot-template.R"
)
for (path in bio_template_files) {
  text <- paste(readLines(rel("templates", path), warn = FALSE), collapse = "\n")
  if (!grepl('analysis_domain = "bioinformatics"', text, fixed = TRUE)) fail("Bioinformatics template must declare analysis_domain in ", path)
}

output_validator_text <- paste(readLines(rel("scripts", "validate-figure-output.R"), warn = FALSE), collapse = "\n")
for (pattern in c("--manuscript-ready", "bioinformatics_validation", "compact_text_pt", "panel_label_pt", "metadata_files <- find_files", "validate_visual_qa", "validate_old_vs_new", "input_md5", "visual_qa_schema_version", "comparison_schema_version", "analysis_fingerprint", "replay_visual_evidence", "replay_comparison_evidence", "required_qa_gates", "journal_profile_snapshot", "crc32_raw", "parse_qa_report")) {
  if (!grepl(pattern, output_validator_text, fixed = TRUE)) fail("Output validator contract missing: ", pattern)
}

for (path in c(
  "figure-design-brief.md",
  "label-burden-strategies.md",
  "manuscript-readiness-rubric.md",
  "publication-visual-standards.md",
  "journal-specs-matrix.md",
  "multi-panel-layout-rules.md",
  "bioinformatics-figure-validation.md",
  "manuscript-aesthetics-rules.md",
  "nature-like-style-principles.md",
  "image-level-qa.md",
  "nature-figure-guardrails.md",
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

legacy_typography_patterns <- c("5-7 pt", "5–7 pt", "5-6 pt", "5–6 pt", "7-8 pt base", "7–8 pt base")
active_typography_docs <- c(
  "publication-visual-standards.md",
  "journal-specs-matrix.md",
  "manuscript-aesthetics-rules.md",
  "color-and-style-policy.md",
  file.path("pattern-library", "grouped-bar-errorbar.md"),
  file.path("pattern-library", "correlation-heatmap.md"),
  file.path("pattern-library", "volcano-ma-enrichment.md"),
  file.path("pattern-library", "multi-panel-manuscript-layout.md")
)
for (path in active_typography_docs) {
  text <- paste(readLines(rel("references", path), warn = FALSE), collapse = "\n")
  hits <- legacy_typography_patterns[vapply(legacy_typography_patterns, function(pattern) grepl(pattern, text, fixed = TRUE), logical(1))]
  if (length(hits) > 0) fail("Legacy typography guidance remains in ", path, ": ", paste(hits, collapse = ", "))
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
