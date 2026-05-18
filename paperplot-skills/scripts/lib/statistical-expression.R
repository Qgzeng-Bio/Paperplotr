# Statistical expression helpers for paperplot-skills.

pp_group_summary <- function(data, group_col, value_col) {
  if (!group_col %in% names(data)) stop("group_col not found: ", group_col, call. = FALSE)
  if (!value_col %in% names(data)) stop("value_col not found: ", value_col, call. = FALSE)
  split_values <- split(data[[value_col]], as.character(data[[group_col]]))
  out <- data.frame(
    group = names(split_values),
    n = vapply(split_values, function(x) sum(is.finite(x)), integer(1)),
    mean = vapply(split_values, function(x) mean(x, na.rm = TRUE), numeric(1)),
    median = vapply(split_values, function(x) stats::median(x, na.rm = TRUE), numeric(1)),
    sd = vapply(split_values, function(x) stats::sd(x, na.rm = TRUE), numeric(1)),
    q1 = vapply(split_values, function(x) stats::quantile(x, 0.25, na.rm = TRUE, names = FALSE), numeric(1)),
    q3 = vapply(split_values, function(x) stats::quantile(x, 0.75, na.rm = TRUE, names = FALSE), numeric(1)),
    stringsAsFactors = FALSE
  )
  out
}

pp_ci_t <- function(x, conf_level = 0.95) {
  x <- x[is.finite(x)]
  n <- length(x)
  if (n < 2) return(c(mean = mean(x), low = NA_real_, high = NA_real_))
  m <- mean(x)
  se <- stats::sd(x) / sqrt(n)
  alpha <- 1 - conf_level
  q <- stats::qt(1 - alpha / 2, df = n - 1)
  c(mean = m, low = m - q * se, high = m + q * se)
}

pp_cliffs_delta <- function(x, y) {
  x <- x[is.finite(x)]
  y <- y[is.finite(y)]
  if (length(x) == 0 || length(y) == 0) return(NA_real_)
  comparisons <- outer(x, y, "-")
  (sum(comparisons > 0) - sum(comparisons < 0)) / (length(x) * length(y))
}

pp_effect_size <- function(data, group_col, value_col, method = c("mean_difference", "standardized_difference", "cliffs_delta"), comparison = NULL) {
  method <- match.arg(method)
  groups <- unique(as.character(data[[group_col]]))
  groups <- groups[!is.na(groups) & nzchar(groups)]
  if (!is.null(comparison)) groups <- as.character(comparison)
  if (length(groups) != 2) stop("Effect size requires exactly two groups.", call. = FALSE)
  x <- data[data[[group_col]] == groups[[1]], value_col]
  y <- data[data[[group_col]] == groups[[2]], value_col]
  x <- x[is.finite(x)]
  y <- y[is.finite(y)]
  estimate <- switch(method,
    mean_difference = mean(x) - mean(y),
    standardized_difference = {
      pooled <- sqrt(((length(x) - 1) * stats::var(x) + (length(y) - 1) * stats::var(y)) / (length(x) + length(y) - 2))
      (mean(x) - mean(y)) / pooled
    },
    cliffs_delta = pp_cliffs_delta(x, y)
  )
  ci <- if (identical(method, "mean_difference") && length(x) > 1 && length(y) > 1) {
    diff_values <- x - mean(y)
    pp_ci_t(diff_values)
  } else {
    c(mean = estimate, low = NA_real_, high = NA_real_)
  }
  data.frame(
    group_1 = groups[[1]],
    group_2 = groups[[2]],
    method = method,
    estimate = estimate,
    ci_low = ci[["low"]],
    ci_high = ci[["high"]],
    direction = paste(groups[[1]], "minus", groups[[2]]),
    stringsAsFactors = FALSE
  )
}

pp_statistical_plan <- function(data, group_col, value_col, paired_id_col = NULL, comparison = NULL) {
  summary <- pp_group_summary(data, group_col, value_col)
  min_n <- min(summary$n, na.rm = TRUE)
  paired <- !is.null(paired_id_col) && paired_id_col %in% names(data)
  recommended_display <- if (paired) {
    "paired_points_and_lines"
  } else if (min_n < 5) {
    "raw_points_only_or_points_with_summary"
  } else if (min_n < 20) {
    "boxplot_with_raw_points"
  } else {
    "violin_or_boxplot_with_points"
  }
  warnings <- character()
  if (min_n < 5) warnings <- c(warnings, "n < 5 per group; boxplot should not be primary evidence")
  if (paired && is.null(paired_id_col)) warnings <- c(warnings, "paired display requested but paired_id_col is missing")
  list(
    group_col = group_col,
    value_col = value_col,
    paired_id_col = paired_id_col,
    paired = paired,
    comparison = comparison,
    group_summary = summary,
    min_n = min_n,
    recommended_display = recommended_display,
    warnings = warnings
  )
}

pp_format_p_value <- function(p) {
  ifelse(is.na(p), "NA", ifelse(p < 0.001, "P < 0.001", paste0("P = ", formatC(p, format = "f", digits = 3))))
}

pp_stat_annotation_plan <- function(statistical_plan, figure_role = "main") {
  show_p <- !identical(figure_role, "main")
  list(
    show_raw_points = TRUE,
    show_effect_size = TRUE,
    show_ci = TRUE,
    show_p_value = show_p,
    p_value_location = if (show_p) "notes_or_light_annotation" else "notes_metadata_only"
  )
}

pp_validate_statistical_expression <- function(plot_type, statistical_plan, data_profile = NULL) {
  status <- "pass"
  note <- paste("recommended display:", statistical_plan$recommended_display)
  if (grepl("boxplot", plot_type) && statistical_plan$min_n < 5) {
    status <- "warn"
    note <- "n < 5 per group; raw points must be primary and boxplot should be avoided or downweighted"
  }
  if (grepl("paired", plot_type) && !isTRUE(statistical_plan$paired)) {
    status <- "fail"
    note <- "paired plot requires paired_id_col"
  }
  pp_qa_result("statistical_expression", status, note)
}
