#' Lab standard ggplot theme
#'
#' @param base_size Base text size in points.
#' @param base_family Base font family.
#' @param line_width Base line width.
#' @param axis_title_margin Margin around axis titles.
#' @param show_grid Whether to draw a light major grid.
#'
#' @return A complete ggplot theme object.
#' @export
theme_lab <- function(
    base_size = 7,
    base_family = "Arial",
    line_width = 0.35,
    axis_title_margin = 4,
    show_grid = FALSE
) {
    grid_major <- if (isTRUE(show_grid)) {
        ggplot2::element_line(linewidth = 0.25, colour = "#D9D9D9")
    } else {
        ggplot2::element_blank()
    }

    theme_obj <- ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
        ggplot2::theme(
            text = ggplot2::element_text(
                family = base_family,
                size = base_size,
                colour = "#1F1F1F"
            ),
            axis.title = ggplot2::element_text(
                size = base_size,
                face = "plain",
                margin = ggplot2::margin(
                    t = axis_title_margin,
                    r = axis_title_margin,
                    b = axis_title_margin,
                    l = axis_title_margin
                )
            ),
            axis.text = ggplot2::element_text(size = base_size - 0.5, colour = "#303030"),
            axis.line = ggplot2::element_line(linewidth = line_width, colour = "#1F1F1F"),
            axis.ticks = ggplot2::element_line(linewidth = line_width, colour = "#1F1F1F"),
            axis.ticks.length = grid::unit(1.5, "mm"),
            legend.title = ggplot2::element_text(size = base_size - 0.2, face = "plain"),
            legend.text = ggplot2::element_text(size = base_size - 0.5),
            legend.key = ggplot2::element_blank(),
            legend.key.size = grid::unit(4.2, "mm"),
            legend.spacing.x = grid::unit(1, "mm"),
            panel.grid.major = grid_major,
            panel.grid.minor = ggplot2::element_blank(),
            panel.border = ggplot2::element_blank(),
            strip.background = ggplot2::element_blank(),
            plot.title = ggplot2::element_text(size = base_size + 1, face = "bold"),
            plot.subtitle = ggplot2::element_text(size = base_size),
            plot.caption = ggplot2::element_text(size = base_size - 1, colour = "#6A6A6A"),
            strip.text = ggplot2::element_text(size = base_size, face = "bold"),
            plot.title.position = "plot",
            plot.margin = ggplot2::margin(6, 6, 6, 6)
        )

    attr(theme_obj, "complete") <- TRUE
    theme_obj
}
