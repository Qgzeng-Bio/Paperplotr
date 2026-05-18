# Design brief and design plan helpers for paperplot-skills.
# Dependencies: base R only; assumes paperplot_helpers.R has defined pp_to_json and pp_assert_output.

pp_design_brief <- function(scientific_message,
                            figure_role = c("main", "supplement", "diagnostic", "exploratory"),
                            audience = "manuscript reviewers",
                            main_comparison = NULL,
                            data_roles = list(),
                            metric_semantics = list(),
                            panel_hierarchy = list(),
                            label_burden = NULL,
                            legend_burden = NULL,
                            acceptable_simplifications = character(),
                            must_show = character(),
                            may_move_to_metadata = character(),
                            old_figure_context = NULL) {
  figure_role <- match.arg(figure_role)
  out <- list(
    scientific_message = pp_nonempty_scalar(scientific_message, "scientific_message"),
    figure_role = figure_role,
    audience = audience,
    main_comparison = main_comparison,
    data_roles = data_roles,
    metric_semantics = metric_semantics,
    panel_hierarchy = panel_hierarchy,
    label_burden = label_burden,
    legend_burden = legend_burden,
    acceptable_simplifications = as.character(acceptable_simplifications),
    must_show = as.character(must_show),
    may_move_to_metadata = as.character(may_move_to_metadata),
    old_figure_context = old_figure_context,
    created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
  pp_validate_design_brief(out)
  class(out) <- c("pp_design_brief", class(out))
  out
}

pp_validate_design_brief <- function(design_brief) {
  required <- c("scientific_message", "figure_role")
  missing <- required[!vapply(required, function(x) !is.null(design_brief[[x]]) && nzchar(as.character(design_brief[[x]][[1]])), logical(1))]
  if (length(missing) > 0) {
    stop("design_brief is missing required fields: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  allowed_roles <- c("main", "supplement", "diagnostic", "exploratory")
  if (!design_brief$figure_role %in% allowed_roles) {
    stop("design_brief has invalid figure_role: ", design_brief$figure_role, call. = FALSE)
  }
  invisible(TRUE)
}

pp_write_design_brief <- function(path, design_brief) {
  pp_validate_design_brief(design_brief)
  if (file.exists(path)) stop("Refusing to overwrite existing design brief file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(pp_to_json(design_brief), con = path)
  pp_assert_output(path)
  invisible(path)
}

pp_data_profile <- function(data, sample_col = NULL, group_col = NULL, metric_col = NULL, value_col = NULL) {
  out <- list(
    n_rows = nrow(data),
    n_columns = ncol(data),
    columns = names(data),
    sample_col = sample_col,
    group_col = group_col,
    metric_col = metric_col,
    value_col = value_col
  )
  if (!is.null(sample_col) && sample_col %in% names(data)) {
    labels <- as.character(data[[sample_col]])
    out$n_samples <- length(unique(labels))
    out$max_sample_label_chars <- max(nchar(labels), na.rm = TRUE)
  }
  if (!is.null(group_col) && group_col %in% names(data)) {
    out$n_groups <- length(unique(as.character(data[[group_col]])))
    out$groups <- sort(unique(as.character(data[[group_col]])))
  }
  if (!is.null(metric_col) && metric_col %in% names(data)) {
    out$n_metrics <- length(unique(as.character(data[[metric_col]])))
    out$metrics <- unique(as.character(data[[metric_col]]))
  }
  if (!is.null(value_col) && value_col %in% names(data)) {
    out$n_missing_values <- sum(is.na(data[[value_col]]))
    out$n_finite_values <- sum(is.finite(data[[value_col]]))
  }
  out
}

pp_visible_vs_metadata_split <- function(must_show = character(), may_move_to_metadata = character(), visible_simplifications = character()) {
  list(
    must_show = as.character(must_show),
    may_move_to_metadata = as.character(may_move_to_metadata),
    visible_simplifications = as.character(visible_simplifications)
  )
}

pp_design_plan <- function(chart_family,
                           figure_role = "main",
                           layout_plan = list(),
                           label_strategy = list(),
                           palette_plan = list(),
                           panel_hierarchy = list(),
                           statistical_plan = list(),
                           pattern_reference = list(),
                           visible_simplifications = character(),
                           risks = character()) {
  out <- list(
    chart_family = pp_nonempty_scalar(chart_family, "chart_family"),
    figure_role = figure_role,
    layout_plan = layout_plan,
    label_strategy = label_strategy,
    palette_plan = palette_plan,
    panel_hierarchy = panel_hierarchy,
    statistical_plan = statistical_plan,
    pattern_reference = pattern_reference,
    visible_simplifications = as.character(visible_simplifications),
    risks = as.character(risks)
  )
  pp_validate_design_plan(out)
  class(out) <- c("pp_design_plan", class(out))
  out
}

pp_validate_design_plan <- function(design_plan) {
  required <- c("chart_family", "figure_role")
  missing <- required[!vapply(required, function(x) !is.null(design_plan[[x]]) && nzchar(as.character(design_plan[[x]][[1]])), logical(1))]
  if (length(missing) > 0) {
    stop("design_plan is missing required fields: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (is.null(design_plan$visible_simplifications)) {
    stop("design_plan must record visible_simplifications, even if empty.", call. = FALSE)
  }
  invisible(TRUE)
}
