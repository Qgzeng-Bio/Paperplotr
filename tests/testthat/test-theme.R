test_that("theme_lab returns a ggplot theme object", {
  theme_obj <- theme_lab()

  expect_s3_class(theme_obj, "theme")
  expect_true(isTRUE(attr(theme_obj, "complete")))
})

test_that("theme_lab honors base size and family", {
  theme_obj <- theme_lab(base_size = 9, base_family = "Arial")

  expect_equal(theme_obj$text$size, 9)
  expect_equal(theme_obj$text$family, "Arial")
})

test_that("theme_clean_composite keeps a low visual-weight theme", {
  theme_obj <- theme_clean_composite(base_size = 8, line_width = 0.3)

  expect_s3_class(theme_obj, "theme")
  expect_true(isTRUE(attr(theme_obj, "complete")))
  expect_s3_class(theme_obj$panel.grid.major, "element_blank")
  expect_s3_class(theme_obj$panel.border, "element_blank")
  expect_equal(theme_obj$axis.line$linewidth, 0.3)
  expect_equal(theme_obj$text$size, 8)
})
