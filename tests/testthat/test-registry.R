.snapshot_registry <- function() {
  list(
    fig_specs = .paperplotr_registry$fig_specs,
    panel_aliases = .paperplotr_registry$panel_aliases,
    panel_hints = .paperplotr_registry$panel_hints,
    journal_presets = .paperplotr_registry$journal_presets,
    output_presets = .paperplotr_registry$output_presets,
    discrete_palettes = .paperplotr_registry$discrete_palettes,
    gradient_palettes = .paperplotr_registry$gradient_palettes,
    group_dictionaries = .paperplotr_registry$group_dictionaries
  )
}

.restore_registry <- function(snapshot) {
  .paperplotr_registry$fig_specs <- snapshot$fig_specs
  .paperplotr_registry$panel_aliases <- snapshot$panel_aliases
  .paperplotr_registry$panel_hints <- snapshot$panel_hints
  .paperplotr_registry$journal_presets <- snapshot$journal_presets
  .paperplotr_registry$output_presets <- snapshot$output_presets
  .paperplotr_registry$discrete_palettes <- snapshot$discrete_palettes
  .paperplotr_registry$gradient_palettes <- snapshot$gradient_palettes
  .paperplotr_registry$group_dictionaries <- snapshot$group_dictionaries
}

test_that("custom figure specs can be registered and resolved", {
  snapshot <- .snapshot_registry()
  on.exit(.restore_registry(snapshot), add = TRUE)

  register_fig_spec(
    name = "6x4",
    panel_w_cm = 6,
    panel_h_cm = 4,
    alias = "wide",
    layout_hint = "Wide single-panel figures"
  )

  expect_true(all(c("6x4", "wide") %in% available_fig_specs()))
  expect_equal(get_fig_size_cm("wide")$spec, "6x4")
  expect_equal(panel_size("6x4")$width_cm, 6)
  expect_match(panel_size("6x4")$layout_hint, "Wide")
})

test_that("custom journal and output presets can be registered", {
  snapshot <- .snapshot_registry()
  on.exit(.restore_registry(snapshot), add = TRUE)

  register_journal_preset(
    name = "journal_x",
    figure_width_cm = 16.5,
    base_size_pt = 8,
    min_text_pt = 6,
    dpi = 450
  )
  register_output_preset(
    name = "journal_x_half",
    journal = "journal_x",
    width_cm = 8.2,
    height_cm = 6.1,
    dpi = 450
  )

  expect_true(all(c("journal_x") %in% available_journal_presets()))
  expect_true(all(c("journal_x_half") %in% available_output_presets()))
  expect_equal(journal_preset("journal_x")$figure_width_cm, 16.5)
})

test_that("custom palettes can be registered", {
  snapshot <- .snapshot_registry()
  on.exit(.restore_registry(snapshot), add = TRUE)

  register_palette("study_palette", c("#1B3A57", "#2E6F95", "#58A4B0"))
  register_palette("study_gradient", c("#F7FBFF", "#6BAED6", "#08306B"), type = "gradient")

  expect_true("study_palette" %in% available_lab_palettes())
  expect_equal(lab_palette(3, palette = "study_palette"), c("#1B3A57", "#2E6F95", "#58A4B0"))
  expect_equal(length(lab_gradient_palette(5, palette = "study_gradient")), 5)
})

test_that("custom group dictionaries can be registered", {
  snapshot <- .snapshot_registry()
  on.exit(.restore_registry(snapshot), add = TRUE)

  register_group_dictionary(
    name = "study_groups",
    values = c(Control = "#4D4D4D", Treatment = "#D55E00", Rescue = "#009E73")
  )

  expect_true("study_groups" %in% available_group_dictionaries())
  expect_equal(group_colors("study_groups")[["Rescue"]], "#009E73")
})

test_that("registration helpers reject accidental duplicate names", {
  snapshot <- .snapshot_registry()
  on.exit(.restore_registry(snapshot), add = TRUE)

  expect_error(
    register_palette("main", c("#000000", "#111111")),
    "already exists"
  )

  register_palette("temp_palette", c("#000000", "#111111"))
  expect_error(
    register_palette("temp_palette", c("#222222", "#333333")),
    "already exists"
  )
})
