#!/usr/bin/env Rscript

fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

command <- commandArgs(trailingOnly = FALSE)
script_arg <- command[grepl("^--file=", command)]
script_path <- if (length(script_arg) == 1L) normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE) else normalizePath("paperplot-skills/scripts/validate-figure-output.R", mustWork = TRUE)
parser_path <- file.path(dirname(script_path), "lib", "contract-parsers.R")
if (!file.exists(parser_path)) fail("Missing runtime contract parser: ", parser_path)
source(parser_path, local = TRUE)

args <- commandArgs(trailingOnly = TRUE)
strict <- "--manuscript-ready" %in% args
args <- setdiff(args, "--manuscript-ready")
if (length(args) != 1L) fail("Usage: Rscript paperplot-skills/scripts/validate-figure-output.R <output_dir> [--manuscript-ready]")
output_dir <- normalizePath(args[[1L]], mustWork = FALSE)
if (!dir.exists(output_dir)) fail("Output directory not found: ", output_dir)

find_files <- function(pattern) sort(list.files(output_dir, pattern = pattern, full.names = TRUE, recursive = TRUE))
nonempty_scalar <- function(x) length(x) == 1L && !is.null(x) && !pp_is_json_null(x) && !is.na(x) && nzchar(trimws(as.character(x)))
scalar_chr <- function(x, default = "") if (nonempty_scalar(x)) as.character(x) else default
scalar_num <- function(x) if (length(x) == 1L && is.numeric(x) && is.finite(x)) as.numeric(x) else NA_real_
scalar_bool <- function(x) length(x) == 1L && is.logical(x) && !is.na(x) && isTRUE(x)
normalize_existing <- function(path) normalizePath(path, mustWork = TRUE)

check_file <- function(path, label, min_size = 1L) {
  if (!file.exists(path) || dir.exists(path)) fail("Missing ", label, ": ", path)
  size <- unname(file.info(path)[["size"]])
  if (is.na(size) || size < min_size) fail("Missing, empty, or suspiciously small ", label, ": ", path, " (", size, " bytes)")
  invisible(size)
}

raw_ascii <- function(bytes) {
  values <- as.integer(bytes)
  values[values < 32L | values > 126L] <- 32L
  rawToChar(as.raw(values))
}
uint32_be <- function(bytes) sum(as.numeric(bytes) * 256^(3:0))

crc32_table <- local({
  poly <- as.integer(-306674912L) # unsigned 0xEDB88320
  vapply(0:255, function(value) {
    crc <- as.integer(value)
    for (i in seq_len(8L)) crc <- if (bitwAnd(crc, 1L) != 0L) bitwXor(bitwShiftR(crc, 1L), poly) else bitwShiftR(crc, 1L)
    crc
  }, integer(1))
})
crc32_raw <- function(bytes) {
  crc <- as.integer(-1L)
  for (value in as.integer(bytes)) {
    index <- bitwAnd(bitwXor(crc, value), 255L) + 1L
    crc <- bitwXor(bitwShiftR(crc, 8L), crc32_table[[index]])
  }
  crc <- bitwXor(crc, as.integer(-1L))
  as.raw(c(
    bitwAnd(bitwShiftR(crc, 24L), 255L), bitwAnd(bitwShiftR(crc, 16L), 255L),
    bitwAnd(bitwShiftR(crc, 8L), 255L), bitwAnd(crc, 255L)
  ))
}

python_executable <- function() {
  python <- Sys.getenv("PAPERPLOT_PYTHON", unset = "")
  if (!nzchar(python)) {
    hits <- unname(Sys.which(c("python3", "python"))); hits <- hits[nzchar(hits)]
    python <- if (length(hits) > 0L) hits[[1L]] else ""
  }
  python
}

run_python_contract <- function(script, arguments, accepted_status = 0L) {
  python <- python_executable()
  if (!nzchar(python)) fail("Manuscript-ready validation requires PAPERPLOT_PYTHON or python3.")
  output <- suppressWarnings(system2(python, c(shQuote(script), vapply(arguments, shQuote, character(1))), stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status") %||% 0L
  if (!status %in% accepted_status) fail("Contract tool failed (", status, "): ", script, " | ", paste(tail(output, 8L), collapse = " | "))
  invisible(output)
}

invocation_args <- function(invocation, comparison = FALSE) {
  args <- character()
  add_value <- function(flag, value) if (nonempty_scalar(value)) c(flag, as.character(value)) else character()
  add_integer <- function(flag, value) if (!is.na(scalar_num(value))) c(flag, as.character(as.integer(scalar_num(value)))) else character()
  if (!comparison) {
    args <- c(args, add_value("--family", invocation$family), add_integer("--dpi", invocation$dpi), add_integer("--page", invocation$page), add_value("--ocr", invocation$ocr), add_integer("--expected-panels", invocation$expected_panels), add_value("--layout-profile", invocation$layout_profile))
    if (scalar_bool(invocation$strict_nature)) args <- c(args, "--strict-nature")
  } else {
    args <- c(args, add_value("--family", invocation$family), add_value("--old-family", invocation$old_family), add_value("--new-family", invocation$new_family), add_integer("--dpi", invocation$dpi), add_integer("--page", invocation$page), add_value("--ocr", invocation$ocr), add_integer("--expected-panels", invocation$expected_panels), add_integer("--old-expected-panels", invocation$old_expected_panels), add_integer("--new-expected-panels", invocation$new_expected_panels), add_value("--layout-profile", invocation$layout_profile), add_value("--old-layout-profile", invocation$old_layout_profile), add_value("--new-layout-profile", invocation$new_layout_profile))
    for (pair in list(c("strict_nature", "--strict-nature"), c("old_strict_nature", "--old-strict-nature"), c("new_strict_nature", "--new-strict-nature"))) if (scalar_bool(invocation[[pair[[1L]]]])) args <- c(args, pair[[2L]])
  }
  args
}

replay_visual_evidence <- function(record, image) {
  script <- file.path(dirname(script_path), "visual-qa-rendered-image.py")
  check_file(script, "bundled rendered-image QA tool", 1000L)
  run_python_contract(script, c("--verify-evidence", record$path))
  out <- tempfile("paperplot-visual-replay-"); dir.create(out, recursive = TRUE)
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)
  args <- c(scalar_chr(image$input_path), "--out", out, invocation_args(image$invocation %||% list()))
  run_python_contract(script, args)
  replay_path <- file.path(out, "visual_qa.json")
  replay <- pp_parse_json_file(replay_path)$image_qa %||% list()
  if (!nonempty_scalar(image$analysis_fingerprint) || !identical(scalar_chr(image$analysis_fingerprint_algorithm), "sha256-canonical-v1") || !identical(scalar_chr(replay$analysis_fingerprint), scalar_chr(image$analysis_fingerprint))) fail("Rendered-image QA does not match a fresh analysis of the current pixels: ", record$path)
  replay
}

replay_comparison_evidence <- function(evidence_path, evidence) {
  script <- file.path(dirname(script_path), "compare-old-new-figures.py")
  check_file(script, "bundled old-vs-new comparison tool", 1000L)
  run_python_contract(script, c("--verify-evidence", evidence_path))
  out <- tempfile("paperplot-comparison-replay-"); dir.create(out, recursive = TRUE)
  on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)
  args <- c(scalar_chr(evidence$old_image), scalar_chr(evidence$new_image), "--out", out, invocation_args(evidence$invocation %||% list(), comparison = TRUE), "--review-evidence", evidence_path)
  run_python_contract(script, args)
  replay <- pp_parse_json_file(file.path(out, "old_vs_new_visual_qa.json"))$old_vs_new_visual_qa %||% list()
  if (!nonempty_scalar(evidence$analysis_fingerprint) || !identical(scalar_chr(evidence$analysis_fingerprint_algorithm), "sha256-canonical-v1") || !identical(scalar_chr(replay$analysis_fingerprint), scalar_chr(evidence$analysis_fingerprint))) fail("Old-vs-new evidence does not match a fresh deterministic comparison: ", evidence_path)
  replay
}

run_decoder <- function(path, kind) {
  if (kind == "pdf") {
    executable <- unname(Sys.which("pdfinfo"))
    if (nzchar(executable)) {
      output <- suppressWarnings(system2(executable, path, stdout = TRUE, stderr = TRUE))
      status <- attr(output, "status") %||% 0L
      if (status != 0L || !any(grepl("^Pages:[[:space:]]+[1-9][0-9]*", output))) fail("PDF parser rejected or found no pages in ", path, ": ", paste(tail(output, 4L), collapse = " | "))
      return(invisible(TRUE))
    }
  } else {
    executable <- unname(Sys.which("identify"))
    if (nzchar(executable)) {
      output <- suppressWarnings(system2(executable, path, stdout = TRUE, stderr = TRUE))
      status <- attr(output, "status") %||% 0L
      if (status != 0L) fail("Image decoder rejected ", path, ": ", paste(tail(output, 4L), collapse = " | "))
      return(invisible(TRUE))
    }
  }
  python <- python_executable()
  if (nzchar(python)) {
    code <- if (kind == "pdf") {
      "import subprocess,sys; p=subprocess.run(['pdftoppm','-f','1','-l','1','-singlefile','-png',sys.argv[1],'/dev/null'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL); raise SystemExit(p.returncode)"
    } else {
      "from PIL import Image; import sys; im=Image.open(sys.argv[1]); im.verify(); im=Image.open(sys.argv[1]); im.load()"
    }
    output <- suppressWarnings(system2(python, c("-c", shQuote(code), shQuote(path)), stdout = TRUE, stderr = TRUE))
    status <- attr(output, "status") %||% 0L
    if (status == 0L) return(invisible(TRUE))
  }
  fail("Manuscript-ready validation requires an available decoder for ", kind, ": ", path)
}

check_pdf_structure <- function(path) {
  size <- unname(file.info(path)[["size"]])
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  seek(con, where = max(0, size - 65536), origin = "start")
  tail_text <- raw_ascii(readBin(con, what = "raw", n = min(65536, size)))
  hits <- regmatches(tail_text, gregexpr("startxref[[:space:]]+([0-9]+)[[:space:]]+%%EOF", tail_text, perl = TRUE))[[1L]]
  if (length(hits) < 1L || identical(hits, "")) fail("PDF lacks a valid startxref/EOF trailer: ", path)
  offset <- suppressWarnings(as.numeric(sub(".*startxref[[:space:]]+([0-9]+)[[:space:]]+%%EOF.*", "\\1", tail(hits, 1L), perl = TRUE)))
  if (!is.finite(offset) || offset < 0 || offset >= size) fail("PDF startxref offset is outside the file: ", path)
  seek(con, where = offset, origin = "start")
  target <- raw_ascii(readBin(con, what = "raw", n = min(1024, size - offset)))
  classic <- grepl("^xref(?:[[:space:]]|$)", target, perl = TRUE)
  stream <- grepl("^[0-9]+[[:space:]]+[0-9]+[[:space:]]+obj.*?/Type[[:space:]]*/XRef", target, perl = TRUE)
  if (!(classic || stream)) fail("PDF startxref does not reference an xref table or stream: ", path)
  if (!grepl("/Root(?:[[:space:]]|$)", paste(target, tail_text), perl = TRUE)) fail("PDF xref/trailer lacks a Root object: ", path)
  invisible(TRUE)
}

check_media <- function(path, kind) {
  minimum <- if (kind == "pdf") 5000L else 1000L
  check_file(path, kind, minimum)
  signature <- readBin(path, what = "raw", n = if (kind == "pdf") 5L else 8L)
  expected <- if (kind == "pdf") charToRaw("%PDF-") else as.raw(c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L))
  if (!identical(signature, expected)) fail("Invalid ", toupper(kind), " signature: ", path)
  if (kind == "pdf") check_pdf_structure(path)
  if (strict) run_decoder(path, kind)
  invisible(TRUE)
}

read_png_geometry <- function(path) {
  file_size <- check_file(path, "PNG", 1000L)
  if (file_size > 1024^3) fail("PNG exceeds the 1 GiB validation limit: ", path)
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  signature <- readBin(con, what = "raw", n = 8L)
  if (!identical(signature, as.raw(c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L)))) fail("Invalid PNG signature: ", path)
  width <- height <- x_ppm <- y_ppm <- NA_real_
  saw_ihdr <- saw_idat <- saw_iend <- FALSE
  idat_closed <- FALSE
  chunk_count <- 0L
  repeat {
    position <- seek(con, where = NA, origin = "current")
    length_raw <- readBin(con, what = "raw", n = 4L)
    if (length(length_raw) == 0L) break
    if (length(length_raw) != 4L) fail("Truncated PNG chunk length: ", path)
    chunk_length <- uint32_be(length_raw)
    remaining <- file_size - seek(con, where = NA, origin = "current")
    if (!is.finite(chunk_length) || chunk_length < 0 || chunk_length > 64 * 1024^2 || chunk_length + 8 > remaining) fail("PNG chunk length is unsafe or exceeds remaining bytes at offset ", position, ": ", path)
    type_raw <- readBin(con, what = "raw", n = 4L)
    if (length(type_raw) != 4L || !grepl("^[A-Za-z]{4}$", rawToChar(type_raw))) fail("Invalid PNG chunk type: ", path)
    chunk_type <- rawToChar(type_raw)
    data <- readBin(con, what = "raw", n = as.integer(chunk_length))
    stored_crc <- readBin(con, what = "raw", n = 4L)
    if (length(data) != chunk_length || length(stored_crc) != 4L) fail("Truncated PNG chunk: ", path)
    if (!identical(crc32_raw(c(type_raw, data)), stored_crc)) fail("PNG CRC mismatch in ", chunk_type, " chunk: ", path)
    chunk_count <- chunk_count + 1L
    if (chunk_count > 100000L) fail("PNG contains too many chunks: ", path)
    if (!saw_ihdr && chunk_type != "IHDR") fail("PNG IHDR must be the first chunk: ", path)
    if (chunk_type == "IHDR") {
      if (saw_ihdr || chunk_length != 13L) fail("PNG must contain one 13-byte IHDR: ", path)
      saw_ihdr <- TRUE
      width <- uint32_be(data[1:4]); height <- uint32_be(data[5:8])
      bit_depth <- as.integer(data[[9L]]); color_type <- as.integer(data[[10L]])
      valid_depth <- switch(as.character(color_type), `0` = bit_depth %in% c(1L, 2L, 4L, 8L, 16L), `2` = bit_depth %in% c(8L, 16L), `3` = bit_depth %in% c(1L, 2L, 4L, 8L), `4` = bit_depth %in% c(8L, 16L), `6` = bit_depth %in% c(8L, 16L), FALSE)
      if (!valid_depth || as.integer(data[[11L]]) != 0L || as.integer(data[[12L]]) != 0L || !as.integer(data[[13L]]) %in% c(0L, 1L)) fail("Unsupported or invalid PNG IHDR fields: ", path)
      if (!is.finite(width) || !is.finite(height) || width < 1 || height < 1 || width * height > 5e8) fail("PNG dimensions are invalid or unsafe: ", path)
    } else if (chunk_type == "IDAT") {
      if (idat_closed) fail("PNG IDAT chunks must be consecutive: ", path)
      saw_idat <- TRUE
    } else if (saw_idat && chunk_type != "IEND") {
      idat_closed <- TRUE
    }
    if (chunk_type == "pHYs") {
      if (saw_idat || chunk_length != 9L) fail("PNG pHYs must be a 9-byte pre-IDAT chunk: ", path)
      if (as.integer(data[[9L]]) == 1L) { x_ppm <- uint32_be(data[1:4]); y_ppm <- uint32_be(data[5:8]) }
    }
    if (chunk_type == "IEND") {
      if (!saw_idat || chunk_length != 0L) fail("PNG IEND requires preceding IDAT and zero length: ", path)
      saw_iend <- TRUE
      if (seek(con, where = NA, origin = "current") != file_size) fail("PNG contains trailing bytes after IEND: ", path)
      break
    }
  }
  if (!saw_ihdr || !saw_idat || !saw_iend) fail("PNG lacks required IHDR, IDAT, or IEND chunks: ", path)
  list(width_px = width, height_px = height, x_ppm = x_ppm, y_ppm = y_ppm)
}

as_string_array <- function(x, label, allow_empty = FALSE) {
  if (pp_is_json_null(x) || !is.list(x)) fail(label, " must be a JSON array")
  if (!allow_empty && length(x) == 0L) fail(label, " must not be empty")
  values <- vapply(seq_along(x), function(i) {
    value <- x[[i]]
    if (!nonempty_scalar(value) || !is.character(value)) fail(label, " contains a null, empty, or non-string value at index ", i)
    as.character(value)
  }, character(1))
  values
}

profile_contracts <- list(
  general_scientific = list(single_cm = 8.8, double_cm = 17.8, max_height_cm = 24.1, scope = "General research fallback", source_url = "", source_status = "local_fallback", last_checked = "2026-08-12"),
  nature_like = list(single_cm = 8.9, double_cm = 18.0, max_height_cm = 17.0, scope = "Nature-like life-science and genomics layouts", source_url = "https://research-figure-guide.nature.com/", source_status = "project_baseline_verify_title", last_checked = "2026-08-12"),
  nature_communications = list(single_cm = 9.0, double_cm = 18.0, max_height_cm = 17.0, scope = "Nature Communications project layouts", source_url = "https://research-figure-guide.nature.com/", source_status = "project_profile_verify_title", last_checked = "2026-08-12"),
  cell_press = list(single_cm = 8.5, double_cm = 17.4, max_height_cm = 20.0, scope = "Cell Press two-column research figures", source_url = "https://www.cell.com/information-for-authors/figure-guidelines", source_status = "official_reviewed", last_checked = "2026-08-12"),
  medical_radiology = list(single_cm = 8.56, double_cm = 17.35, max_height_cm = 23.34, scope = "Radiology-family journal figures", source_url = "", source_status = "imported_unverified", last_checked = "2026-08-12")
)
allowed_presets <- c("cell", "cell_half", "nature", "nature_half", "ncomms", "ncomms_half", "single_column", "double_column", "square")
profile_for_preset <- function(preset) switch(tolower(preset), cell =, cell_half = "cell_press", nature =, nature_half = "nature_like", ncomms =, ncomms_half = "nature_communications", "general_scientific")
column_for_preset <- function(preset) switch(tolower(preset), cell_half =, nature_half =, ncomms_half =, single_column =, square = "single", "double")

validate_profile <- function(x, metadata_path) {
  profile_name <- scalar_chr(x$journal_profile)
  profile <- profile_contracts[[profile_name]]
  if (is.null(profile)) fail("Unknown journal_profile in ", metadata_path, ": ", profile_name)
  snapshot <- x$journal_profile_snapshot %||% list()
  geometry <- x$export_geometry %||% list()
  figure_spec <- x$figure_spec %||% list()
  helper_version <- scalar_chr(x$helper_version)
  if (!nzchar(helper_version)) fail("Metadata missing helper_version: ", metadata_path)
  legacy <- helper_version %in% c("standalone-0.4.0", "standalone-0.4.1")
  modern <- !legacy
  if (strict || modern) {
    for (key in c("scope", "source_status", "last_checked")) if (!nonempty_scalar(snapshot[[key]])) fail("Missing journal profile snapshot ", key, ": ", metadata_path)
    if (!is.character(snapshot$source_url) || length(snapshot$source_url) != 1L || is.na(snapshot$source_url)) fail("Missing journal profile snapshot source_url: ", metadata_path)
    if (!identical(scalar_chr(snapshot$scope), profile$scope) || !identical(as.character(snapshot$source_url), profile$source_url) || !identical(scalar_chr(snapshot$source_status), profile$source_status) || !identical(scalar_chr(snapshot$last_checked), profile$last_checked)) fail("Journal profile snapshot does not match the bundled contract: ", metadata_path)
    preset <- tolower(scalar_chr(geometry$preset))
    figure_preset <- tolower(scalar_chr(figure_spec$output_preset))
    if (!preset %in% allowed_presets || !identical(preset, figure_preset)) fail("export_geometry and figure_spec must contain the same supported preset: ", metadata_path)
    if (!identical(scalar_chr(geometry$journal_profile), profile_name) || !identical(scalar_chr(figure_spec$journal_profile), profile_name)) fail("Top-level, figure_spec, and export_geometry journal profiles must agree: ", metadata_path)
    branded <- preset %in% c("cell", "cell_half", "nature", "nature_half", "ncomms", "ncomms_half")
    if (branded && !identical(profile_for_preset(preset), profile_name)) fail("Branded preset/profile conflict in ", metadata_path)
    width <- scalar_num(geometry$width_cm); height <- scalar_num(geometry$height_cm); dpi <- scalar_num(geometry$dpi)
    if (any(is.na(c(width, height, dpi))) || width <= 0 || height <= 0 || dpi <= 0) fail("Invalid export_geometry dimensions or dpi: ", metadata_path)
    column <- column_for_preset(preset)
    max_width <- if (column == "single") profile$single_cm else profile$double_cm
    if (!identical(scalar_chr(geometry$column_class), column) || is.na(scalar_num(geometry$max_width_cm)) || abs(scalar_num(geometry$max_width_cm) - max_width) > 1e-8 || is.na(scalar_num(geometry$max_height_cm)) || abs(scalar_num(geometry$max_height_cm) - profile$max_height_cm) > 1e-8) fail("Recorded export envelope does not match the selected profile: ", metadata_path)
    if (width > max_width + 1e-8 || height > profile$max_height_cm + 1e-8) fail("Export geometry exceeds journal profile envelope: ", metadata_path)
    return(list(name = profile_name, preset = preset, width_cm = width, height_cm = height, dpi = dpi))
  }
  list(name = profile_name, preset = scalar_chr(figure_spec$output_preset), width_cm = NA_real_, height_cm = NA_real_, dpi = NA_real_)
}

validate_bioinformatics <- function(x, stem, metadata_path) {
  domain <- scalar_chr(x$analysis_domain)
  bio <- x$bioinformatics_validation %||% list()
  status <- scalar_chr(bio$status)
  allowed <- c("pass", "warn", "block", "not_recorded", "not_applicable")
  if (!status %in% allowed) fail("Unknown bioinformatics validation status in ", metadata_path, ": ", status)
  if (domain == "bioinformatics" && status == "not_applicable") fail("Bioinformatics figure cannot mark validation not_applicable: ", metadata_path)
  if (strict && domain == "bioinformatics" && status != "pass") fail("Manuscript-ready bioinformatics validation must pass: ", metadata_path)
  if (status != "pass") return(invisible(status))

  inputs <- as_string_array(bio$input_paths %||% pp_json_null(), "bioinformatics_validation.input_paths")
  records <- bio$input_files %||% list()
  if (!is.list(records) || length(records) != length(inputs)) fail("Bioinformatics PASS input_files must match input_paths: ", metadata_path)
  for (i in seq_along(inputs)) {
    path <- normalize_existing(inputs[[i]])
    record <- records[[i]]
    if (!is.list(record) || !identical(normalize_existing(scalar_chr(record$path)), path)) fail("Bioinformatics input record path mismatch: ", metadata_path)
    if (!identical(tolower(scalar_chr(record$md5)), tolower(unname(tools::md5sum(path)[[1L]])))) fail("Bioinformatics input checksum mismatch: ", path)
  }
  required <- c("organism", "reference_version", "coordinate_system", "sample_order", "units_transforms_denominators", "statistics", "plotting_data_path")
  placeholder <- function(value) grepl("^(todo|unknown|not[ _-]?recorded|tbd)(?:$|[ _:-])", trimws(as.character(value)), ignore.case = TRUE, perl = TRUE)
  missing <- required[!vapply(required, function(key) nonempty_scalar(bio[[key]]) && !placeholder(bio[[key]]), logical(1))]
  if (length(missing) > 0L) fail("Bioinformatics PASS missing or placeholder fields in ", metadata_path, ": ", paste(missing, collapse = ", "))
  evidence <- bio$validation_evidence %||% list()
  evidence_keys <- c("source_records_checked", "sample_order_checked", "units_checked", "statistics_checked", "plotting_data_checked")
  unchecked <- evidence_keys[!vapply(evidence_keys, function(key) scalar_bool(evidence[[key]]), logical(1))]
  if (length(unchecked) > 0L) fail("Bioinformatics PASS lacks confirmed validation evidence in ", metadata_path, ": ", paste(unchecked, collapse = ", "))
  if (!nonempty_scalar(evidence$recorded_at) || identical(scalar_chr(evidence$recorded_at), "not_recorded")) fail("Bioinformatics PASS lacks evidence timestamp: ", metadata_path)
  coordinates <- c("0-based_half-open", "1-based_closed", "not_applicable_gene_level", "not_applicable_nonpositional", "mixed_documented")
  if (!scalar_chr(bio$coordinate_system) %in% coordinates) fail("Unknown PASS coordinate_system: ", metadata_path)
  plotting_path <- normalize_existing(scalar_chr(bio$plotting_data_path))
  expected_plotting <- normalizePath(paste0(stem, "_plotting_data.tsv"), mustWork = FALSE)
  if (!identical(plotting_path, expected_plotting)) fail("Bioinformatics PASS requires a stem-matched _plotting_data.tsv: ", metadata_path)
  check_file(plotting_path, "plotting-data TSV", 20L)
  size <- unname(file.info(plotting_path)[["size"]])
  if (is.na(size) || size > 512 * 1024^2) fail("Plotting-data TSV exceeds the 512 MiB validation limit: ", plotting_path)
  raw_data <- readBin(plotting_path, what = "raw", n = size)
  if (any(raw_data == as.raw(0L))) fail("Plotting-data TSV contains NUL bytes: ", plotting_path)
  lines <- readLines(plotting_path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) < 2L || !grepl("\t", lines[[1L]], fixed = TRUE)) fail("Plotting-data sidecar must be tab-separated with a header and data rows: ", plotting_path)
  field_counts <- lengths(strsplit(lines, "\t", fixed = TRUE))
  if (field_counts[[1L]] < 2L || any(field_counts != field_counts[[1L]])) fail("Plotting-data TSV has inconsistent field counts: ", plotting_path)
  header <- strsplit(lines[[1L]], "\t", fixed = TRUE)[[1L]]
  if (any(!nzchar(header)) || anyDuplicated(header)) fail("Plotting-data TSV header is empty or duplicated: ", plotting_path)
  parsed <- tryCatch(utils::read.delim(plotting_path, header = TRUE, sep = "\t", quote = "", comment.char = "", check.names = FALSE, stringsAsFactors = FALSE), error = function(e) fail("Plotting-data TSV cannot be parsed: ", plotting_path, " | ", conditionMessage(e)))
  if (nrow(parsed) != length(lines) - 1L || ncol(parsed) != field_counts[[1L]]) fail("Plotting-data TSV parsed dimensions disagree with file structure: ", plotting_path)
  record <- bio$plotting_data %||% list()
  if (!is.list(record) || !identical(normalize_existing(scalar_chr(record$path)), plotting_path)) fail("Plotting-data record path mismatch: ", metadata_path)
  if (!identical(tolower(scalar_chr(record$md5)), tolower(unname(tools::md5sum(plotting_path)[[1L]])))) fail("Plotting-data checksum mismatch: ", plotting_path)
  invisible(status)
}

validate_cognitive_review <- function(cognitive, metadata_path) {
  status <- scalar_chr(cognitive$status)
  if (!status %in% c("pass", "warn", "not_recorded")) fail("Unknown cognitive-load status in ", metadata_path, ": ", status)
  if (status == "not_recorded") {
    if (strict) fail("Manuscript-ready validation requires recorded cognitive-load review: ", metadata_path)
    return(invisible(status))
  }
  expected_keys <- c("elements", "colors", "shapes", "legend_entries")
  counts <- cognitive$counts %||% list(); limits <- cognitive$review_limits %||% list()
  if (!is.list(counts) || !setequal(names(counts), expected_keys) || !is.list(limits) || !setequal(names(limits), expected_keys)) fail("Cognitive-load review requires complete counts and review_limits: ", metadata_path)
  count_values <- vapply(expected_keys, function(key) scalar_num(counts[[key]]), numeric(1))
  limit_values <- vapply(expected_keys, function(key) scalar_num(limits[[key]]), numeric(1))
  if (any(is.na(c(count_values, limit_values))) || any(count_values < 0) || any(limit_values < 0)) fail("Cognitive-load counts/limits must be finite non-negative values: ", metadata_path)
  if (!identical(as.numeric(limit_values), c(7, 3, 3, 4))) fail("Cognitive-load review_limits do not match the bundled policy: ", metadata_path)
  expected_exceeded <- expected_keys[count_values > limit_values]
  exceeded <- as_string_array(cognitive$exceeded %||% list(), "cognitive_load_review.exceeded", allow_empty = TRUE)
  if (!setequal(exceeded, expected_exceeded) || anyDuplicated(exceeded)) fail("Cognitive-load exceeded list disagrees with counts/limits: ", metadata_path)
  expected_status <- if (length(expected_exceeded) == 0L) "pass" else "warn"
  if (!identical(status, expected_status)) fail("Cognitive-load status disagrees with counts/limits: ", metadata_path)
  if (!nonempty_scalar(cognitive$chart_family) || !nonempty_scalar(cognitive$action) || !is.logical(cognitive$exception_recorded) || length(cognitive$exception_recorded) != 1L) fail("Cognitive-load review lacks chart_family/action/exception state: ", metadata_path)
  if (strict && status == "warn" && !(scalar_bool(cognitive$exception_recorded) && nonempty_scalar(cognitive$exception_reason))) fail("Manuscript-ready cognitive-load warning lacks a documented exception: ", metadata_path)
  invisible(status)
}

parse_qa_report <- function(path) {
  lines <- trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
  hits <- regmatches(lines, regexec("^- overall status:[[:space:]]*(pass|warn|fail)[[:space:]]*$", lines, ignore.case = TRUE, perl = TRUE))
  values <- tolower(vapply(hits[lengths(hits) == 2L], `[[`, character(1), 2L))
  if (length(values) != 1L) fail("QA report must contain exactly one machine-readable overall status: ", path)
  table_lines <- lines[grepl("^\\|", lines)]
  table_lines <- table_lines[!grepl("^\\|[[:space:]]*(gate|-+)[[:space:]]*\\|", table_lines, ignore.case = TRUE, perl = TRUE)]
  if (length(table_lines) < 1L) fail("QA report must contain at least one gate row: ", path)
  gates <- character(length(table_lines)); statuses <- character(length(table_lines))
  for (i in seq_along(table_lines)) {
    match <- regmatches(table_lines[[i]], regexec("^\\|[[:space:]]*([^|]+?)[[:space:]]*\\|[[:space:]]*([^|]+?)[[:space:]]*\\|", table_lines[[i]], perl = TRUE))[[1L]]
    if (length(match) != 3L) fail("Malformed QA gate row in ", path, ": ", table_lines[[i]])
    gates[[i]] <- trimws(match[[2L]]); statuses[[i]] <- tolower(trimws(match[[3L]]))
    if (!nzchar(gates[[i]]) || !statuses[[i]] %in% c("pass", "warn", "fail")) fail("Unknown or empty QA gate/status in ", path, ": ", table_lines[[i]])
  }
  derived <- if (any(statuses == "fail")) "fail" else if (any(statuses == "warn")) "warn" else "pass"
  if (!identical(values[[1L]], derived)) fail("QA overall status disagrees with gate rows: ", path, " (reported ", values[[1L]], ", derived ", derived, ")")
  list(status = derived, gate_names = unique(gates), gates = stats::setNames(statuses, gates))
}

visual_qa_files <- unique(c(find_files("(^|_)visual_qa\\.json$"), find_files("visual_qa\\.json$")))
visual_records <- lapply(visual_qa_files, function(path) list(path = path, payload = pp_parse_json_file(path)))
find_visual_record <- function(media_paths) {
  hits <- list()
  for (record in visual_records) {
    image <- record$payload$image_qa %||% list()
    input <- scalar_chr(image$input_path)
    if (!nzchar(input) || !file.exists(input)) next
    if (normalize_existing(input) %in% vapply(media_paths, normalize_existing, character(1))) hits[[length(hits) + 1L]] <- record
  }
  if (length(hits) > 1L) fail("Multiple rendered-image QA records match one figure bundle: ", paste(vapply(hits, `[[`, character(1), "path"), collapse = ", "))
  if (length(hits) == 0L) NULL else hits[[1L]]
}

validate_review_record <- function(record, expected_path, label) {
  if (!is.list(record) || !nonempty_scalar(record$path) || !nonempty_scalar(record$md5)) fail("Review sidecar lacks ", label, " file record")
  actual <- normalize_existing(scalar_chr(record$path))
  if (!identical(actual, normalize_existing(expected_path))) fail("Review sidecar ", label, " path mismatch: ", expected_path)
  if (!identical(tolower(scalar_chr(record$md5)), tolower(unname(tools::md5sum(actual)[[1L]])))) fail("Review sidecar ", label, " checksum is stale: ", actual)
  invisible(actual)
}

apply_review_sidecar <- function(metadata, metadata_path, qa_path, stem) {
  review_path <- paste0(stem, "_review.json")
  if (!file.exists(review_path)) return(list(metadata = metadata, path = ""))
  review <- pp_parse_json_file(review_path)
  if (scalar_num(review$review_schema_version) != 1) fail("Unsupported review sidecar schema: ", review_path)
  validate_review_record(review$metadata, metadata_path, "metadata")
  validate_review_record(review$qa, qa_path, "QA")
  visual <- review$visual_qa_review %||% list()
  if (!scalar_chr(visual$status) %in% c("not_recorded", "pass", "accepted_warn")) fail("Unknown visual review sidecar status: ", review_path)
  if (scalar_chr(visual$status) != "not_recorded") {
    evidence <- normalize_existing(scalar_chr(visual$evidence_path))
    if (!identical(tolower(scalar_chr(visual$evidence_md5)), tolower(unname(tools::md5sum(evidence)[[1L]])))) fail("Review sidecar visual evidence checksum is stale: ", review_path)
  }
  old <- review$old_vs_new_review %||% list()
  if (!scalar_chr(old$status) %in% c("not_applicable", "provided")) fail("Unknown old-vs-new review sidecar status: ", review_path)
  if (scalar_chr(old$status) == "provided") {
    evidence <- normalize_existing(scalar_chr(old$evidence_path))
    if (!identical(tolower(scalar_chr(old$evidence_md5)), tolower(unname(tools::md5sum(evidence)[[1L]])))) fail("Review sidecar old-vs-new evidence checksum is stale: ", review_path)
  }
  metadata$visual_qa_review <- visual
  metadata$old_vs_new_review <- old
  metadata$review_sidecar_path <- review_path
  list(metadata = metadata, path = review_path)
}

validate_visual_qa <- function(record, media_paths, metadata, metadata_path) {
  if (is.null(record)) fail("Manuscript-ready validation requires rendered-image visual QA for ", metadata_path)
  image <- record$payload$image_qa %||% list()
  if (scalar_num(image$visual_qa_schema_version) != 3 || !identical(scalar_chr(image$tool_id), "paperplot-visual-qa-rendered-image") || !scalar_bool(image$checked) || !identical(scalar_chr(image$engine), "pillow-raster")) fail("Visual QA lacks the complete rendered-image tool schema: ", record$path)
  input <- normalize_existing(scalar_chr(image$input_path))
  if (!input %in% vapply(media_paths, normalize_existing, character(1))) fail("Visual QA input does not match the figure bundle: ", record$path)
  input_size <- unname(file.info(input)[["size"]])
  if (scalar_num(image$input_size_bytes) != input_size || scalar_num(image$file_size_bytes) != input_size) fail("Visual QA input size is missing or stale: ", record$path)
  if (!nonempty_scalar(image$input_md5) || !identical(tolower(scalar_chr(image$input_md5)), tolower(unname(tools::md5sum(input)[[1L]])))) fail("Visual QA input checksum is missing or stale: ", record$path)
  invocation <- image$invocation %||% list()
  if (!scalar_bool(invocation$strict_nature) || !scalar_chr(invocation$ocr) %in% c("auto", "off", "required") || !scalar_chr(invocation$layout_profile) %in% c("auto", "equal", "hierarchical")) fail("Visual QA invocation is missing strict reproducible parameters: ", record$path)
  replay_visual_evidence(record, image)
  dimensions <- image$image_size_px %||% list()
  if (!is.list(dimensions) || length(dimensions) != 2L || any(!vapply(dimensions, function(value) is.numeric(value) && length(value) == 1L && is.finite(value) && value > 0, logical(1)))) fail("Visual QA lacks valid image dimensions: ", record$path)
  score <- scalar_num(image$manuscript_readiness_score)
  image_status <- scalar_chr(image$status)
  if (is.na(score) || score < 0 || score > 10 || !image_status %in% c("pass", "warn", "fail")) fail("Visual QA score/status is invalid: ", record$path)
  risks <- image$top_risks %||% list()
  if (!is.list(risks) || length(risks) < 1L) fail("Visual QA lacks top_risks: ", record$path)
  risk_statuses <- vapply(risks, function(item) if (is.list(item)) scalar_chr(item$status) else "", character(1))
  risk_codes <- vapply(risks, function(item) if (is.list(item)) scalar_chr(item$code) else "", character(1))
  if (any(!risk_statuses %in% c("pass", "warn", "fail")) || any(!nzchar(risk_codes)) || anyDuplicated(risk_codes)) fail("Visual QA top_risks are malformed: ", record$path)
  derived_image <- if (any(risk_statuses == "fail") || score <= 4) "fail" else if (any(risk_statuses == "warn") || score < 8) "warn" else "pass"
  if (!identical(image_status, derived_image)) fail("Visual QA status disagrees with score/top risks: ", record$path)

  nature <- image$nature_guardrails %||% list()
  if (!scalar_bool(nature$checked) || !scalar_bool(nature$strict) || !identical(scalar_chr(nature$reference), "references/nature-figure-guardrails.md")) fail("Manuscript-ready visual QA must use strict Nature guardrails: ", record$path)
  checks <- nature$checks %||% list()
  expected_ids <- c("export_size_aspect", "readable_typography", "no_visible_overlap", "controlled_whitespace", "panel_balance", "thumbnail_readability", "color_grayscale_safety", "gridline_stroke_discipline", "legend_edge_burden", "actionable_remediation")
  if (!is.list(checks) || length(checks) != length(expected_ids)) fail("Nature guardrails must contain all ten checks: ", record$path)
  check_ids <- vapply(checks, function(item) if (is.list(item)) scalar_chr(item$id) else "", character(1))
  check_statuses <- vapply(checks, function(item) if (is.list(item)) scalar_chr(item$status) else "", character(1))
  if (!setequal(check_ids, expected_ids) || anyDuplicated(check_ids) || any(!check_statuses %in% c("pass", "warn", "fail"))) fail("Nature guardrail checks are malformed: ", record$path)
  derived_nature <- if (any(check_statuses == "fail")) "fail" else if (any(check_statuses == "warn")) "warn" else "pass"
  status <- scalar_chr(nature$status)
  if (!identical(status, derived_nature)) fail("Nature guardrail summary disagrees with its checks: ", record$path)
  if (status == "fail") fail("Unacceptable Nature guardrail status in ", record$path, ": fail")
  hard_codes <- unique(unlist(lapply(checks, function(item) as_string_array(item$hard_hits %||% list(), "nature hard_hits", allow_empty = TRUE)), use.names = FALSE))
  review_codes <- unique(unlist(lapply(checks, function(item) as_string_array(item$review_hits %||% list(), "nature review_hits", allow_empty = TRUE)), use.names = FALSE))
  if (!setequal(as_string_array(nature$hard_risk_codes %||% list(), "nature hard_risk_codes", allow_empty = TRUE), hard_codes) || !setequal(as_string_array(nature$review_risk_codes %||% list(), "nature review_risk_codes", allow_empty = TRUE), review_codes)) fail("Nature risk-code summaries disagree with checks: ", record$path)
  if (status == "pass" && image_status != "pass") fail("Nature pass cannot override a non-pass visual QA status: ", record$path)

  review <- metadata$visual_qa_review %||% list()
  if (!nonempty_scalar(metadata$review_sidecar_path)) fail("Manuscript-ready validation requires a checksum-bound review sidecar: ", metadata_path)
  if (!identical(normalize_existing(scalar_chr(review$evidence_path)), normalize_existing(record$path))) fail("Visual review evidence does not match rendered QA record: ", metadata_path)
  if (!identical(tolower(scalar_chr(review$evidence_md5)), tolower(unname(tools::md5sum(record$path)[[1L]])))) fail("Visual review evidence checksum is stale: ", metadata_path)
  if (status == "warn" && !(identical(scalar_chr(review$status), "accepted_warn") && scalar_bool(review$exception_recorded) && nonempty_scalar(review$exception_reason))) fail("Visual QA warning requires a structured accepted_warn review sidecar: ", metadata_path)
  if (status == "pass" && !identical(scalar_chr(review$status), "pass")) fail("Visual QA pass requires review sidecar status pass: ", metadata_path)
  invisible(status)
}

validate_old_vs_new <- function(metadata, media_paths, metadata_path, visual_record) {
  figure_spec <- metadata$figure_spec %||% list()
  old_path <- scalar_chr(figure_spec$old_figure_path)
  if (!nzchar(old_path)) return(invisible("not_applicable"))
  if (!nonempty_scalar(metadata$review_sidecar_path)) fail("Declared old figure requires a checksum-bound review sidecar: ", metadata_path)
  old_path <- normalize_existing(old_path)
  review <- metadata$old_vs_new_review %||% list()
  if (!identical(scalar_chr(review$status), "provided")) fail("Declared old figure requires provided old-vs-new review evidence: ", metadata_path)
  evidence_path <- normalize_existing(scalar_chr(review$evidence_path))
  if (!identical(tolower(scalar_chr(review$evidence_md5)), tolower(unname(tools::md5sum(evidence_path)[[1L]])))) fail("Old-vs-new review evidence checksum is stale: ", metadata_path)
  evidence <- pp_parse_json_file(evidence_path)$old_vs_new_visual_qa %||% list()
  if (scalar_num(evidence$comparison_schema_version) != 3 || !identical(scalar_chr(evidence$tool_id), "paperplot-compare-old-new-figures") || !scalar_bool(evidence$checked) || !identical(scalar_chr(evidence$status), "pass") || !identical(scalar_chr(evidence$final_verdict), "improved")) fail("Old-vs-new evidence must be checked, pass, and conclude improved: ", evidence_path)
  comparison_invocation <- evidence$invocation %||% list()
  if (!(scalar_bool(comparison_invocation$strict_nature) || scalar_bool(comparison_invocation$new_strict_nature))) fail("Old-vs-new comparison must run strict Nature QA on the new figure: ", evidence_path)
  replay_comparison_evidence(evidence_path, evidence)
  if (!scalar_chr(evidence$deterministic_verdict) %in% c("improved", "mixed", "same") || scalar_bool(evidence$severe_new_panel_risk) || scalar_bool(evidence$new_nature_guardrails_failed)) fail("Old-vs-new deterministic hard gates do not permit improvement: ", evidence_path)
  old_score <- scalar_num(evidence$old_score); new_score <- scalar_num(evidence$new_score)
  if (is.na(old_score) || is.na(new_score) || new_score < old_score || new_score < 8) fail("Old-vs-new readiness scores do not support improvement: ", evidence_path)
  rubric <- evidence$review_rubric %||% list()
  expected_dimensions <- c("message_clarity", "scientific_completeness", "visual_hierarchy", "proportional_balance", "readability_at_target_size", "statistical_expression", "color_legend_discipline", "data_preservation")
  rows <- rubric$rows %||% list()
  if (!scalar_bool(rubric$provided) || !identical(scalar_chr(rubric$status), "improved") || !is.list(rows) || length(rows) != length(expected_dimensions)) fail("Old-vs-new requires a complete improved review rubric: ", evidence_path)
  dimensions <- vapply(rows, function(row) if (is.list(row)) scalar_chr(row$dimension) else "", character(1))
  if (!setequal(dimensions, expected_dimensions) || anyDuplicated(dimensions)) fail("Old-vs-new rubric dimensions are incomplete or duplicated: ", evidence_path)
  old_values <- vapply(rows, function(row) scalar_num(row$old_score), numeric(1)); new_values <- vapply(rows, function(row) scalar_num(row$new_score), numeric(1))
  if (any(is.na(c(old_values, new_values))) || any(old_values < 1 | old_values > 5) || any(new_values < 1 | new_values > 5)) fail("Old-vs-new rubric scores must be 1-5: ", evidence_path)
  if (sum(old_values) != scalar_num(rubric$old_total) || sum(new_values) != scalar_num(rubric$new_total) || sum(new_values) - sum(old_values) != scalar_num(rubric$delta) || sum(new_values) <= sum(old_values)) fail("Old-vs-new rubric totals are inconsistent: ", evidence_path)
  new_summary <- evidence$new_qa_summary %||% list()
  new_nature <- new_summary$nature_guardrails %||% list()
  if (!scalar_bool(new_nature$checked) || !scalar_bool(new_nature$strict) || scalar_chr(new_nature$status) == "fail") fail("Old-vs-new new figure lacks acceptable strict Nature evidence: ", evidence_path)
  if (!identical(normalize_existing(scalar_chr(evidence$old_image)), old_path)) fail("Old-vs-new old image does not match figure_spec: ", evidence_path)
  if (!identical(tolower(scalar_chr(evidence$old_image_md5)), tolower(unname(tools::md5sum(old_path)[[1L]])))) fail("Old-vs-new old image checksum is missing or stale: ", evidence_path)
  new_path <- normalize_existing(scalar_chr(evidence$new_image))
  if (!new_path %in% vapply(media_paths, normalize_existing, character(1))) fail("Old-vs-new new image does not match the figure bundle: ", evidence_path)
  if (!identical(tolower(scalar_chr(evidence$new_image_md5)), tolower(unname(tools::md5sum(new_path)[[1L]])))) fail("Old-vs-new new image checksum is missing or stale: ", evidence_path)
  current_visual <- visual_record$payload$image_qa %||% list()
  if (!identical(new_path, normalize_existing(scalar_chr(current_visual$input_path))) || !identical(scalar_chr(evidence$new_analysis_fingerprint), scalar_chr(current_visual$analysis_fingerprint))) fail("Old-vs-new new-image analysis is not bound to the current rendered-image QA: ", evidence_path)
  if (new_score != scalar_num(current_visual$manuscript_readiness_score) || !identical(scalar_chr(new_nature$status), scalar_chr((current_visual$nature_guardrails %||% list())$status))) fail("Old-vs-new new score or strict summary disagrees with current visual QA: ", evidence_path)
  invisible("pass")
}

metadata_files <- find_files("_metadata\\.json$")
if (length(metadata_files) < 1L) fail("Missing metadata JSON output")
metadata_stems <- sub("_metadata\\.json$", "", metadata_files)
core_candidates <- find_files("(\\.pdf$|\\.png$|_notes\\.md$|_qa\\.md$|_review\\.json$|_label_key\\.csv$|_sample_order\\.csv$|_plotting_data\\.tsv$)")
qa_generated <- character()
for (record in visual_records) {
  payload <- record$payload
  if (is.list(payload$image_qa) && scalar_num(payload$image_qa$visual_qa_schema_version) %in% c(2, 3) && identical(scalar_chr(payload$image_qa$tool_id), "paperplot-visual-qa-rendered-image")) {
    image <- payload$image_qa
    qa_generated <- c(qa_generated, file.path(dirname(record$path), "visual_qa.md"))
    derived <- list(
      list(path = scalar_chr(image$grayscale_preview), md5 = scalar_chr(image$grayscale_preview_md5)),
      list(path = scalar_chr((image$rasterization %||% list())$raster_path), md5 = scalar_chr((image$rasterization %||% list())$raster_md5))
    )
    for (item in derived) {
      value <- item$path
      if (nzchar(value) && file.exists(value) && dirname(normalize_existing(value)) == normalize_existing(dirname(record$path)) && nzchar(item$md5) && identical(tolower(item$md5), tolower(unname(tools::md5sum(value)[[1L]])))) qa_generated <- c(qa_generated, value)
    }
  }
  if (is.list(payload$old_vs_new_visual_qa) && scalar_num(payload$old_vs_new_visual_qa$comparison_schema_version) %in% c(2, 3) && identical(scalar_chr(payload$old_vs_new_visual_qa$tool_id), "paperplot-compare-old-new-figures")) qa_generated <- c(qa_generated, file.path(dirname(record$path), "old_vs_new_visual_qa.md"))
}
qa_generated <- unique(normalizePath(qa_generated[file.exists(qa_generated)], mustWork = TRUE))
normalized_candidates <- normalizePath(core_candidates, mustWork = TRUE)
core_candidates <- core_candidates[!normalized_candidates %in% qa_generated]
candidate_stems <- sub("(_notes\\.md|_qa\\.md|_review\\.json|_label_key\\.csv|_sample_order\\.csv|_plotting_data\\.tsv|\\.pdf|\\.png)$", "", core_candidates)
orphaned <- core_candidates[!candidate_stems %in% metadata_stems]
if (length(orphaned) > 0L) fail("Core figure artifacts lack stem-matched metadata: ", paste(orphaned, collapse = ", "))

allowed_domains <- c("general", "bioinformatics")
allowed_cognitive <- c("pass", "warn", "not_recorded")
counts <- c(pdf = 0L, png = 0L, notes = 0L, metadata = length(metadata_files), qa = 0L, review = 0L, visual_qa = 0L, label_key = 0L, plotting_data = 0L)

for (metadata_path in metadata_files) {
  stem <- sub("_metadata\\.json$", "", metadata_path)
  paths <- list(pdf = paste0(stem, ".pdf"), png = paste0(stem, ".png"), notes = paste0(stem, "_notes.md"), qa = paste0(stem, "_qa.md"))
  check_media(paths$pdf, "pdf"); check_media(paths$png, "png")
  check_file(paths$notes, "notes", 50L); check_file(paths$qa, "QA report", 50L); check_file(metadata_path, "metadata JSON", 50L)
  counts[c("pdf", "png", "notes", "qa")] <- counts[c("pdf", "png", "notes", "qa")] + 1L

  metadata <- pp_parse_json_file(metadata_path)
  if (!is.list(metadata) || pp_is_json_null(metadata)) fail("Metadata JSON root must be an object: ", metadata_path)
  review_result <- apply_review_sidecar(metadata, metadata_path, paths$qa, stem)
  metadata <- review_result$metadata
  if (nzchar(review_result$path)) counts[["review"]] <- counts[["review"]] + 1L
  required_top <- c("figure_id", "template_id", "backend", "helper_version", "task_type", "figure_role", "scientific_message", "plot_type", "journal_profile", "analysis_domain")
  for (key in required_top) if (!nonempty_scalar(metadata[[key]])) fail("Metadata missing ", key, ": ", metadata_path)
  if (!identical(scalar_chr(metadata$backend), "R/ggplot2")) fail("Unsupported metadata backend: ", metadata_path)
  exports <- metadata$export %||% list()
  if (!is.list(exports) || !nonempty_scalar(exports$pdf) || !nonempty_scalar(exports$png)) fail("Metadata export must record PDF and PNG: ", metadata_path)
  if (!identical(normalize_existing(scalar_chr(exports$pdf)), normalize_existing(paths$pdf)) || !identical(normalize_existing(scalar_chr(exports$png)), normalize_existing(paths$png))) fail("Metadata export paths do not match the stem bundle: ", metadata_path)
  schema <- scalar_num(metadata$figure_spec_schema_version)
  if (is.na(schema) || schema != 2) fail("Metadata figure_spec_schema_version must equal 2: ", metadata_path)
  domain <- scalar_chr(metadata$analysis_domain)
  if (!domain %in% allowed_domains) fail("Unknown analysis_domain in ", metadata_path, ": ", domain)

  style <- metadata$style %||% list()
  expected_text <- c(target_text_pt = 9, compact_text_pt = 8, panel_label_pt = 12, min_text_pt = 6)
  for (key in names(expected_text)) if (is.na(scalar_num(style[[key]])) || scalar_num(style[[key]]) != expected_text[[key]]) fail("Metadata ", key, " must equal ", expected_text[[key]], ": ", metadata_path)

  png <- read_png_geometry(paths$png)
  profile <- validate_profile(metadata, metadata_path)
  if (is.finite(profile$width_cm)) {
    if (!is.finite(png$x_ppm) || !is.finite(png$y_ppm) || png$x_ppm <= 0 || png$y_ppm <= 0) fail("PNG lacks physical-resolution metadata required for geometry validation: ", paths$png)
    actual_width <- png$width_px / png$x_ppm * 100
    actual_height <- png$height_px / png$y_ppm * 100
    actual_dpi_x <- png$x_ppm * 0.0254
    actual_dpi_y <- png$y_ppm * 0.0254
    tolerance_cm <- 0.06
    if (abs(actual_width - profile$width_cm) > tolerance_cm || abs(actual_height - profile$height_cm) > tolerance_cm) fail("PNG physical dimensions do not match export_geometry: ", paths$png)
    if (abs(actual_dpi_x - profile$dpi) > 0.5 || abs(actual_dpi_y - profile$dpi) > 0.5) fail("PNG physical DPI does not match export_geometry: ", paths$png)
  }

  cognitive <- metadata$cognitive_load_review %||% list()
  validate_cognitive_review(cognitive, metadata_path)

  validate_bioinformatics(metadata, stem, metadata_path)
  if (file.exists(paste0(stem, "_plotting_data.tsv"))) counts[["plotting_data"]] <- counts[["plotting_data"]] + 1L

  qa_report <- parse_qa_report(paths$qa)
  required_qa_gates <- c("figure_spec", "cognitive_load_review", "bioinformatics_validation", "output_pdf", "output_png", "notes", "metadata")
  missing_qa_gates <- setdiff(required_qa_gates, qa_report$gate_names)
  if (length(missing_qa_gates) > 0L) fail("QA report lacks required gates in ", paths$qa, ": ", paste(missing_qa_gates, collapse = ", "))
  qa_status <- qa_report$status
  metadata_qa <- scalar_chr((metadata$qa %||% list())$status)
  if (!metadata_qa %in% c("pass", "warn", "fail") || !identical(metadata_qa, qa_status)) fail("Metadata and QA report overall status disagree: ", metadata_path)
  if (strict && qa_status != "pass") fail("Manuscript-ready QA status must be pass: ", paths$qa)

  notes_text <- paste(readLines(paths$notes, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  notes_sections <- c("Scientific", "Design", "Label", "Palette", "Known", "Files")
  missing_notes <- notes_sections[!vapply(notes_sections, function(value) grepl(value, notes_text, fixed = TRUE), logical(1))]
  if (length(missing_notes) > 0L) fail("Notes missing design sections in ", paths$notes, ": ", paste(missing_notes, collapse = ", "))

  label_key <- paste0(stem, "_label_key.csv")
  strategy <- scalar_chr((metadata$label_strategy %||% list())$strategy)
  if (grepl("rank_index", strategy, fixed = TRUE) && !file.exists(label_key)) fail("Rank-index strategy requires a stem-matched label key: ", metadata_path)
  if (file.exists(label_key)) {
    check_file(label_key, "label key", 20L)
    counts[["label_key"]] <- counts[["label_key"]] + 1L
  }

  visual <- find_visual_record(c(paths$pdf, paths$png))
  if (!is.null(visual)) counts[["visual_qa"]] <- counts[["visual_qa"]] + 1L
  if (strict) {
    validate_visual_qa(visual, c(paths$pdf, paths$png), metadata, metadata_path)
    validate_old_vs_new(metadata, c(paths$pdf, paths$png), metadata_path, visual)
  }
}

cat("figure output validation passed\n")
cat("mode: ", if (strict) "manuscript-ready" else "candidate", "\n", sep = "")
cat("output directory: ", output_dir, "\n", sep = "")
cat(paste(paste0(names(counts), ": ", counts), collapse = ", "), "\n", sep = "")
