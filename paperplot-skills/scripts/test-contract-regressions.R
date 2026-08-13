#!/usr/bin/env Rscript

fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)
expect_true <- function(value, label) if (!isTRUE(value)) fail("Expected TRUE: ", label)
expect_error <- function(expr, label) {
  result <- try(force(expr), silent = TRUE)
  if (!inherits(result, "try-error")) fail("Expected error: ", label)
  invisible(result)
}

repo_root <- normalizePath(getwd(), mustWork = TRUE)
skill_root <- file.path(repo_root, "paperplot-skills")
helper_path <- file.path(skill_root, "scripts", "paperplot_helpers.R")
parser_path <- file.path(skill_root, "scripts", "lib", "contract-parsers.R")
validator_path <- file.path(skill_root, "scripts", "validate-figure-output.R")
visual_script <- file.path(skill_root, "scripts", "visual-qa-rendered-image.py")
compare_script <- file.path(skill_root, "scripts", "compare-old-new-figures.py")
rscript_bin <- Sys.getenv("PAPERPLOT_RSCRIPT", unset = file.path(R.home("bin"), "Rscript"))
python_bin <- Sys.getenv("PAPERPLOT_PYTHON", unset = "")
if (!nzchar(python_bin)) {
  hits <- unname(Sys.which(c("python3", "python"))); hits <- hits[nzchar(hits)]
  python_bin <- if (length(hits) > 0L) hits[[1L]] else ""
}
if (!nzchar(python_bin)) fail("Contract regression tests require PAPERPLOT_PYTHON with Pillow.")
pillow <- suppressWarnings(system2(python_bin, c("-c", shQuote("from PIL import Image")), stdout = TRUE, stderr = TRUE))
pillow_status <- attr(pillow, "status"); if (is.null(pillow_status)) pillow_status <- 0L
if (pillow_status != 0L) fail("Contract regression tests require a Python interpreter with Pillow: ", python_bin)
source(helper_path)
source(parser_path)

work_root <- file.path("/tmp", paste0("paperplot-contract-regressions-", format(Sys.time(), "%Y%m%d-%H%M%S")))
dir.create(work_root, recursive = TRUE, showWarnings = FALSE)

run_process <- function(command, args) {
  output <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status") %||% 0L
  list(status = status, output = output)
}
run_validator <- function(path, strict = FALSE) run_process(rscript_bin, c(validator_path, path, if (strict) "--manuscript-ready"))
expect_validator <- function(path, strict, should_pass, label) {
  result <- run_validator(path, strict)
  if (should_pass && result$status != 0L) fail(label, " unexpectedly failed: ", paste(result$output, collapse = " | "))
  if (!should_pass && result$status == 0L) fail(label, " unexpectedly passed")
  invisible(result)
}
replace_file_text <- function(path, old, new, fixed = TRUE) {
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  text <- if (fixed) sub(old, new, text, fixed = TRUE) else sub(old, new, text, perl = TRUE)
  writeLines(text, path, useBytes = TRUE)
}

make_notes <- function(path, output_files) {
  writeLines(c(
    "# Figure Notes", "", "## Scientific Message", "Contract fixture.", "",
    "## Design Decisions", "Minimal deterministic fixture.", "",
    "## Label Strategy", "No lookup labels.", "", "## Palette", "Two muted groups.", "",
    "## Known Limitations", "Synthetic contract test only.", "", "## Output Files",
    paste(names(output_files), unname(output_files), sep = ": ")
  ), path)
}

make_fixture <- function(name, bio = FALSE, with_old_figure = FALSE) {
  out_dir <- file.path(work_root, name)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(20260813)
  n <- 320L
  data <- data.frame(
    Feature_ID = paste0("F", seq_len(n)),
    X_Value = seq_len(n),
    Y_Value = 20 + seq_len(n) * 0.06 + sin(seq_len(n) / 8) * 5 + stats::rnorm(n, sd = 1.6),
    Group = rep(c("A", "B"), length.out = n), stringsAsFactors = FALSE
  )
  input_path <- file.path(out_dir, "input.tsv")
  utils::write.table(data, input_path, sep = "\t", quote = FALSE, row.names = FALSE)
  stem <- file.path(out_dir, "figure")
  notes_path <- paste0(stem, "_notes.md")
  metadata_path <- paste0(stem, "_metadata.json")
  qa_path <- paste0(stem, "_qa.md")
  plotting_path <- paste0(stem, "_plotting_data.tsv")
  old_path <- NULL
  if (with_old_figure) {
    old_path <- file.path(work_root, paste0(name, "-old.png"))
    grDevices::png(old_path, width = 1800, height = 1200, res = 150, bg = "white")
    graphics::par(mar = c(12, 12, 12, 12))
    graphics::plot(c(5, 95), c(5, 95), xlim = c(0, 100), ylim = c(0, 100), pch = 16, cex = 0.35, col = "grey70", axes = FALSE, ann = FALSE)
    grDevices::dev.off()
  }
  spec <- pp_figure_spec(
    figure_id = "contract_fixture", template_id = "contract-regression",
    task_type = if (with_old_figure) "redesign" else "new",
    scientific_message = "Validate the output contract.", plot_type = "scatter",
    output_preset = "nature_half", analysis_domain = if (bio) "bioinformatics" else "general",
    old_figure_path = old_path
  )
  metric <- pp_metric_spec("Y_Value", "Y value", "unitless", "neutral")
  cognitive <- pp_cognitive_load_review(3, 2, 1, 2, chart_family = "scatter")
  bio_validation <- NULL
  if (bio) {
    pp_write_plotting_data(plotting_path, data)
    bio_validation <- pp_bioinformatics_validation(
      status = "pass", input_paths = input_path, organism = "Chenopodium quinoa",
      reference_version = "QQ74 v2", coordinate_system = "not_applicable_gene_level",
      sample_order = "input Feature_ID order", units_transforms_denominators = "Raw unitless fixture values; all 320 rows",
      statistics = "Descriptive fixture; no inferential test", plotting_data_path = plotting_path,
      notes = "Regression fixture", source_records_checked = TRUE, sample_order_checked = TRUE,
      units_checked = TRUE, statistics_checked = TRUE, plotting_data_checked = TRUE
    )
  }
  plot <- ggplot2::ggplot(data, ggplot2::aes(x = X_Value, y = Y_Value, colour = Group)) +
    ggplot2::geom_point(size = 1.45, alpha = 0.82) + pp_scale_color(data$Group) + pp_theme()
  outputs <- pp_save_all(plot, stem, preset = spec$output_preset)
  make_notes(notes_path, outputs)
  qa <- pp_qa_summary(
    pp_qa_preflight(spec, metric, cognitive_load_review = cognitive, bioinformatics_validation = bio_validation),
    pp_qa_result("fixture", "pass", "contract fixture completed")
  )
  pp_write_metadata(
    metadata_path, spec, metric, outputs,
    layout = list(type = "single_panel", width_cm = 8.9, height_cm = 6),
    qa = list(status = pp_qa_status(qa)), data_summary = pp_data_summary(data),
    cognitive_load_review = cognitive, bioinformatics_validation = bio_validation,
    sidecars = if (bio) list(plotting_data = plotting_path) else list()
  )
  qa <- pp_qa_summary(qa, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
  pp_write_qa_report(qa_path, qa)
  list(
    dir = out_dir, stem = stem, metadata = metadata_path, qa = qa_path,
    pdf = outputs[["pdf"]], png = outputs[["png"]], input = input_path,
    plotting = if (bio) plotting_path else "", old = old_path,
    visual = file.path(out_dir, "visual-qa", "visual_qa.json"),
    comparison = file.path(out_dir, "old-vs-new", "old_vs_new_visual_qa.json"),
    review = paste0(stem, "_review.json")
  )
}

run_visual <- function(fixture) {
  out <- dirname(fixture$visual)
  unlink(out, recursive = TRUE, force = TRUE)
  result <- run_process(python_bin, c(visual_script, fixture$png, "--out", out, "--strict-nature", "--ocr", "off"))
  if (result$status != 0L) fail("Real strict visual QA fixture failed: ", paste(result$output, collapse = " | "))
  payload <- pp_parse_json_file(fixture$visual)$image_qa
  status <- payload$nature_guardrails$status
  if (!status %in% c("pass", "warn")) fail("Real visual fixture is not acceptable: ", status)
  status
}

write_review_scores <- function(path) {
  dimensions <- c("message_clarity", "scientific_completeness", "visual_hierarchy", "proportional_balance", "readability_at_target_size", "statistical_expression", "color_legend_discipline", "data_preservation")
  payload <- list(
    rubric_version = "1.0", dimensions = stats::setNames(lapply(dimensions, function(key) list(old_score = 1L, new_score = 5L, notes = "Synthetic regression review.")), dimensions)
  )
  writeLines(pp_to_json(payload), path)
}

run_comparison <- function(fixture) {
  if (is.null(fixture$old) || !file.exists(fixture$old)) fail("Old figure fixture missing")
  out <- dirname(fixture$comparison)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  review_scores <- file.path(out, "completed-review.json")
  write_review_scores(review_scores)
  result <- run_process(python_bin, c(
    compare_script, fixture$old, fixture$png, "--out", out,
    "--review-json", review_scores, "--ocr", "off", "--new-strict-nature"
  ))
  if (result$status != 0L) fail("Real old-vs-new comparison failed: ", paste(result$output, collapse = " | "))
  evidence <- pp_parse_json_file(fixture$comparison)$old_vs_new_visual_qa
  if (!identical(evidence$status, "pass") || !identical(evidence$final_verdict, "improved")) fail("Synthetic old-vs-new fixture did not conclude improved")
  fixture$comparison
}

attach_review <- function(fixture, visual_status = NULL, old_evidence = NULL) {
  unlink(fixture$review, force = TRUE)
  visual_status <- visual_status %||% pp_parse_json_file(fixture$visual)$image_qa$nature_guardrails$status
  pp_write_review_sidecar(
    fixture$review, fixture$metadata, fixture$qa,
    visual_qa_path = fixture$visual,
    visual_status = if (visual_status == "warn") "accepted_warn" else "pass",
    visual_exception_reason = if (visual_status == "warn") "Synthetic visual warning reviewed; no hard guardrail failed." else "",
    old_vs_new_path = old_evidence
  )
}

clone_fixture <- function(fixture, name) {
  target <- file.path(work_root, name)
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  entries <- list.files(fixture$dir, recursive = TRUE, all.files = TRUE, no.. = TRUE, full.names = TRUE, include.dirs = TRUE)
  rel <- substring(entries, nchar(fixture$dir) + 2L)
  dirs <- entries[dir.exists(entries)]
  if (length(dirs) > 0L) for (dir in dirs) dir.create(file.path(target, substring(dir, nchar(fixture$dir) + 2L)), recursive = TRUE, showWarnings = FALSE)
  files <- entries[!dir.exists(entries)]
  if (length(files) > 0L && !all(file.copy(files, file.path(target, substring(files, nchar(fixture$dir) + 2L)), overwrite = TRUE))) fail("Could not clone fixture: ", name)
  old <- normalizePath(fixture$dir, mustWork = TRUE); new <- normalizePath(target, mustWork = TRUE)
  for (path in list.files(target, pattern = "\\.(json|md)$", full.names = TRUE, recursive = TRUE)) {
    text <- readLines(path, warn = FALSE, encoding = "UTF-8")
    writeLines(gsub(old, new, text, fixed = TRUE), path, useBytes = TRUE)
  }
  review <- file.path(target, "figure_review.json")
  unlink(review, force = TRUE)
  list(
    dir = target, stem = file.path(target, "figure"), metadata = file.path(target, "figure_metadata.json"),
    qa = file.path(target, "figure_qa.md"), pdf = file.path(target, "figure.pdf"), png = file.path(target, "figure.png"),
    input = file.path(target, "input.tsv"), plotting = file.path(target, "figure_plotting_data.tsv"), old = fixture$old,
    visual = file.path(target, "visual-qa", "visual_qa.json"), comparison = file.path(target, "old-vs-new", "old_vs_new_visual_qa.json"), review = review
  )
}

# Parser, writer, and frontmatter boundaries.
parsed <- pp_parse_json_text('{"emoji":"\\uD83D\\uDE00","values":[1,null,2]}')
expect_true(identical(parsed$emoji, "\U0001F600"), "Unicode surrogate pair")
expect_true(length(parsed$values) == 3L && pp_is_json_null(parsed$values[[2L]]), "JSON null sentinel")
expect_error(pp_parse_json_text('{"a":1,"a":2}'), "duplicate JSON key")
expect_error(pp_parse_json_text('{"x":"\\uD83D"}'), "isolated surrogate")
expect_error(pp_parse_json_text(paste0(strrep("[", 129), "0", strrep("]", 129))), "JSON nesting")
expect_error(pp_parse_json_text(paste0('"', strrep("a", 101), '"'), max_string_chars = 100L), "JSON string limit")
expect_error(pp_parse_json_text("[1,2,3]", max_tokens = 2L), "JSON token limit")
expect_error(pp_to_json(structure(list(1, 2), names = c("a", "a"))), "duplicate JSON writer keys")
expect_true(identical(pp_to_json(pp_json_null()), "null"), "JSON null sentinel round trip")
writer <- pp_parse_json_text(pp_to_json(list(empty = character(), object = pp_json_object(), missing = NA_character_, control = paste0("a", intToUtf8(1L), "b"))))
expect_true(is.list(writer$empty) && length(writer$empty) == 0L && is.list(writer$object) && pp_is_json_null(writer$missing), "JSON writer unambiguous empties/null")
old_outdec <- getOption("OutDec"); options(OutDec = ",")
locale_json <- pp_to_json(list(decimal = 1.25, scientific = 1e-7, negative = -0.5))
locale_roundtrip <- pp_parse_json_text(locale_json)
options(OutDec = old_outdec)
expect_true(identical(locale_roundtrip$decimal, 1.25) && identical(locale_roundtrip$scientific, 1e-7) && identical(locale_roundtrip$negative, -0.5), "locale-independent JSON numbers")
for (value in c("description: broken: [", "description: # comment", "description: null", "description: true", "description: 'a'b'")) {
  path <- file.path(work_root, paste0("frontmatter-", length(list.files(work_root)), ".md"))
  writeLines(c("---", "name: paperplot-skills", value, "---", "# Body"), path)
  expect_error(pp_parse_skill_frontmatter(path), paste("frontmatter", value))
}

# Figure-spec and provenance constraints.
v1 <- list(figure_id = "f", template_id = "t", backend = "R/ggplot2", helper_version = "legacy", task_type = "new", figure_role = "main", scientific_message = "m", plot_type = "scatter", output_preset = "nature_half")
migrated <- pp_validate_figure_spec(v1)
expect_true(migrated$figure_spec_schema_version == 2L && migrated$migrated_from_schema == 1L, "v1-to-v2 migration")
future <- migrated; future$figure_spec_schema_version <- 999L
expect_error(pp_validate_figure_spec(future), "future schema")
expect_error(pp_figure_spec("f", "t", scientific_message = "m", plot_type = "scatter", output_preset = "ncomms", journal_profile = "nature_like"), "branded conflict")
expect_error(pp_figure_spec("f", "t", scientific_message = "m", plot_type = "scatter", output_preset = "double_column", journal_profile = "medical_radiology"), "profile envelope")
expect_error(pp_bioinformatics_validation(status = "pass", input_paths = "/missing.tsv", organism = "x", reference_version = "x", coordinate_system = "not_applicable_gene_level", sample_order = "x", units_transforms_denominators = "x", statistics = "x", plotting_data_path = "/missing_plotting_data.tsv"), "missing provenance files")

# Real-tool positive strict fixtures.
general <- make_fixture("general-pass")
general_visual_status <- run_visual(general); attach_review(general, general_visual_status)
bio <- make_fixture("bio-pass", bio = TRUE)
bio_visual_status <- run_visual(bio); attach_review(bio, bio_visual_status)
expect_validator(general$dir, FALSE, TRUE, "general candidate")
expect_validator(general$dir, TRUE, TRUE, "general real-tool manuscript-ready")
expect_validator(bio$dir, TRUE, TRUE, "bio real-tool manuscript-ready")
old_vs_new <- make_fixture("old-vs-new-pass", with_old_figure = TRUE)
old_visual_status <- run_visual(old_vs_new)
old_evidence <- run_comparison(old_vs_new)
attach_review(old_vs_new, old_visual_status, old_evidence)
expect_validator(old_vs_new$dir, TRUE, TRUE, "real-tool old-vs-new manuscript-ready")

# Media false positives and malicious lengths.
invalid_pdf <- clone_fixture(general, "invalid-pdf")
writeBin(c(charToRaw("%PDF-1.4\n"), rep(charToRaw("X"), 6000L), charToRaw("\n%%EOF\n")), invalid_pdf$pdf)
expect_validator(invalid_pdf$dir, FALSE, FALSE, "fake PDF structure")
invalid_png <- clone_fixture(general, "invalid-png")
writeBin(c(as.raw(c(137,80,78,71,13,10,26,10)), as.raw(c(0,0,0,13)), charToRaw("IHDR"), as.raw(c(0,0,0,89,0,0,0,60,8,2,0,0,0)), as.raw(c(0,0,0,0)), rep(as.raw(0), 1100)), invalid_png$png)
expect_validator(invalid_png$dir, FALSE, FALSE, "fake PNG CRC/IDAT")
huge_chunk <- clone_fixture(general, "huge-png-chunk")
bytes <- readBin(huge_chunk$png, what = "raw", n = 1200L); bytes[9:12] <- as.raw(c(127,255,255,255)); writeBin(bytes, huge_chunk$png)
expect_validator(huge_chunk$dir, FALSE, FALSE, "unsafe PNG chunk length")

# QA report must contain the full common gate set and derive overall status from every row.
qa_missing_gate <- clone_fixture(general, "qa-missing-gate")
qa_lines <- readLines(qa_missing_gate$qa, warn = FALSE)
writeLines(qa_lines[!grepl("^\\| figure_spec \\|", qa_lines)], qa_missing_gate$qa)
expect_validator(qa_missing_gate$dir, FALSE, FALSE, "missing required QA gate")
qa_conflict <- clone_fixture(general, "qa-conflict")
write(c("", "| injected | fail | corrupt |"), qa_conflict$qa, append = TRUE)
expect_validator(qa_conflict$dir, FALSE, FALSE, "QA gate/overall contradiction")

# Missing or forged rendered evidence must fail strict validation.
missing_visual <- make_fixture("missing-visual")
expect_validator(missing_visual$dir, TRUE, FALSE, "missing visual QA")
forged_visual <- make_fixture("forged-visual")
dir.create(dirname(forged_visual$visual), recursive = TRUE)
forged <- list(image_qa = list(visual_qa_schema_version = 3L, tool_id = "paperplot-visual-qa-rendered-image", checked = TRUE, engine = "pillow-raster", input_path = forged_visual$png, input_md5 = pp_file_md5(forged_visual$png), input_size_bytes = file.info(forged_visual$png)$size, nature_guardrails = list(checked = TRUE, strict = TRUE, status = "pass")))
writeLines(pp_to_json(forged), forged_visual$visual)
attach_review(forged_visual, "pass")
expect_validator(forged_visual$dir, TRUE, FALSE, "incomplete forged visual schema")
internal_visual <- clone_fixture(general, "visual-internal-conflict")
replace_file_text(internal_visual$visual, '"status": "warn"', '"status": "pass"')
attach_review(internal_visual, "pass")
expect_validator(internal_visual$dir, TRUE, FALSE, "visual internal inconsistency")
rebound_visual <- clone_fixture(general, "rebound-forged-visual")
visual_payload <- pp_parse_json_file(rebound_visual$visual)
visual_payload$image_qa$image_size_px <- list(1L, 1L)
writeLines(pp_to_json(visual_payload), rebound_visual$visual)
refingerprint <- paste0("import importlib.util,json,sys; spec=importlib.util.spec_from_file_location('vqa',sys.argv[1]); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); p=sys.argv[2]; x=json.load(open(p)); x['image_qa']['analysis_fingerprint']=m.visual_analysis_fingerprint(x['image_qa']); open(p,'w').write(json.dumps(x)+'\\n')")
result <- run_process(python_bin, c("-c", shQuote(refingerprint), visual_script, rebound_visual$visual))
if (result$status != 0L) fail("Could not refingerprint forged visual fixture: ", paste(result$output, collapse = " | "))
attach_review(rebound_visual, general_visual_status)
expect_validator(rebound_visual$dir, TRUE, FALSE, "refingerprinted visual metrics disagree with pixel replay")
stale_review <- clone_fixture(general, "stale-review")
attach_review(stale_review, general_visual_status)
write(c("", "<!-- changed -->"), stale_review$qa, append = TRUE)
expect_validator(stale_review$dir, TRUE, FALSE, "stale review sidecar")
no_review_sidecar <- clone_fixture(general, "no-review-sidecar")
unlink(no_review_sidecar$review, force = TRUE)
expect_validator(no_review_sidecar$dir, TRUE, FALSE, "visual evidence without review sidecar")

# Forged old-vs-new evidence must fail despite matching hashes.
forged_old <- make_fixture("forged-old", with_old_figure = TRUE)
forged_old_status <- run_visual(forged_old)
dir.create(dirname(forged_old$comparison), recursive = TRUE)
fake_comparison <- list(old_vs_new_visual_qa = list(
  comparison_schema_version = 3L, tool_id = "paperplot-compare-old-new-figures", checked = TRUE,
  old_image = forged_old$old, old_image_md5 = pp_file_md5(forged_old$old), new_image = forged_old$png,
  new_image_md5 = pp_file_md5(forged_old$png), status = "pass", final_verdict = "improved"
))
writeLines(pp_to_json(fake_comparison), forged_old$comparison)
attach_review(forged_old, forged_old_status, forged_old$comparison)
expect_validator(forged_old$dir, TRUE, FALSE, "incomplete forged old-vs-new schema")
rebound_comparison <- clone_fixture(old_vs_new, "rebound-forged-comparison")
comparison_payload <- pp_parse_json_file(rebound_comparison$comparison)
comparison_payload$old_vs_new_visual_qa$new_score <- 10L
writeLines(pp_to_json(comparison_payload), rebound_comparison$comparison)
refingerprint <- paste0("import importlib.util,json,sys; spec=importlib.util.spec_from_file_location('cmp',sys.argv[1]); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); p=sys.argv[2]; x=json.load(open(p)); x['old_vs_new_visual_qa']['analysis_fingerprint']=m.comparison_analysis_fingerprint(x['old_vs_new_visual_qa']); open(p,'w').write(json.dumps(x)+'\\n')")
result <- run_process(python_bin, c("-c", shQuote(refingerprint), compare_script, rebound_comparison$comparison))
if (result$status != 0L) fail("Could not refingerprint forged comparison fixture: ", paste(result$output, collapse = " | "))
attach_review(rebound_comparison, old_visual_status, rebound_comparison$comparison)
expect_validator(rebound_comparison$dir, TRUE, FALSE, "refingerprinted comparison score disagrees with deterministic replay")

# Full-tree orphan and metadata tampering.
orphan <- clone_fixture(general, "orphan")
file.copy(orphan$png, file.path(orphan$dir, "orphan.png"))
expect_validator(orphan$dir, FALSE, FALSE, "orphan core artifact")
unknown_preset <- clone_fixture(general, "unknown-preset")
replace_file_text(unknown_preset$metadata, '"preset": "nature_half"', '"preset": "custom"')
expect_validator(unknown_preset$dir, FALSE, FALSE, "unknown export preset")
bad_dpi <- clone_fixture(general, "bad-dpi")
replace_file_text(bad_dpi$metadata, '"dpi": 600', '"dpi": 1')
expect_validator(bad_dpi$dir, FALSE, FALSE, "metadata/PNG DPI mismatch")
stale_profile_date <- clone_fixture(general, "stale-profile-date")
replace_file_text(stale_profile_date$metadata, '"last_checked": "2026-08-12"', '"last_checked": "1900-01-01"')
expect_validator(stale_profile_date$dir, FALSE, FALSE, "profile last_checked mismatch")
incomplete_cognitive <- clone_fixture(general, "incomplete-cognitive")
metadata_payload <- pp_parse_json_file(incomplete_cognitive$metadata)
metadata_payload$cognitive_load_review$counts <- NULL
writeLines(pp_to_json(metadata_payload), incomplete_cognitive$metadata)
expect_validator(incomplete_cognitive$dir, FALSE, FALSE, "incomplete cognitive schema")
forged_cognitive <- clone_fixture(general, "forged-cognitive")
metadata_payload <- pp_parse_json_file(forged_cognitive$metadata)
metadata_payload$cognitive_load_review$counts$colors <- 9
metadata_payload$cognitive_load_review$status <- "pass"
metadata_payload$cognitive_load_review$exceeded <- list()
writeLines(pp_to_json(metadata_payload), forged_cognitive$metadata)
expect_validator(forged_cognitive$dir, FALSE, FALSE, "forged cognitive pass")
future_metadata <- clone_fixture(general, "future-schema")
replace_file_text(future_metadata$metadata, '"figure_spec_schema_version": 2', '"figure_spec_schema_version": 999')
expect_validator(future_metadata$dir, FALSE, FALSE, "future metadata schema")
duplicate <- clone_fixture(general, "duplicate-key")
text <- readLines(duplicate$metadata, warn = FALSE); line <- which(grepl('"backend": "R/ggplot2"', text, fixed = TRUE))[1L]; text <- append(text, '  "backend": "wrong",', after = line - 1L); writeLines(text, duplicate$metadata)
expect_validator(duplicate$dir, FALSE, FALSE, "duplicate metadata key")

# Bioinformatics null, stale paths, and malformed TSV.
null_bio <- clone_fixture(bio, "null-bio")
replace_file_text(null_bio$metadata, paste0('"', normalizePath(null_bio$input), '"'), "null")
expect_validator(null_bio$dir, FALSE, FALSE, "null bio input")
missing_paths <- clone_fixture(bio, "missing-paths")
replace_file_text(missing_paths$metadata, normalizePath(missing_paths$input), "/definitely/missing/input.tsv")
expect_validator(missing_paths$dir, FALSE, FALSE, "missing bio input")
malformed_tsv <- clone_fixture(bio, "malformed-tsv")
writeLines(c("A\tB", "1\t2", "3,4"), malformed_tsv$plotting)
metadata_payload <- pp_parse_json_file(malformed_tsv$metadata)
metadata_payload$bioinformatics_validation$plotting_data$md5 <- pp_file_md5(malformed_tsv$plotting)
metadata_payload$bioinformatics_validation$plotting_data$size_bytes <- unname(file.info(malformed_tsv$plotting)[["size"]])
writeLines(pp_to_json(metadata_payload), malformed_tsv$metadata)
expect_validator(malformed_tsv$dir, FALSE, FALSE, "malformed plotting TSV")

cat("contract regression tests passed\n")
cat("temporary contract root: ", work_root, "\n", sep = "")
