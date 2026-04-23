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
