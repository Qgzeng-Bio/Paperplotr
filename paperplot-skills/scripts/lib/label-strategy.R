# Design-aware label strategy helpers for paperplot-skills.

pp_label_burden_score <- function(labels, available_width_cm, font_size_pt = 6.5) {
  labels <- as.character(labels)
  labels <- labels[!is.na(labels)]
  if (length(labels) == 0) {
    return(list(score = 0, status = "pass", n_labels = 0, max_chars = 0, message = "no labels"))
  }
  available_width_pt <- available_width_cm / 2.54 * 72
  max_chars <- max(nchar(labels, type = "chars"), na.rm = TRUE)
  score <- max_chars * font_size_pt * 0.55 * length(labels) / available_width_pt
  status <- if (score < 0.8) "pass" else if (score <= 1.2) "warn" else "fail"
  message <- switch(status,
    pass = "visible labels fit the available width",
    warn = "visible labels are dense; use rotation, wrapping, abbreviation, or selective labels",
    fail = "visible labels are too dense for manuscript display; prefer rank index plus key labels and sidecar"
  )
  list(score = unname(score), status = status, n_labels = length(labels), max_chars = max_chars, message = message)
}

pp_rank_index_map <- function(samples, order = NULL, prefix = "") {
  samples <- as.character(samples)
  sample_order <- if (is.null(order)) unique(samples) else as.character(order)
  sample_order <- sample_order[!duplicated(sample_order)]
  data.frame(
    rank_index = seq_along(sample_order),
    rank_label = paste0(prefix, seq_along(sample_order)),
    sample = sample_order,
    stringsAsFactors = FALSE
  )
}

pp_select_key_labels <- function(data, sample_col, value_col = NULL, group_col = NULL, max_labels = 8) {
  if (!sample_col %in% names(data)) stop("sample_col not found: ", sample_col, call. = FALSE)
  samples <- unique(as.character(data[[sample_col]]))
  key <- character()
  if (!is.null(value_col) && value_col %in% names(data)) {
    values <- data[[value_col]]
    ok <- is.finite(values)
    if (any(ok)) {
      ordered <- data[ok, , drop = FALSE]
      ordered <- ordered[order(ordered[[value_col]], decreasing = TRUE), , drop = FALSE]
      key <- c(key, head(as.character(ordered[[sample_col]]), 2), tail(as.character(ordered[[sample_col]]), 2))
    }
  }
  if (!is.null(group_col) && group_col %in% names(data)) {
    by_group <- split(as.character(data[[sample_col]]), as.character(data[[group_col]]))
    key <- c(key, vapply(by_group, function(x) unique(x)[[1]], character(1)))
  }
  key <- unique(key[nzchar(key)])
  if (length(key) == 0) key <- head(samples, max_labels)
  head(key, max_labels)
}

pp_label_strategy_v2 <- function(labels, figure_role, available_width_cm, sample_identity_role = "lookup") {
  figure_role <- match.arg(figure_role, c("main", "supplement", "diagnostic", "exploratory"))
  burden <- pp_label_burden_score(labels, available_width_cm = available_width_cm)
  n <- length(unique(as.character(labels)))
  strategy <- "direct"
  visible_label_policy <- "show_all"
  needs_label_key <- FALSE
  direct_label_mode <- "none"
  if (identical(figure_role, "diagnostic")) {
    strategy <- "full_labels_diagnostic"
    visible_label_policy <- "show_all"
  } else if (n <= 8 && burden$status != "fail") {
    strategy <- "direct"
    visible_label_policy <- "show_all"
  } else if (n <= 20 && sample_identity_role != "lookup" && burden$status != "fail") {
    strategy <- "abbreviate_or_rotate"
    visible_label_policy <- "show_most"
    needs_label_key <- TRUE
  } else if (identical(figure_role, "main")) {
    strategy <- "rank_index_key_labels"
    visible_label_policy <- "rank_index_plus_selected_labels"
    needs_label_key <- TRUE
    direct_label_mode <- "selected_key_samples"
  } else {
    strategy <- "rank_index_or_abbreviated_labels"
    visible_label_policy <- "reduced_labels"
    needs_label_key <- TRUE
    direct_label_mode <- "selected_key_samples"
  }
  list(
    status = burden$status,
    strategy = strategy,
    visible_label_policy = visible_label_policy,
    sample_identity_role = sample_identity_role,
    needs_label_key = needs_label_key,
    direct_label_mode = direct_label_mode,
    burden = burden,
    message = burden$message
  )
}

pp_prepare_rank_axis <- function(data, sample_col, sample_order, index_col = "rank_index") {
  rank_map <- pp_rank_index_map(sample_order)
  idx <- match(as.character(data[[sample_col]]), rank_map$sample)
  data[[index_col]] <- idx
  attr(data, "rank_map") <- rank_map
  data
}

pp_write_label_key <- function(path, rank_map) {
  if (file.exists(path)) stop("Refusing to overwrite existing label key file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(rank_map, path, row.names = FALSE)
  pp_assert_output(path)
  invisible(path)
}

pp_should_flip_axes <- function(label_strategy, figure_role, plot_role) {
  if (identical(figure_role, "diagnostic")) return(TRUE)
  if (identical(label_strategy$strategy, "rank_index_key_labels")) return(FALSE)
  if (identical(plot_role, "sample_lookup_primary")) return(TRUE)
  FALSE
}
