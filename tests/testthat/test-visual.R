test_that("default scatter remains visually stable", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() +
    theme_lab()

  vdiffr::expect_doppelganger("default-scatter", p)
})

test_that("semantic groupmap preview remains visually stable", {
  skip_if_not_installed("vdiffr")

  vdiffr::expect_doppelganger(
    "semantic-groupmap-preview",
    .build_gallery_semantic_preview()
  )
})

test_that("tagged gallery layout remains visually stable", {
  skip_if_not_installed("vdiffr")
  skip_if_not_installed("patchwork")

  vdiffr::expect_doppelganger(
    "tagged-gallery-layout",
    .build_gallery_overview_layout()
  )
})
