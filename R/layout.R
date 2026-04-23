#' Compose multiple plots with a lab-standard patchwork layout
#'
#' @param ... ggplot objects or a single list of ggplot objects.
#' @param ncol Number of columns in the composed layout.
#' @param nrow Number of rows in the composed layout.
#' @param guides Guide collection strategy passed to `patchwork::wrap_plots()`.
#'
#' @return A patchwork composition.
#' @export
layout_lab <- function(..., ncol = NULL, nrow = NULL, guides = "collect") {
    if (!requireNamespace("patchwork", quietly = TRUE)) {
        cli::cli_abort("Package {.pkg patchwork} is required for {.fn layout_lab}.")
    }

    plots <- list(...)
    if (length(plots) == 1 && is.list(plots[[1]]) && !inherits(plots[[1]], "ggplot")) {
        plots <- plots[[1]]
    }

    plots <- Filter(Negate(is.null), plots)
    if (length(plots) == 0) {
        cli::cli_abort("Provide at least one plot to {.fn layout_lab}.")
    }

    patchwork::wrap_plots(plots = plots, ncol = ncol, nrow = nrow, guides = guides)
}
