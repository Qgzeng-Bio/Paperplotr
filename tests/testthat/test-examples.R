test_that("render_paperplotr_examples generates a reusable figure gallery", {
  output_dir <- tempfile("paperplotr-gallery-")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  paths <- render_paperplotr_examples(output_dir = output_dir)

  expect_length(paths, 8)
  expect_true(all(c(
    "pca_scatter",
    "state_composition_bar",
    "violin_box",
    "feature_heatmap",
    "class_composition",
    "box_compare",
    "violin_compare",
    "dot_compare"
  ) %in% names(paths)))
  expect_true(all(file.exists(unname(paths))))
})
