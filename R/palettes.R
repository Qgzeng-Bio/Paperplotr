.lab_discrete_palettes <- list(
    main = c(
        "#1F77B4", "#D55E00", "#009E73", "#CC79A7",
        "#E6AB02", "#56B4E9", "#7F3C8D", "#11A579",
        "#3969AC", "#F2B701", "#E73F74", "#80BA5A"
    ),
    gray = c("#4D4D4D", "#8C8C8C", "#D9D9D9"),
    black_and_white = c(
        "#000000", "#A0A0A4", "#808080", "#D4D4D4", "#606060",
        "#A0A0A4", "#606060", "#E8E8E8", "#A0A0A4"
    ),
    colors = c(
        "#0000FF", "#FF0000", "#00C000", "#AD07E3", "#FF8000",
        "#000000", "#94641F", "#000080", "#610051", "#A00000",
        "#056943", "#F2B77C", "#00FF00", "#90BFF9", "#C0C0FF",
        "#606060", "#FFFF00", "#C06000", "#D4D4D4", "#C0C000"
    ),
    floral = c(
        "#285291", "#4F2B8E", "#91188E", "#539027", "#0D405B", "#34274D",
        "#91181D", "#2C3324", "#022240", "#21063F", "#3D0620", "#022013"
    ),
    prism_light = c(
        "#A48AD3", "#1CC5FE", "#6FC7CF", "#FBA27D", "#FB7D80",
        "#2C1453", "#114CE8", "#0E6F7C", "#FB4F06", "#FB0005"
    ),
    prism_dark = c(
        "#2C1453", "#114CE8", "#0E6F7C", "#FB4F06", "#FB0005",
        "#A48AD3", "#1CC5FE", "#6FC7CF", "#FBA27D", "#FB7D80"
    ),
    colorblind_safe = c(
        "#000000", "#FF0066", "#107F80", "#40007F", "#AA66FF", "#66CCFE"
    ),
    waves = c("#031431", "#6F5A35", "#63615D", "#33565F", "#27292B"),
    starry = c("#000000", "#042E3D", "#765A22", "#44726D", "#9A9343"),
    pearl = c("#000000", "#4D402F", "#22456F", "#B63530", "#85827A", "#705443"),
    viridis = c("#440154", "#414487", "#2A788E", "#22A884", "#7AD151", "#FDE725"),
    magma = c("#000004", "#3B0F70", "#8C2981", "#DE4968", "#FE9F6D", "#FCFDBF"),
    inferno = c("#000004", "#420A68", "#932667", "#DD513A", "#FCA50A", "#FCFFA4"),
    plasma = c("#0D0887", "#6A00A8", "#B12A90", "#E16462", "#FCA636", "#F0F921")
)

.lab_gradient_palettes <- list(
    blue_red = c("#2166AC", "#67A9CF", "#F7F7F7", "#EF8A62", "#B2182B"),
    teal_gold = c("#0B6E69", "#55A868", "#F4EBD0", "#DDAA33", "#A76C00"),
    graphpad_heatmap = c("#DCEEFF", "#B7D8F6", "#F6F2EC", "#F7C7B2", "#EA907A", "#C95A6A"),
    graphpad_heatmap_alt = c("#E6F2FB", "#A9D0E9", "#D7E6DD", "#F3E7C9", "#D7B18C", "#9B7AA5")
)

.lab_group_dictionaries <- list(
    default = c(
        Control = "#4D4D4D",
        Treatment = "#D55E00",
        WT = "#1F77B4",
        Mutant = "#CC79A7",
        KO = "#D55E00",
        OE = "#009E73",
        Mock = "#8C8C8C",
        Stress = "#E6AB02",
        Resistant = "#11A579",
        Susceptible = "#E73F74",
        Root = "#3969AC",
        Shoot = "#80BA5A"
    )
)

.lab_example_group_dictionaries <- list(
    quinoa_samples = c(
        Cqu = "#1F77B4",
        LM134 = "#1F77B4",
        CquZ = "#2F4B7C",
        LM42 = "#4E79A7",
        LM96 = "#A0CBE8",
        LM172 = "#F28E2B",
        LM176 = "#FFBE7D",
        LM177 = "#59A14F",
        LM225 = "#8CD17D",
        LM270 = "#76B7B2",
        LM320 = "#499894",
        LM393 = "#E15759",
        LM411 = "#FF9D9A",
        CHEN199 = "#79706E",
        CHEN90 = "#BAB0AC",
        D10126 = "#B07AA1",
        D12282 = "#D4A6C8",
        Javi = "#9D7660",
        PI614919 = "#D7B5A6",
        QQ74 = "#E15759",
        Regalona = "#86BCB6",
        `0321072RM` = "#EDC948"
    ),
    subgenome_classes = c(
        `A-A` = "#1F77B4",
        `A-B` = "#009E73",
        `B-B` = "#D55E00",
        `A subgenome` = "#1F77B4",
        `B subgenome` = "#D55E00",
        Shared = "#8C8C8C",
        Cq5A = "#2F6CA3",
        Cq5B = "#A14B1F"
    ),
    trash_monomers = c(
        `40-bp` = "#8FD3F4",
        `79-bp` = "#F8B6A6",
        `171-bp` = "#C9B6F0",
        `40bp` = "#8FD3F4",
        `79bp` = "#F8B6A6",
        `171bp` = "#C9B6F0"
    ),
    trash_monomers_graphpad_alt = c(
        `40-bp` = "#9CC9E7",
        `79-bp` = "#E8C9A0",
        `171-bp` = "#B7A7D9",
        `40bp` = "#9CC9E7",
        `79bp` = "#E8C9A0",
        `171bp` = "#B7A7D9"
    ),
    ancestry_components = c(
        K1 = "#1F77B4",
        K2 = "#D55E00",
        K3 = "#009E73",
        K4 = "#CC79A7",
        Highland = "#1F77B4",
        Coastal = "#D55E00",
        Admixed = "#009E73"
    )
)

#' List available semantic color dictionaries
#'
#' @param include_examples Whether to include domain-specific example
#'   dictionaries used in package demonstrations and backward compatibility.
#'
#' @return A character vector of available dictionary names.
#' @export
available_group_dictionaries <- function(include_examples = FALSE) {
    include_examples <- .validate_flag(include_examples, "include_examples")

    names(.all_group_dictionaries(include_examples = include_examples))
}

#' List available discrete palettes
#'
#' @return A character vector of available discrete palette names.
#' @export
available_lab_palettes <- function() {
    names(.all_discrete_palettes())
}

#' Return a lab discrete palette
#'
#' @param n Number of colors required.
#' @param palette Palette name.
#' @param reverse Whether to reverse the palette.
#' @param alpha Opacity multiplier between `0` and `1`.
#'
#' @return A character vector of hex colors.
#' @export
lab_palette <- function(n, palette = "main", reverse = FALSE, alpha = 1) {
    if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1) {
        cli::cli_abort("{.arg n} must be a positive number.")
    }

    if (!is.character(palette) || length(palette) != 1 || is.na(palette)) {
        cli::cli_abort("{.arg palette} must be a single palette name.")
    }
    if (!is.numeric(alpha) || length(alpha) != 1 || is.na(alpha) || alpha < 0 || alpha > 1) {
        cli::cli_abort("{.arg alpha} must be a single number between 0 and 1.")
    }

    palette_values <- .all_discrete_palettes()[[palette]]
    if (is.null(palette_values)) {
        cli::cli_abort(
            c(
                "Unknown palette.",
                "x" = "Unknown palette: {.val {palette}}",
                "i" = "Available palettes: {.val {available_lab_palettes()}}"
            )
        )
    }

    if (isTRUE(reverse)) {
        palette_values <- rev(palette_values)
    }

    if (n > length(palette_values)) {
        palette_values <- grDevices::colorRampPalette(palette_values)(n)
    } else {
        palette_values <- palette_values[seq_len(n)]
    }

    if (!identical(alpha, 1)) {
        palette_values <- grDevices::adjustcolor(palette_values, alpha.f = alpha)
    }

    unname(palette_values)
}

#' Return a lab gradient palette
#'
#' @param n Number of colors required.
#' @param palette Gradient palette name.
#' @param reverse Whether to reverse the palette.
#'
#' @return A character vector of hex colors.
#' @export
lab_gradient_palette <- function(n = 256, palette = "blue_red", reverse = FALSE) {
    colors <- .all_gradient_palettes()[[palette]]
    if (is.null(colors)) {
        cli::cli_abort(
            c(
                "Unknown gradient palette.",
                "x" = "Unknown gradient palette: {.val {palette}}",
                "i" = "Available palettes: {.val {names(.all_gradient_palettes())}}"
            )
        )
    }

    if (isTRUE(reverse)) {
        colors <- rev(colors)
    }

    grDevices::colorRampPalette(colors)(n)
}

#' Return semantic group color mappings
#'
#' @param dictionary A named dictionary such as `"default"`. Domain-specific
#'   example dictionaries are still available for backward compatibility but are
#'   not listed unless `available_group_dictionaries(include_examples = TRUE)` is
#'   used. You may also pass a named override vector as the first argument, which
#'   applies on top of the default dictionary.
#' @param overrides Optional named vector of color overrides.
#'
#' @return A named character vector.
#' @export
group_colors <- function(dictionary = "default", overrides = NULL) {
    if (is.null(overrides) && !is.null(names(dictionary))) {
        overrides <- dictionary
        dictionary <- "default"
    }

    if (!is.character(dictionary) || length(dictionary) != 1 || is.na(dictionary)) {
        cli::cli_abort("{.arg dictionary} must be a single dictionary name.")
    }

    public_values <- .all_group_dictionaries(include_examples = FALSE)
    all_values <- .all_group_dictionaries(include_examples = TRUE)
    if (!dictionary %in% names(all_values)) {
        cli::cli_abort(
            c(
                "Unknown semantic color dictionary.",
                "x" = "Unknown dictionary: {.val {dictionary}}",
                "i" = "Available dictionaries: {.val {names(public_values)}}",
                "i" = "Use {.code available_group_dictionaries(include_examples = TRUE)} to list domain-specific example dictionaries."
            )
        )
    }
    if (!dictionary %in% names(public_values)) {
        cli::cli_warn(
            c(
                "Using a domain-specific example dictionary.",
                "i" = "{.val {dictionary}} is kept for examples and backward compatibility.",
                "i" = "For reusable workflows, prefer {.fn register_group_dictionary} with project-specific mappings."
            )
        )
    }

    values <- all_values[[dictionary]]
    if (!is.null(overrides)) {
        if (is.null(names(overrides)) || anyNA(names(overrides)) || any(names(overrides) == "")) {
            cli::cli_abort("{.arg overrides} must be a named vector.")
        }
        values[names(overrides)] <- unname(overrides)
    }

    values
}

.warn_missing_groups <- function(groups, values) {
    missing_groups <- setdiff(unique(groups), names(values))
    if (length(missing_groups) > 0) {
        cli::cli_warn("Unknown groups will use {.arg na.value}: {.val {missing_groups}}")
    }
}

#' Discrete lab color scale
#'
#' @param palette Palette name.
#' @param reverse Whether to reverse the palette.
#' @param alpha Opacity multiplier between `0` and `1`.
#' @param na.value Fallback color for missing values.
#' @param guide Legend guide. Use `"none"` to suppress the guide.
#' @param ... Passed to `ggplot2::discrete_scale()`.
#'
#' @return A ggplot scale.
#' @export
scale_color_lab <- function(palette = "main", reverse = FALSE, alpha = 1, na.value = "#BFBFBF", guide = ggplot2::guide_legend(), ...) {
    ggplot2::discrete_scale(
        aesthetics = "colour",
        palette = function(n) lab_palette(n, palette = palette, reverse = reverse, alpha = alpha),
        na.value = na.value,
        guide = guide,
        ...
    )
}

#' Discrete lab fill scale
#'
#' @param palette Palette name.
#' @param reverse Whether to reverse the palette.
#' @param alpha Opacity multiplier between `0` and `1`.
#' @param na.value Fallback color for missing values.
#' @param guide Legend guide. Use `"none"` to suppress the guide.
#' @param ... Passed to `ggplot2::discrete_scale()`.
#'
#' @return A ggplot scale.
#' @export
scale_fill_lab <- function(palette = "main", reverse = FALSE, alpha = 1, na.value = "#BFBFBF", guide = ggplot2::guide_legend(), ...) {
    ggplot2::discrete_scale(
        aesthetics = "fill",
        palette = function(n) lab_palette(n, palette = palette, reverse = reverse, alpha = alpha),
        na.value = na.value,
        guide = guide,
        ...
    )
}

#' Semantic color scale for group names
#'
#' @param values Named vector of colors. If `NULL`, uses `dictionary`.
#' @param dictionary Semantic color dictionary name.
#' @param groups Optional vector of group names to validate before plotting.
#' @param na.value Fallback color for unknown groups.
#' @param ... Passed to `ggplot2::scale_colour_manual()`.
#'
#' @return A ggplot scale.
#' @export
scale_color_groupmap <- function(values = NULL, dictionary = "default", groups = NULL, na.value = "#BFBFBF", ...) {
    values <- rlang::`%||%`(values, group_colors(dictionary = dictionary))
    if (!is.null(groups)) {
        .warn_missing_groups(groups = groups, values = values)
    }

    ggplot2::scale_colour_manual(values = values, na.value = na.value, ...)
}

#' Semantic fill scale for group names
#'
#' @param values Named vector of colors. If `NULL`, uses `dictionary`.
#' @param dictionary Semantic color dictionary name.
#' @param groups Optional vector of group names to validate before plotting.
#' @param na.value Fallback color for unknown groups.
#' @param ... Passed to `ggplot2::scale_fill_manual()`.
#'
#' @return A ggplot scale.
#' @export
scale_fill_groupmap <- function(values = NULL, dictionary = "default", groups = NULL, na.value = "#BFBFBF", ...) {
    values <- rlang::`%||%`(values, group_colors(dictionary = dictionary))
    if (!is.null(groups)) {
        .warn_missing_groups(groups = groups, values = values)
    }

    ggplot2::scale_fill_manual(values = values, na.value = na.value, ...)
}
