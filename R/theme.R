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

#' Clean composite manuscript theme
#'
#' A restrained complete theme for dense multi-panel manuscript figures. It
#' keeps the background white, removes decorative grids, uses thin strokes, and
#' gives legends and captions a low visual weight so repeated panels, tracks,
#' trees, and compact summaries remain scannable.
#'
#' @param base_size Base text size in points.
#' @param base_family Base font family.
#' @param line_width Base axis and tick line width.
#' @param axis_title_margin Margin around axis titles.
#' @param legend_key_size Legend key size in millimetres.
#'
#' @return A complete ggplot theme object.
#' @export
#'
#' @examples
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
#'     ggplot2::geom_point(size = 1.4) +
#'     scale_color_lab(palette = "manuscript_clean") +
#'     theme_clean_composite(base_family = "")
theme_clean_composite <- function(
    base_size = 7,
    base_family = "Arial",
    line_width = 0.3,
    axis_title_margin = 3,
    legend_key_size = 3.6
) {
    legend_key_size <- .validate_positive_number(legend_key_size, "legend_key_size")

    theme_obj <- theme_lab(
        base_size = base_size,
        base_family = base_family,
        line_width = line_width,
        axis_title_margin = axis_title_margin,
        show_grid = FALSE
    ) +
        ggplot2::theme(
            text = ggplot2::element_text(
                family = base_family,
                size = base_size,
                colour = "#202020"
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
            axis.text = ggplot2::element_text(size = base_size - 0.7, colour = "#303030"),
            axis.line = ggplot2::element_line(linewidth = line_width, colour = "#2A2A2A"),
            axis.ticks = ggplot2::element_line(linewidth = line_width, colour = "#2A2A2A"),
            axis.ticks.length = grid::unit(1.2, "mm"),
            legend.title = ggplot2::element_text(size = base_size - 0.4, face = "plain"),
            legend.text = ggplot2::element_text(size = base_size - 0.7),
            legend.key = ggplot2::element_blank(),
            legend.key.size = grid::unit(legend_key_size, "mm"),
            legend.margin = ggplot2::margin(0, 0, 0, 0),
            legend.box.margin = ggplot2::margin(0, 0, 0, 0),
            legend.background = ggplot2::element_blank(),
            legend.box.background = ggplot2::element_blank(),
            panel.background = ggplot2::element_rect(fill = "white", colour = NA),
            plot.background = ggplot2::element_rect(fill = "white", colour = NA),
            panel.grid.major = ggplot2::element_blank(),
            panel.grid.minor = ggplot2::element_blank(),
            panel.border = ggplot2::element_blank(),
            strip.background = ggplot2::element_blank(),
            strip.text = ggplot2::element_text(size = base_size, face = "plain", colour = "#202020"),
            plot.title = ggplot2::element_text(size = base_size + 0.5, face = "plain"),
            plot.subtitle = ggplot2::element_text(size = base_size - 0.2, colour = "#404040"),
            plot.caption = ggplot2::element_text(size = base_size - 1, colour = "#6A6A6A"),
            plot.margin = ggplot2::margin(4, 4, 4, 4)
        )

    attr(theme_obj, "complete") <- TRUE
    theme_obj
}
