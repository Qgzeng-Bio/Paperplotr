#!/usr/bin/env Rscript

fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)
repo_root <- normalizePath(getwd(), mustWork = TRUE)
skill_root <- file.path(repo_root, "paperplot-skills")
template_root <- file.path(skill_root, "templates")
helper_path <- file.path(skill_root, "scripts", "paperplot_helpers.R")
score_script <- file.path(skill_root, "scripts", "score-pressure-scenario.R")
scenario_file <- file.path(skill_root, "pressure-scenarios", "scenario-specs.R")
if (!file.exists(helper_path)) fail("Missing helper: ", helper_path)
if (!file.exists(score_script)) fail("Missing scorer: ", score_script)
source(scenario_file)

r_string <- function(x) paste0('"', gsub('(["\\\\])', '\\\\\1', x), '"')
replace_fixed <- function(text, old, new) gsub(old, new, text, fixed = TRUE)

patch_template <- function(template_text, input_path, output_dir) {
  text <- template_text
  text <- replace_fixed(text, 'input_path <- "TODO-input.csv"', paste0("input_path <- ", r_string(input_path)))
  text <- replace_fixed(text, 'input_csv <- "TODO_input.csv"', paste0("input_csv <- ", r_string(input_path)))
  text <- replace_fixed(text, 'output_dir <- "figures"', paste0("output_dir <- ", r_string(output_dir)))
  text <- replace_fixed(text, 'output_dir <- "outputs"', paste0("output_dir <- ", r_string(output_dir)))
  replacements <- list(
    'sample_col <- "TODO_sample"' = 'sample_col <- "sample"',
    'group_col <- "TODO_group"' = 'group_col <- "group"',
    'metric_col <- "TODO_metric"' = 'metric_col <- "metric"',
    'mode_col <- "TODO_metric"' = 'mode_col <- "metric"',
    'unit_col <- "TODO_unit"' = 'unit_col <- "unit"',
    'score_col <- "TODO_score"' = 'score_col <- "score"',
    'value_col <- "TODO_value"' = 'value_col <- "value"',
    'gene_col <- "TODO_gene"' = 'gene_col <- "gene"',
    'log2fc_col <- "TODO_log2fc"' = 'log2fc_col <- "log2fc"',
    'padj_col <- "TODO_padj"' = 'padj_col <- "padj"',
    'base_mean_col <- "TODO_base_mean"' = 'base_mean_col <- "base_mean"',
    'term_col <- "TODO_term"' = 'term_col <- "term"',
    'ratio_col <- "TODO_ratio"' = 'ratio_col <- "ratio"',
    'qvalue_col <- "TODO_qvalue"' = 'qvalue_col <- "qvalue"',
    'count_col <- "TODO_count"' = 'count_col <- "count"'
  )
  for (old in names(replacements)) text <- replace_fixed(text, old, replacements[[old]])
  text
}

make_pressure_data <- function(path) {
  set.seed(20260510)
  samples <- paste0("LongSampleName_", sprintf("%02d", seq_len(36)), "_assembly")
  metrics <- c("QV", "Contig N50", "Gaps", "BUSCO complete", "Telomeres", "Integrated quality")
  grid <- expand.grid(sample = samples, metric = metrics, stringsAsFactors = FALSE)
  grid$group <- rep(c("LM", "nonLM"), length.out = nrow(grid))
  grid$unit <- c(QV = "QV", `Contig N50` = "Mb", Gaps = "count", `BUSCO complete` = "%", Telomeres = "count", `Integrated quality` = "%")[grid$metric]
  base <- c(QV = 70, `Contig N50` = 55, Gaps = 12, `BUSCO complete` = 98, Telomeres = 30, `Integrated quality` = 82)
  grid$value <- round(base[grid$metric] + rnorm(nrow(grid), sd = 3), 3)
  score_map <- setNames(round(seq(98, 55, length.out = length(samples)) + rnorm(length(samples), sd = 2), 3), samples)
  grid$score <- unname(score_map[grid$sample])
  grid$x <- rep(seq_along(samples), times = length(metrics))
  grid$y <- grid$value
  grid$category <- rep(paste0("Category", seq_len(8)), length.out = nrow(grid))
  grid$gene <- paste0("Gene", sprintf("%05d", seq_len(nrow(grid))))
  grid$log2fc <- round(rnorm(nrow(grid), sd = 1.5), 3)
  grid$pvalue <- pmax(runif(nrow(grid), min = 0.0001, max = 0.95), .Machine$double.xmin)
  grid$padj <- p.adjust(grid$pvalue, method = "BH")
  grid$base_mean <- round(exp(rnorm(nrow(grid), mean = 4.3, sd = 1.1)), 3)
  grid$term <- paste("Long enriched biological process", rep(seq_len(40), length.out = nrow(grid)))
  grid$ratio <- round(runif(nrow(grid), min = 0.03, max = 0.75), 3)
  grid$qvalue <- p.adjust(runif(nrow(grid), min = 0.0001, max = 0.45), method = "BH")
  grid$count <- sample(5:120, nrow(grid), replace = TRUE)
  write.csv(grid, path, row.names = FALSE)
}

run_one <- function(spec, root) {
  scenario <- spec$scenario
  template <- spec$template
  work_dir <- file.path(root, scenario)
  output_dir <- file.path(work_dir, "outputs")
  input_path <- file.path(work_dir, "pressure-data.csv")
  script_path <- file.path(work_dir, template)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  make_pressure_data(input_path)
  patched <- patch_template(readLines(file.path(template_root, template), warn = FALSE), input_path, output_dir)
  writeLines(patched, script_path)
  output <- system2("Rscript", script_path, stdout = TRUE, stderr = TRUE, env = paste0("PAPERPLOT_HELPER=", helper_path))
  status <- attr(output, "status"); if (is.null(status)) status <- 0L
  if (!identical(status, 0L)) return(data.frame(scenario = scenario, pass = FALSE, detail = paste(tail(output, 8), collapse = " | "), output_dir = output_dir, stringsAsFactors = FALSE))
  score <- system2("Rscript", c(score_script, scenario, output_dir), stdout = TRUE, stderr = TRUE)
  score_status <- attr(score, "status"); if (is.null(score_status)) score_status <- 0L
  data.frame(scenario = scenario, pass = identical(score_status, 0L), detail = if (identical(score_status, 0L)) "ok" else paste(score, collapse = " | "), output_dir = output_dir, stringsAsFactors = FALSE)
}

root <- file.path("/tmp", paste0("paperplot-pressure-", format(Sys.time(), "%Y%m%d-%H%M%S")))
dir.create(root, recursive = TRUE, showWarnings = FALSE)
scenarios <- pp_pressure_scenarios()
results <- do.call(rbind, lapply(seq_len(nrow(scenarios)), function(i) run_one(scenarios[i, ], root)))
print(results, row.names = FALSE)
cat(sum(results$pass), "/", nrow(results), " pressure scenarios passed\n", sep = "")
cat("temporary pressure root: ", root, "\n", sep = "")
if (!all(results$pass)) fail("Pressure scenarios failed")
