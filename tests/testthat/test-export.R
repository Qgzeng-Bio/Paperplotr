test_that("save_lab writes a file using a figure spec", {
  skip_if_not_installed("ggplot2")

  plot_path <- tempfile(fileext = ".png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
    ggplot2::geom_point() +
    theme_lab()

  returned <- save_lab(
    plot = p,
    filename = plot_path,
    spec = "4.9x4.9",
    journal = "cell"
  )

  expect_equal(returned, plot_path)
  expect_true(file.exists(plot_path))
})

test_that("save_lab_plot writes a file using a named preset", {
  skip_if_not_installed("ggplot2")

  plot_path <- tempfile(fileext = ".png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
    ggplot2::geom_point() +
    theme_lab()

  returned <- save_lab_plot(
    plot = p,
    filename = plot_path,
    preset = "cell_half",
    dpi = 300
  )

  expect_equal(returned, plot_path)
  expect_true(file.exists(plot_path))
})

test_that("save_lab_plot rejects plots with text below preset minimum", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab(base_size = 5)

  expect_error(
    save_lab_plot(
      plot = p,
      filename = tempfile(fileext = ".png"),
      preset = "cell_half"
    ),
    "minimum text size"
  )
})

test_that("save_lab rejects unknown figure specs", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()

  expect_error(
    save_lab(
      plot = p,
      filename = tempfile(fileext = ".png"),
      spec = "bad_spec"
    ),
    "Unknown spec"
  )
})

test_that("save_lab supports explicit devices for grid grobs", {
  grob <- grid::rectGrob(gp = grid::gpar(fill = "#1F77B4", col = NA))
  out <- tempfile("paperplotr-grob-")

  returned <- save_lab(
    plot = grob,
    filename = out,
    spec = "2x2",
    device = "pdf",
    validate_fonts = FALSE
  )

  expect_equal(returned, out)
  expect_true(file.exists(out))
})

test_that("save_lab supports named Quartz PDF devices on macOS", {
  skip_on_os(c("windows", "linux", "solaris"))

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()
  out <- tempfile(fileext = ".pdf")

  returned <- save_lab(
    plot = p,
    filename = out,
    spec = "2x2",
    device = "quartz_pdf",
    validate_fonts = FALSE
  )

  expect_equal(returned, out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 5000)
})

test_that("save_lab supports ragg PNG output", {
  skip_if_not_installed("ragg")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()
  out <- tempfile(fileext = ".png")

  returned <- save_lab(
    plot = p,
    filename = out,
    spec = "2x2",
    device = "ragg_png"
  )

  expect_equal(returned, out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 1000)
})

test_that("save_lab_plot supports ragg TIFF output", {
  skip_if_not_installed("ragg")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()
  out <- tempfile(fileext = ".tiff")

  returned <- save_lab_plot(
    plot = p,
    filename = out,
    preset = "cell_half",
    device = "ragg_tiff"
  )

  expect_equal(returned, out)
  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 1000)
})

test_that("save_lab supports svglite output", {
  skip_if_not_installed("svglite")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()
  out <- tempfile(fileext = ".svg")

  returned <- save_lab(
    plot = p,
    filename = out,
    spec = "2x2",
    device = "svglite"
  )

  expect_equal(returned, out)
  expect_true(file.exists(out))
  expect_true(any(grepl("<svg", readLines(out, n = 5), fixed = TRUE)))
})

test_that("save_lab reports suspiciously small output files", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()

  expect_error(
    save_lab(
      plot = p,
      filename = tempfile(fileext = ".png"),
      spec = "2x2",
      min_output_size_bytes = .Machine$integer.max
    ),
    "suspiciously small"
  )
})

test_that("save_lab rejects unknown named devices", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()

  expect_error(
    save_lab(
      plot = p,
      filename = tempfile(fileext = ".pdf"),
      spec = "2x2",
      device = "bad_device"
    ),
    "Unsupported graphics device"
  )
})

test_that("save_lab_plot validates width and height overrides", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_lab()

  expect_error(
    save_lab_plot(
      plot = p,
      filename = tempfile(fileext = ".png"),
      width = 0
    ),
    "width"
  )

  expect_error(
    save_lab_plot(
      plot = p,
      filename = tempfile(fileext = ".png"),
      height = -1
    ),
    "height"
  )
})
