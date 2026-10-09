#!/usr/bin/env Rscript
source("paperplot-skills/scripts/paperplot_helpers.R")
check <- function(value, message) if (!isTRUE(value)) stop(message)
fails <- function(expr) check(inherits(tryCatch(force(expr), error = identity), "error"), "Expected an error")
s <- pp_render_spec(4)
# Default profile is Nature: 183 mm double column, 89 mm single, 8 pt bold lowercase tags, text 5-7 pt.
check(s$journal == "nature" && s$width_mm == 183 && s$height_mm == 120 && s$text_pt$panel_tag == 8, "Nature main canvas/tag defaults")
check(identical(unlist(s$expected_tags), c("a", "b", "c", "d")) && identical(pp_panel_tag_levels(s), "a"), "Nature lowercase tags")
check(all(unlist(s$text_pt[setdiff(names(s$text_pt), "panel_tag")]) <= 7), "Nature text <= 7 pt outside tags")
check(pp_render_spec()$width_mm == 89, "Single-column width")
check(pp_render_spec(2, case = "igs")$width_mm == 183, "IGS canvas")
check(pp_render_spec(2, case = "manhattan")$width_mm == 183, "Manhattan canvas follows double column")
check(pp_render_spec(text_pt = list(axis_title = 6))$text_pt$axis_title == 6, "Explicit role override inside the journal range")
fails(pp_render_spec(text_pt = list(axis_title = 7.5)))   # Nature caps ordinary text at 7 pt
fails(pp_render_spec(text_pt = list(caption = 4.5)))      # ... and floors it at 5 pt
fails(pp_render_spec(column = "mid"))                     # Nature publishes no 1.5-column width
fails(pp_render_spec(journal = "science"))                # unknown profile
check(suppressWarnings(pp_render_spec(height_mm = 171)$height_mm) == 171 && inherits(tryCatch(pp_render_spec(height_mm = 171), warning = identity), "warning"), "Nature 170 mm height guard warns")
# Cell profile: 85/114/174 mm, uppercase tags, text 6-8 pt, strokes 0.5-1.5 pt.
cs <- pp_render_spec(4, journal = "cell")
check(cs$journal == "cell" && cs$width_mm == 174 && identical(unlist(cs$expected_tags), c("A", "B", "C", "D")) && identical(pp_panel_tag_levels(cs), "A"), "Cell main canvas/tags")
check(pp_render_spec(journal = "cell")$width_mm == 85 && pp_render_spec(journal = "cell", column = "mid")$width_mm == 114, "Cell single / 1.5 column")
check(all(unlist(cs$stroke_pt) >= 0.5 & unlist(cs$stroke_pt) <= 1.5), "Cell strokes within 0.5-1.5 pt")
check(pp_render_spec(text_pt = list(axis_title = 8), journal = "cell")$text_pt$axis_title == 8, "Cell allows 8 pt text")
fails(pp_render_spec(text_pt = list(caption = 5.5), journal = "cell"))  # below Cell's 6 pt floor
bad_stroke <- cs; bad_stroke$stroke_pt$separator <- 0.25
fails(pp_validate_journal_spec(bad_stroke))
# Legacy cm presets must agree with the journal profiles.
check(isTRUE(all.equal(c(pp_output_preset("nature")$width_cm, pp_output_preset("nature_half")$width_cm) * 10, c(183, 89))), "Nature presets agree with the profile")
check(isTRUE(all.equal(c(pp_output_preset("cell")$width_cm, pp_output_preset("cell_mid")$width_cm, pp_output_preset("cell_half")$width_cm) * 10, c(174, 114, 85))), "Cell presets agree with the profile")
old <- options(paperplot.journal = "cell"); check(pp_render_spec()$width_mm == 85, "Journal option selects the profile"); options(old)
Sys.setenv(PAPERPLOT_JOURNAL = "cell"); check(pp_render_spec()$journal == "cell", "Journal env selects the profile"); Sys.unsetenv("PAPERPLOT_JOURNAL")
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
fails(pp_normalize_production(ggplot2::ggplot(mtcars,ggplot2::aes(wt,mpg))+ggplot2::geom_text(label='required',check_overlap=TRUE),s))

source("paperplot-skills/recipes/paperplot_code_recipes.R")
demo_plot<-pp_recipe_plot('lollipop_ranked',pp_recipe_mock_data('lollipop_ranked'),mode='demo')
fails(pp_normalize_production(demo_plot,pp_render_spec()))
fails(pp_normalize_production(pp_compose_manuscript(list(demo_plot,demo_plot)),pp_render_spec(2)))
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
  # Explicit legacy export: retain SVG geometry/parser regression coverage.
  files <- pp_save_all_with_qa_loop(igs, file.path(out, "synthetic-igs"), formats = c("pdf", "svg", "png"), render_spec = spec, max_iterations = 0)
  audit <- attr(files, "qa_export_audit")
  check(audit$checks$pdf_page_mm == "pass", "Actual PDF page dimensions")
  check(audit$checks$pdf_font_embedding == "pass", "Embedded Arial")
  check(audit$checks$svg_typography == "pass", "SVG font and role sizes")
  check(audit$checks$pdf_typography == "pass", "PDF font and role sizes")
  check(audit$checks$shared_row_alignment == "pass", "Shared rows within 0.2 mm")
  check(audit$checks$count_column_header == "pass", "One n header")
  check(audit$checks$axis_tick_strokes == "pass", "Actual axis and tick stroke units")
  check(audit$checks$marker_dimensions == "pass", "Actual marker dimensions")
  check(audit$checks$png_pixels == "pass", "300 dpi legacy PNG dimensions")
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
  check(attr(main, "qa_export_audit")$checks$pdf_page_mm == "pass", "183 x 120 mm main canvas")
  check(attr(main, "qa_export_audit")$checks$pdf_panel_tags == "pass", "Unique bold abcd PDF tags")
  main_audit <- attr(main, "qa_export_audit")
  check(identical(names(main), c("pdf", "jpg")), "Default PDF/JPG only")
  check(all(vapply(main_audit$checks[c("jpg_pixels", "jpg_dpi", "jpg_encoding", "jpg_rgb")], identical, logical(1), "pass")), "Actual 300-dpi RGB JPEG")
  check(!any(file.exists(paste0(file.path(out, "synthetic-main"), c(".png", ".svg")))), "No legacy default deliveries")
  cat("Synthetic export artifacts:", out, "\n")
} else if('--require-production' %in% commandArgs(TRUE)) stop('Formal render check requires the complete environment; skipping is not success.') else cat("SKIP physical exports: formal environment unavailable; no acceptance claimed.\n")
cat("Production contract tests passed.\n")
