#!/usr/bin/env Rscript

fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) fail("Usage: Rscript paperplot-skills/scripts/validate-figure-output.R <output_dir>")
output_dir <- normalizePath(args[[1]], mustWork = FALSE)
if (!dir.exists(output_dir)) fail("Output directory not found: ", output_dir)

find_files <- function(pattern) list.files(output_dir, pattern = pattern, full.names = TRUE, recursive = TRUE)

pdf_files <- find_files("\\.pdf$")
png_files <- find_files("\\.png$")
notes_files <- find_files("_notes\\.md$")
metadata_files <- find_files("_metadata\\.json$")
qa_files <- find_files("_qa\\.md$")
label_key_files <- find_files("_label_key\\.csv$")

check_nonempty <- function(files, label) {
  if (length(files) < 1) fail("Missing ", label, " output")
  sizes <- file.info(files)[["size"]]
  if (any(is.na(sizes) | sizes <= 0)) fail("Empty ", label, " output: ", paste(files[is.na(sizes) | sizes <= 0], collapse = ", "))
}

check_nonempty(pdf_files, "PDF")
check_nonempty(png_files, "PNG")
check_nonempty(notes_files, "notes")
check_nonempty(metadata_files, "metadata JSON")
check_nonempty(qa_files, "QA report")

metadata_text <- paste(readLines(metadata_files[[1]], warn = FALSE), collapse = "\n")
metadata_keys <- c("figure_id", "template_id", "backend", "export", "layout", "style", "palette", "qa", "design_brief", "design_plan", "label_strategy", "visual_budget")
missing_metadata <- metadata_keys[!vapply(metadata_keys, function(x) grepl(paste0('"', x, '"'), metadata_text, fixed = TRUE), logical(1))]
if (length(missing_metadata) > 0) fail("metadata JSON missing keys: ", paste(missing_metadata, collapse = ", "))

if (grepl("rank_index", metadata_text, fixed = TRUE) && length(label_key_files) < 1 && !grepl('"label_key"', metadata_text, fixed = TRUE)) {
  fail("rank-index strategy requires a label key sidecar or metadata label_key entry")
}

notes_text <- paste(readLines(notes_files[[1]], warn = FALSE), collapse = "\n")
notes_sections <- c("Scientific", "Design", "Label", "Palette", "Known", "Files")
missing_notes <- notes_sections[!vapply(notes_sections, function(x) grepl(x, notes_text, fixed = TRUE), logical(1))]
if (length(missing_notes) > 0) fail("notes missing design sections containing: ", paste(missing_notes, collapse = ", "))

qa_text <- paste(readLines(qa_files[[1]], warn = FALSE), collapse = "\n")
if (!grepl("overall status", qa_text, fixed = TRUE)) fail("QA report missing overall status")

cat("figure output validation passed\n")
cat("output directory: ", output_dir, "\n", sep = "")
cat("pdf: ", length(pdf_files), ", png: ", length(png_files), ", notes: ", length(notes_files), ", metadata: ", length(metadata_files), ", qa: ", length(qa_files), ", label_key: ", length(label_key_files), "\n", sep = "")
