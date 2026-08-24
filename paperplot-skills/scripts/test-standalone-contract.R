#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(ggplot2))

script_arg <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", script_arg[grepl("^--file=", script_arg)])
script_dir <- if (length(file_arg)) dirname(normalizePath(file_arg[[1]])) else getwd()
helper_file <- file.path(script_dir, "paperplot_helpers.R")
Sys.setenv(PAPERPLOT_HELPER = helper_file)
source(helper_file)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_equal <- function(actual, expected, message, tolerance = 1e-8) {
  equal <- if (is.numeric(actual) && is.numeric(expected)) {
    length(actual) == length(expected) && all(abs(actual - expected) <= tolerance)
  } else {
    identical(actual, expected)
  }
  if (!equal) {
    stop(message, "\nactual: ", paste(actual, collapse = ", "),
         "\nexpected: ", paste(expected, collapse = ", "), call. = FALSE)
  }
}

# Theme construction must not mutate ggplot2's process-wide geom defaults.
text_default_before <- ggplot2::GeomText$default_aes$size
label_default_before <- ggplot2::GeomLabel$default_aes$size
invisible(pp_theme(base_size = 7))
assert_true(identical(ggplot2::GeomText$default_aes$size, text_default_before),
            "pp_theme() changed the global GeomText default")
assert_true(identical(ggplot2::GeomLabel$default_aes$size, label_default_before),
            "pp_theme() changed the global GeomLabel default")

# Documented shell-safe environment keys must override registry values.
old_dense <- Sys.getenv("PAPERPLOT_POINT_SIZES_DENSE", unset = NA_character_)
Sys.setenv(PAPERPLOT_POINT_SIZES_DENSE = "1.11")
assert_equal(pp_style_number("point_sizes.dense"), 1.11,
             "PAPERPLOT_POINT_SIZES_DENSE did not override the style registry")
if (is.na(old_dense)) Sys.unsetenv("PAPERPLOT_POINT_SIZES_DENSE") else Sys.setenv(PAPERPLOT_POINT_SIZES_DENSE = old_dense)

# Finalization fills implicit text defaults on the plot copy and preserves
# deliberate explicit sizes without touching the global geom registry.
implicit_plot <- ggplot(data.frame(x = 1, y = 1, label = "A"), aes(x, y, label = label)) +
  geom_text()
implicit_final <- pp_finalize(implicit_plot)
expected_text_size <- pp_text_size("body")
assert_equal(implicit_final$layers[[1]]$aes_params$size, expected_text_size,
             "pp_finalize() did not fill the implicit text size")
assert_true(identical(ggplot2::GeomText$default_aes$size, text_default_before),
            "pp_finalize() leaked a global GeomText change")

explicit_plot <- ggplot(data.frame(x = 1, y = 1, label = "A"), aes(x, y, label = label)) +
  geom_text(size = 2.25)
explicit_final <- pp_finalize(explicit_plot)
assert_equal(explicit_final$layers[[1]]$aes_params$size, 2.25,
             "pp_finalize() overwrote an explicit text size")

# Machine-only advice must remain local and must not create .GlobalEnv state.
if (exists("applied", envir = .GlobalEnv, inherits = FALSE)) rm("applied", envir = .GlobalEnv)
manual_fix_plot <- pp_apply_machine_fixes(
  ggplot(data.frame(x = 1, y = 1), aes(x, y)) + geom_point(),
  list(machine_fixes = list(list(param = "label_repel", value = TRUE)))
)
assert_true(!exists("applied", envir = .GlobalEnv, inherits = FALSE),
            "pp_apply_machine_fixes() leaked an 'applied' variable into .GlobalEnv")
assert_true(any(grepl("manual:", attr(manual_fix_plot, "pp_machine_fixes_applied"), fixed = TRUE)),
            "Manual-only label advice was not recorded")

# A one-retry loop means QA runs once before and once after the retry.
qa_calls <- 0L
pp_run_visual_qa <- function(...) {
  qa_calls <<- qa_calls + 1L
  if (qa_calls == 1L) {
    list(
      available = TRUE,
      status = "warn",
      qa_dir = tempfile("qa-initial-"),
      machine_fixes = list(list(param = "legend.position", value = "bottom"))
    )
  } else {
    list(available = TRUE, status = "pass", qa_dir = tempfile("qa-final-"), machine_fixes = list())
  }
}
loop_plot <- ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_point() + pp_theme()
loop_stem <- tempfile("paperplot-contract-loop-")
loop_outputs <- pp_save_all_with_qa_loop(loop_plot, loop_stem, formats = "png", max_iterations = 1L)
assert_equal(qa_calls, 2L, "QA was not rerun after the auto-fix render")
assert_equal(attr(loop_outputs, "qa_iterations"), 1L, "QA retry count was not recorded")
assert_equal(attr(loop_outputs, "qa_initial_status"), "warn", "Initial QA status was not recorded")
assert_equal(attr(loop_outputs, "qa_final_status"), "pass", "Final QA status did not come from the post-fix render")

# A retry that does not improve status/score must be rejected and the initial
# deterministic render restored.
qa_calls <- 0L
pp_run_visual_qa <- function(...) {
  qa_calls <<- qa_calls + 1L
  if (qa_calls == 1L) {
    list(available = TRUE, status = "warn", manuscript_readiness_score = 8,
         qa_dir = tempfile("qa-initial-"),
         machine_fixes = list(list(param = "axis.text.x.angle", value = 45)))
  } else {
    list(available = TRUE, status = "warn", manuscript_readiness_score = 7,
         qa_dir = tempfile("qa-candidate-"), machine_fixes = list())
  }
}
rejected_outputs <- pp_save_all_with_qa_loop(
  loop_plot, tempfile("paperplot-contract-reject-"), formats = "png", max_iterations = 1L
)
assert_equal(qa_calls, 2L, "Rejected QA candidate was not evaluated")
assert_equal(length(attr(rejected_outputs, "qa_machine_fixes")), 0L,
             "A non-improving machine fix was recorded as accepted")
assert_true(length(attr(rejected_outputs, "qa_machine_fixes_rejected")) == 1L,
            "A non-improving machine fix was not recorded as rejected")
assert_equal(attr(rejected_outputs, "qa_final_status"), "warn",
             "Rejected candidate did not restore the initial QA result")

if (requireNamespace("jsonlite", quietly = TRUE)) {
  metadata_path <- tempfile("paperplot-contract-metadata-", fileext = ".json")
  figure_spec <- pp_figure_spec(
    figure_id = "contract_test",
    template_id = "standalone-contract",
    scientific_message = "Verify QA-loop metadata propagation.",
    plot_type = "scatter",
    output_preset = "nature_half"
  )
  extended_outputs <- pp_extend_output_files(loop_outputs, notes = "notes.md")
  assert_equal(attr(extended_outputs, "qa_final_status"), "pass",
               "Extending output files dropped QA-loop attributes")
  pp_write_metadata(metadata_path, figure_spec, output_files = extended_outputs)
  metadata <- jsonlite::fromJSON(metadata_path, simplifyVector = FALSE)
  assert_equal(metadata$qa_loop$initial_status, "warn", "Metadata lost the initial QA status")
  assert_equal(metadata$qa_loop$final_status, "pass", "Metadata lost the final QA status")
  assert_equal(metadata$qa_loop$iterations, 1L, "Metadata lost the QA retry count")
}

cat("standalone contract tests passed\n")
