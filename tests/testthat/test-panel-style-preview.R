test_that("panel style preview script emits both v3 preview files", {
  script <- testthat::test_path("..", "..", "..", "panel_style_preview.R")
  testthat::skip_if_not(file.exists(script), "Repository-level preview script is not bundled in package checks.")
  script <- normalizePath(script, mustWork = TRUE)

  output <- trimws(system2("Rscript", script, stdout = TRUE, stderr = TRUE))

  expect_true(any(grepl("panel_style_preview_v3\\.png$", output)))
  expect_true(any(grepl("panel_style_preview_v3_annotated\\.png$", output)))

  generated_paths <- grep("panel_style_preview_v3(_annotated)?\\.png$", output, value = TRUE)
  expect_length(generated_paths, 2)
  expect_true(all(file.exists(generated_paths)))
})

test_that("panel style preview scatter helper uses symmetric 2x2 limits", {
  script <- testthat::test_path("..", "..", "..", "panel_style_preview.R")
  testthat::skip_if_not(file.exists(script), "Repository-level preview script is not bundled in package checks.")
  script <- normalizePath(script, mustWork = TRUE)
  env <- new.env(parent = globalenv())

  sys.source(script, envir = env)

  p <- env$build_preview_scatter_plot()
  built <- ggplot2::ggplot_build(p)
  x_range <- built$layout$panel_params[[1]]$x.range
  y_range <- built$layout$panel_params[[1]]$y.range

  expect_equal(x_range, c(-220, 220))
  expect_equal(y_range, c(-220, 220))
})
