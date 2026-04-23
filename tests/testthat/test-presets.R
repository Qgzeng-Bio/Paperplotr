test_that("fig_specs exposes canonical panel definitions", {
  expect_true(is.data.frame(fig_specs))
  expect_true(all(c(
    "spec", "panel_w_cm", "panel_h_cm",
    "nonpanel_w_cm", "nonpanel_h_cm",
    "gap_cm", "base_font_pt", "min_linewidth"
  ) %in% names(fig_specs)))
  expect_true(all(c("2x2", "2.58x2", "4.9x2", "4.9x4.9") %in% fig_specs$spec))
})

test_that("get_fig_size_cm computes figure dimensions from spec", {
  size <- get_fig_size_cm("4.9x2", ncol = 3, nrow = 1)

  expect_equal(size$spec, "4.9x2")
  expect_equal(size$width_cm, 15.9)
  expect_equal(size$height_cm, 2.9)
})

test_that("panel_size returns known preset dimensions", {
  size <- panel_size("2x2")

  expect_equal(size$name, "2x2")
  expect_equal(size$width_cm, 2.0)
  expect_equal(size$height_cm, 2.0)
  expect_equal(size$reserved_cm, 0.9)
  expect_match(size$layout_hint, "6")
})

test_that("recommend_panel_spec returns the default main-figure recommendation", {
  rec <- recommend_panel_spec(n_panels = 4)

  expect_equal(rec$spec, "4.9x4.9")
  expect_equal(rec$ncol, 2L)
  expect_equal(rec$nrow, 2L)
  expect_false(rec$split_figure)
  expect_match(rec$rationale, "default", ignore.case = TRUE)
})

test_that("recommend_panel_spec downshifts to small multiples for simple dense grids", {
  rec <- recommend_panel_spec(n_panels = 8, complexity = "simple")

  expect_equal(rec$spec, "2.58x2")
  expect_equal(rec$ncol, 4L)
  expect_equal(rec$nrow, 2L)
  expect_false(rec$split_figure)
})

test_that("recommend_panel_spec uses compact presets for simple supplementary grids", {
  rec <- recommend_panel_spec(
    n_panels = 6,
    complexity = "simple",
    supplementary = TRUE
  )

  expect_equal(rec$spec, "2.58x2")
  expect_equal(rec$ncol, 3L)
  expect_equal(rec$nrow, 2L)
  expect_false(rec$split_figure)
})

test_that("recommend_panel_spec upgrades complex panel mixes and flags splitting", {
  rec <- recommend_panel_spec(
    n_panels = 8,
    heatmap = TRUE,
    rotated_x_labels = TRUE,
    complex_legend = TRUE
  )

  expect_equal(rec$spec, "4.9x4.9")
  expect_equal(rec$ncol, 4L)
  expect_equal(rec$nrow, 2L)
  expect_true(rec$split_figure)
  expect_match(rec$rationale, "split", ignore.case = TRUE)
})

test_that("journal_preset returns known publication defaults", {
  preset <- journal_preset("cell")

  expect_equal(preset$journal, "cell")
  expect_equal(preset$figure_width_cm, 17.4)
  expect_equal(preset$base_size_pt, 8)
  expect_equal(preset$min_text_pt, 6)
})

test_that("unknown preset names fail clearly", {
  expect_error(panel_size("unknown"), "Unknown panel size")
  expect_error(journal_preset("unknown"), "Unknown journal preset")
  expect_error(get_fig_size_cm("unknown"), "Unknown spec")
  expect_error(recommend_panel_spec(0), "positive integer")
  expect_error(recommend_panel_spec(3, complexity = "dense"), "must be one of")
  expect_error(panel_size(character(0)), "single non-empty string")
})

test_that("preset discovery helpers expose supported names", {
  expect_true(all(c("2x2", "4.9x4.9", "4.9") %in% available_fig_specs()))
  expect_true(all(c("cell", "nature", "ncomms") %in% available_journal_presets()))
  expect_true(all(c("cell_half", "nature_half", "ncomms_half") %in% available_output_presets()))
})
