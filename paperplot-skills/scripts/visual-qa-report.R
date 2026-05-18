#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: Rscript visual-qa-report.R <output_dir>", call. = FALSE)
output_dir <- normalizePath(args[[1]], mustWork = TRUE)

read_png_dims <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  sig <- readBin(con, "raw", n = 8)
  if (length(sig) != 8 || !identical(as.integer(sig), c(137, 80, 78, 71, 13, 10, 26, 10))) return(c(width = NA_integer_, height = NA_integer_))
  readBin(con, "integer", n = 1, size = 4, endian = "big")
  chunk <- rawToChar(readBin(con, "raw", n = 4))
  if (!identical(chunk, "IHDR")) return(c(width = NA_integer_, height = NA_integer_))
  width <- readBin(con, "integer", n = 1, size = 4, endian = "big")
  height <- readBin(con, "integer", n = 1, size = 4, endian = "big")
  c(width = width, height = height)
}

pdf_files <- list.files(output_dir, pattern = "\\.pdf$", full.names = TRUE)
png_files <- list.files(output_dir, pattern = "\\.png$", full.names = TRUE)
metadata_files <- list.files(output_dir, pattern = "_metadata\\.json$", full.names = TRUE)
qa_files <- list.files(output_dir, pattern = "_qa\\.md$", full.names = TRUE)
visual_qa_files <- list.files(output_dir, pattern = "^visual_qa\\.json$", full.names = TRUE)

if (length(pdf_files) < 1) warning("No PDF found in output directory.")
if (length(png_files) < 1) warning("No PNG found in output directory.")

png_lines <- if (length(png_files) > 0) {
  unlist(lapply(png_files, function(path) {
    dims <- read_png_dims(path)
    size <- file.info(path)$size
    c(
      paste0("- file: ", basename(path)),
      paste0("  - pixels: ", dims[["width"]], " x ", dims[["height"]]),
      paste0("  - bytes: ", size)
    )
  }))
} else {
  "- No PNG preview found."
}

pdf_lines <- if (length(pdf_files) > 0) {
  paste0("- ", basename(pdf_files), " (", file.info(pdf_files)$size, " bytes)")
} else {
  "- No PDF vector output found."
}

report_path <- file.path(output_dir, paste0("visual_qa_report_", format(Sys.time(), "%Y%m%d-%H%M%S"), ".md"))
lines <- c(
  "# Rendered figure visual QA report",
  "",
  "## Output directory",
  paste0("- ", output_dir),
  "",
  "## PDF files",
  pdf_lines,
  "",
  "## PNG preview dimensions",
  png_lines,
  "",
  "## Sidecar contract",
  paste0("- metadata files: ", length(metadata_files)),
  paste0("- QA report files: ", length(qa_files)),
  paste0("- deterministic visual QA files: ", length(visual_qa_files)),
  "",
  "## Deterministic Visual QA",
  "",
  if (length(visual_qa_files) > 0) c(
    paste0("- source: ", basename(visual_qa_files[[1]])),
    "```json",
    readLines(visual_qa_files[[1]], warn = FALSE),
    "```"
  ) else c(
    "- Not run. Use:",
    "",
    "```bash",
    "python3 scripts/visual-qa-rendered-image.py <image_or_output_dir> --out <qa_dir>",
    "```"
  ),
  "",
  "## Manual image-level QA checklist",
  "",
  "Mark each item after inspecting the actual rendered PNG/PDF preview:",
  "",
  "- [ ] Text remains readable at final target width.",
  "- [ ] No axis text, facet strips, labels, or legends overlap.",
  "- [ ] Primary scientific message is visible within 3-5 seconds.",
  "- [ ] Legend does not dominate the data region.",
  "- [ ] Panel hierarchy is clear and panel spacing is controlled.",
  "- [ ] Colors are functional, consistent, and color-blind safer.",
  "- [ ] Figure remains interpretable in grayscale or black-white print when needed.",
  "- [ ] Axis labels include variables, units, transforms, and denominators where needed.",
  "- [ ] Statistical marks, intervals, n, and tests are clear or documented in notes/metadata.",
  "- [ ] Output looks like a manuscript figure, not a diagnostic dump.",
  "",
  "## Old-vs-new comparison",
  "",
  "Complete this section when an old figure exists:",
  "",
  "| item | old | new | verdict |",
  "|---|---|---|---|",
  "| message clarity |  |  |  |",
  "| label burden |  |  |  |",
  "| legend burden |  |  |  |",
  "| panel hierarchy |  |  |  |",
  "| statistical expression |  |  |  |",
  "| color semantics |  |  |  |",
  "| visual rhythm |  |  |  |",
  "| manuscript readiness |  |  |  |"
)
writeLines(lines, report_path)
cat("visual QA report written: ", report_path, "\n", sep = "")
