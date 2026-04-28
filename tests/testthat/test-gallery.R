test_that("gallery vignette documents the core visual workflow", {
  gallery_path <- testthat::test_path("..", "..", "vignettes", "gallery.Rmd")

  skip_if_not(file.exists(gallery_path), "Gallery source vignette is checked in source-tree tests.")

  gallery_text <- readLines(gallery_path, warn = FALSE)
  expect_true(any(grepl("theme_lab\\(", gallery_text)))
  expect_true(any(grepl("scale_.*_groupmap\\(", gallery_text)))
  expect_true(any(grepl("layout_lab\\(", gallery_text)))
  expect_true(any(grepl("tag_levels", gallery_text)))
  expect_true(any(grepl("ragg_png|ragg_tiff|svglite|quartz_pdf", gallery_text)))
})
