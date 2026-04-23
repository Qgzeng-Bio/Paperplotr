test_that("lab_palette returns stable palette sizes", {
  cols <- lab_palette(8)

  expect_length(cols, 8)
  expect_true(all(grepl("^#", cols)))
})

test_that("available_lab_palettes exposes Prism palette families", {
  palettes <- available_lab_palettes()

  expect_true(all(c(
    "main",
    "gray",
    "colors",
    "prism_light",
    "prism_dark",
    "colorblind_safe",
    "viridis"
  ) %in% palettes))
})

test_that("Prism palette values stay stable", {
  cols <- lab_palette(6, palette = "colors")
  prism_light <- lab_palette(5, palette = "prism_light")
  prism_dark <- lab_palette(5, palette = "prism_dark")

  expect_equal(cols, c("#0000FF", "#FF0000", "#00C000", "#AD07E3", "#FF8000", "#000000"))
  expect_equal(prism_light, c("#A48AD3", "#1CC5FE", "#6FC7CF", "#FBA27D", "#FB7D80"))
  expect_equal(prism_dark, c("#2C1453", "#114CE8", "#0E6F7C", "#FB4F06", "#FB0005"))
})

test_that("lab_palette supports reverse order and alpha adjustment", {
  cols <- lab_palette(3, palette = "waves", reverse = TRUE, alpha = 0.5)

  expect_equal(cols, c("#27292B80", "#33565F80", "#63615D80"))
})

test_that("group_colors preserves semantic mappings and overrides", {
  groups <- group_colors(c(Control = "#000000"))

  expect_equal(groups[["Control"]], "#000000")
  expect_true("Treatment" %in% names(groups))
})

test_that("default semantic dictionary is available", {
  dicts <- available_group_dictionaries()

  expect_true("default" %in% dicts)
})

test_that("default semantic dictionary returns stable mappings", {
  groups <- group_colors("default")

  expect_true(all(c("Control", "Treatment", "WT", "Mutant") %in% names(groups)))
  expect_match(groups[["Treatment"]], "^#")
})

test_that("named overrides still work with dictionary selection", {
  groups <- group_colors("default", c(Control = "#000000"))

  expect_equal(groups[["Control"]], "#000000")
  expect_true("Treatment" %in% names(groups))
})

test_that("gradient palettes are available", {
  alt_gradient <- lab_gradient_palette(6, palette = "graphpad_heatmap_alt")

  expect_length(alt_gradient, 6)
  expect_true(all(grepl("^#", alt_gradient)))
})

test_that("group scales validate missing groups when provided", {
  expect_warning(
    scale_color_groupmap(groups = c("Control", "Unknown")),
    "Unknown groups"
  )
})

test_that("discrete lab scales accept Prism palettes", {
  fill_scale <- scale_fill_lab(palette = "plasma", alpha = 0.6)
  color_scale <- scale_color_lab(palette = "colorblind_safe")

  expect_s3_class(fill_scale, "ScaleDiscrete")
  expect_s3_class(color_scale, "ScaleDiscrete")
})

test_that("group scales can use the default semantic dictionary directly", {
  expect_warning(
    scale_fill_groupmap(dictionary = "default", groups = c("Control", "Unknown")),
    "Unknown groups"
  )
})
