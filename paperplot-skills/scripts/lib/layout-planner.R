# Multi-panel layout planning helpers for paperplot-skills.

pp_panel_spec <- function(panel_id, message, role = c("primary", "secondary", "supporting"), plot_type, metric = NULL) {
  role <- match.arg(role)
  list(
    panel_id = pp_nonempty_scalar(panel_id, "panel_id"),
    message = pp_nonempty_scalar(message, "message"),
    role = role,
    plot_type = pp_nonempty_scalar(plot_type, "plot_type"),
    metric = metric
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
  primary_weight <- if (length(panel_hierarchy$primary) > 0) 1.25 else 1
  list(
    figure_role = figure_role,
    n_panels = panel_hierarchy$n_panels,
    primary_weight = primary_weight,
    shared_legend_preferred = TRUE,
    repeated_axis_titles_allowed = !identical(figure_role, "main"),
    max_primary_panels = if (identical(figure_role, "main")) 2 else Inf
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
    primary_position = if (length(panel_hierarchy$primary) > 0) "upper-left or largest available slot" else "not specified"
  )
}

pp_shared_guide_plan <- function(panel_specs, palette_plan = NULL) {
  plot_types <- vapply(panel_specs, function(x) x$plot_type, character(1))
  list(
    shared_legend = length(unique(plot_types)) <= length(plot_types),
    legend_position = "bottom",
    palette_plan = palette_plan,
    repeated_guides = "avoid unless panel-specific semantics differ"
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
