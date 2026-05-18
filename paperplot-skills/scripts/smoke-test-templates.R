#!/usr/bin/env Rscript

fail <- function(...) {
  stop(paste(..., collapse = ""), call. = FALSE)
}

repo_root <- normalizePath(getwd(), mustWork = TRUE)
skill_root <- file.path(repo_root, "paperplot-skills")
template_root <- file.path(skill_root, "templates")
helper_path <- file.path(skill_root, "scripts", "paperplot_helpers.R")
validator_path <- file.path(skill_root, "scripts", "validate-figure-output.R")

if (!dir.exists(skill_root)) fail("paperplot-skills directory not found from working directory: ", repo_root)
if (!file.exists(helper_path)) fail("Missing helper: ", helper_path)
if (!file.exists(validator_path)) fail("Missing output validator: ", validator_path)

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

missing_templates <- template_files[!file.exists(file.path(template_root, template_files))]
if (length(missing_templates) > 0) fail("Missing template files: ", paste(missing_templates, collapse = ", "))

r_string <- function(x) paste0('"', gsub('(["\\\\])', '\\\\\\1', x), '"')
replace_fixed <- function(text, old, new) gsub(old, new, text, fixed = TRUE)

patch_template <- function(template_text, input_path, output_dir) {
  text <- template_text
  text <- replace_fixed(text, 'input_path <- "TODO-input.csv"', paste0("input_path <- ", r_string(input_path)))
  text <- replace_fixed(text, 'input_csv <- "TODO_input.csv"', paste0("input_csv <- ", r_string(input_path)))
  text <- replace_fixed(text, 'output_dir <- "figures"', paste0("output_dir <- ", r_string(output_dir)))
  text <- replace_fixed(text, 'output_dir <- "outputs"', paste0("output_dir <- ", r_string(output_dir)))
  text <- replace_fixed(text, 'x_col <- "TODO_x"', 'x_col <- "x"')
  text <- replace_fixed(text, 'y_col <- "TODO_y"', 'y_col <- "y"')
  text <- replace_fixed(text, 'group_col <- "TODO_group"', 'group_col <- "group"')
  text <- replace_fixed(text, 'group_col <- NULL', 'group_col <- "group"')
  text <- replace_fixed(text, 'value_col <- "TODO_value"', 'value_col <- "value"')
  text <- replace_fixed(text, 'category_col <- "TODO_category"', 'category_col <- "category"')
  text <- replace_fixed(text, 'error_col <- NULL', 'error_col <- "error"')
  text <- replace_fixed(text, 'pc1_col <- "TODO_PC1"', 'pc1_col <- "pc1"')
  text <- replace_fixed(text, 'pc2_col <- "TODO_PC2"', 'pc2_col <- "pc2"')
  text <- replace_fixed(text, 'panel_col <- "TODO_panel"', 'panel_col <- "panel"')
  text <- replace_fixed(text, 'sample_col <- "TODO_sample"', 'sample_col <- "sample"')
  text <- replace_fixed(text, 'paired_id_col <- "TODO_sample"', 'paired_id_col <- "sample"')
  text <- replace_fixed(text, 'condition_col <- "TODO_group"', 'condition_col <- "group"')
  text <- replace_fixed(text, 'metric_col <- "TODO_metric"', 'metric_col <- "metric"')
  text <- replace_fixed(text, 'mode_col <- "TODO_metric"', 'mode_col <- "metric"')
  text <- replace_fixed(text, 'unit_col <- "TODO_unit"', 'unit_col <- "unit"')
  text <- replace_fixed(text, 'score_col <- "TODO_score"', 'score_col <- "score"')
  text <- replace_fixed(text, 'gene_col <- "TODO_gene"', 'gene_col <- "gene"')
  text <- replace_fixed(text, 'log2fc_col <- "TODO_log2fc"', 'log2fc_col <- "log2fc"')
  text <- replace_fixed(text, 'padj_col <- "TODO_padj"', 'padj_col <- "padj"')
  text <- replace_fixed(text, 'base_mean_col <- "TODO_base_mean"', 'base_mean_col <- "base_mean"')
  text <- replace_fixed(text, 'term_col <- "TODO_term"', 'term_col <- "term"')
  text <- replace_fixed(text, 'ratio_col <- "TODO_ratio"', 'ratio_col <- "ratio"')
  text <- replace_fixed(text, 'qvalue_col <- "TODO_qvalue"', 'qvalue_col <- "qvalue"')
  text <- replace_fixed(text, 'count_col <- "TODO_count"', 'count_col <- "count"')
  text <- replace_fixed(text, 'x_label <- "TODO x label with units"', 'x_label <- "X value (a.u.)"')
  text <- replace_fixed(text, 'y_label <- "TODO y label with units"', 'y_label <- "Y value (a.u.)"')
  text <- replace_fixed(text, 'y_label <- "TODO value with units"', 'y_label <- "Value (a.u.)"')
  text <- replace_fixed(text, 'y_label <- "TODO value"', 'y_label <- "Value (a.u.)"')
  text <- replace_fixed(text, 'value_label <- "TODO value"', 'value_label <- "Value (%)"')
  text <- replace_fixed(text, 'pc1_label <- "PC1 (TODO%)"', 'pc1_label <- "PC1 (42%)"')
  text <- replace_fixed(text, 'pc2_label <- "PC2 (TODO%)"', 'pc2_label <- "PC2 (18%)"')
  text
}

make_smoke_data <- function(path) {
  set.seed(20260508)
  samples <- paste0("S", sprintf("%02d", seq_len(12)))
  metrics <- c("QV", "Contig N50", "Gaps", "BUSCO complete", "Telomeres", "Integrated quality")
  grid <- expand.grid(sample = samples, metric = metrics, stringsAsFactors = FALSE)
  grid$group <- rep(c("Reference", "New assembly"), length.out = nrow(grid))
  grid$unit <- c(QV = "QV", `Contig N50` = "Mb", Gaps = "log10", `BUSCO complete` = "%", Telomeres = "count", `Integrated quality` = "%")[grid$metric]
  metric_base <- c(QV = 70, `Contig N50` = 55, Gaps = 1.1, `BUSCO complete` = 99, Telomeres = 32, `Integrated quality` = 82)
  grid$value <- round(metric_base[grid$metric] + rnorm(nrow(grid), sd = 2.5), 3)
  score_map <- setNames(round(seq(95, 72, length.out = length(samples)) + rnorm(length(samples), sd = 1.2), 3), samples)
  grid$score <- unname(score_map[grid$sample])
  grid$x <- rep(seq_along(samples), times = length(metrics))
  grid$y <- grid$value
  grid$category <- rep(paste0("Cat", seq_len(6)), length.out = nrow(grid))
  grid$error <- round(runif(nrow(grid), min = 0.05, max = 0.22), 3)
  grid$pc1 <- round(rnorm(nrow(grid), sd = 2.0), 3)
  grid$pc2 <- round(rnorm(nrow(grid), sd = 1.2), 3)
  grid$panel <- grid$metric
  grid$gene <- paste0("Gene", sprintf("%04d", seq_len(nrow(grid))))
  grid$log2fc <- round(rnorm(nrow(grid), sd = 1.4), 3)
  grid$pvalue <- pmax(runif(nrow(grid), min = 0.0005, max = 0.9), .Machine$double.xmin)
  grid$padj <- p.adjust(grid$pvalue, method = "BH")
  grid$base_mean <- round(exp(rnorm(nrow(grid), mean = 4.2, sd = 1.0)), 3)
  grid$term <- paste("Enriched term", rep(seq_len(24), length.out = nrow(grid)))
  grid$ratio <- round(runif(nrow(grid), min = 0.05, max = 0.65), 3)
  grid$qvalue <- p.adjust(runif(nrow(grid), min = 0.0005, max = 0.5), method = "BH")
  grid$count <- sample(5:80, nrow(grid), replace = TRUE)
  write.csv(grid, path, row.names = FALSE)
}

check_notes <- function(notes_path) {
  notes <- readLines(notes_path, warn = FALSE)
  required <- c("## Output Files", "bytes", "## Design Decisions", "## QA Gate", "## Known Limitations", "## Label Strategy", "## Information Moved Out Of The Visible Figure")
  missing <- required[!vapply(required, function(pattern) any(grepl(pattern, notes, fixed = TRUE)), logical(1))]
  if (length(missing) > 0) paste("notes missing:", paste(missing, collapse = ", ")) else NA_character_
}

check_metadata_contract <- function(metadata_path) {
  metadata <- paste(readLines(metadata_path, warn = FALSE), collapse = "\n")
  required <- c("\"design_brief\"", "\"design_plan\"", "\"label_strategy\"", "\"visual_budget\"")
  missing <- required[!vapply(required, function(pattern) grepl(pattern, metadata, fixed = TRUE), logical(1))]
  if (length(missing) > 0) paste("metadata missing:", paste(missing, collapse = ", ")) else NA_character_
}

run_template <- function(template_name, work_root) {
  template_path <- file.path(template_root, template_name)
  template_id <- sub("\\.R$", "", template_name)
  template_work <- file.path(work_root, template_id)
  output_dir <- file.path(template_work, "outputs")
  input_path <- file.path(template_work, "smoke-data.csv")
  script_path <- file.path(template_work, template_name)

  dir.create(template_work, recursive = TRUE, showWarnings = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  make_smoke_data(input_path)

  patched <- patch_template(readLines(template_path, warn = FALSE), input_path, output_dir)
  writeLines(patched, script_path)

  output <- system2("Rscript", script_path, stdout = TRUE, stderr = TRUE, env = paste0("PAPERPLOT_HELPER=", helper_path))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L

  pdf_files <- list.files(output_dir, pattern = "\\.pdf$", full.names = TRUE)
  png_files <- list.files(output_dir, pattern = "\\.png$", full.names = TRUE)
  notes_files <- list.files(output_dir, pattern = "_notes\\.md$", full.names = TRUE)
  metadata_files <- list.files(output_dir, pattern = "_metadata\\.json$", full.names = TRUE)
  qa_files <- list.files(output_dir, pattern = "_qa\\.md$", full.names = TRUE)

  problems <- character()
  if (!identical(status, 0L)) problems <- c(problems, paste("Rscript status", status))
  if (length(pdf_files) < 1) problems <- c(problems, "missing PDF")
  if (length(png_files) < 1) problems <- c(problems, "missing PNG")
  if (length(notes_files) < 1) problems <- c(problems, "missing notes")
  if (length(metadata_files) < 1) problems <- c(problems, "missing metadata")
  if (length(qa_files) < 1) problems <- c(problems, "missing QA")

  for (files in list(pdf_files, png_files, notes_files, metadata_files, qa_files)) {
    if (length(files) > 0 && any(file.info(files)[["size"]] <= 0, na.rm = TRUE)) problems <- c(problems, "empty output file")
  }
  if (length(notes_files) > 0) {
    notes_problem <- check_notes(notes_files[[1]])
    if (!is.na(notes_problem)) problems <- c(problems, notes_problem)
  }
  if (length(metadata_files) > 0) {
    metadata_problem <- check_metadata_contract(metadata_files[[1]])
    if (!is.na(metadata_problem)) problems <- c(problems, metadata_problem)
  }
  if (length(problems) == 0) {
    validation <- system2("Rscript", c(validator_path, output_dir), stdout = TRUE, stderr = TRUE)
    validation_status <- attr(validation, "status")
    if (is.null(validation_status)) validation_status <- 0L
    if (!identical(validation_status, 0L)) problems <- c(problems, paste("output validator status", validation_status), paste(validation, collapse = " | "))
  }
  if (length(problems) > 0 && length(output) > 0) problems <- c(problems, paste("Rscript output:", paste(tail(output, 8), collapse = " | ")))

  data.frame(
    template = template_name,
    pass = length(problems) == 0,
    pdf = length(pdf_files),
    png = length(png_files),
    notes = length(notes_files),
    metadata = length(metadata_files),
    qa = length(qa_files),
    detail = if (length(problems) == 0) "ok" else paste(problems, collapse = "; "),
    output_dir = output_dir,
    stringsAsFactors = FALSE
  )
}

work_root <- file.path("/tmp", paste0("paperplot-skills-smoke-", format(Sys.time(), "%Y%m%d-%H%M%S")))
dir.create(work_root, recursive = TRUE, showWarnings = FALSE)

results <- do.call(rbind, lapply(template_files, function(template_name) {
  tryCatch(run_template(template_name, work_root), error = function(e) {
    data.frame(template = template_name, pass = FALSE, pdf = 0L, png = 0L, notes = 0L, metadata = 0L, qa = 0L, detail = conditionMessage(e), output_dir = NA_character_, stringsAsFactors = FALSE)
  })
}))

print(results, row.names = FALSE)

passed <- sum(results$pass)
total <- nrow(results)
cat(passed, "/", total, " templates passed smoke tests\n", sep = "")
cat("temporary smoke root: ", work_root, "\n", sep = "")

if (passed != total) fail("Template smoke tests failed")
