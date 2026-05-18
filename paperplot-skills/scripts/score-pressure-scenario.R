#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript score-pressure-scenario.R <scenario> <output_dir>", call. = FALSE)
scenario <- args[[1]]
output_dir <- args[[2]]
metadata_files <- list.files(output_dir, pattern = "_metadata\\.json$", full.names = TRUE)
if (length(metadata_files) < 1) stop("No metadata file found in ", output_dir, call. = FALSE)
metadata <- paste(readLines(metadata_files[[1]], warn = FALSE), collapse = "\n")
label_key_files <- list.files(output_dir, pattern = "_label_key\\.csv$", full.names = TRUE)

has_all <- function(patterns) all(vapply(patterns, function(x) grepl(x, metadata, fixed = TRUE), logical(1)))
pass <- switch(
  scenario,
  "quinoa-genome-quality" = length(label_key_files) >= 1 && has_all(c("rank_index_key_labels", "bio quality rank", "label_key")),
  "dense-sample-labels" = length(label_key_files) >= 1 && has_all(c("rank_index_key_labels", "label_key")),
  "volcano-selected-labels" = has_all(c("selected_extreme_labels", "thresholds", "volcano")),
  "enrichment-top-terms" = has_all(c("top_term_labels_visible", "max_terms", "q-value")),
  "duplication-panel-hierarchy" = has_all(c("panel_hierarchy", "bio_duplication_mode_four_panel", "duplication")),
  FALSE
)
if (!pass) stop("Pressure scenario failed: ", scenario, call. = FALSE)
cat("pressure scenario passed: ", scenario, "\n", sep = "")
