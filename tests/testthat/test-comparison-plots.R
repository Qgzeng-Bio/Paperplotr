.comparison_unpaired_data <- data.frame(
  condition = rep(c("Control", "Treatment"), each = 12),
  value = c(
    4.2, 4.5, 4.8, 5.0, 5.1, 5.3, 4.9, 5.4, 5.5, 4.7, 5.2, 4.6,
    6.1, 6.4, 6.0, 6.7, 6.8, 6.3, 6.5, 6.9, 6.2, 7.0, 6.6, 6.4
  ),
  batch = rep(c("Batch 1", "Batch 2"), each = 6, times = 2)
)

.comparison_paired_data <- data.frame(
  sample_id = rep(paste0("S", 1:8), times = 2),
  condition = rep(c("Before", "After"), each = 8),
  value = c(4.1, 4.5, 4.0, 4.7, 4.6, 4.9, 4.2, 4.8, 5.3, 5.6, 5.2, 5.9, 5.8, 6.0, 5.4, 5.7)
)

test_that("high-level comparison plots return ggplot objects", {
  p_box <- plot_box_paper(.comparison_unpaired_data, condition, value)
  p_violin <- plot_violin_paper(.comparison_unpaired_data, condition, value)
  p_dot <- plot_dot_paper(.comparison_unpaired_data, condition, value)

  expect_s3_class(p_box, "ggplot")
  expect_s3_class(p_violin, "ggplot")
  expect_s3_class(p_dot, "ggplot")
})

test_that("comparison plots support paired designs when id is supplied", {
  p <- plot_dot_paper(
    .comparison_paired_data,
    condition,
    value,
    paired = TRUE,
    id = sample_id
  )

  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("comparison plots validate paired id and explicit comparisons", {
  expect_error(
    plot_box_paper(.comparison_paired_data, condition, value, paired = TRUE),
    "id"
  )

  expect_error(
    plot_box_paper(.comparison_unpaired_data, condition, value, show_signif = TRUE),
    "comparisons"
  )

  expect_error(
    plot_box_paper(
      .comparison_unpaired_data,
      condition,
      value,
      show_signif = TRUE,
      comparisons = list()
    ),
    "comparisons"
  )
})

test_that("comparison plots support significance annotations", {
  p <- plot_box_paper(
    .comparison_unpaired_data,
    condition,
    value,
    show_signif = TRUE,
    comparisons = list(c("Control", "Treatment"))
  )

  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("comparison plots support log scale, dictionaries, palettes, and facets", {
  p_violin <- plot_violin_paper(
    .comparison_unpaired_data,
    condition,
    value,
    dictionary = "default",
    facet = batch,
    log_scale = TRUE
  )
  p_dot <- plot_dot_paper(
    .comparison_unpaired_data,
    condition,
    value,
    palette = "gray"
  )

  expect_match(p_violin$scales$get_scales("y")$trans$name, "log")
  expect_no_error(ggplot2::ggplot_build(p_violin))
  expect_no_error(ggplot2::ggplot_build(p_dot))
})

test_that("low-level paper layers return standard ggplot components", {
  jitter_pos <- position_paper_jitter()
  summary_layers <- layer_summary_paper(summary_type = "mean_se")
  signif_layers <- layer_signif_paper(
    .comparison_unpaired_data,
    x = condition,
    y = value,
    comparisons = list(c("Control", "Treatment"))
  )

  expect_s3_class(jitter_pos, "PositionJitter")
  expect_length(summary_layers, 2)
  expect_true(length(signif_layers) >= 1)
})
