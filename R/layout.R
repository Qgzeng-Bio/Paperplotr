#' Compose multiple plots with a lab-standard patchwork layout
#'
#' @param ... ggplot objects or a single list of ggplot objects.
#' @param ncol Number of columns in the composed layout.
#' @param nrow Number of rows in the composed layout.
#' @param guides Guide collection strategy passed to `patchwork::wrap_plots()`.
#' @param tag_levels Optional tag level passed to `patchwork::plot_annotation()`,
#'   such as `"A"` or `"a"`.
#' @param tag_size Panel tag text size in points.
#' @param tag_face Panel tag font face.
#' @param tag_family Panel tag font family. If `NULL`, uses the active theme.
#' @param tag_position Two numeric values used for `plot.tag.position`.
#'
#' @return A patchwork composition.
#' @export
layout_lab <- function(
    ...,
    ncol = NULL,
    nrow = NULL,
    guides = "collect",
    tag_levels = NULL,
    tag_size = 10,
    tag_face = "bold",
    tag_family = NULL,
    tag_position = c(0, 1)
) {
    if (!requireNamespace("patchwork", quietly = TRUE)) {
        cli::cli_abort("Package {.pkg patchwork} is required for {.fn layout_lab}.")
    }

    tag_size <- .validate_positive_number(tag_size, "tag_size")
    tag_face <- .validate_scalar_string(tag_face, "tag_face")
    if (!is.null(tag_family)) {
        tag_family <- .validate_scalar_string(tag_family, "tag_family")
    }
    if (!is.numeric(tag_position) || length(tag_position) != 2 || anyNA(tag_position)) {
        cli::cli_abort("{.arg tag_position} must be a numeric vector of length 2.")
    }

    plots <- list(...)
    if (length(plots) == 1 && is.list(plots[[1]]) && !inherits(plots[[1]], "ggplot")) {
        plots <- plots[[1]]
    }

    plots <- Filter(Negate(is.null), plots)
    if (length(plots) == 0) {
        cli::cli_abort("Provide at least one plot to {.fn layout_lab}.")
    }

    composed <- patchwork::wrap_plots(plots = plots, ncol = ncol, nrow = nrow, guides = guides)

    if (!is.null(tag_levels)) {
        composed <- composed +
            patchwork::plot_annotation(
                tag_levels = tag_levels,
                theme = ggplot2::theme(
                    plot.tag = ggplot2::element_text(
                        size = tag_size,
                        face = tag_face,
                        family = tag_family
                    ),
                    plot.tag.position = tag_position
                )
            )
    }

    composed
}
