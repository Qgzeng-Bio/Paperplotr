.clean_composite_principles <- data.frame(
    principle = c(
        "low visual weight",
        "functional color",
        "foreground and context separation",
        "repeated-structure alignment",
        "explicit panel hierarchy",
        "deliberate whitespace",
        "uniform typography",
        "caption-first narrative",
        "units and scale clarity",
        "shared legend economy",
        "final-size export"
    ),
    rationale = c(
        "Thin strokes and sparse grids keep dense scientific panels from feeling heavy.",
        "Color should encode groups, tracks, thresholds, or emphasis rather than decoration.",
        "Muted background evidence lets primary signals and nominated features stand out.",
        "Rows, tracks, samples, and chromosome panels become scannable when their anchors align.",
        "Primary evidence needs more area and contrast than supporting diagnostics.",
        "Reserved empty space reduces lookup burden and keeps legends from crowding data.",
        "One font family and a narrow size range make multi-panel figures feel coherent.",
        "Panel titles should stay short; scientific interpretation belongs mainly in the caption.",
        "Axes, legends, transformations, and denominators should be explicit enough to avoid guessing.",
        "Repeated legends waste data area; collect or reserve legends when semantics are shared.",
        "Themes and presets should be checked at the manuscript width where the figure will be read."
    ),
    paperplotr_action = c(
        "Use theme_clean_composite(line_width = 0.3) and avoid heavy gridlines.",
        "Use scale_color_lab(palette = \"manuscript_clean\") or project-specific group_colors().",
        "Use lower alpha or pale gradients for background layers and stronger accents only for key evidence.",
        "Use layout_lab() and consistent factor ordering before composing panels.",
        "Assign primary and supporting panels before choosing panel sizes or layout weights.",
        "Reserve legend and annotation space deliberately instead of shrinking data regions.",
        "Use one base_family and base_size across all panels.",
        "Avoid long plot titles inside panels; keep labels concise and explain details in captions.",
        "Include units such as Mb, %, log2, or normalized counts in axis and legend labels.",
        "Use layout_lab(guides = \"collect\") when panels share color semantics.",
        "Export with save_lab() or save_lab_plot() using the target journal or output preset."
    ),
    stringsAsFactors = FALSE
)

#' PaperPlotR design principles
#'
#' Return the package-level checklist behind the clean manuscript composite
#' style: low visual weight, functional color, explicit hierarchy, strong
#' alignment, and final-size export discipline.
#'
#' @param style Principle set to return. Currently only `"clean_composite"` is
#'   available.
#'
#' @return A data frame with `principle`, `rationale`, and `paperplotr_action`
#'   columns.
#' @export
#'
#' @examples
#' paperplot_principles()
paperplot_principles <- function(style = "clean_composite") {
    style <- rlang::arg_match0(style, values = "clean_composite")

    .clean_composite_principles
}
