#!/usr/bin/env Rscript
args <- commandArgs(FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  cat("Preview unavailable: install ggplot2 in this R version's library.\n")
  quit(status = 1)
}
source(file.path(dirname(normalizePath(script)), "paperplot_helpers.R"))
result <- pp_check_environment(composite = TRUE)
cat(pp_to_json(result), "\n")
if (!isTRUE(result$production_available)) quit(status = 1)
