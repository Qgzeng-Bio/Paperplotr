test_that("paperplot_principles returns the clean composite checklist", {
  principles <- paperplot_principles()

  expect_s3_class(principles, "data.frame")
  expect_equal(names(principles), c("principle", "rationale", "paperplotr_action"))
  expect_true("functional color" %in% principles$principle)
  expect_true(any(grepl("theme_clean_composite", principles$paperplotr_action, fixed = TRUE)))
})

test_that("paperplot_principles rejects unknown styles", {
  expect_error(paperplot_principles("unknown"))
})
