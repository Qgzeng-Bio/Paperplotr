#!/usr/bin/env Rscript

fail <- function(...) {
  stop(paste(..., collapse = ""), call. = FALSE)
}

root <- normalizePath(file.path(getwd(), "paperplot-skills"), mustWork = FALSE)
if (!dir.exists(root)) {
  fail("paperplot-skills directory not found from working directory: ", getwd())
}

rel <- function(...) file.path(root, ...)

required_files <- c(
  "SKILL.md",
  "README.md",
  file.path("references", "paperplotr-workflow.md"),
  file.path("references", "figure-quality-checklist.md"),
  file.path("references", "export-and-versioning.md"),
  file.path("references", "template-selection-guide.md"),
  file.path("references", "ai-behavior-rules.md"),
  file.path("references", "boundaries-and-non-goals.md"),
  file.path("templates", "single-panel-template.R"),
  file.path("templates", "multi-panel-template.R"),
  file.path("templates", "comparison-boxplot-template.R"),
  file.path("templates", "violin-dot-template.R"),
  file.path("templates", "correlation-scatter-template.R"),
  file.path("templates", "heatmap-template.R"),
  file.path("templates", "pca-scatter-template.R"),
  file.path("templates", "barplot-template.R"),
  file.path("templates", "notes-template.md"),
  file.path("examples", "example-task-prompts.md"),
  file.path("examples", "example-output-report.md"),
  file.path("examples", "github-ready-checklist.md"),
  file.path("scripts", "validate-skill.R"),
  file.path("scripts", "smoke-test-templates.R")
)

missing_required <- required_files[!file.exists(file.path(root, required_files))]
if (length(missing_required) > 0) {
  fail("Missing required files: ", paste(missing_required, collapse = ", "))
}

skill_path <- rel("SKILL.md")
skill_lines <- readLines(skill_path, warn = FALSE)
if (length(skill_lines) < 5 || !identical(skill_lines[[1]], "---")) {
  fail("SKILL.md must start with --- frontmatter")
}

frontmatter_end <- which(skill_lines[-1] == "---")
if (length(frontmatter_end) == 0) {
  fail("SKILL.md frontmatter closing --- not found")
}
frontmatter_end <- frontmatter_end[[1]] + 1L
frontmatter <- skill_lines[2:(frontmatter_end - 1L)]
body <- skill_lines[(frontmatter_end + 1L):length(skill_lines)]

if (!any(grepl("^name:\\s*paperplot-skills\\s*$", frontmatter))) {
  fail("SKILL.md frontmatter must contain name: paperplot-skills")
}

description_line <- frontmatter[grepl("^description:\\s*", frontmatter)]
if (length(description_line) != 1) {
  fail("SKILL.md frontmatter must contain exactly one description field")
}

description <- sub("^description:\\s*", "", description_line)
description <- gsub("^['\"]|['\"]$", "", description)
if (nchar(description, type = "chars") > 1024) {
  fail("SKILL.md description exceeds 1024 characters")
}
if (length(skill_lines) > 200) {
  fail("SKILL.md is too long for a concise skill entrypoint: ", length(skill_lines), " lines")
}
if (!any(nzchar(trimws(body)))) {
  fail("SKILL.md body is empty")
}

readme_path <- rel("README.md")
readme_text <- readLines(readme_path, warn = FALSE)
required_readme_sections <- c(
  "## Quick Start",
  "## Repository-Local Usage",
  "## How To Validate",
  "## How To Run Smoke Tests",
  "## Template Outputs",
  "## Adapting Templates",
  "## GitHub Readiness Checklist",
  "## Contribution Rules"
)
missing_readme_sections <- required_readme_sections[
  !vapply(required_readme_sections, function(x) any(grepl(x, readme_text, fixed = TRUE)), logical(1))
]
if (length(missing_readme_sections) > 0) {
  fail("README.md is missing required GitHub-ready sections: ", paste(missing_readme_sections, collapse = ", "))
}

template_paths <- list.files(rel("templates"), pattern = "\\.R$", full.names = TRUE)
if (length(template_paths) != 8) {
  fail("Expected 8 R templates, found ", length(template_paths))
}

forbidden_patterns <- c(
  "/Users/",
  "8-VScode",
  "8-Code",
  "quinoa",
  "TRASH",
  "subgenome",
  "ancestry_components"
)

check_contains <- function(text, pattern, path) {
  if (!any(grepl(pattern, text, fixed = TRUE))) {
    fail("Missing required pattern in ", path, ": ", pattern)
  }
}

for (path in template_paths) {
  rel_path <- sub(paste0("^", root, "/?"), "", path)
  text <- readLines(path, warn = FALSE)

  check_contains(text, "library(ggplot2)", rel_path)
  check_contains(text, "library(PaperPlotR)", rel_path)
  check_contains(text, "timestamp", rel_path)
  check_contains(text, "output_stem", rel_path)
  check_contains(text, "notes_path", rel_path)
  check_contains(text, "theme_lab", rel_path)
  check_contains(text, "stop_if_outputs_exist", rel_path)
  check_contains(text, "format_output_files", rel_path)
  if (!any(grepl("save_lab\\(|save_lab_plot\\(", text))) {
    fail("Template must use save_lab() or save_lab_plot(): ", rel_path)
  }
  if (!any(grepl("notes_path|writeLines", text))) {
    fail("Template must write or reserve notes logic: ", rel_path)
  }
  check_contains(text, "file.exists", rel_path)
  check_contains(text, "Refusing to overwrite", rel_path)
  check_contains(text, "file.info", rel_path)

  for (pattern in forbidden_patterns) {
    if (any(grepl(pattern, text, fixed = TRUE))) {
      fail("Forbidden project-specific pattern in ", rel_path, ": ", pattern)
    }
  }
  cat("checked template: ", rel_path, "\n", sep = "")
}

skill_text <- readLines(skill_path, warn = FALSE)
for (pattern in forbidden_patterns) {
  if (any(grepl(pattern, skill_text, fixed = TRUE))) {
    fail("Forbidden project-specific pattern in SKILL.md: ", pattern)
  }
}

reference_text <- unlist(lapply(list.files(rel("references"), full.names = TRUE), readLines, warn = FALSE))
if (any(grepl("use .*domain.*default|default.*domain", reference_text, ignore.case = TRUE))) {
  fail("References appear to make domain-specific dictionaries default behavior")
}

smoke_text <- readLines(rel("scripts", "smoke-test-templates.R"), warn = FALSE)
required_smoke_patterns <- c(
  "tempdir()",
  "single-panel-template.R",
  "multi-panel-template.R",
  "comparison-boxplot-template.R",
  "violin-dot-template.R",
  "correlation-scatter-template.R",
  "heatmap-template.R",
  "pca-scatter-template.R",
  "barplot-template.R",
  "## Output Files",
  "bytes",
  "templates passed smoke tests"
)
missing_smoke_patterns <- required_smoke_patterns[
  !vapply(required_smoke_patterns, function(x) any(grepl(x, smoke_text, fixed = TRUE)), logical(1))
]
if (length(missing_smoke_patterns) > 0) {
  fail("smoke-test-templates.R is missing required patterns: ", paste(missing_smoke_patterns, collapse = ", "))
}

cat("paperplot-skills validation passed\n")
