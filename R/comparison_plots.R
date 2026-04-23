.summary_mean_se <- function(x) {
    x <- x[!is.na(x)]
    center <- mean(x)
    se <- if (length(x) <= 1) 0 else stats::sd(x) / sqrt(length(x))

    c(y = center, ymin = center - se, ymax = center + se)
}

.summary_median_iqr <- function(x) {
    x <- x[!is.na(x)]
    iqr <- stats::quantile(x, probs = c(0.25, 0.75), names = FALSE)

    c(y = stats::median(x), ymin = iqr[[1]], ymax = iqr[[2]])
}

.summary_fun_data <- function(summary_type) {
    switch(
        summary_type,
        mean_se = .summary_mean_se,
        median_iqr = .summary_median_iqr,
        cli::cli_abort("Unknown {.arg summary_type}: {.val {summary_type}}")
    )
}

.summary_fun_point <- function(summary_type) {
    switch(
        summary_type,
        mean_se = mean,
        median_iqr = stats::median,
        cli::cli_abort("Unknown {.arg summary_type}: {.val {summary_type}}")
    )
}

.validate_comparisons <- function(comparisons) {
    if (!is.list(comparisons) || length(comparisons) == 0) {
        cli::cli_abort("{.arg comparisons} must be a non-empty list of two-element character vectors.")
    }

    for (comp in comparisons) {
        if (!is.character(comp) || length(comp) != 2 || anyNA(comp) || any(!nzchar(comp))) {
            cli::cli_abort("{.arg comparisons} must be a non-empty list of two-element character vectors.")
        }
    }

    invisible(TRUE)
}

.quo_name <- function(quo, arg) {
    if (rlang::quo_is_missing(quo) || rlang::quo_is_null(quo)) {
        return(NULL)
    }

    expr <- rlang::get_expr(quo)
    if (!rlang::is_symbol(expr)) {
        cli::cli_abort("{.arg {arg}} must be a simple column name.")
    }

    rlang::as_name(expr)
}

.resolve_comparison_inputs <- function(data, x, y, group, facet, id, paired, dictionary, palette, show_signif, comparisons, log_scale) {
    x_name <- .quo_name(x, "x")
    y_name <- .quo_name(y, "y")
    group_name <- .quo_name(group, "group")
    facet_name <- .quo_name(facet, "facet")
    id_name <- .quo_name(id, "id")

    if (isTRUE(paired) && is.null(id_name)) {
        cli::cli_abort("{.arg id} is required when {.arg paired = TRUE}.")
    }

    if (isTRUE(paired) && !is.null(group_name) && group_name != x_name) {
        cli::cli_abort("{.arg paired = TRUE} is only supported when groups are defined by {.arg x}.")
    }

    if (isTRUE(show_signif) && is.null(comparisons)) {
        cli::cli_abort("{.arg comparisons} must be supplied when {.arg show_signif = TRUE}.")
    }
    if (isTRUE(show_signif)) {
        .validate_comparisons(comparisons)
    }

    if (isTRUE(show_signif) && !is.null(facet_name)) {
        cli::cli_abort("Facet-specific significance annotations are not supported in v1.")
    }

    if (!is.null(dictionary) && !is.null(palette)) {
        cli::cli_abort("Use either {.arg dictionary} or {.arg palette}, not both.")
    }

    if (isTRUE(log_scale) && any(data[[y_name]] <= 0, na.rm = TRUE)) {
        cli::cli_abort("{.arg y} must be positive when {.arg log_scale = TRUE}.")
    }

    list(
        x_name = x_name,
        y_name = y_name,
        group_name = group_name,
        facet_name = facet_name,
        id_name = id_name,
        show_legend = !is.null(group_name) && group_name != x_name
    )
}

.resolve_fill_scale <- function(dictionary = NULL, palette = NULL) {
    if (!is.null(dictionary)) {
        return(scale_fill_groupmap(dictionary = dictionary))
    }

    scale_fill_lab(palette = rlang::`%||%`(palette, "main"))
}

.apply_common_plot_settings <- function(plot, log_scale = FALSE, show_legend = FALSE, show_signif = FALSE, facet = NULL) {
    upper_expand <- if (isTRUE(show_signif)) 0.22 else 0.08
    plot <- plot +
        theme_lab() +
        ggplot2::theme(
            axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1),
            legend.position = if (isTRUE(show_legend)) "top" else "none",
            panel.grid = ggplot2::element_blank()
        ) +
        ggplot2::coord_cartesian(clip = "off")

    plot <- if (isTRUE(log_scale)) {
        plot + ggplot2::scale_y_log10(expand = ggplot2::expansion(mult = c(0.02, upper_expand)))
    } else {
        plot + ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.02, upper_expand)))
    }

    if (!rlang::quo_is_missing(facet) && !rlang::quo_is_null(facet)) {
        plot <- plot + ggplot2::facet_wrap(ggplot2::vars(!!facet))
    }

    plot
}

.build_annotation_df <- function(data, x_name, y_name, comparisons, paired = FALSE, id_name = NULL, test = NULL, log_scale = FALSE) {
    x_values <- data[[x_name]]
    x_levels <- if (is.factor(x_values)) levels(x_values) else unique(as.character(x_values))
    x_chr <- as.character(x_values)
    y_values <- data[[y_name]]

    if (is.null(test)) {
        test <- "wilcox"
    }
    if (!identical(test, "wilcox")) {
        cli::cli_abort("Only {.val wilcox} is supported for {.arg test} in v1.")
    }

    base_max <- max(y_values, na.rm = TRUE)
    base_min <- min(y_values, na.rm = TRUE)
    spread <- max(base_max - base_min, abs(base_max) * 0.1, 0.1)

    ann <- lapply(seq_along(comparisons), function(i) {
        comp <- comparisons[[i]]
        if (!is.character(comp) || length(comp) != 2) {
            cli::cli_abort("Each comparison must be a character vector of length 2.")
        }
        if (!all(comp %in% x_levels)) {
            cli::cli_abort("Unknown comparison groups: {.val {setdiff(comp, x_levels)}}")
        }

        group_a <- data[x_chr == comp[[1]], , drop = FALSE]
        group_b <- data[x_chr == comp[[2]], , drop = FALSE]
        p_value <- if (isTRUE(paired)) {
            merged <- merge(
                group_a[, c(id_name, y_name), drop = FALSE],
                group_b[, c(id_name, y_name), drop = FALSE],
                by = id_name,
                suffixes = c("_a", "_b")
            )
            if (nrow(merged) == 0) {
                cli::cli_abort("No overlapping ids were found for paired comparison {.val {comp}}.")
            }
            stats::wilcox.test(
                merged[[paste0(y_name, "_a")]],
                merged[[paste0(y_name, "_b")]],
                paired = TRUE,
                exact = FALSE
            )$p.value
        } else {
            stats::wilcox.test(group_a[[y_name]], group_b[[y_name]], paired = FALSE, exact = FALSE)$p.value
        }

        annotation <- if (is.na(p_value)) {
            "NA"
        } else if (p_value <= 1e-4) {
            "****"
        } else if (p_value <= 1e-3) {
            "***"
        } else if (p_value <= 1e-2) {
            "**"
        } else if (p_value <= 5e-2) {
            "*"
        } else {
            "ns"
        }

        y_position <- if (isTRUE(log_scale)) {
            base_max * (1.08 + 0.12 * (i - 1))
        } else {
            base_max + spread * (0.08 + 0.12 * (i - 1))
        }

        data.frame(
            xmin = match(comp[[1]], x_levels),
            xmax = match(comp[[2]], x_levels),
            annotation = annotation,
            y_position = y_position,
            stringsAsFactors = FALSE
        )
    })

    do.call(rbind, ann)
}

#' Standard jitter position for PaperPlotR point layers
#'
#' @param width Horizontal jitter width.
#' @param height Vertical jitter height.
#' @param seed Random seed for jitter placement.
#'
#' @return A ggplot position object.
#' @export
position_paper_jitter <- function(width = 0.12, height = 0, seed = 1) {
    ggplot2::position_jitter(width = width, height = height, seed = seed)
}

#' Standard raw-point layer for PaperPlotR comparison plots
#'
#' @param mapping Aesthetic mapping.
#' @param data Optional data frame.
#' @param paired Whether points should be connected by sample id.
#' @param id Optional sample id column used when `paired = TRUE`.
#' @param position Position adjustment for points.
#' @param alpha Point alpha.
#' @param size Point size.
#' @param stroke Point stroke width.
#' @param point_shape Point shape.
#' @param point_colour Outline colour for points.
#' @param line_colour Colour for paired connecting lines.
#' @param line_width Line width for paired connecting lines.
#' @param ... Additional arguments passed to `ggplot2::geom_point()`.
#'
#' @return A ggplot layer or list of layers.
#' @export
layer_points_paper <- function(
    mapping = NULL,
    data = NULL,
    paired = FALSE,
    id = NULL,
    position = position_paper_jitter(),
    alpha = 0.8,
    size = 1.9,
    stroke = 0.25,
    point_shape = 21,
    point_colour = "#1F1F1F",
    line_colour = "#8C8C8C",
    line_width = 0.3,
    ...
) {
    point_layer <- ggplot2::geom_point(
        mapping = mapping,
        data = data,
        position = position,
        alpha = alpha,
        size = size,
        stroke = stroke,
        shape = point_shape,
        colour = point_colour,
        ...
    )

    if (!isTRUE(paired)) {
        return(point_layer)
    }

    id_quo <- rlang::enquo(id)
    id_name <- .quo_name(id_quo, "id")
    if (is.null(id_name)) {
        cli::cli_abort("{.arg id} must be supplied when {.arg paired = TRUE}.")
    }
    if (is.null(data) || is.null(mapping)) {
        cli::cli_abort("{.arg data} and {.arg mapping} are required when {.arg paired = TRUE}.")
    }

    x_name <- .quo_name(mapping$x, "mapping$x")
    y_name <- .quo_name(mapping$y, "mapping$y")
    if (is.null(x_name) || is.null(y_name)) {
        cli::cli_abort("Paired point layers require simple {.arg x} and {.arg y} mappings.")
    }

    line_df <- data[order(data[[id_name]], data[[x_name]]), , drop = FALSE]
    line_layer <- ggplot2::geom_line(
        data = line_df,
        mapping = ggplot2::aes(
            x = !!rlang::sym(x_name),
            y = !!rlang::sym(y_name),
            group = !!rlang::sym(id_name)
        ),
        inherit.aes = FALSE,
        linewidth = line_width,
        colour = line_colour,
        alpha = 0.7,
        show.legend = FALSE
    )

    list(line_layer, point_layer)
}

#' Standard summary layers for PaperPlotR comparison plots
#'
#' @param summary_type Summary style, either `"mean_se"` or `"median_iqr"`.
#' @param position Position adjustment for grouped summaries.
#' @param errorbar_width Error bar width.
#' @param point_size Summary point size.
#' @param point_shape Summary point shape.
#' @param line_width Error bar line width.
#' @param colour Outline colour.
#' @param fill Fill colour for summary points.
#'
#' @return A list of ggplot layers.
#' @export
layer_summary_paper <- function(
    summary_type = c("mean_se", "median_iqr"),
    position = ggplot2::position_identity(),
    errorbar_width = 0.14,
    point_size = 2.2,
    point_shape = 23,
    line_width = 0.35,
    colour = "#1F1F1F",
    fill = "white"
) {
    summary_type <- match.arg(summary_type)
    list(
        ggplot2::stat_summary(
            fun.data = .summary_fun_data(summary_type),
            geom = "errorbar",
            width = errorbar_width,
            linewidth = line_width,
            colour = colour,
            position = position,
            show.legend = FALSE
        ),
        ggplot2::stat_summary(
            fun = .summary_fun_point(summary_type),
            geom = "point",
            shape = point_shape,
            size = point_size,
            stroke = line_width,
            colour = colour,
            fill = fill,
            position = position,
            show.legend = FALSE
        )
    )
}

#' Standard significance annotation layer for PaperPlotR comparison plots
#'
#' @param data Data frame used for comparisons.
#' @param x Grouping column.
#' @param y Numeric response column.
#' @param comparisons List of two-element character vectors.
#' @param paired Whether to run paired Wilcoxon tests.
#' @param id Optional sample id column required for paired tests.
#' @param test Statistical test name. Only `"wilcox"` is supported in v1.
#' @param log_scale Whether the plot uses a log-scaled y axis.
#' @param line_width Bracket line width.
#' @param text_size Annotation text size.
#' @param colour Bracket and text colour.
#'
#' @return A ggplot layer or list of layers.
#' @export
layer_signif_paper <- function(
    data,
    x,
    y,
    comparisons,
    paired = FALSE,
    id = NULL,
    test = NULL,
    log_scale = FALSE,
    line_width = 0.35,
    text_size = 3.2,
    colour = "#1F1F1F"
) {
    x_quo <- rlang::enquo(x)
    y_quo <- rlang::enquo(y)
    id_quo <- rlang::enquo(id)
    x_name <- .quo_name(x_quo, "x")
    y_name <- .quo_name(y_quo, "y")
    id_name <- .quo_name(id_quo, "id")

    ann_df <- .build_annotation_df(
        data = data,
        x_name = x_name,
        y_name = y_name,
        comparisons = comparisons,
        paired = paired,
        id_name = id_name,
        test = test,
        log_scale = log_scale
    )

    max_y <- max(data[[y_name]], na.rm = TRUE)
    min_y <- min(data[[y_name]], na.rm = TRUE)
    spread <- max(max_y - min_y, abs(max_y) * 0.1, 0.1)
    tip_length <- if (isTRUE(log_scale)) max_y * 0.03 else spread * 0.03
    label_offset <- if (isTRUE(log_scale)) max_y * 0.04 else spread * 0.04

    seg_df <- do.call(
        rbind,
        lapply(seq_len(nrow(ann_df)), function(i) {
            row <- ann_df[i, , drop = FALSE]
            data.frame(
                x = c(row$xmin, row$xmin, row$xmax),
                xend = c(row$xmax, row$xmin, row$xmax),
                y = c(row$y_position, row$y_position - tip_length, row$y_position - tip_length),
                yend = c(row$y_position, row$y_position, row$y_position),
                stringsAsFactors = FALSE
            )
        })
    )

    text_df <- transform(
        ann_df,
        x = (xmin + xmax) / 2,
        y = y_position + label_offset
    )

    list(
        ggplot2::geom_segment(
            data = seg_df,
            mapping = ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
            inherit.aes = FALSE,
            linewidth = line_width,
            colour = colour
        ),
        ggplot2::geom_text(
            data = text_df,
            mapping = ggplot2::aes(x = x, y = y, label = annotation),
            inherit.aes = FALSE,
            size = text_size,
            colour = colour
        )
    )
}

#' Shared parameter contract for PaperPlotR comparison plot helpers
#'
#' @param data A data frame.
#' @param x Grouping column mapped to the x axis.
#' @param y Numeric response column mapped to the y axis.
#' @param group Optional grouping column used for fill mapping and dodging.
#' @param id Optional sample id column used for paired designs.
#' @param paired Whether to treat the design as paired.
#' @param show_points Whether to draw raw points.
#' @param show_summary Whether to add summary points and intervals.
#' @param summary_type Summary style, either `"mean_se"` or `"median_iqr"`.
#' @param log_scale Whether to apply a log-scaled y axis.
#' @param dictionary Optional semantic color dictionary name.
#' @param palette Optional PaperPlotR palette name.
#' @param facet Optional faceting column.
#' @param comparisons Optional list of two-element character vectors used for
#'   significance annotation.
#' @param show_signif Whether to add significance annotations.
#' @param test Statistical test name. Currently only `"wilcox"` is supported.
#' @param geom_kind Internal geometry selector.
#' @param ... Additional arguments forwarded to the underlying geometry layer.
#'
#' @keywords internal
.comparison_plot_core <- function(
    data,
    x,
    y,
    group = NULL,
    id = NULL,
    paired = FALSE,
    show_points = TRUE,
    show_summary = TRUE,
    summary_type = c("mean_se", "median_iqr"),
    log_scale = FALSE,
    dictionary = NULL,
    palette = NULL,
    facet = NULL,
    comparisons = NULL,
    show_signif = FALSE,
    test = NULL,
    geom_kind = c("box", "violin", "dot"),
    ...
) {
    summary_type <- match.arg(summary_type)
    geom_kind <- match.arg(geom_kind)

    x_quo <- rlang::enquo(x)
    y_quo <- rlang::enquo(y)
    group_quo <- rlang::enquo(group)
    facet_quo <- rlang::enquo(facet)
    id_quo <- rlang::enquo(id)

    inputs <- .resolve_comparison_inputs(
        data = data,
        x = x_quo,
        y = y_quo,
        group = group_quo,
        facet = facet_quo,
        id = id_quo,
        paired = paired,
        dictionary = dictionary,
        palette = palette,
        show_signif = show_signif,
        comparisons = comparisons,
        log_scale = log_scale
    )

    fill_quo <- if (rlang::quo_is_missing(group_quo) || rlang::quo_is_null(group_quo)) x_quo else group_quo
    has_group <- !is.null(inputs$group_name) && inputs$group_name != inputs$x_name

    box_position <- if (has_group) ggplot2::position_dodge(width = 0.72) else ggplot2::position_identity()
    point_position <- if (has_group) {
        ggplot2::position_jitterdodge(jitter.width = 0.08, dodge.width = 0.72, seed = 1)
    } else {
        position_paper_jitter()
    }

    plot <- ggplot2::ggplot(data, ggplot2::aes(x = !!x_quo, y = !!y_quo, fill = !!fill_quo))

    if (identical(geom_kind, "box")) {
        plot <- plot + ggplot2::geom_boxplot(
            width = if (has_group) 0.56 else 0.28,
            outlier.shape = NA,
            linewidth = 0.35,
            colour = "#1F1F1F",
            position = box_position,
            alpha = 0.95,
            ...
        )
    }

    if (identical(geom_kind, "violin")) {
        plot <- plot +
            ggplot2::geom_violin(
                width = if (has_group) 0.78 else 0.88,
                trim = FALSE,
                colour = NA,
                alpha = 0.85,
                position = box_position,
                ...
            ) +
            ggplot2::geom_boxplot(
                width = if (has_group) 0.18 else 0.14,
                outlier.shape = NA,
                linewidth = 0.3,
                colour = "#1F1F1F",
                position = box_position,
                alpha = 0.9,
                show.legend = FALSE
            )
    }

    if (isTRUE(show_points)) {
        plot <- plot + layer_points_paper(
            mapping = ggplot2::aes(x = !!x_quo, y = !!y_quo, fill = !!fill_quo),
            data = data,
            paired = paired,
            id = !!id_quo,
            position = point_position
        )
    }

    if (isTRUE(show_summary)) {
        plot <- plot + layer_summary_paper(summary_type = summary_type, position = box_position)
    }

    if (isTRUE(show_signif)) {
        plot <- plot + layer_signif_paper(
            data = data,
            x = !!x_quo,
            y = !!y_quo,
            comparisons = comparisons,
            paired = paired,
            id = !!id_quo,
            test = test,
            log_scale = log_scale
        )
    }

    plot <- plot +
        .resolve_fill_scale(dictionary = dictionary, palette = palette) +
        ggplot2::labs(x = NULL)

    .apply_common_plot_settings(
        plot = plot,
        log_scale = log_scale,
        show_legend = inputs$show_legend,
        show_signif = show_signif,
        facet = facet_quo
    )
}

#' PaperPlotR box plot with raw points and optional significance
#'
#' @inheritParams .comparison_plot_core
#' @return A ggplot object.
#' @export
plot_box_paper <- function(
    data,
    x,
    y,
    group = NULL,
    id = NULL,
    paired = FALSE,
    show_points = TRUE,
    show_summary = TRUE,
    summary_type = c("mean_se", "median_iqr"),
    log_scale = FALSE,
    dictionary = NULL,
    palette = NULL,
    facet = NULL,
    comparisons = NULL,
    show_signif = FALSE,
    test = NULL,
    ...
) {
    .comparison_plot_core(
        data = data,
        x = {{ x }},
        y = {{ y }},
        group = {{ group }},
        id = {{ id }},
        paired = paired,
        show_points = show_points,
        show_summary = show_summary,
        summary_type = summary_type,
        log_scale = log_scale,
        dictionary = dictionary,
        palette = palette,
        facet = {{ facet }},
        comparisons = comparisons,
        show_signif = show_signif,
        test = test,
        geom_kind = "box",
        ...
    )
}

#' PaperPlotR violin plot with box overlay and optional significance
#'
#' @inheritParams .comparison_plot_core
#' @return A ggplot object.
#' @export
plot_violin_paper <- function(
    data,
    x,
    y,
    group = NULL,
    id = NULL,
    paired = FALSE,
    show_points = TRUE,
    show_summary = TRUE,
    summary_type = c("mean_se", "median_iqr"),
    log_scale = FALSE,
    dictionary = NULL,
    palette = NULL,
    facet = NULL,
    comparisons = NULL,
    show_signif = FALSE,
    test = NULL,
    ...
) {
    .comparison_plot_core(
        data = data,
        x = {{ x }},
        y = {{ y }},
        group = {{ group }},
        id = {{ id }},
        paired = paired,
        show_points = show_points,
        show_summary = show_summary,
        summary_type = summary_type,
        log_scale = log_scale,
        dictionary = dictionary,
        palette = palette,
        facet = {{ facet }},
        comparisons = comparisons,
        show_signif = show_signif,
        test = test,
        geom_kind = "violin",
        ...
    )
}

#' PaperPlotR dot plot with summary overlay and optional significance
#'
#' @inheritParams .comparison_plot_core
#' @return A ggplot object.
#' @export
plot_dot_paper <- function(
    data,
    x,
    y,
    group = NULL,
    id = NULL,
    paired = FALSE,
    show_points = TRUE,
    show_summary = TRUE,
    summary_type = c("mean_se", "median_iqr"),
    log_scale = FALSE,
    dictionary = NULL,
    palette = NULL,
    facet = NULL,
    comparisons = NULL,
    show_signif = FALSE,
    test = NULL,
    ...
) {
    .comparison_plot_core(
        data = data,
        x = {{ x }},
        y = {{ y }},
        group = {{ group }},
        id = {{ id }},
        paired = paired,
        show_points = show_points,
        show_summary = show_summary,
        summary_type = summary_type,
        log_scale = log_scale,
        dictionary = dictionary,
        palette = palette,
        facet = {{ facet }},
        comparisons = comparisons,
        show_signif = show_signif,
        test = test,
        geom_kind = "dot",
        ...
    )
}
