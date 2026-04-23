#' Canonical PaperPlotR figure specifications
#'
#' A data frame of panel geometry presets used by `get_fig_size_cm()` and
#' `panel_size()`. `spec` identifies the canonical panel size, while
#' `nonpanel_w_cm` and `nonpanel_h_cm` reserve space for axes and titles.
#'
#' @format A data frame with 4 rows and 8 variables:
#' \describe{
#'   \item{spec}{Canonical panel preset id.}
#'   \item{panel_w_cm}{Panel width in centimeters.}
#'   \item{panel_h_cm}{Panel height in centimeters.}
#'   \item{nonpanel_w_cm}{Reserved horizontal space in centimeters.}
#'   \item{nonpanel_h_cm}{Reserved vertical space in centimeters.}
#'   \item{gap_cm}{Default gap between adjacent panels.}
#'   \item{base_font_pt}{Recommended base text size in points.}
#'   \item{min_linewidth}{Recommended minimum line width.}
#' }
#' @export
fig_specs <- data.frame(
    spec = c("2x2", "2.58x2", "4.9x2", "4.9x4.9"),
    panel_w_cm = c(2.0, 2.58, 4.9, 4.9),
    panel_h_cm = c(2.0, 2.0, 2.0, 4.9),
    nonpanel_w_cm = c(0.9, 0.9, 0.9, 0.9),
    nonpanel_h_cm = c(0.9, 0.9, 0.9, 0.9),
    gap_cm = c(0.15, 0.15, 0.15, 0.15),
    base_font_pt = c(7, 7, 7, 7),
    min_linewidth = c(0.35, 0.35, 0.35, 0.35),
    stringsAsFactors = FALSE
)

.lab_panel_aliases <- c("4.9" = "4.9x4.9")

.lab_panel_hints <- c(
    "2x2" = "6 panels per 17.4 cm row with axis/title space reserved.",
    "2.58x2" = "5 panels per 17.4 cm row with axis/title space reserved.",
    "4.9x2" = "3 panels per 17.4 cm row with compact height.",
    "4.9x4.9" = "3 square panels per 17.4 cm row."
)

.lab_journal_presets <- list(
    cell = list(
        journal = "cell",
        figure_width_cm = 17.4,
        base_size_pt = 8,
        min_text_pt = 6,
        dpi = 600,
        base_family = "Arial",
        line_width = 0.4
    ),
    nature = list(
        journal = "nature",
        figure_width_cm = 18.0,
        base_size_pt = 8,
        min_text_pt = 6,
        dpi = 600,
        base_family = "Arial",
        line_width = 0.35
    ),
    ncomms = list(
        journal = "ncomms",
        figure_width_cm = 18.0,
        base_size_pt = 8,
        min_text_pt = 6,
        dpi = 600,
        base_family = "Arial",
        line_width = 0.35
    )
)

.lab_output_presets <- list(
    cell = list(journal = "cell", width_cm = 17.4, height_cm = 12.0, dpi = 600),
    cell_half = list(journal = "cell", width_cm = 8.7, height_cm = 6.0, dpi = 600),
    nature = list(journal = "nature", width_cm = 18.0, height_cm = 12.0, dpi = 600),
    nature_half = list(journal = "nature", width_cm = 9.0, height_cm = 6.0, dpi = 600),
    ncomms = list(journal = "ncomms", width_cm = 18.0, height_cm = 12.0, dpi = 600),
    ncomms_half = list(journal = "ncomms", width_cm = 9.0, height_cm = 6.0, dpi = 600)
)

.resolve_spec_name <- function(name) {
    .validate_scalar_string(name, "name")
    alias <- unname(.all_panel_aliases()[name])
    if (length(alias) == 0 || is.na(alias)) {
        return(name)
    }

    alias
}

.resolve_fig_spec <- function(spec) {
    resolved_spec <- .resolve_spec_name(spec)
    all_specs <- .all_fig_specs()
    idx <- match(resolved_spec, all_specs$spec)

    if (is.na(idx)) {
        cli::cli_abort(
            c(
                "Unknown spec.",
                "x" = "Unknown spec: {.val {spec}}",
                "i" = "Available specs: {.val {available_fig_specs()}}"
            )
        )
    }

    all_specs[idx, , drop = FALSE]
}

#' List available figure specifications
#'
#' Returns canonical figure spec names plus supported compatibility aliases.
#'
#' @return A character vector of supported figure specification names.
#' @export
available_fig_specs <- function() {
    unique(c(.all_fig_specs()$spec, names(.all_panel_aliases())))
}

.validate_panel_count <- function(x, arg) {
    if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 1 || x != as.integer(x)) {
        cli::cli_abort("{.arg {arg}} must be a positive integer.")
    }

    as.integer(x)
}

#' Compute figure width and height from a panel specification
#'
#' @param spec Canonical panel specification name.
#' @param ncol Number of panel columns.
#' @param nrow Number of panel rows.
#'
#' @return A named list with width and height in cm.
#' @export
get_fig_size_cm <- function(spec, ncol = 1, nrow = 1) {
    ncol <- .validate_panel_count(ncol, "ncol")
    nrow <- .validate_panel_count(nrow, "nrow")
    row <- .resolve_fig_spec(spec)

    list(
        spec = row$spec[[1]],
        width_cm = row$nonpanel_w_cm[[1]] + ncol * row$panel_w_cm[[1]] + (ncol - 1) * row$gap_cm[[1]],
        height_cm = row$nonpanel_h_cm[[1]] + nrow * row$panel_h_cm[[1]] + (nrow - 1) * row$gap_cm[[1]]
    )
}

#' Get a named panel size preset
#'
#' @param name Preset name.
#'
#' @return A named list describing the preset dimensions in cm.
#' @export
panel_size <- function(name) {
    .validate_scalar_string(name, "name")
    resolved_name <- .resolve_spec_name(name)
    if (!resolved_name %in% .all_fig_specs()$spec) {
        cli::cli_abort(
            c(
                "Unknown panel size preset.",
                "x" = "Unknown panel size: {.val {name}}",
                "i" = "Available presets: {.val {available_fig_specs()}}"
            )
        )
    }

    row <- .resolve_fig_spec(name)
    resolved_name <- row$spec[[1]]

    list(
        name = name,
        spec = resolved_name,
        width_cm = row$panel_w_cm[[1]],
        height_cm = row$panel_h_cm[[1]],
        reserved_cm = max(row$nonpanel_w_cm[[1]], row$nonpanel_h_cm[[1]]),
        layout_hint = .all_panel_hints()[[resolved_name]]
    )
}

#' List available journal presets
#'
#' @return A character vector of supported journal preset names.
#' @export
available_journal_presets <- function() {
    names(.all_journal_presets())
}

#' Get a named journal preset
#'
#' @param name Journal preset name.
#'
#' @return A named list of journal-specific defaults.
#' @export
journal_preset <- function(name) {
    .validate_scalar_string(name, "name")
    preset <- .all_journal_presets()[[tolower(name)]]
    if (is.null(preset)) {
        cli::cli_abort(
            c(
                "Unknown journal preset.",
                "x" = "Unknown journal preset: {.val {name}}",
                "i" = "Available presets: {.val {available_journal_presets()}}"
            )
        )
    }

    preset
}

#' List available output presets
#'
#' @return A character vector of supported save preset names.
#' @export
available_output_presets <- function() {
    names(.all_output_presets())
}

.resolve_output_preset <- function(name) {
    .validate_scalar_string(name, "name")
    preset <- .all_output_presets()[[tolower(name)]]
    if (is.null(preset)) {
        cli::cli_abort(
            c(
                "Unknown output preset.",
                "x" = "Unknown save preset: {.val {name}}",
                "i" = "Available presets: {.val {available_output_presets()}}"
            )
        )
    }

    preset
}

.validate_complexity_level <- function(complexity) {
    rlang::arg_match0(
        arg = .validate_scalar_string(complexity, "complexity"),
        values = c("auto", "simple", "moderate", "complex")
    )
}

.validate_plot_type <- function(plot_type) {
    rlang::arg_match0(
        arg = .validate_scalar_string(plot_type, "plot_type"),
        values = c(
            "general",
            "bar",
            "stacked_bar",
            "line",
            "histogram",
            "profile",
            "scatter",
            "box",
            "violin",
            "dot",
            "heatmap",
            "small_multiples"
        )
    )
}

.recommend_layout_dims <- function(n_panels) {
    if (n_panels <= 0L) {
        cli::cli_abort("{.arg n_panels} must be a positive integer.")
    }

    if (n_panels == 1L) {
        return(list(ncol = 1L, nrow = 1L))
    }

    if (n_panels == 2L) {
        return(list(ncol = 2L, nrow = 1L))
    }

    if (n_panels == 3L) {
        return(list(ncol = 3L, nrow = 1L))
    }

    if (n_panels == 4L) {
        return(list(ncol = 2L, nrow = 2L))
    }

    if (n_panels <= 6L) {
        return(list(ncol = 3L, nrow = 2L))
    }

    if (n_panels <= 8L) {
        return(list(ncol = 4L, nrow = 2L))
    }

    if (n_panels == 9L) {
        return(list(ncol = 3L, nrow = 3L))
    }

    if (n_panels <= 12L) {
        return(list(ncol = 4L, nrow = 3L))
    }

    ncol <- ceiling(sqrt(n_panels))
    nrow <- ceiling(n_panels / ncol)
    list(ncol = as.integer(ncol), nrow = as.integer(nrow))
}

.resolve_recommendation_complexity <- function(
    plot_type,
    complexity,
    long_labels,
    rotated_x_labels,
    significance,
    heatmap,
    complex_legend,
    dense_points
) {
    if (!identical(complexity, "auto")) {
        return(complexity)
    }

    score <- 0L
    score <- score + if (isTRUE(heatmap)) 2L else 0L
    score <- score + if (isTRUE(long_labels)) 1L else 0L
    score <- score + if (isTRUE(rotated_x_labels)) 1L else 0L
    score <- score + if (isTRUE(significance)) 1L else 0L
    score <- score + if (isTRUE(complex_legend)) 1L else 0L
    score <- score + if (isTRUE(dense_points)) 1L else 0L
    score <- score + if (plot_type %in% c("box", "violin", "dot", "scatter", "stacked_bar")) 1L else 0L
    score <- score + if (plot_type %in% c("heatmap", "small_multiples")) 1L else 0L

    if (score <= 1L) {
        return("simple")
    }

    if (score <= 3L) {
        return("moderate")
    }

    "complex"
}

#' Recommend a PaperPlotR panel spec and layout
#'
#' Encodes the package's default panel-size heuristics for multi-panel figure
#' planning. The recommendation starts from panel count, then upgrades compact
#' presets when labels, legends, heatmaps, significance annotations, or dense
#' point overlays make a panel harder to read.
#'
#' @param n_panels Number of panels to place in the composed figure.
#' @param plot_type Broad plot family such as `"general"`, `"heatmap"`,
#'   `"stacked_bar"`, or `"small_multiples"`.
#' @param complexity One of `"auto"`, `"simple"`, `"moderate"`, or `"complex"`.
#'   `"auto"` scores common readability risks from the logical flags below.
#' @param supplementary Whether the figure is primarily a supplementary or
#'   overview figure rather than a main-text figure.
#' @param long_labels Whether panels contain long axis/category labels.
#' @param rotated_x_labels Whether x-axis labels need rotation.
#' @param significance Whether significance brackets or p-value annotations are
#'   present.
#' @param heatmap Whether at least one panel is a heatmap.
#' @param complex_legend Whether the figure uses a large or multi-category
#'   legend.
#' @param dense_points Whether panels overlay many points on summaries.
#'
#' @return A named list with the recommended `spec`, `ncol`, `nrow`,
#'   `figure_width_cm`, `figure_height_cm`, inferred `complexity`,
#'   `split_figure`, and human-readable `rationale`.
#' @export
recommend_panel_spec <- function(
    n_panels,
    plot_type = "general",
    complexity = "auto",
    supplementary = FALSE,
    long_labels = FALSE,
    rotated_x_labels = FALSE,
    significance = FALSE,
    heatmap = FALSE,
    complex_legend = FALSE,
    dense_points = FALSE
) {
    n_panels <- .validate_panel_count(n_panels, "n_panels")
    plot_type <- .validate_plot_type(plot_type)
    complexity <- .validate_complexity_level(complexity)
    supplementary <- .validate_flag(supplementary, "supplementary")
    long_labels <- .validate_flag(long_labels, "long_labels")
    rotated_x_labels <- .validate_flag(rotated_x_labels, "rotated_x_labels")
    significance <- .validate_flag(significance, "significance")
    heatmap <- .validate_flag(heatmap, "heatmap")
    complex_legend <- .validate_flag(complex_legend, "complex_legend")
    dense_points <- .validate_flag(dense_points, "dense_points")

    if (identical(plot_type, "heatmap")) {
        heatmap <- TRUE
    }

    resolved_complexity <- .resolve_recommendation_complexity(
        plot_type = plot_type,
        complexity = complexity,
        long_labels = long_labels,
        rotated_x_labels = rotated_x_labels,
        significance = significance,
        heatmap = heatmap,
        complex_legend = complex_legend,
        dense_points = dense_points
    )

    layout <- .recommend_layout_dims(n_panels)

    spec <- if (n_panels <= 6L) {
        "4.9x4.9"
    } else if (n_panels <= 9L) {
        "2.58x2"
    } else {
        "2x2"
    }

    if (isTRUE(supplementary) &&
        n_panels >= 4L &&
        identical(spec, "4.9x4.9") &&
        identical(resolved_complexity, "simple") &&
        !isTRUE(long_labels) &&
        !isTRUE(rotated_x_labels) &&
        !isTRUE(significance) &&
        !isTRUE(heatmap) &&
        !isTRUE(complex_legend) &&
        !isTRUE(dense_points)) {
        spec <- "2.58x2"
    }

    simple_strip_plot <- plot_type %in% c("bar", "line", "histogram", "profile") &&
        identical(resolved_complexity, "simple") &&
        n_panels <= 3L &&
        !isTRUE(long_labels) &&
        !isTRUE(rotated_x_labels) &&
        !isTRUE(significance) &&
        !isTRUE(heatmap) &&
        !isTRUE(complex_legend) &&
        !isTRUE(dense_points)

    if (isTRUE(simple_strip_plot)) {
        spec <- "4.9x2"
    }

    if (identical(resolved_complexity, "moderate") && identical(spec, "2x2")) {
        spec <- "2.58x2"
    }

    if (identical(resolved_complexity, "complex") ||
        isTRUE(heatmap) ||
        isTRUE(rotated_x_labels) ||
        isTRUE(long_labels) ||
        isTRUE(significance) ||
        isTRUE(complex_legend)) {
        spec <- "4.9x4.9"
    }

    split_figure <- (n_panels >= 7L && identical(spec, "4.9x4.9")) ||
        (n_panels >= 10L && !identical(resolved_complexity, "simple"))

    size <- get_fig_size_cm(spec = spec, ncol = layout$ncol, nrow = layout$nrow)

    rationale_parts <- c(
        if (n_panels <= 6L) {
            "Default main-figure rule keeps 1-6 panels at 4.9x4.9 for readable paper panels."
        } else if (n_panels <= 9L) {
            "Panel count enters the small-multiples range, so the baseline recommendation starts from 2.58x2."
        } else {
            "High-density panel grids default to the compact 2x2 preset."
        },
        if (isTRUE(simple_strip_plot)) {
            "Simple strip-like plots can use the compact 4.9x2 format."
        },
        if (isTRUE(supplementary) && identical(spec, "2.58x2")) {
            "Simple supplementary overview figures can downshift to 2.58x2."
        },
        if (!identical(resolved_complexity, "simple") && identical(spec, "4.9x4.9")) {
            "Readability risks promote the layout to 4.9x4.9."
        },
        if (isTRUE(split_figure)) {
            "The panel count and complexity suggest splitting the figure instead of forcing every panel into one page."
        }
    )

    list(
        n_panels = n_panels,
        plot_type = plot_type,
        complexity = resolved_complexity,
        spec = spec,
        ncol = layout$ncol,
        nrow = layout$nrow,
        figure_width_cm = size$width_cm,
        figure_height_cm = size$height_cm,
        split_figure = split_figure,
        rationale = paste(rationale_parts[nzchar(rationale_parts)], collapse = " ")
    )
}
