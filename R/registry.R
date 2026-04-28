.paperplotr_registry <- new.env(parent = emptyenv())

.paperplotr_registry$fig_specs <- data.frame(
    spec = character(),
    panel_w_cm = numeric(),
    panel_h_cm = numeric(),
    nonpanel_w_cm = numeric(),
    nonpanel_h_cm = numeric(),
    gap_cm = numeric(),
    base_font_pt = numeric(),
    min_linewidth = numeric(),
    stringsAsFactors = FALSE
)

.paperplotr_registry$panel_aliases <- character()
.paperplotr_registry$panel_hints <- character()
.paperplotr_registry$journal_presets <- list()
.paperplotr_registry$output_presets <- list()
.paperplotr_registry$discrete_palettes <- list()
.paperplotr_registry$gradient_palettes <- list()
.paperplotr_registry$group_dictionaries <- list()

.validate_named_character_values <- function(values, arg, require_names = FALSE) {
    if (!is.character(values) || length(values) == 0 || anyNA(values) || any(!nzchar(values))) {
        cli::cli_abort("{.arg {arg}} must be a non-empty character vector.")
    }

    if (isTRUE(require_names)) {
        if (is.null(names(values)) || anyNA(names(values)) || any(!nzchar(names(values)))) {
            cli::cli_abort("{.arg {arg}} must be a named character vector.")
        }
    }

    values
}

.validate_named_list_fields <- function(x, required, arg) {
    if (!is.list(x)) {
        cli::cli_abort("{.arg {arg}} must be a list.")
    }

    missing_fields <- setdiff(required, names(x))
    if (length(missing_fields) > 0) {
        cli::cli_abort(
            c(
                "{.arg {arg}} is missing required fields.",
                "x" = "Missing: {.val {missing_fields}}"
            )
        )
    }

    x
}

.merge_named_lists <- function(defaults, registered) {
    utils::modifyList(defaults, registered)
}

.all_panel_aliases <- function() {
    aliases <- as.list(.lab_panel_aliases)
    aliases <- utils::modifyList(aliases, as.list(.paperplotr_registry$panel_aliases))
    unlist(aliases, use.names = TRUE)
}

.all_panel_hints <- function() {
    hints <- as.list(.lab_panel_hints)
    hints <- utils::modifyList(hints, as.list(.paperplotr_registry$panel_hints))
    unlist(hints, use.names = TRUE)
}

.all_fig_specs <- function() {
    if (nrow(.paperplotr_registry$fig_specs) == 0) {
        return(fig_specs)
    }

    rbind(fig_specs, .paperplotr_registry$fig_specs)
}

.all_journal_presets <- function() {
    .merge_named_lists(.lab_journal_presets, .paperplotr_registry$journal_presets)
}

.all_output_presets <- function() {
    .merge_named_lists(.lab_output_presets, .paperplotr_registry$output_presets)
}

.all_discrete_palettes <- function() {
    .merge_named_lists(.lab_discrete_palettes, .paperplotr_registry$discrete_palettes)
}

.all_gradient_palettes <- function() {
    .merge_named_lists(.lab_gradient_palettes, .paperplotr_registry$gradient_palettes)
}

.all_group_dictionaries <- function(include_examples = FALSE) {
    dictionaries <- .merge_named_lists(.lab_group_dictionaries, .paperplotr_registry$group_dictionaries)
    if (isTRUE(include_examples)) {
        dictionaries <- .merge_named_lists(dictionaries, .lab_example_group_dictionaries)
    }

    dictionaries
}

#' Register a custom figure specification
#'
#' Adds a figure specification at runtime so it can be used by
#' `available_fig_specs()`, `panel_size()`, and `get_fig_size_cm()`.
#'
#' @param name Specification name.
#' @param panel_w_cm Panel width in centimeters.
#' @param panel_h_cm Panel height in centimeters.
#' @param nonpanel_w_cm Reserved horizontal non-panel space in centimeters.
#' @param nonpanel_h_cm Reserved vertical non-panel space in centimeters.
#' @param gap_cm Gap between panels in centimeters.
#' @param base_font_pt Recommended base font size in points.
#' @param min_linewidth Recommended minimum line width.
#' @param alias Optional compatibility aliases that should resolve to `name`.
#' @param layout_hint Optional hint text returned by `panel_size()`.
#' @param overwrite Whether to overwrite an existing registered specification.
#'
#' @return The registered figure specification row, invisibly.
#' @export
register_fig_spec <- function(
    name,
    panel_w_cm,
    panel_h_cm,
    nonpanel_w_cm = 0.9,
    nonpanel_h_cm = 0.9,
    gap_cm = 0.15,
    base_font_pt = 7,
    min_linewidth = 0.35,
    alias = NULL,
    layout_hint = NULL,
    overwrite = FALSE
) {
    name <- .validate_scalar_string(name, "name")
    overwrite <- .validate_flag(overwrite, "overwrite")
    panel_w_cm <- .validate_positive_number(panel_w_cm, "panel_w_cm")
    panel_h_cm <- .validate_positive_number(panel_h_cm, "panel_h_cm")
    nonpanel_w_cm <- .validate_positive_number(nonpanel_w_cm, "nonpanel_w_cm")
    nonpanel_h_cm <- .validate_positive_number(nonpanel_h_cm, "nonpanel_h_cm")
    gap_cm <- .validate_positive_number(gap_cm, "gap_cm")
    base_font_pt <- .validate_positive_number(base_font_pt, "base_font_pt")
    min_linewidth <- .validate_positive_number(min_linewidth, "min_linewidth")

    if (!is.null(alias)) {
        alias <- .validate_named_character_values(unname(alias), "alias")
        if (any(alias %in% names(.all_panel_aliases())) && !isTRUE(overwrite)) {
            cli::cli_abort("One or more {.arg alias} values already exist. Use {.arg overwrite = TRUE} to replace them.")
        }
    }

    existing_specs <- .all_fig_specs()$spec
    if (name %in% existing_specs && !(name %in% .paperplotr_registry$fig_specs$spec && isTRUE(overwrite))) {
        cli::cli_abort("Figure spec {.val {name}} already exists. Use {.arg overwrite = TRUE} to replace a registered spec.")
    }

    row <- data.frame(
        spec = name,
        panel_w_cm = panel_w_cm,
        panel_h_cm = panel_h_cm,
        nonpanel_w_cm = nonpanel_w_cm,
        nonpanel_h_cm = nonpanel_h_cm,
        gap_cm = gap_cm,
        base_font_pt = base_font_pt,
        min_linewidth = min_linewidth,
        stringsAsFactors = FALSE
    )

    registered <- .paperplotr_registry$fig_specs
    if (name %in% registered$spec) {
        registered <- registered[registered$spec != name, , drop = FALSE]
    }
    .paperplotr_registry$fig_specs <- rbind(registered, row)

    if (!is.null(alias)) {
        new_aliases <- stats::setNames(rep(name, length(alias)), alias)
        .paperplotr_registry$panel_aliases[names(new_aliases)] <- unname(new_aliases)
    }

    if (!is.null(layout_hint)) {
        .paperplotr_registry$panel_hints[name] <- .validate_scalar_string(layout_hint, "layout_hint")
    }

    invisible(row)
}

#' Register a custom journal preset
#'
#' Adds a journal preset at runtime so it can be used by `journal_preset()`.
#'
#' @param name Preset name.
#' @param figure_width_cm Figure width in centimeters.
#' @param base_size_pt Default base text size in points.
#' @param min_text_pt Minimum allowed text size in points.
#' @param dpi Default export dpi.
#' @param base_family Default font family.
#' @param line_width Default line width.
#' @param overwrite Whether to overwrite an existing registered preset.
#'
#' @return The registered journal preset, invisibly.
#' @export
register_journal_preset <- function(
    name,
    figure_width_cm,
    base_size_pt = 8,
    min_text_pt = 6,
    dpi = 600,
    base_family = "Arial",
    line_width = 0.35,
    overwrite = FALSE
) {
    name <- tolower(.validate_scalar_string(name, "name"))
    overwrite <- .validate_flag(overwrite, "overwrite")
    figure_width_cm <- .validate_positive_number(figure_width_cm, "figure_width_cm")
    base_size_pt <- .validate_positive_number(base_size_pt, "base_size_pt")
    min_text_pt <- .validate_positive_number(min_text_pt, "min_text_pt")
    dpi <- .validate_positive_number(dpi, "dpi")
    line_width <- .validate_positive_number(line_width, "line_width")
    base_family <- .validate_scalar_string(base_family, "base_family")

    if (name %in% names(.all_journal_presets()) && !(name %in% names(.paperplotr_registry$journal_presets) && isTRUE(overwrite))) {
        cli::cli_abort("Journal preset {.val {name}} already exists. Use {.arg overwrite = TRUE} to replace a registered preset.")
    }

    preset <- list(
        journal = name,
        figure_width_cm = figure_width_cm,
        base_size_pt = base_size_pt,
        min_text_pt = min_text_pt,
        dpi = dpi,
        base_family = base_family,
        line_width = line_width
    )

    .paperplotr_registry$journal_presets[[name]] <- preset
    invisible(preset)
}

#' Register a custom output preset
#'
#' Adds an output preset at runtime so it can be used by `save_lab_plot()`.
#'
#' @param name Preset name.
#' @param journal Journal preset name used for validation defaults.
#' @param width_cm Figure width in centimeters.
#' @param height_cm Figure height in centimeters.
#' @param dpi Default export dpi.
#' @param overwrite Whether to overwrite an existing registered preset.
#'
#' @return The registered output preset, invisibly.
#' @export
register_output_preset <- function(name, journal, width_cm, height_cm, dpi = 600, overwrite = FALSE) {
    name <- tolower(.validate_scalar_string(name, "name"))
    journal <- tolower(.validate_scalar_string(journal, "journal"))
    overwrite <- .validate_flag(overwrite, "overwrite")
    width_cm <- .validate_positive_number(width_cm, "width_cm")
    height_cm <- .validate_positive_number(height_cm, "height_cm")
    dpi <- .validate_positive_number(dpi, "dpi")

    if (!journal %in% names(.all_journal_presets())) {
        cli::cli_abort(
            c(
                "Unknown journal preset for {.arg journal}.",
                "i" = "Available presets: {.val {names(.all_journal_presets())}}"
            )
        )
    }

    if (name %in% names(.all_output_presets()) && !(name %in% names(.paperplotr_registry$output_presets) && isTRUE(overwrite))) {
        cli::cli_abort("Output preset {.val {name}} already exists. Use {.arg overwrite = TRUE} to replace a registered preset.")
    }

    preset <- list(journal = journal, width_cm = width_cm, height_cm = height_cm, dpi = dpi)
    .paperplotr_registry$output_presets[[name]] <- preset
    invisible(preset)
}

#' Register a custom palette
#'
#' Adds a discrete or gradient palette at runtime so it can be used by the
#' palette and scale helpers.
#'
#' @param name Palette name.
#' @param values Character vector of hex colors.
#' @param type Palette type: `"discrete"` or `"gradient"`.
#' @param overwrite Whether to overwrite an existing registered palette.
#'
#' @return The registered palette values, invisibly.
#' @export
register_palette <- function(name, values, type = c("discrete", "gradient"), overwrite = FALSE) {
    name <- tolower(.validate_scalar_string(name, "name"))
    values <- .validate_named_character_values(values, "values")
    type <- match.arg(type)
    overwrite <- .validate_flag(overwrite, "overwrite")

    palette_pool <- if (identical(type, "gradient")) .all_gradient_palettes() else .all_discrete_palettes()
    registered_pool_name <- if (identical(type, "gradient")) "gradient_palettes" else "discrete_palettes"

    if (name %in% names(palette_pool) && !(name %in% names(.paperplotr_registry[[registered_pool_name]]) && isTRUE(overwrite))) {
        cli::cli_abort("Palette {.val {name}} already exists. Use {.arg overwrite = TRUE} to replace a registered palette.")
    }

    .paperplotr_registry[[registered_pool_name]][[name]] <- unname(values)
    invisible(unname(values))
}

#' Register a custom semantic color dictionary
#'
#' Adds a named color dictionary at runtime so it can be used by
#' `group_colors()` and the groupmap scales.
#'
#' @param name Dictionary name.
#' @param values Named character vector of colors.
#' @param overwrite Whether to overwrite an existing registered dictionary.
#'
#' @return The registered dictionary, invisibly.
#' @export
register_group_dictionary <- function(name, values, overwrite = FALSE) {
    name <- tolower(.validate_scalar_string(name, "name"))
    values <- .validate_named_character_values(values, "values", require_names = TRUE)
    overwrite <- .validate_flag(overwrite, "overwrite")

    if (name %in% names(.all_group_dictionaries(include_examples = TRUE)) &&
        !(name %in% names(.paperplotr_registry$group_dictionaries) && isTRUE(overwrite))) {
        cli::cli_abort("Group dictionary {.val {name}} already exists. Use {.arg overwrite = TRUE} to replace a registered dictionary.")
    }

    .paperplotr_registry$group_dictionaries[[name]] <- values
    invisible(values)
}
