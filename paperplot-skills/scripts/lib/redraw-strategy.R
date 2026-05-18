# Redraw strategy helpers for paperplot-skills.

pp_redraw_strategy <- function(old_figure_context = NULL, design_brief, data_profile = NULL) {
  pp_validate_design_brief(design_brief)
  context <- old_figure_context %||% list()
  has_good_rhythm <- isTRUE(context$has_good_visual_rhythm)
  chart_misleading <- isTRUE(context$misleading_chart_type)
  has_fake_lines <- isTRUE(context$has_connecting_lines) && !isTRUE(context$line_semantics_valid)
  panel_hierarchy_unclear <- isTRUE(context$panel_hierarchy_unclear)
  dense_labels <- isTRUE(context$dense_labels)
  mode <- if (identical(design_brief$figure_role, "diagnostic")) {
    "diagnostic_only"
  } else if (chart_misleading || has_fake_lines) {
    "rebuild"
  } else if (panel_hierarchy_unclear) {
    "recompose"
  } else if (has_good_rhythm && dense_labels) {
    "refine_structure"
  } else if (has_good_rhythm) {
    "preserve_structure"
  } else {
    "refine_structure"
  }
  out <- list(
    mode = mode,
    preserve = if (has_good_rhythm) "useful visual rhythm" else character(),
    remove = c(if (has_fake_lines) "unjustified connecting lines" else character(), if (dense_labels) "dense lookup labels" else character()),
    reason = switch(mode,
      preserve_structure = "old figure has useful rhythm and only local repairs are needed",
      refine_structure = "old figure has usable structure but labels or visual burden need redesign",
      recompose = "panel hierarchy or guide burden needs re-composition",
      rebuild = "old chart type or line semantics may mislead readers",
      diagnostic_only = "goal is diagnostic inspection, not manuscript output"
    ),
    old_figure_context = context,
    data_profile = data_profile
  )
  pp_validate_redraw_decision(out)
  out
}

pp_preserve_visual_rhythm <- function(old_figure_context, candidate_plan) {
  if (!isTRUE(old_figure_context$has_good_visual_rhythm)) return(FALSE)
  if (isTRUE(candidate_plan$destroys_visual_rhythm)) return(FALSE)
  TRUE
}

pp_compare_design_plans <- function(old_plan, new_plan) {
  list(
    same_chart_family = identical(old_plan$chart_family, new_plan$chart_family),
    old_chart_family = old_plan$chart_family %||% NA_character_,
    new_chart_family = new_plan$chart_family %||% NA_character_,
    old_label_strategy = old_plan$label_strategy$strategy %||% NA_character_,
    new_label_strategy = new_plan$label_strategy$strategy %||% NA_character_
  )
}

pp_validate_redraw_decision <- function(redraw_strategy) {
  allowed <- c("preserve_structure", "refine_structure", "recompose", "rebuild", "diagnostic_only")
  if (is.null(redraw_strategy$mode) || !redraw_strategy$mode %in% allowed) {
    stop("Invalid redraw strategy mode.", call. = FALSE)
  }
  if (!nzchar(redraw_strategy$reason %||% "")) {
    stop("redraw_strategy must record a reason.", call. = FALSE)
  }
  invisible(TRUE)
}
