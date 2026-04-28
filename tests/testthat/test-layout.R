test_that("layout_lab returns a patchwork composition", {
  skip_if_not_installed("patchwork")

  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_boxplot()

  composed <- layout_lab(p1, p2, ncol = 2)

  expect_s3_class(composed, "patchwork")
})

test_that("layout_lab can add panel tags directly", {
  skip_if_not_installed("patchwork")

  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_boxplot()

  composed <- layout_lab(
    p1,
    p2,
    ncol = 2,
    tag_levels = "A",
    tag_size = 9,
    tag_face = "bold",
    tag_family = "Arial"
  )

  expect_s3_class(composed, "patchwork")
  expect_equal(composed$patches$annotation$tag_levels, "A")
  expect_equal(composed$patches$annotation$theme$plot.tag$size, 9)
  expect_equal(composed$patches$annotation$theme$plot.tag$face, "bold")
  expect_equal(composed$patches$annotation$theme$plot.tag$family, "Arial")
})

test_that("layout_lab requires at least one plot", {
  skip_if_not_installed("patchwork")

  expect_error(layout_lab(), "at least one plot")
  expect_error(layout_lab(list()), "at least one plot")
})
