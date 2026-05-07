#!/usr/bin/env Rscript

fail <- function(...) {
  stop(paste(..., collapse = ""), call. = FALSE)
}

repo_root <- normalizePath(getwd(), mustWork = TRUE)
skill_root <- file.path(repo_root, "paperplot-skills")
template_root <- file.path(skill_root, "templates")

if (!dir.exists(skill_root)) {
  fail("paperplot-skills directory not found from working directory: ", repo_root)
}

template_files <- c(
  "single-panel-template.R",
  "multi-panel-template.R",
  "comparison-boxplot-template.R",
  "violin-dot-template.R",
  "correlation-scatter-template.R",
  "heatmap-template.R",
  "pca-scatter-template.R",
  "barplot-template.R"
)

missing_templates <- template_files[!file.exists(file.path(template_root, template_files))]
if (length(missing_templates) > 0) {
  fail("Missing template files: ", paste(missing_templates, collapse = ", "))
}

r_string <- function(x) {
  paste0('"', gsub('(["\\\\])', '\\\\\\1', x), '"')
}

replace_fixed <- function(text, old, new) {
  gsub(old, new, text, fixed = TRUE)
}

patch_template <- function(template_text, input_path, output_dir) {
  text <- template_text
  text <- replace_fixed(text, 'input_path <- "TODO-input.csv"', paste0("input_path <- ", r_string(input_path)))
  text <- replace_fixed(text, 'output_dir <- "figures"', paste0("output_dir <- ", r_string(output_dir)))
  text <- replace_fixed(text, 'x_col <- "TODO_x"', 'x_col <- "x"')
  text <- replace_fixed(text, 'y_col <- "TODO_y"', 'y_col <- "y"')
  text <- replace_fixed(text, 'group_col <- "TODO_group"', 'group_col <- "group"')
  text <- replace_fixed(text, 'group_col <- NULL', 'group_col <- "group"')
  text <- replace_fixed(text, 'value_col <- "TODO_value"', 'value_col <- "value"')
  text <- replace_fixed(text, 'category_col <- "TODO_category"', 'category_col <- "category"')
  text <- replace_fixed(text, 'error_col <- NULL', 'error_col <- "error"')
  text <- replace_fixed(text, 'pc1_col <- "TODO_PC1"', 'pc1_col <- "pc1"')
  text <- replace_fixed(text, 'pc2_col <- "TODO_PC2"', 'pc2_col <- "pc2"')
  text <- replace_fixed(text, 'x_label <- "TODO x label with units"', 'x_label <- "X value (a.u.)"')
  text <- replace_fixed(text, 'y_label <- "TODO y label with units"', 'y_label <- "Y value (a.u.)"')
  text <- replace_fixed(text, 'pc1_label <- "PC1 (TODO%)"', 'pc1_label <- "PC1 (42%)"')
  text <- replace_fixed(text, 'pc2_label <- "PC2 (18%)"', 'pc2_label <- "PC2 (18%)"')
  if (identical(Sys.getenv("PAPERPLOTR_SMOKE_BASE_DEVICES"), "true")) {
    text <- replace_fixed(
      text,
      'png_device <- if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"',
      'png_device <- "png"'
    )
    text <- replace_fixed(
      text,
      'if (requireNamespace("svglite", quietly = TRUE)) {',
      'if (FALSE && requireNamespace("svglite", quietly = TRUE)) {'
    )
  }
  text
}

make_smoke_data <- function(path) {
  set.seed(20260506)
  n <- 72
  df <- data.frame(
    x = rep(seq_len(12), each = 6),
    y = round(rnorm(n, mean = rep(seq_len(12), each = 6) * 0.25, sd = 0.8), 3),
    group = rep(c("Control", "TreatmentA", "TreatmentB"), length.out = n),
    value = round(rnorm(n, mean = rep(c(0.2, 0.8, 1.1), length.out = n), sd = 0.35), 3),
    category = rep(paste0("Cat", 1:6), length.out = n),
    error = round(runif(n, min = 0.05, max = 0.18), 3),
    pc1 = round(rnorm(n, sd = 2.0), 3),
    pc2 = round(rnorm(n, sd = 1.2), 3),
    sample = paste0("S", seq_len(n)),
    check.names = FALSE
  )
  write.csv(df, path, row.names = FALSE)
}

check_notes <- function(notes_path) {
  notes <- readLines(notes_path, warn = FALSE)
  required <- c("## Output Files", "bytes", "PaperPlotR functions", "preset")
  missing <- required[
    !vapply(required, function(pattern) any(grepl(pattern, notes, fixed = TRUE)), logical(1))
  ]
  if (length(missing) > 0) {
    paste("notes missing:", paste(missing, collapse = ", "))
  } else {
    NA_character_
  }
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

  output <- system2("Rscript", script_path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }

  pdf_files <- list.files(output_dir, pattern = "\\.pdf$", full.names = TRUE)
  png_files <- list.files(output_dir, pattern = "\\.png$", full.names = TRUE)
  notes_files <- list.files(output_dir, pattern = "_notes\\.md$", full.names = TRUE)

  problems <- character()
  if (!identical(status, 0L)) {
    problems <- c(problems, paste("Rscript status", status))
  }
  if (length(pdf_files) < 1) {
    problems <- c(problems, "missing PDF")
  }
  if (length(png_files) < 1) {
    problems <- c(problems, "missing PNG")
  }
  if (length(notes_files) < 1) {
    problems <- c(problems, "missing notes")
  }

  if (length(pdf_files) > 0 && any(file.info(pdf_files)[["size"]] <= 0, na.rm = TRUE)) {
    problems <- c(problems, "empty PDF")
  }
  if (length(png_files) > 0 && any(file.info(png_files)[["size"]] <= 0, na.rm = TRUE)) {
    problems <- c(problems, "empty PNG")
  }
  if (length(notes_files) > 0) {
    notes_problem <- check_notes(notes_files[[1]])
    if (!is.na(notes_problem)) {
      problems <- c(problems, notes_problem)
    }
  }
  if (length(problems) > 0 && length(output) > 0) {
    problems <- c(problems, paste("Rscript output:", paste(tail(output, 8), collapse = " | ")))
  }

  data.frame(
    template = template_name,
    pass = length(problems) == 0,
    pdf = length(pdf_files),
    png = length(png_files),
    notes = length(notes_files),
    detail = if (length(problems) == 0) "ok" else paste(problems, collapse = "; "),
    stringsAsFactors = FALSE
  )
}

work_root <- file.path(tempdir(), paste0("paperplot-skills-smoke-", format(Sys.time(), "%Y%m%d-%H%M%S")))
dir.create(work_root, recursive = TRUE, showWarnings = FALSE)

results <- do.call(
  rbind,
  lapply(template_files, function(template_name) {
    tryCatch(
      run_template(template_name, work_root),
      error = function(e) {
        data.frame(
          template = template_name,
          pass = FALSE,
          pdf = 0L,
          png = 0L,
          notes = 0L,
          detail = conditionMessage(e),
          stringsAsFactors = FALSE
        )
      }
    )
  })
)

print(results, row.names = FALSE)

passed <- sum(results$pass)
total <- nrow(results)
cat(passed, "/", total, " templates passed smoke tests\n", sep = "")
cat("temporary smoke root: ", work_root, "\n", sep = "")

if (passed != total) {
  fail("Template smoke tests failed")
}
