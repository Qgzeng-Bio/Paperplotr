#!/usr/bin/env Rscript
# Focused interactive-style contract tests. Synthetic tables here are test fixtures only.
source("paperplot-skills/scripts/paperplot_helpers.R")
source("paperplot-skills/recipes/paperplot_code_recipes.R")

check <- function(value, message) if (!isTRUE(value)) stop(message, call. = FALSE)
fails <- function(expr, message = "Expected an error") {
  result <- tryCatch(force(expr), error = identity)
  check(inherits(result, "error"), message)
}

check(identical(unname(pp_discrete_palettes$wong), c(
  "#0072B2", "#E69F00", "#009E73", "#CC79A7",
  "#56B4E9", "#D55E00", "#F0E442", "#000000")), "Wong palette values/order")
check(identical(pp_palette(4), unname(pp_discrete_palettes$wong[1:4])), "Wong is the categorical default")
fails(pp_palette(9), "Wong >8 must require an explicit alternative")
fails(pp_validate_palette(letters[1:9], "discrete"), "Wong validation must reject >8 groups")
check(length(pp_palette(13, palette = "graphpad_discrete")) == 13, "Legacy GraphPad palette remains interpolatable")
named <- c(Control = "#111111", Treatment = "#EEEEEE")
check(identical(pp_group_colors(names(named), values = named), named), "Explicit named colors remain unchanged")
check(identical(pp_group_colors(c("Up", "Down", "NS"), palette = "up_down_ns"),
               pp_discrete_palettes$up_down_ns[c("Up", "Down", "NS")]), "Semantic legacy palette remains available")

nine_groups <- data.frame(group = factor(paste0("G", 1:9)), value = seq_len(9))
fails(pp_recipe_plot("boxplot_jitter", nine_groups), "Default nine-group recipe palette must fail")
legacy_box <- pp_recipe_plot("boxplot_jitter", nine_groups, params = list(palette = "graphpad_discrete"))
legacy_box_scale <- legacy_box$scales$get_scales("fill")
check(!is.null(legacy_box_scale) && length(legacy_box_scale$palette(9)) == 9, "Explicit legacy palette reaches boxplot scale")
complete_named <- setNames(grDevices::rainbow(9), levels(nine_groups$group))
named_box <- pp_recipe_plot("boxplot_jitter", nine_groups, params = list(colors = complete_named))
check(length(named_box$scales$get_scales("fill")$palette(9)) == 9, "Complete named mapping reaches boxplot scale")
fails(pp_recipe_plot("boxplot_jitter", nine_groups, params = list(palette = "not_a_palette")), "Unknown recipe palette must fail")
fails(pp_recipe_plot("boxplot_jitter", nine_groups, params = list(colors = complete_named[-1])), "Incomplete recipe color mapping must fail")
nine_scatter <- data.frame(x = seq_len(9), y = seq_len(9) + .5, group = factor(paste0("G", 1:9)))
legacy_scatter <- pp_recipe_plot("scatter_regression", nine_scatter, params = list(palette = "graphpad_discrete"))
check(length(legacy_scatter$scales$get_scales("colour")$palette(9)) == 9, "Explicit legacy palette reaches scatter scale")
fails(pp_recipe_plot("scatter_regression", nine_scatter), "Default nine-group scatter palette must fail")

small <- expand.grid(row = letters[1:3], col = LETTERS[1:4], KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
small$value <- seq_len(nrow(small)) / 10
small$value[2] <- NA_real_
small_policy <- pp_heatmap_value_labels(small, "col", "row", "value", "auto")
check(isTRUE(small_policy$show_values), "Small heatmap auto labels")
check(identical(small$value, small_policy$data$value), "Heatmap label policy preserves values")
check(small_policy$data$.pp_heatmap_label[2] == "NA", "Heatmap labels mark NA without changing values")
check(grepl("0.1", small_policy$data$.pp_heatmap_label[1]), "Heatmap labels use compact values")
compact <- data.frame(x = 1:4, y = 1, value = c(0.141, -0.00885, 1, NA))
check(identical(pp_heatmap_value_labels(compact, "x", "y", "value")$data$.pp_heatmap_label,
                c("0.141", "-0.00885", "1", "NA")),
      "Heatmap values use independent compact labels without shared trailing-zero padding")
dense <- expand.grid(row = sprintf("r%02d", 1:11), col = sprintf("c%02d", 1:11), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
dense$value <- seq_len(nrow(dense))
check(!isTRUE(pp_heatmap_value_labels(dense, "col", "row", "value", "auto")$show_values), "Dense heatmap auto labels are conservative")
check(isTRUE(pp_heatmap_value_labels(dense, "col", "row", "value", TRUE)$show_values), "Explicit heatmap labels are on")
check(!isTRUE(pp_heatmap_value_labels(dense, "col", "row", "value", FALSE)$show_values), "Explicit heatmap labels are off")
fails(pp_heatmap_value_labels(small, "col", "row", "value", "invalid"), "Invalid show_values must fail")
required_policy <- pp_heatmap_value_labels(dense, "col", "row", "value", "auto", required = TRUE)
check(isTRUE(required_policy$show_values), "Required labels cannot be auto-hidden")
fails(pp_heatmap_value_labels(dense, "col", "row", "value", FALSE, required = TRUE), "Required labels cannot be explicitly disabled")
facet_policy <- pp_heatmap_value_labels(dense, "col", "row", "value", "auto", facet = rep(c("A", "B"), length.out = nrow(dense)))
check(!isTRUE(facet_policy$show_values), "Faceted density tightens auto label policy")
fails(pp_heatmap_value_labels(small, "col", "row", "value", "auto", physical_slot = list(width_mm = -1, height_mm = 20)), "Invalid physical slot must fail")
fails(pp_heatmap_value_labels(small, "col", "row", "value", "auto", physical_slot = list(width_mm = numeric(), height_mm = 20)), "Empty physical width must fail")
fails(pp_heatmap_value_labels(small, "col", "row", "value", "auto", physical_slot = list(width_mm = c(20, 21), height_mm = 20)), "Multi-value physical width must fail")
policy_summary <- pp_heatmap_label_policy_summary(small_policy)
check(is.null(policy_summary$data) && identical(policy_summary$show_values, TRUE) && policy_summary$counts$cells == 12, "Heatmap policy summary is compact")

raw_df <- data.frame(group = factor(rep(c("Control", "Treatment"), each = 4)), value = c(1, 2, 3, 4, 2, 3, 4, 5), stringsAsFactors = FALSE)
raw_plot <- pp_recipe_plot("boxplot_jitter", raw_df)
check(any(vapply(raw_plot$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))), "Distribution recipe keeps real raw points")
violin_plot <- pp_recipe_plot("violin_dot", raw_df)
check(any(vapply(violin_plot$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))), "Violin recipe keeps real raw points")
label_df <- data.frame(metric = rep(letters[1:11], each = 11), category = rep(LETTERS[1:11], 11), value = seq_len(121), group = "All")
label_plot <- pp_recipe_plot("heatmap_cell_label", label_df)
check(any(vapply(label_plot$layers, function(layer) inherits(layer$geom, "GeomText"), logical(1))), "Labels variant keeps required dense labels")
check(!is.null(attr(label_plot, "pp_heatmap_value_label_policy_summary")), "Recipe retains compact heatmap label policy")
label_evidence <- pp_plot_evidence(label_plot)
check(!is.null(label_evidence$label_policy) && is.null(label_evidence$label_policy$data), "Plot evidence retains only label policy summary")
label_normalized <- pp_normalize_production(label_plot, pp_render_spec(mode = "preview", width_mm = 89, height_mm = 62))
check(identical(attr(label_normalized, "pp_heatmap_value_label_policy_summary"), attr(label_plot, "pp_heatmap_value_label_policy_summary")), "Normalization preserves heatmap label policy")
# The direct template must pass the same label decision to metadata, not notes only.
heatmap_calls <- as.list(parse("paperplot-skills/templates/heatmap-template.R"))
metadata_calls <- Filter(function(x) is.call(x) && identical(x[[1]], as.name("pp_write_metadata")), heatmap_calls)
check(length(metadata_calls) == 1L &&
      identical(as.list(metadata_calls[[1]])$label_strategy, as.name("label_strategy")),
      "Heatmap template persists its actual label policy in JSON metadata")

if (!isTRUE(pp_check_environment(full = FALSE)$production_available)) {
  stop("Production-path contract test requires the locked runtime, Arial, and export tools; run through paperplot-run.", call. = FALSE)
}

out <- file.path("tmp", paste0("pdf-jpg-interactive-style-test-", Sys.getpid(), "-", format(Sys.time(), "%Y%m%d%H%M%S")))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(out, recursive = TRUE, force = TRUE), add = TRUE)
fixture <- data.frame(group = factor(rep(c("Control", "Treatment"), each = 5)), value = c(1, 2, 2, 3, 4, 2, 3, 4, 5, 6))
p <- ggplot2::ggplot(fixture, ggplot2::aes(group, value, fill = group)) +
  ggplot2::geom_boxplot(outlier.shape = NA) +
  ggplot2::geom_point(position = ggplot2::position_jitter(width = .08, seed = 104729), size = 1.3) +
  pp_theme()

visual_calls <- 0L
audit_calls <- 0L
original_visual <- get("pp_run_visual_qa", envir = .GlobalEnv)
original_audit <- get("pp_run_export_audit", envir = .GlobalEnv)
qa_paths <- character()
assign("pp_run_visual_qa", function(path, ...) {
  qa_paths <<- c(qa_paths, path)
  visual_calls <<- visual_calls + 1L
  list(available = TRUE, status = "pass", qa_dir = tempfile("stub-visual-qa-"), top_risks = list())
}, envir = .GlobalEnv)
assign("pp_run_export_audit", function(...) { audit_calls <<- audit_calls + 1L; list(status = "unverified", checks = list(engine = "unverified"), reviewable_checks = character()) }, envir = .GlobalEnv)
on.exit({
  assign("pp_run_visual_qa", original_visual, envir = .GlobalEnv)
  assign("pp_run_export_audit", original_audit, envir = .GlobalEnv)
}, add = TRUE)

before <- fixture
preview_stem <- file.path(out, "preview")
preview <- pp_save_all_with_qa_loop(p, preview_stem,
  render_spec = pp_render_spec(mode = "preview", width_mm = 89, height_mm = 62), max_iterations = 2L)
check(all(file.exists(unname(preview))), "Preview files exist")
check(identical(names(preview), c("pdf", "jpg")), "Preview default PDF/JPG")
check(attr(preview, "qa_render_spec")$dpi == 300, "Preview 300 dpi")
check(!any(file.exists(paste0(preview_stem, c(".svg", ".png")))), "No default SVG/PNG delivery")
for (formats in list(character(), c("jpg", "JPG"), "../jpg", "", NA_character_)) {
  invalid_stem <- file.path(out, "invalid-formats")
  fails(pp_save_all_with_qa_loop(p, invalid_stem, formats = formats), "Reject invalid formats before writes")
  check(!length(Sys.glob(paste0(invalid_stem, "*"))), "Invalid formats leave no sidecars")
}
check(file.exists(paste0(preview_stem, "_production_qa.json")), "Preview metadata exists")
check(visual_calls == 0L && audit_calls == 0L, "Preview calls neither visual QA nor export audit")
check(identical(attr(preview, "qa_initial_status"), "not_run") && identical(attr(preview, "qa_final_status"), "not_run"), "Preview QA is explicitly not_run")
check(identical(attr(preview, "qa_iterations"), 0L), "Preview has zero repair iterations")
check(identical(attr(preview, "qa_contract")$tier, "interactive draft"), "Preview tier is interactive draft")
check(identical(attr(preview, "qa_contract")$checks$visual_layout, "unverified"), "Preview visual check remains unverified")
check(identical(attr(preview, "qa_contract")$checks$export_engine, "unverified"), "Preview export check remains unverified")
check(!"export_" %in% unlist(attr(preview, "qa_contract")$reviewable),
      "An empty audit review list must not produce a phantom export_ check")
check(all(unlist(attr(preview, "qa_contract")$reviewable) %in% names(attr(preview, "qa_contract")$checks)),
      "Every reviewable check must actually exist")
legacy_review <- pp_final_qa(list(data_integrity = "pass", visual_layout = "unverified"),
  human_review = "pass", required = c("data_integrity", "visual_layout"),
  reviewable = "export_", evidence_hash = "fixture",
  reviews = list(export_ = list(decision = "pass", reviewer = "AUTOMATED FIXTURE",
                               reason = "Phantom-check regression only", evidence_hash = "fixture")))
check(legacy_review$status == "warn" && !length(legacy_review$resolved_reviews),
      "Unknown legacy review checks must not crash or approve unverified work")
check(!dir.exists(paste0(preview_stem, "_visual_qa")), "Preview does not create candidate QA copies")
check(identical(before, fixture), "Preview does not mutate source data")
review_stem <- file.path(out, "review-preview")
review_preview <- pp_save_all_with_qa_loop(p, review_stem, formats = "png",
  render_spec = pp_render_spec(mode = "preview", human_review = "pass", width_mm = 89, height_mm = 62))
check(identical(attr(review_preview, "qa_contract")$status, "warn") && identical(attr(review_preview, "qa_contract")$tier, "interactive draft"), "Preview human review cannot promote draft")
fails(pp_save_all_with_qa_loop(p, preview_stem,
  render_spec = pp_render_spec(mode = "preview", width_mm = 89, height_mm = 62)), "Preview refuses no-overwrite rerun")
demo_plot <- pp_recipe_plot("boxplot_jitter", raw_df, mode = "demo")
fails(pp_save_all_with_qa_loop(demo_plot, file.path(out, "demo-preview"), formats = "png",
  render_spec = pp_render_spec(mode = "preview", width_mm = 89, height_mm = 62)), "Demo provenance cannot enter preview")

production_stem <- file.path(out, "production")
production <- pp_save_all_with_qa_loop(p, production_stem,
  render_spec = pp_render_spec(mode = "production", width_mm = 89, height_mm = 62, expected_labels = c("group", "value")), max_iterations = 2L)
check(all(file.exists(unname(production))), "Production files exist")
check(identical(names(production), c("pdf", "jpg")), "Production default PDF/JPG")
check(identical(qa_paths, unname(production[['jpg']])), "Production QA receives JPG")
# Reapplying density updates the existing JFIF marker rather than duplicating it.
jpeg_hash <- unname(tools::md5sum(production[['jpg']]))
pp_set_jpeg_dpi(production[['jpg']], 300)
check(identical(unname(tools::md5sum(production[['jpg']])), jpeg_hash), 'JPEG density write is idempotent')
actual <- original_audit(production, attr(production, "qa_render_spec"), file.path(out, "actual-audit"))
for (key in c('.pdf_present', '.jpg_present', 'pdf_page_mm', 'pdf_font_embedding', 'pdf_typography', 'pdf_required_labels', 'jpg_pixels', 'jpg_dpi', 'jpg_rgb', 'jpg_encoding'))
  check(identical(actual$checks[[key]], 'pass'), paste('Real default export:', key))
missing <- original_audit(production['pdf'], attr(production, 'qa_render_spec'), file.path(out, 'missing-jpg-audit'))
check(identical(missing$checks[['.jpg_present']], 'fail'), 'Declared missing JPG fails')
check(!any(file.exists(paste0(production_stem, c('.svg', '.png')))), 'No production SVG/PNG delivery')
check(visual_calls == 1L && audit_calls == 1L, paste("Production still calls visual QA and export audit; counts:", visual_calls, audit_calls))
check(identical(attr(production, "qa_iterations"), 0L), "Passing production stub needs no repair iteration")
check(identical(attr(production, "qa_contract")$checks$export_engine, "unverified"), "Stubbed audit remains auditable")
check(identical(before, fixture), "Production does not mutate source data")
cat("Interactive style contract tests passed. Synthetic fixtures are test-only; no manuscript acceptance claimed.\n")
