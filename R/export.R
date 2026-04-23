.default_extension_device <- function(filename) {
    ext <- tolower(tools::file_ext(filename))
    switch(
        ext,
        png = "png",
        jpg = "jpeg",
        jpeg = "jpeg",
        pdf = "pdf",
        tiff = "tiff",
        tif = "tiff",
        svg = "svg",
        cli::cli_abort("Unsupported output extension: {.val {ext}}")
    )
}

.normalize_ggsave_device <- function(filename, device = NULL) {
    if (is.null(device)) {
        return(.default_extension_device(filename))
    }

    if (is.function(device)) {
        return(device)
    }

    .validate_scalar_string(device, "device")
    tolower(device)
}

.plot_text_sizes <- function(plot) {
    if (!inherits(plot, "ggplot")) {
        return(numeric(0))
    }

    theme_obj <- rlang::`%||%`(plot$theme, ggplot2::theme_get())
    elements <- c("text", "axis.text", "axis.title", "legend.text", "legend.title", "plot.title", "strip.text")
    sizes <- numeric(0)

    for (element_name in elements) {
        element <- theme_obj[[element_name]]

        if (!is.null(element) && !is.null(element$size)) {
            sizes[element_name] <- element$size
        }
    }

    sizes
}

.validate_min_text_size <- function(plot, preset) {
    sizes <- .plot_text_sizes(plot)
    if (length(sizes) == 0) {
        return(invisible(TRUE))
    }

    min_size <- min(unname(sizes))
    if (min_size < preset$min_text_pt) {
        cli::cli_abort(
            c(
                "Plot text is smaller than the preset minimum text size.",
                "x" = "Detected minimum text size: {min_size} pt",
                "i" = "Preset minimum text size: {preset$min_text_pt} pt"
            )
        )
    }

    invisible(TRUE)
}

.validate_plot_object <- function(plot) {
    if (!inherits(plot, "ggplot") && !inherits(plot, "patchwork") && !.is_grob_like(plot)) {
        cli::cli_abort("{.arg plot} must be a ggplot, patchwork, or grid grob object.")
    }

    invisible(TRUE)
}

.prepare_output_path <- function(filename, create_dirs = TRUE) {
    filename <- .validate_scalar_string(filename, "filename")
    create_dirs <- .validate_flag(create_dirs, "create_dirs")

    if (isTRUE(create_dirs)) {
        dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
    }

    filename
}

#' Save a plot using canonical lab figure specifications
#'
#' @param plot A ggplot object.
#' @param filename Output file path.
#' @param spec Canonical figure specification such as `"2x2"` or `"4.9x4.9"`.
#' @param ncol Number of panel columns represented by the output figure.
#' @param nrow Number of panel rows represented by the output figure.
#' @param journal Journal preset used for dpi and minimum text validation.
#' @param dpi Optional dpi override.
#' @param bg Background color passed to `ggplot2::ggsave()`.
#' @param device Optional graphics device. Defaults from file extension.
#' @param validate_fonts Whether to enforce journal minimum text size.
#' @param create_dirs Whether to create parent directories automatically.
#' @param ... Additional arguments passed to `ggplot2::ggsave()`.
#'
#' @return The output filename, invisibly.
#' @export
save_lab <- function(
    plot,
    filename,
    spec,
    ncol = 1,
    nrow = 1,
    journal = "cell",
    dpi = NULL,
    bg = "white",
    device = NULL,
    validate_fonts = TRUE,
    create_dirs = TRUE,
    ...
) {
    .validate_flag(validate_fonts, "validate_fonts")
    .validate_plot_object(plot)
    journal <- .validate_scalar_string(journal, "journal")

    journal_values <- journal_preset(journal)
    figure_size <- get_fig_size_cm(spec = spec, ncol = ncol, nrow = nrow)

    if (isTRUE(validate_fonts)) {
        .validate_min_text_size(plot = plot, preset = journal_values)
    }

    filename <- .prepare_output_path(filename = filename, create_dirs = create_dirs)
    ggsave_device <- .normalize_ggsave_device(filename = filename, device = device)

    ggplot2::ggsave(
        filename = filename,
        plot = plot,
        width = figure_size$width_cm,
        height = figure_size$height_cm,
        units = "cm",
        dpi = rlang::`%||%`(dpi, journal_values$dpi),
        device = ggsave_device,
        bg = bg,
        ...
    )

    invisible(filename)
}

#' Save a plot with lab figure presets
#'
#' @param plot A ggplot object.
#' @param filename Output file path.
#' @param preset Named output preset such as `"cell_half"`.
#' @param width Optional override width in cm.
#' @param height Optional override height in cm.
#' @param dpi Optional override resolution.
#' @param units Units passed to `ggplot2::ggsave()`.
#' @param device Optional graphics device. Defaults from file extension.
#' @param validate_fonts Whether to enforce journal minimum text size.
#' @param create_dirs Whether to create parent directories automatically.
#' @param ... Additional arguments passed to `ggplot2::ggsave()`.
#'
#' @return The output filename, invisibly.
#' @export
save_lab_plot <- function(
    plot,
    filename,
    preset = "cell_half",
    width = NULL,
    height = NULL,
    dpi = NULL,
    units = "cm",
    device = NULL,
    validate_fonts = TRUE,
    create_dirs = TRUE,
    ...
) {
    .validate_flag(validate_fonts, "validate_fonts")
    .validate_plot_object(plot)
    preset <- .validate_scalar_string(preset, "preset")
    units <- .validate_output_units(units)
    width <- .validate_positive_number(width, "width", allow_null = TRUE)
    height <- .validate_positive_number(height, "height", allow_null = TRUE)

    preset_values <- .resolve_output_preset(preset)
    journal_values <- journal_preset(preset_values$journal)

    if (isTRUE(validate_fonts)) {
        .validate_min_text_size(plot = plot, preset = journal_values)
    }

    filename <- .prepare_output_path(filename = filename, create_dirs = create_dirs)

    ggsave_device <- .normalize_ggsave_device(filename = filename, device = device)
    ggplot2::ggsave(
        filename = filename,
        plot = plot,
        width = rlang::`%||%`(width, preset_values$width_cm),
        height = rlang::`%||%`(height, preset_values$height_cm),
        units = units,
        dpi = rlang::`%||%`(dpi, preset_values$dpi),
        device = ggsave_device,
        bg = "white",
        ...
    )

    invisible(filename)
}
