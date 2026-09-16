#!/usr/bin/env Rscript
source("paperplot-skills/scripts/paperplot_helpers.R")
check <- function(value, message) if (!isTRUE(value)) stop(message)
fails <- function(expr) check(inherits(tryCatch(force(expr), error = identity), "error"), "Expected an error")
s <- pp_render_spec(4)
check(s$width_mm == 180 && s$height_mm == 120 && s$text_pt$panel_tag == 12, "Main canvas/tag defaults")
check(pp_render_spec()$width_mm == 89, "Single-column width")
check(pp_render_spec(2, case = "igs")$width_mm == 183, "IGS canvas")
check(pp_render_spec(text_pt = list(axis_title = 8))$text_pt$axis_title == 8, "Explicit role override")
check(!all(pp_arial_faces(data.frame(family = "Helvetica", style = "Regular"))), "No silent font substitution")
args <- pp_qa_context_args(list(ocr = "required", strict_nature = TRUE, strict_detail_qa = TRUE))
check(all(c("required", "--strict-nature", "--strict-detail-qa") %in% args), "QA options propagated")
check(pp_final_qa(list(layout = "fail"), "pass")$status == "fail", "Fail propagation")
check(pp_final_qa(list(layout = "unverified"), "pass")$status == "warn", "Unavailable is not pass")
check(pp_final_qa(list(layout = "pass"))$tier == "manuscript candidate", "Human review required")
check(pp_final_qa(list(data_integrity='pass',physical_export='pass',visual_layout='pass'), "pass")$tier == "manuscript-ready", "Reviewed result")
check(pp_final_qa(list(), 'pass')$status=='warn','Empty checks cannot certify a figure')

p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
  ggplot2::geom_text(ggplot2::aes(label = cyl), size = 8) + ggplot2::theme_classic(base_size = 24)
before <- p$layers[[2]]$aes_params$size
normalized <- pp_normalize_production(p, pp_render_spec())
check(p$layers[[2]]$aes_params$size == before, "No mutation of source plot")
check(abs(normalized$layers[[2]]$aes_params$size * ggplot2::.pt - 6.5) < .01, "Normalize annotation size")
check(normalized$theme$axis.text$size == 6 && normalized$theme$text$family == "Arial", "Theme roles")
pp_assert_data_unchanged(pp_plot_evidence(p), pp_plot_evidence(normalized))
fails(pp_assert_data_unchanged(c(.94, .96), c(.96, .94)))
fails(pp_assert_data_unchanged(factor(c("A", "B")), factor(c("A", "B"), levels = c("B", "A"))))
fails(pp_normalize_production(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, size = cyl)) + ggplot2::geom_text(label = "x"), s))

source("paperplot-skills/recipes/paperplot_code_recipes.R")
fails(pp_read_recipe_data("missing.csv", "lollipop_ranked"))
check(nrow(pp_read_recipe_data("missing.csv", "lollipop_ranked", "demo")) > 0, "Explicit demo")
csv <- tempfile(fileext = ".csv")
utils::write.csv(data.frame(value = 1), csv, row.names = FALSE)
fails(pp_read_recipe_data(csv, "lollipop_ranked"))
f <- tempfile(fileext = ".png"); writeBin(raw(10000), f)
files <- c(png = f); attr(files, "qa_final_status") <- "fail"
check(pp_qa_status(pp_qa_postflight(files)) == "fail", "Postflight reads image QA")
check(identical(pp_normalize_production(p, s)$theme$panel.background$fill, "white"), "White data region")
if (!is.null(pp_resolve_qa_python()) && requireNamespace("jsonlite", quietly = TRUE)) {
  fake <- tempfile(fileext = ".py")
  writeLines(c("import sys,json,pathlib", "out=pathlib.Path(sys.argv[sys.argv.index('--out')+1])",
    "out.mkdir(parents=True,exist_ok=True)",
    "(out/'visual_qa.json').write_text(json.dumps({'image_qa':{'status':'fail'}}))", "sys.exit(2)"), fake)
  previous <- Sys.getenv("PAPERPLOT_QA_SCRIPT", unset = "")
  Sys.setenv(PAPERPLOT_QA_SCRIPT = fake)
  qa <- pp_run_visual_qa(f)
  if (nzchar(previous)) Sys.setenv(PAPERPLOT_QA_SCRIPT = previous) else Sys.unsetenv("PAPERPLOT_QA_SCRIPT")
  check(isTRUE(qa$available) && qa$status == "fail", "Detector exit 2 means a detected failure, not unavailable")
}

if (requireNamespace("patchwork", quietly = TRUE)) {
  combo <- pp_compose_manuscript(list(p, p, p, p), design = "AB\nCC\nDD")
  norm <- pp_normalize_production(combo, s)
  check(pp_infer_panel_count(norm) == 4, "Composite panel count")
  pp_assert_data_unchanged(pp_plot_evidence(combo), pp_plot_evidence(norm))
}

out <- Sys.getenv("PAPERPLOT_TEST_OUTPUT", tempfile("paperplot-production-test-"))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
if (isTRUE(pp_check_environment(TRUE)$production_available)) {
  missing_glyph <- ggplot2::ggplot(data.frame(x=1,y=1),ggplot2::aes(x,y))+ggplot2::geom_point()+ggplot2::labs(title='藜')
  fails(pp_check_plot_glyphs(missing_glyph,pp_render_spec()))
  # Synthetic fixture only: never a reconstruction of the user's IGS data.
  d <- data.frame(species = paste("Species", letters[1:6]), suffix = c("(A)", "(B)", "(6x)", "(A)", "(B)", "(A)"),
    n = 101:106, p_ge95 = c(80, 20, 30, 10, 0, 0), p90_95 = c(5, 20, 10, 10, 1, 0),
    p85_90 = c(5, 30, 30, 40, 4, 1), p80_85 = c(5, 20, 20, 20, 15, 4),
    p_lt80 = c(5, 10, 10, 20, 80, 95), median = c(.97, .94, .9, .85, .8, .75),
    max = c(.99, .98, .96, .94, .9, .82))
  invalid <- d; invalid$p_ge95[1] <- 90; fails(pp_igs_figure(invalid))
  igs <- pp_igs_figure(d)
  spec <- pp_render_spec(2, case = "igs", mode = "demo")
  files <- pp_save_all_with_qa_loop(igs, file.path(out, "synthetic-igs"), render_spec = spec, max_iterations = 0)
  audit <- attr(files, "qa_export_audit")
  check(audit$checks$pdf_page_mm == "pass", "Actual PDF page dimensions")
  check(audit$checks$pdf_font_embedding == "pass", "Embedded Arial")
  check(audit$checks$svg_typography == "pass", "SVG font and role sizes")
  check(audit$checks$pdf_typography == "pass", "PDF font and role sizes")
  check(audit$checks$shared_row_alignment == "pass", "Shared rows within 0.2 mm")
  check(audit$checks$count_column_header == "pass", "One n header")
  check(audit$checks$axis_tick_strokes == "pass", "Actual axis and tick stroke units")
  check(audit$checks$marker_dimensions == "pass", "Actual marker dimensions")
  check(audit$checks$png_pixels == "pass", "600 dpi dimensions")
  check(attr(files, "qa_contract")$tier != "manuscript-ready", "Synthetic fixture cannot certify real figure")
  panels <- list(
    ggplot2::ggplot(d, ggplot2::aes(median, max)) + ggplot2::geom_point(colour = "#173B73") + ggplot2::labs(title = "Summary association"),
    ggplot2::ggplot(d, ggplot2::aes(species, p_ge95)) + ggplot2::geom_col(fill = "#337FB8", width = .6) +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)) + ggplot2::labs(x = NULL, y = "Fraction (%)", title = "Category composition"),
    ggplot2::ggplot(d, ggplot2::aes(n, median)) + ggplot2::geom_line(colour = "#D55E00") +
      ggplot2::geom_point(colour = "#D55E00") + ggplot2::labs(title = "Synthetic profile", x = "Index", y = "Identity"),
    ggplot2::ggplot(d, ggplot2::aes(median, species)) + ggplot2::geom_segment(ggplot2::aes(xend = max, yend = species), colour = "#C9C9C9") +
      ggplot2::geom_point(colour = "#173B73") + ggplot2::labs(title = "Within-row summary", y = NULL))
  four <- pp_compose_manuscript(panels, design = "AB\nCD", widths = c(1.15, 1), heights = c(1, 1))
  main <- pp_save_all_with_qa_loop(four, file.path(out, "synthetic-main"), render_spec = pp_render_spec(4, mode = "demo"), max_iterations = 0)
  check(attr(main, "qa_export_audit")$checks$pdf_page_mm == "pass", "180 x 120 mm main canvas")
  check(attr(main, "qa_export_audit")$checks$svg_panel_tags == "pass", "Unique bold ABCD tags")
  cat("Synthetic export artifacts:", out, "\n")
} else if('--require-production' %in% commandArgs(TRUE)) stop('Formal render check requires the complete environment; skipping is not success.') else cat("SKIP physical exports: formal environment unavailable; no acceptance claimed.\n")
cat("Production contract tests passed.\n")
