test_that("default scatter remains visually stable", {
  skip_if_not_installed("vdiffr")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() +
    theme_lab()

  vdiffr::expect_doppelganger("default-scatter", p)
})
