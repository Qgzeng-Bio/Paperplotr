# Multi-panel layout planning helpers for paperplot-skills.

pp_panel_spec <- function(panel_id, message, role = c("primary", "secondary", "supporting"),
                          plot_type, metric = NULL, guide_semantics = NULL) {
  role <- match.arg(role)
  list(
    panel_id = pp_nonempty_scalar(panel_id, "panel_id"),
    message = pp_nonempty_scalar(message, "message"),
    role = role,
    plot_type = pp_nonempty_scalar(plot_type, "plot_type"),
    metric = metric,
    guide_semantics = guide_semantics
  )
}

pp_panel_hierarchy <- function(panel_specs) {
  if (!is.list(panel_specs) || length(panel_specs) == 0) stop("panel_specs must be a non-empty list.", call. = FALSE)
  roles <- vapply(panel_specs, function(x) x$role %||% "", character(1))
  out <- list(
    panels = panel_specs,
    n_panels = length(panel_specs),
    primary = vapply(panel_specs[roles == "primary"], function(x) x$panel_id, character(1)),
    secondary = vapply(panel_specs[roles == "secondary"], function(x) x$panel_id, character(1)),
    supporting = vapply(panel_specs[roles == "supporting"], function(x) x$panel_id, character(1))
  )
  pp_validate_panel_hierarchy(out)
  out
}

pp_layout_budget <- function(panel_hierarchy, figure_role = "main") {
  pp_validate_panel_hierarchy(panel_hierarchy)
  list(
    figure_role = figure_role,
    n_panels = panel_hierarchy$n_panels,
    layout_profile = "equal",
    repeated_axis_titles_allowed = !identical(figure_role, "main"),
    max_primary_panels = if (identical(figure_role, "main")) 2 else Inf,
    note = "Faceted production templates use equal panel boxes. Use an explicit composite backend for unequal role weights."
  )
}

pp_recommend_manuscript_layout <- function(panel_hierarchy, available_width_cm, available_height_cm) {
  pp_validate_panel_hierarchy(panel_hierarchy)
  n <- panel_hierarchy$n_panels
  dims <- if (n <= 1) c(1, 1) else if (n == 2) c(2, 1) else if (n <= 4) c(2, 2) else if (n <= 6) c(3, 2) else c(4, ceiling(n / 4))
  list(
    type = "manuscript_grid",
    ncol = dims[[1]],
    nrow = dims[[2]],
    width_cm = available_width_cm,
    height_cm = available_height_cm,
    expected_panels = n,
    layout_profile = "equal",
    primary_position = if (length(panel_hierarchy$primary) > 0) "upper-left within equal panel boxes" else "not specified"
  )
}

pp_shared_guide_plan <- function(panel_specs, palette_plan = NULL) {
  guide_semantics <- vapply(panel_specs, function(x) x$guide_semantics %||% "", character(1))
  palette_type <- palette_plan$type %||% ""
  # Shared guides require the same mapped variable/meaning in every panel and
  # one declared palette semantic. Chart family alone is not sufficient.
  shared_legend <- length(guide_semantics) > 0L && all(nzchar(guide_semantics)) &&
    length(unique(guide_semantics)) == 1L && nzchar(palette_type)
  list(
    shared_legend = shared_legend,
    shared_legend_reason = if (shared_legend) {
      "all panels share one guide variable and palette semantics"
    } else {
      "heterogeneous panels must keep compact per-panel guides"
    },
    legend_position = "bottom",
    palette_plan = palette_plan,
    repeated_guides = "avoid unless panel-specific semantics differ"
  )
}

# Pre-render legend placement planner (WP3).
# Estimates the physical footprint of a legend BEFORE rendering from entry
# count, longest label, and the style registry, then picks the placement that
# fits the canvas: bottom strip first (best readability), right column next,
# otherwise flags an overflow risk instead of letting the renderer decide.
pp_legend_plan <- function(entries, labels = NULL, canvas_width_cm = NULL, canvas_height_cm = NULL,
                           base_size = pp_style_number("base_size"), has_title = FALSE,
                           title_chars = 10) {
  entries <- max(0L, as.integer(entries[[1]]))
  labels <- as.character(labels)
  labels <- labels[nzchar(labels)]
  key_mm <- pp_spacing_mm("legend_key")
  # Adaptive key shrink keeps very long keys from eating the data region.
  if (entries > 12) key_mm <- max(2.6, key_mm * (1 - (entries - 12) * 0.02))
  pt_to_mm <- 25.4 / 72
  # Legend text renders at the theme hierarchy offset (base_size - 0.5 by
  # default); glyph advance measured from PDF text bboxes is ~0.55 em.
  legend_text_pt <- base_size + pp_style_registry()$font_hierarchy$legend_text
  char_mm <- legend_text_pt * pt_to_mm * 0.55
  entry_gap_mm <- 1.2
  # Sum each label's own width; multiplying the longest label by the entry
  # count overestimated real legends ~3x and pushed them off-bottom wrongly.
  if (length(labels)) {
    label_widths_mm <- nchar(labels, type = "chars") * char_mm
    total_text_mm <- sum(label_widths_mm)
    max_label_mm <- max(label_widths_mm)
  } else {
    avg_chars <- 12
    total_text_mm <- entries * avg_chars * char_mm
    max_label_mm <- avg_chars * char_mm
  }
  title_mm <- if (isTRUE(has_title)) title_chars * char_mm + entry_gap_mm else 0
  bottom_w_mm <- total_text_mm + entries * (key_mm + entry_gap_mm) + title_mm + 4
  right_w_mm <- key_mm + entry_gap_mm + max_label_mm + 4
  right_h_mm <- entries * (key_mm * 0.72) + title_mm + 3
  fits_bottom <- if (is.null(canvas_width_cm)) TRUE else bottom_w_mm <= canvas_width_cm * 10 * 0.9
  fits_right <- if (is.null(canvas_height_cm)) TRUE else {
    right_h_mm <= canvas_height_cm * 10 * 0.72 &&
      right_w_mm <= canvas_width_cm * 10 * 0.28
  }
  position <- if (entries <= 0L) {
    "none"
  } else if (fits_bottom) {
    "bottom"
  } else if (fits_right) {
    "right"
  } else {
    "bottom"
  }
  overflow_risk <- entries > 0L && !fits_bottom && !fits_right
  list(
    entries = entries,
    position = position,
    direction = if (identical(position, "right")) "vertical" else "horizontal",
    key_size_mm = round(key_mm, 2),
    estimated_bottom_width_mm = round(bottom_w_mm, 1),
    estimated_right_block_mm = c(width = round(right_w_mm, 1), height = round(right_h_mm, 1)),
    overflow_risk = overflow_risk,
    status = if (overflow_risk) "warn" else "pass",
    note = if (overflow_risk) {
      "Legend does not fit bottom or right within budget; reduce entries or move mapping to a label-key sidecar."
    } else if (identical(position, "none")) {
      "No legend entries; guides suppressed."
    } else {
      paste0("Legend placed ", position, " (~", if (identical(position, "bottom")) bottom_w_mm else right_w_mm, " mm wide).")
    }
  )
}

pp_panel_tag_labels <- function(n, style = "uppercase") {
  labels <- LETTERS[seq_len(n)]
  if (identical(style, "lowercase")) labels <- letters[seq_len(n)]
  labels
}

pp_validate_panel_hierarchy <- function(panel_hierarchy) {
  if (is.null(panel_hierarchy$n_panels) || panel_hierarchy$n_panels < 1) stop("panel_hierarchy must contain panels.", call. = FALSE)
  if (length(panel_hierarchy$primary) > 2) warning("Main manuscript figures usually should not have more than two primary panels.", call. = FALSE)
  invisible(TRUE)
}

pp_validate_panel_alignment <- function(layout_plan) {
  if (is.null(layout_plan$ncol) || is.null(layout_plan$nrow)) stop("layout_plan must include ncol and nrow.", call. = FALSE)
  invisible(TRUE)
}
