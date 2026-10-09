#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: Rscript visual-qa-report.R <output_dir>", call. = FALSE)
output_dir <- normalizePath(args[[1]], mustWork = TRUE)

read_raster_dims <- function(path) {
  py <- Sys.getenv("PAPERPLOT_PYTHON", unname(Sys.which("python3")))
  values <- tryCatch(suppressWarnings(system2(py, c("-c", shQuote("from PIL import Image; import sys; print(*Image.open(sys.argv[1]).size)"),
    shQuote(path)), stdout = TRUE, stderr = FALSE)), error = function(e) character())
  dims <- suppressWarnings(as.integer(strsplit(paste(values, collapse = " "), " +")[[1]]))
  if (length(dims) != 2L || anyNA(dims)) dims <- c(NA_integer_, NA_integer_)
  stats::setNames(dims, c("width", "height"))
}

pdf_files <- list.files(output_dir, pattern = "\\.pdf$", full.names = TRUE)
raster_files <- list.files(output_dir, pattern = "\\.(jpg|jpeg|png)$", full.names = TRUE)
metadata_files <- list.files(output_dir, pattern = "_metadata\\.json$", full.names = TRUE)
qa_files <- list.files(output_dir, pattern = "_qa\\.md$", full.names = TRUE)
visual_qa_files <- list.files(output_dir, pattern = "^visual_qa\\.json$", full.names = TRUE)

if (length(pdf_files) < 1) warning("No PDF found in output directory.")
if (length(raster_files) < 1) warning("No JPG/PNG found in output directory.")

raster_lines <- if (length(raster_files) > 0) {
  unlist(lapply(raster_files, function(path) {
    dims <- read_raster_dims(path)
    size <- file.info(path)$size
    c(
      paste0("- file: ", basename(path)),
      paste0("  - pixels: ", dims[["width"]], " x ", dims[["height"]]),
      paste0("  - bytes: ", size)
    )
  }))
} else {
  "- No JPG/PNG preview found."
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
  "## Raster preview dimensions (JPG default; PNG legacy)",
  raster_lines,
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
    "${PAPERPLOT_PYTHON:-python3} scripts/visual-qa-rendered-image.py <image_or_output_dir> --out <qa_dir>",
    "```"
  ),
  "",
  "## Manual image-level QA checklist",
  "",
  "Mark each item after inspecting the actual rendered JPG/PDF preview (or explicitly requested legacy PNG):",
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
