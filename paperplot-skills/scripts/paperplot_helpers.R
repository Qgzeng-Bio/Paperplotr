# Standalone helper functions for paperplot-skills.
# Dependencies: base R, grDevices, grid, tools, and ggplot2.

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("The standalone paperplot skill requires ggplot2.", call. = FALSE)
}

pp_helper_source_file <- local({
  ofile <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(ofile) && nzchar(ofile) && file.exists(ofile)) normalizePath(ofile) else NULL
})

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

pp_helper_version <- "standalone-0.4.1"

# ---- Style registry (WP1): single source of truth for global style constants ----
# Templates must consume these through pp_theme()/pp_finalize(). Literal
# overrides outside this registry are treated as style drift.
pp_style_registry <- function() {
  list(
    base_size = 7,
    family_fallbacks = c("Arial", "Helvetica", "Liberation Sans", "DejaVu Sans", "sans"),
    font_hierarchy = list(
      axis_title = 0,
      axis_text = -0.5,
      legend_title = -0.2,
      legend_text = -0.5,
      strip_text = 0,
      plot_title = 1,
      plot_subtitle = 0,
      plot_caption = -1
    ),
    text_sizes_pt = list(
      body = 7,
      label = 6.5,
      minimum = 6,
      panel_tag = 8
    ),
    line_widths = list(
      axis_line = 0.35,
      axis_ticks = 0.35,
      grid_major = 0.25,
      reference = 0.28,
      interval = 0.45,
      outline = 0.35
    ),
    point_sizes = list(
      micro = 0.55,
      dense = 0.85,
      normal = 1.3,
      emphasis = 2.0
    ),
    spacing_mm = list(
      tick_length = 1.5,
      legend_key = 4.2,
      legend_spacing_x = 1,
      # ggplot2::margin() defaults to points. These values preserve the old
      # 6 pt / 4 pt visual spacing while making the registry's mm unit honest.
      plot_margin = 2.12,
      axis_title_margin = 1.41
    )
  )
}

# Resolve a style constant by dotted path (e.g. "point_sizes.dense"), letting
# options(paperplot.point_sizes_dense)/PAPERPLOT_POINT_SIZES_DENSE override the
# registry value session-wide. One setting here applies to every template.
pp_style_number <- function(path, default = NULL) {
  parts <- strsplit(path, ".", fixed = TRUE)[[1]]
  value <- pp_style_registry()
  for (p in parts) {
    if (!is.list(value) || is.null(value[[p]])) {
      value <- NULL
      break
    }
    value <- value[[p]]
  }
  resolved <- if (is.null(value)) default else value
  opt_key <- paste0("paperplot.", gsub("\\.", "_", path))
  opt <- getOption(opt_key)
  if (!is.null(opt)) {
    opt <- suppressWarnings(as.numeric(opt))
    if (length(opt) != 1L || !is.finite(opt)) stop("Invalid numeric style option: ", opt_key, call. = FALSE)
    return(opt)
  }
  env_key <- toupper(gsub("[^A-Za-z0-9]", "_", opt_key))
  env_val <- Sys.getenv(env_key, unset = "")
  if (nzchar(env_val)) {
    num <- suppressWarnings(as.numeric(env_val))
    if (length(num) == 1L && is.finite(num)) return(num)
    stop("Invalid numeric style environment value: ", env_key, call. = FALSE)
  }
  resolved
}

pp_text_size <- function(role = c("body", "label", "minimum", "panel_tag"),
                         unit = c("geom", "pt")) {
  role <- match.arg(role)
  unit <- match.arg(unit)
  value_pt <- pp_style_number(paste0("text_sizes_pt.", role))
  if (identical(unit, "pt")) value_pt else value_pt / ggplot2::.pt
}

pp_point_size <- function(role = c("micro", "dense", "normal", "emphasis")) {
  role <- match.arg(role)
  pp_style_number(paste0("point_sizes.", role))
}

pp_line_width <- function(role = c("axis_line", "axis_ticks", "grid_major", "reference", "interval", "outline")) {
  role <- match.arg(role)
  pp_style_number(paste0("line_widths.", role))
}

pp_spacing_mm <- function(role = c("tick_length", "legend_key", "legend_spacing_x", "plot_margin", "axis_title_margin")) {
  role <- match.arg(role)
  pp_style_number(paste0("spacing_mm.", role))
}

pp_discrete_palettes <- list(
  graphpad_discrete = c(
    "#4E79A7", "#F28E2B", "#59A14F", "#E15759",
    "#B07AA1", "#76B7B2", "#EDC948", "#79706E",
    "#9C755F", "#BAB0AC", "#A0CBE8", "#FFBE7D"
  ),
  graphpad_muted = c(
    "#6F8DBD", "#E6A157", "#7CB77D", "#D47474",
    "#B79AC8", "#8EC7C2", "#E5CB6C", "#8E8E8E"
  ),
  gray = c("#303030", "#6A6A6A", "#A6A6A6", "#D0D0D0"),
  colorblind_safe = c("#000000", "#0072B2", "#D55E00", "#009E73", "#CC79A7", "#F0E442"),
  new_reference = c(New = "#D55E00", Reference = "#4D4D4D", Published = "#8E8E8E"),
  treatment_control = c(Treatment = "#D55E00", Control = "#4D4D4D"),
  up_down_ns = c(Up = "#D55E00", Down = "#0072B2", NS = "#8E8E8E")
)

pp_gradient_palettes <- list(
  graphpad_heatmap = c("#DCEEFF", "#B7D8F6", "#F6F2EC", "#F7C7B2", "#EA907A", "#C95A6A"),
  graphpad_heatmap_alt = c("#E6F2FB", "#A9D0E9", "#D7E6DD", "#F3E7C9", "#D7B18C", "#9B7AA5"),
  blue_red = c("#2166AC", "#67A9CF", "#F7F7F7", "#EF8A62", "#B2182B"),
  quality = c("#B2182B", "#F7F7F7", "#2166AC")
)

pp_output_presets <- list(
  cell = list(width_cm = 17.4, height_cm = 12.0, dpi = 600, min_text_pt = 6),
  cell_half = list(width_cm = 8.7, height_cm = 6.0, dpi = 600, min_text_pt = 6),
  nature = list(width_cm = 18.0, height_cm = 12.0, dpi = 600, min_text_pt = 6),
  nature_half = list(width_cm = 9.0, height_cm = 6.0, dpi = 600, min_text_pt = 6),
  ncomms = list(width_cm = 18.0, height_cm = 12.0, dpi = 600, min_text_pt = 6),
  ncomms_half = list(width_cm = 9.0, height_cm = 6.0, dpi = 600, min_text_pt = 6),
  single_column = list(width_cm = 8.9, height_cm = 6.2, dpi = 600, min_text_pt = 6),
  double_column = list(width_cm = 18.0, height_cm = 12.0, dpi = 600, min_text_pt = 6),
  square = list(width_cm = 8.9, height_cm = 8.9, dpi = 600, min_text_pt = 6)
)

pp_fig_specs <- data.frame(
  spec = c("2x2", "2.58x2", "4.9x2", "4.9x4.9"),
  panel_w_cm = c(2.0, 2.58, 4.9, 4.9),
  panel_h_cm = c(2.0, 2.0, 2.0, 4.9),
  nonpanel_w_cm = c(0.9, 0.9, 0.9, 0.9),
  nonpanel_h_cm = c(0.9, 0.9, 0.9, 0.9),
  gap_cm = c(0.15, 0.15, 0.15, 0.15),
  stringsAsFactors = FALSE
)

pp_nonempty_scalar <- function(x, name) {
  if (length(x) != 1 || is.na(x) || !nzchar(trimws(as.character(x)))) {
    stop(name, " must be a non-empty scalar.", call. = FALSE)
  }
  as.character(x)
}

pp_pattern_reference <- function(figure_family,
                                 pattern_doc = NULL,
                                 template_id = NULL,
                                 source = "replica-pattern-library") {
  family <- as.character(figure_family %||% "")
  key <- tolower(gsub("[^a-z0-9]+", "_", family))
  doc_map <- list(
    grouped_boxplot_jitter = "references/pattern-library/raincloud-violin-jitter.md",
    boxplot_jitter = "references/pattern-library/raincloud-violin-jitter.md",
    violin_dot = "references/pattern-library/raincloud-violin-jitter.md",
    comparison_boxplot = "references/pattern-library/raincloud-violin-jitter.md",
    paired_comparison = "references/pattern-library/raincloud-violin-jitter.md",
    raincloud = "references/pattern-library/raincloud-violin-jitter.md",
    raincloud_violin_jitter = "references/pattern-library/raincloud-violin-jitter.md",
    barplot = "references/pattern-library/grouped-bar-errorbar.md",
    grouped_bar = "references/pattern-library/grouped-bar-errorbar.md",
    grouped_bar_errorbar = "references/pattern-library/grouped-bar-errorbar.md",
    bio_duplication_mode_four_panel = "references/pattern-library/grouped-bar-errorbar.md",
    scatter_regression = "references/pattern-library/scatter-regression-marginal.md",
    association = "references/pattern-library/scatter-regression-marginal.md",
    ordination_scatter = "references/pattern-library/pca-pcoa-ordination.md",
    pcoa_marginal = "references/pattern-library/pca-pcoa-ordination.md",
    pca_pcoa_ordination = "references/pattern-library/pca-pcoa-ordination.md",
    heatmap = "references/pattern-library/correlation-heatmap.md",
    annotated_heatmap = "references/pattern-library/correlation-heatmap.md",
    multi_metric_small_multiples_rank_index = "references/pattern-library/multi-panel-manuscript-layout.md",
    multi_metric_rank_small_multiples = "references/pattern-library/multi-panel-manuscript-layout.md",
    manuscript_four_panel = "references/pattern-library/multi-panel-manuscript-layout.md",
    bio_genome_quality_small_multiples = "references/pattern-library/multi-panel-manuscript-layout.md",
    volcano = "references/pattern-library/volcano-ma-enrichment.md",
    volcano_plot = "references/pattern-library/volcano-ma-enrichment.md",
    ma_plot = "references/pattern-library/volcano-ma-enrichment.md",
    enrichment_dotplot = "references/pattern-library/volcano-ma-enrichment.md",
    compact_dot_matrix_enrichment = "references/pattern-library/compact-dot-matrix-enrichment.md",
    dot_matrix_enrichment = "references/pattern-library/compact-dot-matrix-enrichment.md",
    bubble_heatmap_enrichment = "references/pattern-library/compact-dot-matrix-enrichment.md",
    effect_size_forest = "references/pattern-library/model-validation-figures.md",
    model_validation = "references/pattern-library/model-validation-figures.md",
    model_validation_composite = "references/pattern-library/model-validation-figures.md",
    lollipop_ranked = "references/pattern-library/grouped-bar-errorbar.md",
    lollipop_dumbbell_dotplot = "references/pattern-library/grouped-bar-errorbar.md",
    upset_set_plot = "references/pattern-library/upset-set-plot.md",
    manhattan_genomewide = "references/pattern-library/manhattan-genomewide.md"
  )
  inferred_doc <- doc_map[[key]]
  if (is.null(inferred_doc)) inferred_doc <- "references/figure-type-selector.md"
  list(
    figure_family = family,
    pattern_doc = pattern_doc %||% inferred_doc,
    template_id = template_id,
    source = source,
    selection_rule = "Detected data roles and chart family are matched against references/pattern-library before drawing.",
    qa_focus = c("label burden", "legend burden", "color burden", "rendered image QA", "old-vs-new comparison")
  )
}

pp_figure_spec <- function(figure_id, template_id, task_type = "new", figure_role = "main",
                           scientific_message, plot_type, sample_id = NULL, group_var = NULL,
                           output_preset = "nature_half") {
  spec <- list(
    figure_id = pp_nonempty_scalar(figure_id, "figure_id"),
    template_id = pp_nonempty_scalar(template_id, "template_id"),
    backend = "R/ggplot2",
    helper_version = pp_helper_version,
    task_type = pp_nonempty_scalar(task_type, "task_type"),
    figure_role = pp_nonempty_scalar(figure_role, "figure_role"),
    scientific_message = pp_nonempty_scalar(scientific_message, "scientific_message"),
    plot_type = pp_nonempty_scalar(plot_type, "plot_type"),
    sample_id = sample_id,
    group_var = group_var,
    output_preset = pp_nonempty_scalar(output_preset, "output_preset"),
    created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
  pp_validate_figure_spec(spec)
  class(spec) <- c("pp_figure_spec", class(spec))
  spec
}

pp_validate_figure_spec <- function(figure_spec) {
  required <- c("figure_id", "template_id", "backend", "scientific_message", "plot_type", "output_preset")
  missing <- required[!vapply(required, function(x) !is.null(figure_spec[[x]]) && nzchar(as.character(figure_spec[[x]])), logical(1))]
  if (length(missing) > 0) {
    stop("figure_spec is missing required fields: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

pp_metric_spec <- function(metric, label = metric, unit = "", direction = "neutral",
                           transform = "none", role = "primary") {
  n <- length(metric)
  recycle <- function(x) rep(x, length.out = n)
  out <- data.frame(
    metric = as.character(metric),
    label = as.character(recycle(label)),
    unit = as.character(recycle(unit)),
    direction = as.character(recycle(direction)),
    transform = as.character(recycle(transform)),
    role = as.character(recycle(role)),
    stringsAsFactors = FALSE
  )
  pp_validate_metric_spec(out)
  out
}

pp_validate_metric_spec <- function(metric_spec, allow_missing_units = FALSE) {
  required <- c("metric", "label", "unit", "direction", "transform", "role")
  missing_cols <- setdiff(required, names(metric_spec))
  if (length(missing_cols) > 0) {
    stop("metric_spec missing columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (any(!nzchar(trimws(metric_spec$metric)))) {
    stop("metric_spec contains empty metric names.", call. = FALSE)
  }
  if (any(duplicated(metric_spec$metric))) {
    stop("metric_spec contains duplicate metric names: ", paste(unique(metric_spec$metric[duplicated(metric_spec$metric)]), collapse = ", "), call. = FALSE)
  }
  allowed_direction <- c("higher_better", "lower_better", "neutral")
  bad_direction <- setdiff(unique(metric_spec$direction), allowed_direction)
  if (length(bad_direction) > 0) {
    stop("metric_spec has invalid direction: ", paste(bad_direction, collapse = ", "), call. = FALSE)
  }
  allowed_transform <- c("none", "log", "log10", "sqrt", "rank", "percentile", "z_score", "normalized", "scaled", "user_defined")
  bad_transform <- setdiff(unique(metric_spec$transform), allowed_transform)
  if (length(bad_transform) > 0) {
    stop("metric_spec has invalid transform: ", paste(bad_transform, collapse = ", "), call. = FALSE)
  }
  if (!isTRUE(allow_missing_units) && any(!nzchar(trimws(metric_spec$unit)))) {
    stop("metric_spec must record units; use 'unitless' or 'a.u.' when appropriate.", call. = FALSE)
  }
  invisible(TRUE)
}

pp_axis_label <- function(label, unit = "", transform = "none") {
  unit <- unit %||% ""
  suffix <- if (nzchar(unit)) paste0(" (", unit, ")") else ""
  transform_note <- if (!identical(transform, "none")) paste0("; ", transform) else ""
  paste0(label, suffix, transform_note)
}

pp_metric_label <- function(metric_spec, include_unit = TRUE) {
  pp_validate_metric_spec(metric_spec)
  if (!isTRUE(include_unit)) return(metric_spec$label)
  mapply(pp_axis_label, metric_spec$label, metric_spec$unit, metric_spec$transform, USE.NAMES = FALSE)
}

pp_validate_units <- function(metric_spec) {
  pp_validate_metric_spec(metric_spec)
  invisible(TRUE)
}

pp_format_number <- function(x, digits = 3, big.mark = ",") {
  formatC(x, format = "fg", digits = digits, big.mark = big.mark)
}

pp_format_percent <- function(x, digits = 1, input_scale = c("fraction", "percent")) {
  input_scale <- match.arg(input_scale)
  value <- if (identical(input_scale, "fraction")) x * 100 else x
  paste0(formatC(value, format = "f", digits = digits), "%")
}

pp_resolve_family <- function(preferred = "Arial") {
  # Resolve a manuscript sans-serif that actually exists on this machine.
  # Avoids hard "invalid font type" failures when Arial is absent (e.g. Linux).
  fallbacks <- c(preferred, "Helvetica", "Liberation Sans", "DejaVu Sans", "sans")
  if (requireNamespace("systemfonts", quietly = TRUE)) {
    families <- tryCatch(unique(systemfonts::system_fonts()$family), error = function(e) character(0))
    hit <- fallbacks[fallbacks %in% families]
    if (length(hit)) return(hit[[1]])
  }
  "sans"
}

pp_theme <- function(base_size = pp_style_number("base_size"),
                     base_family = pp_resolve_family(pp_style_registry()$family_fallbacks[[1]]),
                     line_width = pp_line_width("axis_line"),
                     axis_title_margin = pp_spacing_mm("axis_title_margin"),
                     show_grid = FALSE) {
  hier <- pp_style_registry()$font_hierarchy
  grid_major <- if (isTRUE(show_grid)) {
    ggplot2::element_line(linewidth = pp_line_width("grid_major"), colour = "#D9D9D9")
  } else {
    ggplot2::element_blank()
  }

  out <- ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(family = base_family, size = base_size, colour = "#1F1F1F"),
      axis.title = ggplot2::element_text(
        size = base_size + hier$axis_title,
        margin = ggplot2::margin(
          t = axis_title_margin, r = axis_title_margin,
          b = axis_title_margin, l = axis_title_margin,
          unit = "mm"
        )
      ),
      axis.text = ggplot2::element_text(size = base_size + hier$axis_text, colour = "#303030"),
      axis.line = ggplot2::element_line(linewidth = line_width, colour = "#1F1F1F"),
      axis.ticks = ggplot2::element_line(linewidth = line_width, colour = "#1F1F1F"),
      axis.ticks.length = grid::unit(pp_spacing_mm("tick_length"), "mm"),
      legend.title = ggplot2::element_text(size = base_size + hier$legend_title),
      legend.text = ggplot2::element_text(size = base_size + hier$legend_text),
      legend.key = ggplot2::element_blank(),
      legend.key.size = grid::unit(pp_spacing_mm("legend_key"), "mm"),
      legend.spacing.x = grid::unit(pp_spacing_mm("legend_spacing_x"), "mm"),
      panel.grid.major = grid_major,
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(size = base_size + hier$strip_text, face = "bold"),
      plot.title = ggplot2::element_text(size = base_size + hier$plot_title, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = base_size + hier$plot_subtitle),
      plot.caption = ggplot2::element_text(size = base_size + hier$plot_caption, colour = "#6A6A6A"),
      plot.title.position = "plot",
      plot.margin = ggplot2::margin(
        pp_spacing_mm("plot_margin"), pp_spacing_mm("plot_margin"),
        pp_spacing_mm("plot_margin"), pp_spacing_mm("plot_margin"),
        unit = "mm"
      )
    )
  attr(out, "paperplot_theme") <- TRUE
  out
}

# Finalize a plot copy without changing ggplot2's process-wide geom defaults.
# House defaults are applied first; deliberate plot-local theme overrides remain
# intact. Text/label layers with no explicit or mapped size/family receive local
# manuscript defaults, including optional ggrepel geoms.
pp_finalize <- function(plot, base_size = pp_style_number("base_size"),
                        base_family = pp_resolve_family(pp_style_registry()$family_fallbacks[[1]]),
                        show_grid = FALSE) {
  if (!inherits(plot, "ggplot")) return(plot)
  out <- plot
  existing_theme <- out$theme
  out$theme <- pp_theme(base_size = base_size, base_family = base_family, show_grid = show_grid) + existing_theme
  text_classes <- c("GeomText", "GeomLabel", "GeomTextRepel", "GeomLabelRepel")
  for (i in seq_along(out$layers)) {
    layer <- out$layers[[i]]
    if (!any(class(layer$geom) %in% text_classes)) next
    size_mapped <- !is.null(layer$mapping$size) || !is.null(out$mapping$size)
    family_mapped <- !is.null(layer$mapping$family) || !is.null(out$mapping$family)
    if (!size_mapped && is.null(layer$aes_params$size)) layer$aes_params$size <- base_size / ggplot2::.pt
    if (!family_mapped && is.null(layer$aes_params$family)) layer$aes_params$family <- base_family
    out$layers[[i]] <- layer
  }
  attr(out, "paperplot_finalized") <- TRUE
  out
}

pp_palette <- function(n, palette = "graphpad_discrete", reverse = FALSE, alpha = 1) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1) {
    stop("n must be a positive number.", call. = FALSE)
  }
  values <- pp_discrete_palettes[[palette]]
  if (is.null(values)) {
    stop("Unknown discrete palette: ", palette, call. = FALSE)
  }
  if (isTRUE(reverse)) values <- rev(values)
  if (n > length(values)) {
    values <- grDevices::colorRampPalette(unname(values))(n)
  } else {
    values <- unname(values[seq_len(n)])
  }
  if (!identical(alpha, 1)) values <- grDevices::adjustcolor(values, alpha.f = alpha)
  unname(values)
}

pp_gradient_palette <- function(n = 256, palette = "graphpad_heatmap", reverse = FALSE) {
  values <- pp_gradient_palettes[[palette]]
  if (is.null(values)) {
    stop("Unknown gradient palette: ", palette, call. = FALSE)
  }
  if (isTRUE(reverse)) values <- rev(values)
  grDevices::colorRampPalette(unname(values))(n)
}

pp_group_colors <- function(groups, values = NULL, palette = "graphpad_discrete") {
  groups <- unique(as.character(groups))
  groups <- groups[!is.na(groups) & nzchar(groups)]
  if (!is.null(values)) {
    if (is.null(names(values)) || any(!nzchar(names(values)))) {
      stop("values must be a named color vector.", call. = FALSE)
    }
    missing_groups <- setdiff(groups, names(values))
    if (length(missing_groups) > 0) {
      extras <- pp_palette(length(missing_groups), palette = palette)
      names(extras) <- missing_groups
      values <- c(values, extras)
    }
    return(values[unique(c(groups, names(values)))])
  }
  semantic <- pp_discrete_palettes[[palette]]
  if (!is.null(semantic) && !is.null(names(semantic)) && all(groups %in% names(semantic))) {
    return(semantic[groups])
  }
  colors <- pp_palette(length(groups), palette = palette)
  names(colors) <- groups
  colors
}

pp_scale_color <- function(groups = NULL, values = NULL, palette = "graphpad_discrete",
                           na.value = "#BFBFBF", guide = ggplot2::guide_legend(), ...) {
  if (!is.null(groups) || !is.null(values)) {
    return(ggplot2::scale_colour_manual(
      values = pp_group_colors(groups %||% names(values), values = values, palette = palette),
      na.value = na.value,
      guide = guide,
      ...
    ))
  }
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = function(n) pp_palette(n, palette = palette),
    na.value = na.value,
    guide = guide,
    ...
  )
}

pp_scale_fill <- function(groups = NULL, values = NULL, palette = "graphpad_discrete",
                          na.value = "#BFBFBF", guide = ggplot2::guide_legend(), ...) {
  if (!is.null(groups) || !is.null(values)) {
    return(ggplot2::scale_fill_manual(
      values = pp_group_colors(groups %||% names(values), values = values, palette = palette),
      na.value = na.value,
      guide = guide,
      ...
    ))
  }
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = function(n) pp_palette(n, palette = palette),
    na.value = na.value,
    guide = guide,
    ...
  )
}

pp_validate_palette <- function(groups = NULL, variable_type = c("discrete", "continuous"),
                                palette = "graphpad_discrete") {
  variable_type <- match.arg(variable_type)
  if (identical(variable_type, "continuous")) {
    if (is.null(pp_gradient_palettes[[palette]])) {
      stop("Continuous variables must use a gradient palette; unknown gradient palette: ", palette, call. = FALSE)
    }
    return(pp_qa_result("palette", "pass", paste("continuous palette:", palette)))
  }
  if (is.null(pp_discrete_palettes[[palette]])) {
    stop("Discrete variables must use a discrete palette; unknown discrete palette: ", palette, call. = FALSE)
  }
  n_groups <- length(unique(as.character(groups %||% character())))
  capacity <- length(pp_discrete_palettes[[palette]])
  if (n_groups > capacity) {
    return(pp_qa_result("palette", "warn", paste("group count", n_groups, "exceeds base palette capacity", capacity, "and will be interpolated")))
  }
  pp_qa_result("palette", "pass", paste("discrete palette:", palette))
}

pp_check_color_mapping <- function(groups, values) {
  if (is.null(values)) return(pp_qa_result("color_mapping", "pass", "no manual color mapping supplied"))
  groups <- unique(as.character(groups))
  missing <- setdiff(groups, names(values))
  if (length(missing) > 0) {
    return(pp_qa_result("color_mapping", "fail", paste("manual colors missing groups:", paste(missing, collapse = ", "))))
  }
  pp_qa_result("color_mapping", "pass", "manual colors cover all groups")
}

pp_output_preset <- function(name = "nature_half") {
  preset <- pp_output_presets[[tolower(name)]]
  if (is.null(preset)) {
    stop("Unknown output preset: ", name, call. = FALSE)
  }
  preset
}

pp_panel_size <- function(name = "4.9x4.9") {
  idx <- match(name, pp_fig_specs$spec)
  if (is.na(idx)) {
    stop("Unknown panel size: ", name, call. = FALSE)
  }
  as.list(pp_fig_specs[idx, , drop = FALSE])
}

pp_fig_size_cm <- function(spec = "4.9x4.9", ncol = 1, nrow = 1) {
  row <- pp_panel_size(spec)
  list(
    width_cm = row$nonpanel_w_cm + ncol * row$panel_w_cm + (ncol - 1) * row$gap_cm,
    height_cm = row$nonpanel_h_cm + nrow * row$panel_h_cm + (nrow - 1) * row$gap_cm
  )
}

pp_recommend_layout <- function(n_panels, plot_type = "general", complex = FALSE) {
  if (!is.numeric(n_panels) || length(n_panels) != 1 || is.na(n_panels) || n_panels < 1) {
    stop("n_panels must be a positive integer.", call. = FALSE)
  }
  n_panels <- as.integer(n_panels)
  dims <- if (n_panels == 1) {
    c(1, 1)
  } else if (n_panels == 2) {
    c(2, 1)
  } else if (n_panels == 3) {
    c(3, 1)
  } else if (n_panels == 4) {
    c(2, 2)
  } else if (n_panels <= 6) {
    c(3, 2)
  } else if (n_panels <= 8) {
    c(4, 2)
  } else if (n_panels == 9) {
    c(3, 3)
  } else {
    c(4, ceiling(n_panels / 4))
  }
  spec <- if (isTRUE(complex) || plot_type %in% c("heatmap", "small_multiples")) {
    "4.9x4.9"
  } else if (n_panels <= 6) {
    "4.9x4.9"
  } else {
    "2.58x2"
  }
  size <- pp_fig_size_cm(spec, ncol = dims[[1]], nrow = dims[[2]])
  list(ncol = dims[[1]], nrow = dims[[2]], spec = spec, width_cm = size$width_cm, height_cm = size$height_cm)
}

pp_recommend_facet_grid <- function(n_panels, plot_type = "small_multiples", complex = TRUE) {
  pp_recommend_layout(n_panels, plot_type = plot_type, complex = complex)
}

pp_estimate_canvas_size <- function(n_panels, plot_type = "general", complex = FALSE, preset = NULL) {
  layout <- pp_recommend_layout(n_panels, plot_type = plot_type, complex = complex)
  if (!is.null(preset) && n_panels == 1) {
    preset_values <- pp_output_preset(preset)
    layout$width_cm <- preset_values$width_cm
    layout$height_cm <- preset_values$height_cm
  }
  layout
}

pp_assess_layout_risk <- function(n_panels, plot_type = "general", label_strategy = NULL) {
  status <- "pass"
  notes <- character()
  if (n_panels > 8 && plot_type %in% c("main", "small_multiples", "general")) {
    status <- "warn"
    notes <- c(notes, "many panels; consider supplementary figure or ranking summary")
  }
  if (n_panels >= 5 && n_panels <= 8 && plot_type %in% c("dot_heatmap", "bubble_heatmap")) {
    status <- "fail"
    notes <- c(notes, "5-8 heterogeneous metrics should default to small multiples")
  }
  if (!is.null(label_strategy) && identical(label_strategy$status, "fail")) {
    status <- "fail"
    notes <- c(notes, "label density requires layout or label changes")
  }
  if (length(notes) == 0) notes <- "layout risk acceptable"
  pp_qa_result("layout", status, paste(notes, collapse = "; "))
}

pp_assess_label_density <- function(labels, available_width_cm, font_size_pt = 6.5) {
  labels <- as.character(labels)
  labels <- labels[!is.na(labels)]
  if (length(labels) == 0) {
    return(list(score = 0, status = "pass", message = "no labels", n_labels = 0, max_chars = 0))
  }
  available_width_pt <- available_width_cm / 2.54 * 72
  max_chars <- max(nchar(labels, type = "chars"), na.rm = TRUE)
  score <- max_chars * font_size_pt * 0.55 * length(labels) / available_width_pt
  status <- if (score < 0.8) "pass" else if (score <= 1.2) "warn" else "fail"
  message <- switch(status,
    pass = "labels can be shown directly",
    warn = "labels are dense; rotate or wrap",
    fail = "labels are overcrowded; abbreviate, thin, or use a label key"
  )
  list(score = unname(score), status = status, message = message, n_labels = length(labels), max_chars = max_chars)
}

pp_wrap_labels <- function(labels, width = 12) {
  vapply(as.character(labels), function(x) paste(strwrap(x, width = width), collapse = "\n"), character(1))
}

pp_abbreviate_labels <- function(labels, max_chars = 14, min_chars = 4) {
  labels <- as.character(labels)
  out <- labels
  long <- nchar(out, type = "chars") > max_chars
  if (any(long)) {
    out[long] <- abbreviate(out[long], minlength = min_chars, strict = TRUE, named = FALSE)
  }
  out <- make.unique(out, sep = "_")
  names(out) <- labels
  out
}

pp_every_n_labels <- function(labels, n = 2) {
  labels <- as.character(labels)
  if (n <= 1) return(labels)
  ifelse((seq_along(labels) - 1) %% n == 0, labels, "")
}

pp_make_label_key <- function(original, display) {
  data.frame(original = as.character(original), display = as.character(display), stringsAsFactors = FALSE)
}

pp_label_strategy <- function(labels, available_width_cm, font_size_pt = 6.5, max_chars = 14) {
  labels <- as.character(labels)
  assessment <- pp_assess_label_density(labels, available_width_cm = available_width_cm, font_size_pt = font_size_pt)
  display <- labels
  angle <- 0
  show_every <- 1
  strategy <- "direct"
  if (identical(assessment$status, "warn")) {
    strategy <- "rotate_or_wrap"
    display <- ifelse(nchar(labels, type = "chars") > max_chars, pp_wrap_labels(labels, width = max_chars), labels)
    angle <- 45
  }
  if (identical(assessment$status, "fail")) {
    strategy <- "abbreviate_and_rotate"
    display <- unname(pp_abbreviate_labels(labels, max_chars = max_chars))
    angle <- 45
    show_every <- max(1, ceiling(assessment$score / 1.2))
    if (show_every > 1) display <- pp_every_n_labels(display, n = show_every)
  }
  list(
    status = assessment$status,
    strategy = strategy,
    score = assessment$score,
    angle = angle,
    show_every = show_every,
    labels = display,
    label_key = pp_make_label_key(labels, display),
    message = assessment$message
  )
}

pp_adjust_margins_for_labels <- function(plot, label_strategy) {
  if (is.null(label_strategy) || is.null(label_strategy$angle) || label_strategy$angle == 0) return(plot)
  plot + ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = label_strategy$angle, hjust = 1, vjust = 1),
    plot.margin = ggplot2::margin(6, 6, 10, 6)
  )
}

pp_stop_if_outputs_exist <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) > 0) {
    stop("Refusing to overwrite existing output files: ", paste(existing, collapse = ", "), call. = FALSE)
  }
}

pp_min_output_size <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  switch(ext, pdf = 5000, png = 1000, jpg = 1000, jpeg = 1000, tiff = 1000, tif = 1000, svg = 100, json = 50, md = 50, 100)
}

pp_assert_output <- function(filename, min_output_size_bytes = NULL) {
  min_output_size_bytes <- min_output_size_bytes %||% pp_min_output_size(filename)
  if (!file.exists(filename)) {
    stop("Output file was not created: ", filename, call. = FALSE)
  }
  size <- file.info(filename)[["size"]]
  if (is.na(size) || size < min_output_size_bytes) {
    stop("Output file is suspiciously small: ", filename, " (", size, " bytes)", call. = FALSE)
  }
  invisible(TRUE)
}

pp_default_device <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  if (identical(ext, "pdf")) {
    if (identical(Sys.info()[["sysname"]], "Darwin")) {
      return(function(filename, width, height, bg = "white", ...) {
        grDevices::quartz(type = "pdf", file = filename, width = width, height = height, bg = bg, ...)
      })
    }
    # Non-macOS: prefer cairo_pdf so PDF text honors fontconfig (real Arial when
    # installed) instead of the PostScript font DB that errors on "Arial".
    if (isTRUE(capabilities("cairo"))) {
      return(grDevices::cairo_pdf)
    }
  }
  # Raster: prefer ragg when available; it resolves fonts via fontconfig and is
  # more robust/consistent across platforms than the default bitmap device.
  if (ext %in% c("png", "jpg", "jpeg", "tiff", "tif") && requireNamespace("ragg", quietly = TRUE)) {
    return(switch(ext,
      png = ragg::agg_png,
      jpg = ragg::agg_jpeg,
      jpeg = ragg::agg_jpeg,
      tiff = ragg::agg_tiff,
      tif = ragg::agg_tiff
    ))
  }
  NULL
}

# Smallest themed/labelled text size in points for a ggplot object.
# Theme element sizes are absolute pt when set numerically; geom text/label
# layer sizes are in geom units and convert via ggplot2::.pt.
pp_theme_text_sizes_pt <- function(plot) {
  sizes <- numeric(0)
  if (inherits(plot, "ggplot") && !is.null(plot$theme)) {
    for (name in names(plot$theme)) {
      el <- plot$theme[[name]]
      if (inherits(el, "element_text") && !inherits(el$size, "rel")) {
        s <- suppressWarnings(as.numeric(el$size))
        sizes <- c(sizes, s[!is.na(s)])
      }
    }
  }
  sizes
}

pp_layer_text_sizes_pt <- function(plot) {
  sizes <- numeric(0)
  if (inherits(plot, "ggplot") && !is.null(plot$layers)) {
    for (lr in plot$layers) {
      is_text_geom <- any(class(lr$geom) %in% c("GeomText", "GeomLabel", "GeomTextRepel", "GeomLabelRepel"))
      if (is_text_geom) {
        s <- lr$aes_params$size %||% lr$geom$default_aes$size
        if (is.numeric(s)) sizes <- c(sizes, s * ggplot2::.pt)
      }
    }
  }
  sizes
}

pp_min_rendered_text_pt <- function(plot) {
  all_sizes <- c(pp_theme_text_sizes_pt(plot), pp_layer_text_sizes_pt(plot))
  if (length(all_sizes)) min(all_sizes) else NA_real_
}

# Apply a legend plan (see pp_legend_plan in scripts/lib/layout-planner.R) to a
# plot: position, direction, and the adaptive key size decided before render.
# Dual-mode: with `plot` supplied it returns the updated plot; without `plot`
# it returns a theme object so pipelines can do
#   pp_theme() + pp_apply_legend_plan(plan = legend_plan).
pp_apply_legend_plan <- function(plot = NULL, plan, position = plan$position,
                                 direction = plan$direction, key_size_mm = plan$key_size_mm) {
  if (is.null(plan)) {
    if (is.null(plot)) return(ggplot2::theme()) else return(plot)
  }
  th <- ggplot2::theme(
    legend.position = position,
    legend.direction = if (identical(direction, "vertical")) "vertical" else "horizontal",
    legend.key.size = grid::unit(key_size_mm, "mm")
  )
  if (identical(position, "none")) {
    th <- th + ggplot2::theme(legend.title = ggplot2::element_blank())
  }
  if (is.null(plot)) th else plot + th
}

# Extract the rendered legend grob from a plot (experimental; for multi-ggplot
# composites that want one canvas-level shared key). Returns NULL when the plot
# has no guides. cowplot is not required.
pp_extract_legend <- function(plot) {
  g <- tryCatch(ggplot2::ggplotGrob(plot), error = function(e) NULL)
  if (is.null(g)) return(NULL)
  idx <- which(vapply(g$grobs, function(x) {
    !inherits(x, "zeroGrob") && grepl("guide-box", x$name %||% "", fixed = TRUE)
  }, logical(1)))
  if (!length(idx)) return(NULL)
  g$grobs[[idx[[1]]]]
}

# ---- WP6: closed-loop QA auto-fix ------------------------------------------

pp_set_qa_context <- function(plot, family = NULL, expected_panels = NULL,
                              layout_profile = NULL, target_width_mm = NULL,
                              journal_profile = NULL, allow_grid = "auto") {
  attr(plot, "pp_qa_context") <- list(
    family = family,
    expected_panels = expected_panels,
    layout_profile = layout_profile,
    target_width_mm = target_width_mm,
    journal_profile = journal_profile,
    allow_grid = allow_grid
  )
  plot
}

pp_infer_panel_count <- function(plot) {
  if (!inherits(plot, "ggplot")) return(1L)
  tryCatch({
    layout <- ggplot2::ggplot_build(plot)$layout$layout
    max(1L, length(unique(layout$PANEL)))
  }, error = function(e) 1L)
}

pp_resolve_qa_context <- function(plot, preset, width = NULL, context = list()) {
  preset_values <- pp_output_preset(preset)
  stored <- attr(plot, "pp_qa_context") %||% list()
  merged <- utils::modifyList(stored, context, keep.null = TRUE)
  expected_panels <- merged$expected_panels %||% pp_infer_panel_count(plot)
  if (expected_panels <= 1L) expected_panels <- NULL
  merged$expected_panels <- expected_panels
  merged$layout_profile <- merged$layout_profile %||% if (!is.null(expected_panels)) "equal" else "auto"
  merged$target_width_mm <- merged$target_width_mm %||% ((width %||% preset_values$width_cm) * 10)
  merged$journal_profile <- merged$journal_profile %||% if (grepl("nature", preset, fixed = TRUE)) "nature" else "generic"
  merged$allow_grid <- merged$allow_grid %||% "auto"
  merged
}

pp_qa_context_args <- function(context) {
  args <- c("--ocr", "off")
  if (!is.null(context$family) && nzchar(context$family)) args <- c(args, "--family", shQuote(context$family))
  if (!is.null(context$expected_panels)) args <- c(args, "--expected-panels", as.character(context$expected_panels))
  if (!is.null(context$layout_profile)) args <- c(args, "--layout-profile", context$layout_profile)
  if (!is.null(context$target_width_mm)) args <- c(args, "--target-width-mm", as.character(context$target_width_mm))
  if (!is.null(context$journal_profile)) args <- c(args, "--journal-profile", context$journal_profile)
  if (!is.null(context$allow_grid)) args <- c(args, "--allow-grid", context$allow_grid)
  args
}

pp_locate_qa_script <- function() {
  env <- Sys.getenv("PAPERPLOT_QA_SCRIPT", unset = "")
  if (nzchar(env) && file.exists(env)) return(normalizePath(env))
  rel_candidates <- c(
    file.path("paperplot-skills", "scripts", "visual-qa-rendered-image.py"),
    file.path("scripts", "visual-qa-rendered-image.py")
  )
  dir <- getwd()
  for (i in 1:5) {
    for (cand in rel_candidates) {
      path <- file.path(dir, cand)
      if (file.exists(path)) return(normalizePath(path))
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) break
    dir <- parent
  }
  NULL
}

pp_python_supports_visual_qa <- function(python) {
  if (is.null(python) || !nzchar(python)) return(FALSE)
  status <- tryCatch(
    suppressWarnings(system2(python, c("-c", shQuote("import PIL")), stdout = FALSE, stderr = FALSE)),
    error = function(e) 127L
  )
  identical(as.integer(status), 0L)
}

pp_resolve_qa_python <- function() {
  configured <- Sys.getenv("PAPERPLOT_PYTHON", unset = "")
  if (nzchar(configured)) return(configured)
  candidates <- unique(c(
    unname(Sys.which("python3")),
    unname(Sys.which("python")),
    Sys.getenv("CONDA_PYTHON_EXE", unset = "")
  ))
  candidates <- candidates[nzchar(candidates)]
  hit <- candidates[vapply(candidates, pp_python_supports_visual_qa, logical(1))]
  if (length(hit)) hit[[1]] else NULL
}

# Run rendered-image QA and always return an auditable availability result.
pp_run_visual_qa <- function(path, out_dir = tempfile("pp-qa-"), extra_args = character()) {
  script <- pp_locate_qa_script()
  if (is.null(script)) return(list(available = FALSE, status = "unavailable", qa_dir = out_dir, error = "visual QA script not found"))
  py <- pp_resolve_qa_python()
  if (is.null(py)) return(list(available = FALSE, status = "unavailable", qa_dir = out_dir, error = "no Python interpreter with Pillow was found; set PAPERPLOT_PYTHON"))
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  output <- tryCatch(
    suppressWarnings(system2(py, c(shQuote(script), shQuote(path), "--out", shQuote(out_dir), extra_args), stdout = TRUE, stderr = TRUE)),
    error = function(e) structure(conditionMessage(e), status = 127L)
  )
  status <- attr(output, "status") %||% 0L
  json_path <- file.path(out_dir, "visual_qa.json")
  if (!identical(as.integer(status), 0L) || !file.exists(json_path)) {
    return(list(available = FALSE, status = "unavailable", qa_dir = out_dir,
                error = paste(output, collapse = "\n")))
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return(list(available = FALSE, status = "unavailable", qa_dir = out_dir, error = "R package jsonlite is unavailable"))
  }
  payload <- tryCatch(jsonlite::fromJSON(json_path, simplifyVector = FALSE)$image_qa, error = function(e) NULL)
  if (is.null(payload)) return(list(available = FALSE, status = "unavailable", qa_dir = out_dir, error = "visual_qa.json could not be parsed"))
  payload$available <- TRUE
  payload$qa_dir <- out_dir
  payload
}

# Apply whitelisted machine fixes from visual QA onto a ggplot object.
# Only parameters with explicit branches here are ever applied; everything
# else stays prose for human/agent review.
pp_apply_machine_fixes <- function(plot, qa_payload) {
  fixes <- qa_payload$machine_fixes %||% list()
  applied <- character()
  angle_x <- NULL; hjust_x <- NULL
  margin_mm <- NULL; key_mm <- NULL; legend_pos <- NULL
  for (f in fixes) {
    param <- f$param; value <- f$value
    if (is.null(param)) next
    switch(param,
      "legend.position" = { if (value %in% c("bottom", "right", "none")) legend_pos <- value },
      "legend.key.size_mm" = {
        candidate <- suppressWarnings(as.numeric(value))
        if (length(candidate) == 1L && is.finite(candidate) && candidate >= 2 && candidate <= 8) key_mm <- candidate
      },
      "plot.margin_mm" = {
        candidate <- suppressWarnings(as.numeric(value))
        if (length(candidate) == 1L && is.finite(candidate) && candidate >= 0.5 && candidate <= 8) margin_mm <- candidate
      },
      "axis.text.x.angle" = {
        candidate <- suppressWarnings(as.numeric(value))
        if (length(candidate) == 1L && candidate %in% c(0, 30, 45, 90)) angle_x <- candidate
      },
      "axis.text.x.hjust" = {
        candidate <- suppressWarnings(as.numeric(value))
        if (length(candidate) == 1L && is.finite(candidate) && candidate >= 0 && candidate <= 1) hjust_x <- candidate
      },
      # label_repel requires rebuilding geoms; report it instead of guessing.
      "label_repel" = applied <- c(applied, "label_repel (manual: rebuild text layers with ggrepel)")
    )
  }
  th <- ggplot2::theme()
  if (!is.null(legend_pos)) {
    th <- th + ggplot2::theme(legend.position = legend_pos)
    applied <- c(applied, paste0("legend.position=", legend_pos))
  }
  if (!is.null(key_mm)) {
    th <- th + ggplot2::theme(legend.key.size = grid::unit(key_mm, "mm"))
    applied <- c(applied, paste0("legend.key.size=", key_mm, "mm"))
  }
  if (!is.null(margin_mm)) {
    th <- th + ggplot2::theme(plot.margin = ggplot2::margin(margin_mm, margin_mm, margin_mm, margin_mm, unit = "mm"))
    applied <- c(applied, paste0("plot.margin=", margin_mm, "mm"))
  }
  if (!is.null(angle_x)) {
    th <- th + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = angle_x, hjust = if (!is.null(hjust_x)) hjust_x else 1))
    applied <- c(applied, paste0("axis.text.x.angle=", angle_x))
  }
  if (length(applied)) plot <- plot + th
  attr(plot, "pp_machine_fixes_applied") <- applied
  attr(plot, "pp_machine_fixes_requested") <- vapply(fixes, function(f) f$param %||% "", character(1))
  plot
}

pp_qa_candidate_improved <- function(initial, candidate) {
  rank <- c(unavailable = 0L, fail = 1L, warn = 2L, pass = 3L)
  initial_status <- initial$status %||% "unavailable"
  candidate_status <- candidate$status %||% "unavailable"
  initial_rank <- if (initial_status %in% names(rank)) unname(rank[[initial_status]]) else 0L
  candidate_rank <- if (candidate_status %in% names(rank)) unname(rank[[candidate_status]]) else 0L
  if (candidate_rank > initial_rank) return(TRUE)
  if (candidate_rank < initial_rank) return(FALSE)
  initial_score <- suppressWarnings(as.numeric(initial$manuscript_readiness_score %||% NA_real_))
  candidate_score <- suppressWarnings(as.numeric(candidate$manuscript_readiness_score %||% NA_real_))
  is.finite(initial_score) && is.finite(candidate_score) && candidate_score > initial_score
}

# Save PDF+PNG, run rendered-image QA, apply at most one whitelisted visual
# retry, then always QA the retried output before reporting final status.
pp_save_all_with_qa_loop <- function(plot, output_stem, preset = "nature_half", formats = c("pdf", "png"),
                                     max_iterations = 1L, overwrite = FALSE, width = NULL, height = NULL,
                                     dpi = NULL, qa_context = list(), qa_out_dir = paste0(output_stem, "_visual_qa"), ...) {
  if (!isTRUE(overwrite) && dir.exists(qa_out_dir)) stop("Refusing to overwrite existing QA directory: ", qa_out_dir, call. = FALSE)
  plot <- pp_finalize(plot)
  initial_plot <- plot
  context <- pp_resolve_qa_context(plot, preset = preset, width = width, context = qa_context)
  output_files <- pp_save_all(plot, output_stem, preset = preset, formats = formats,
                              overwrite = overwrite, width = width, height = height, dpi = dpi,
                              finalize_plot = FALSE, ...)
  iterations <- 0L
  all_fixes <- character()
  png_file <- if ("png" %in% names(output_files)) output_files[["png"]]
  qa_args <- pp_qa_context_args(context)
  qa <- if (!is.null(png_file)) {
    pp_run_visual_qa(png_file, out_dir = file.path(qa_out_dir, "iteration-0"), extra_args = qa_args)
  } else {
    list(available = FALSE, status = "unavailable", qa_dir = qa_out_dir, error = "PNG preview was not requested")
  }
  initial_status <- qa$status %||% "unavailable"
  initial_qa <- qa
  rejected_fixes <- character()
  while (iterations < max_iterations && isTRUE(qa$available) && qa$status %in% c("warn", "fail")) {
    fixed <- pp_apply_machine_fixes(plot, qa)
    new_fixes <- attr(fixed, "pp_machine_fixes_applied")
    theme_fixes <- new_fixes[!grepl("manual:", new_fixes)]
    if (!length(theme_fixes)) break
    plot <- fixed
    all_fixes <- c(all_fixes, theme_fixes)
    iterations <- iterations + 1L
    output_files <- pp_save_all(plot, output_stem, preset = preset, formats = formats,
                                overwrite = TRUE, width = width, height = height, dpi = dpi,
                                finalize_plot = FALSE, ...)
    qa <- pp_run_visual_qa(png_file, out_dir = file.path(qa_out_dir, paste0("iteration-", iterations)), extra_args = qa_args)
  }
  if (iterations > 0L && !pp_qa_candidate_improved(initial_qa, qa)) {
    rejected_fixes <- all_fixes
    all_fixes <- character()
    output_files <- pp_save_all(initial_plot, output_stem, preset = preset, formats = formats,
                                overwrite = TRUE, width = width, height = height, dpi = dpi,
                                finalize_plot = FALSE, ...)
    qa <- initial_qa
  }
  attr(output_files, "qa_iterations") <- iterations
  attr(output_files, "qa_machine_fixes") <- all_fixes
  attr(output_files, "qa_machine_fixes_rejected") <- rejected_fixes
  attr(output_files, "qa_available") <- isTRUE(qa$available)
  attr(output_files, "qa_initial_status") <- initial_status
  attr(output_files, "qa_final_status") <- qa$status %||% "unavailable"
  attr(output_files, "qa_error") <- qa$error %||% NULL
  attr(output_files, "qa_context") <- context
  attr(output_files, "qa_final_dir") <- qa$qa_dir %||% qa_out_dir
  output_files
}

pp_save_plot <- function(plot, filename, preset = "nature_half", width = NULL, height = NULL,
                         dpi = NULL, units = "cm", overwrite = FALSE, validate_output = TRUE,
                         finalize_plot = TRUE,
                         text_floor_action = getOption("paperplot.text_floor_action", "error"), ...) {
  if (!isTRUE(overwrite) && file.exists(filename)) {
    stop("Refusing to overwrite existing output file: ", filename, call. = FALSE)
  }
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  preset_values <- pp_output_preset(preset)
  if (isTRUE(finalize_plot)) plot <- pp_finalize(plot)
  # Save-time gate (WP2): enforce the preset's promised minimum text size.
  # min_text_pt was defined on every output preset but never consumed; this
  # warning makes the floor real. Silence with PAPERPLOT_ALLOW_SMALL_TEXT=1.
  floor_pt <- preset_values$min_text_pt
  min_pt <- tryCatch(pp_min_rendered_text_pt(plot), error = function(e) NA_real_)
  allow_small <- identical(Sys.getenv("PAPERPLOT_ALLOW_SMALL_TEXT"), "1")
  text_floor_action <- if (allow_small) "off" else match.arg(text_floor_action, c("error", "warn", "off"))
  if (!identical(text_floor_action, "off") && !is.na(min_pt) && !is.null(floor_pt) && min_pt < floor_pt - 0.01) {
    message <- sprintf(
      "Text-size floor violated for '%s': smallest themed/labelled text is %.2f pt but preset '%s' requires >= %g pt. Raise base_size/label sizes, or set PAPERPLOT_ALLOW_SMALL_TEXT=1 only for a documented diagnostic exception.",
      basename(filename), min_pt, preset, floor_pt
    )
    if (identical(text_floor_action, "error")) stop(message, call. = FALSE) else warning(message, call. = FALSE)
  }
  device <- pp_default_device(filename)
  ggplot2::ggsave(
    filename = filename,
    plot = plot,
    width = width %||% preset_values$width_cm,
    height = height %||% preset_values$height_cm,
    units = units,
    dpi = dpi %||% preset_values$dpi,
    device = device,
    bg = "white",
    ...
  )
  if (isTRUE(validate_output)) pp_assert_output(filename)
  invisible(filename)
}

pp_save_all <- function(plot, output_stem, preset = "nature_half", formats = c("pdf", "png"),
                        overwrite = FALSE, width = NULL, height = NULL, dpi = NULL,
                        finalize_plot = TRUE, ...) {
  formats <- unique(tolower(formats))
  output_files <- stats::setNames(paste0(output_stem, ".", formats), formats)
  if (!isTRUE(overwrite)) pp_stop_if_outputs_exist(output_files)
  if (isTRUE(finalize_plot)) plot <- pp_finalize(plot)
  for (fmt in formats) {
    pp_save_plot(plot, output_files[[fmt]], preset = preset, width = width, height = height, dpi = dpi,
                 overwrite = overwrite, finalize_plot = FALSE, ...)
  }
  output_files
}

pp_format_output_files <- function(paths) {
  sizes <- file.info(unname(paths))[["size"]]
  paste0("- ", names(paths), ": ", unname(paths), " (", sizes, " bytes)")
}

pp_extend_output_files <- function(output_files, ...) {
  qa_attributes <- attributes(output_files)
  qa_attributes <- qa_attributes[grepl("^qa_", names(qa_attributes))]
  out <- c(output_files, ...)
  for (name in names(qa_attributes)) attr(out, name) <- qa_attributes[[name]]
  out
}

pp_data_summary <- function(df) {
  list(n_rows = nrow(df), n_columns = ncol(df), columns = names(df))
}

pp_json_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\"', x)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x
}

pp_to_json <- function(x, indent = 0) {
  sp <- paste(rep(" ", indent), collapse = "")
  sp2 <- paste(rep(" ", indent + 2), collapse = "")
  if (is.null(x)) return("null")
  if (inherits(x, "data.frame")) {
    rows <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
    return(pp_to_json(rows, indent = indent))
  }
  if (is.list(x) && !is.data.frame(x)) {
    if (length(x) == 0) return("{}")
    nms <- names(x)
    if (!is.null(nms) && all(nzchar(nms))) {
      parts <- vapply(seq_along(x), function(i) {
        paste0(sp2, '"', pp_json_escape(nms[[i]]), '": ', pp_to_json(x[[i]], indent + 2))
      }, character(1))
      return(paste0("{\n", paste(parts, collapse = ",\n"), "\n", sp, "}"))
    }
    parts <- vapply(x, pp_to_json, character(1), indent = indent + 2)
    return(paste0("[\n", paste(paste0(sp2, parts), collapse = ",\n"), "\n", sp, "]"))
  }
  if (is.logical(x)) return(ifelse(is.na(x), "null", ifelse(x, "true", "false")))
  if (is.numeric(x)) return(ifelse(is.na(x), "null", as.character(x)))
  if (length(x) > 1) return(pp_to_json(as.list(x), indent = indent))
  paste0('"', pp_json_escape(x), '"')
}

pp_write_metadata <- function(path, figure_spec, metric_spec = NULL, output_files,
                              layout = list(), palette = list(), ordering = list(),
                              qa = list(), data_summary = list()) {
  if (file.exists(path)) stop("Refusing to overwrite existing metadata file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  pp_validate_figure_spec(figure_spec)
  if (!is.null(metric_spec)) pp_validate_metric_spec(metric_spec)
  payload <- list(
    figure_id = figure_spec$figure_id,
    template_id = figure_spec$template_id,
    backend = figure_spec$backend,
    helper_version = figure_spec$helper_version,
    task_type = figure_spec$task_type,
    figure_role = figure_spec$figure_role,
    scientific_message = figure_spec$scientific_message,
    plot_type = figure_spec$plot_type,
    data = data_summary,
    metrics = metric_spec,
    ordering = ordering,
    style = list(theme = "pp_theme", palette = palette),
    layout = layout,
    export = as.list(output_files),
    qa = qa
  )
  writeLines(pp_to_json(payload), con = path)
  pp_assert_output(path)
  invisible(path)
}

pp_qa_result <- function(gate, status = "pass", note = "") {
  status <- match.arg(status, c("pass", "warn", "fail"))
  data.frame(gate = as.character(gate), status = status, note = as.character(note), stringsAsFactors = FALSE)
}

pp_as_qa_df <- function(x) {
  if (is.null(x)) return(data.frame(gate = character(), status = character(), note = character(), stringsAsFactors = FALSE))
  if (inherits(x, "data.frame")) return(x[, c("gate", "status", "note"), drop = FALSE])
  if (is.list(x) && all(c("gate", "status", "note") %in% names(x))) return(pp_qa_result(x$gate, x$status, x$note))
  stop("QA results must be data frames from pp_qa_result().", call. = FALSE)
}

pp_qa_summary <- function(...) {
  items <- list(...)
  dfs <- lapply(items, pp_as_qa_df)
  if (length(dfs) == 0) return(pp_as_qa_df(NULL))
  do.call(rbind, dfs)
}

pp_qa_status <- function(qa_results) {
  qa_results <- pp_as_qa_df(qa_results)
  if (nrow(qa_results) == 0) return("warn")
  if (any(qa_results$status == "fail")) return("fail")
  if (any(qa_results$status == "warn")) return("warn")
  "pass"
}

pp_qa_preflight <- function(figure_spec, metric_spec = NULL, label_strategy = NULL,
                            palette_check = NULL, layout_check = NULL) {
  pp_validate_figure_spec(figure_spec)
  results <- list(pp_qa_result("figure_spec", "pass", "required figure fields recorded"))
  if (!is.null(metric_spec)) {
    pp_validate_metric_spec(metric_spec)
    results <- c(results, list(pp_qa_result("metric_spec", "pass", "metric units, directions, transforms, and roles recorded")))
  }
  if (!is.null(label_strategy)) {
    results <- c(results, list(pp_qa_result("labels", label_strategy$status, label_strategy$message)))
  }
  if (!is.null(palette_check)) results <- c(results, list(palette_check))
  if (!is.null(layout_check)) results <- c(results, list(layout_check))
  do.call(pp_qa_summary, results)
}

pp_qa_postflight <- function(output_files, notes_path = NULL, metadata_path = NULL) {
  results <- list()
  for (nm in names(output_files)) {
    status <- if (file.exists(output_files[[nm]]) && file.info(output_files[[nm]])[["size"]] >= pp_min_output_size(output_files[[nm]])) "pass" else "fail"
    results <- c(results, list(pp_qa_result(paste0("output_", nm), status, output_files[[nm]])))
  }
  if (!is.null(notes_path)) {
    results <- c(results, list(pp_qa_result("notes", if (file.exists(notes_path)) "pass" else "fail", notes_path)))
  }
  if (!is.null(metadata_path)) {
    results <- c(results, list(pp_qa_result("metadata", if (file.exists(metadata_path)) "pass" else "fail", metadata_path)))
  }
  do.call(pp_qa_summary, results)
}

pp_write_qa_report <- function(path, qa_results) {
  if (file.exists(path)) stop("Refusing to overwrite existing QA report file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  qa_results <- pp_as_qa_df(qa_results)
  lines <- c(
    "# Figure QA Report",
    "",
    paste("- overall status:", pp_qa_status(qa_results)),
    "",
    "| gate | status | note |",
    "|---|---|---|",
    apply(qa_results, 1, function(row) paste0("| ", row[["gate"]], " | ", row[["status"]], " | ", row[["note"]], " |"))
  )
  writeLines(lines, con = path)
  pp_assert_output(path)
  invisible(path)
}

pp_export_manifest <- function(output_files, notes_path = NULL, metadata_path = NULL, qa_path = NULL) {
  c(output_files, notes = notes_path, metadata = metadata_path, qa = qa_path)
}

pp_write_notes <- function(path, figure_id, input_path, output_files, preset,
                           design_decisions = character(), qa_checks = character(),
                           remaining_issues = "None", figure_spec = NULL,
                           metric_spec = NULL, layout = list(), palette = list(),
                           ordering = list(), label_strategy = NULL,
                           data_summary = list()) {
  if (file.exists(path)) stop("Refusing to overwrite existing notes file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  metric_lines <- if (!is.null(metric_spec)) {
    c("| metric | label | unit | direction | transform | role |", "|---|---|---|---|---|---|",
      apply(metric_spec, 1, function(row) paste0("| ", paste(row[c("metric", "label", "unit", "direction", "transform", "role")], collapse = " | "), " |")))
  } else {
    "- No metric_spec recorded"
  }
  qa_lines <- if (length(qa_checks) > 0) paste0("- ", qa_checks) else "- Not recorded"
  label_line <- if (!is.null(label_strategy)) {
    paste0("- strategy: ", label_strategy$strategy, "; status: ", label_strategy$status, "; score: ", pp_format_number(label_strategy$score, 3))
  } else {
    "- strategy: not recorded"
  }
  layout_lines <- if (length(layout) > 0) paste0("- ", names(layout), ": ", unlist(layout, use.names = FALSE)) else "- Not recorded"
  palette_lines <- if (length(palette) > 0) paste0("- ", names(palette), ": ", unlist(palette, use.names = FALSE)) else "- Not recorded"
  ordering_lines <- if (length(ordering) > 0) paste0("- ", names(ordering), ": ", unlist(ordering, use.names = FALSE)) else "- Not recorded"
  lines <- c(
    "# Figure Notes",
    "",
    "## Figure Identity",
    paste("- figure id:", figure_id),
    paste("- template:", figure_spec$template_id %||% "not recorded"),
    paste("- backend:", figure_spec$backend %||% "R/ggplot2"),
    paste("- helper version:", pp_helper_version),
    "",
    "## Scientific Purpose",
    paste("- main message:", figure_spec$scientific_message %||% "not recorded"),
    paste("- figure role:", figure_spec$figure_role %||% "not recorded"),
    "",
    "## Data",
    paste("- input data:", input_path),
    paste("- rows:", data_summary$n_rows %||% "not recorded"),
    paste("- columns:", if (length(data_summary$columns %||% character()) > 0) paste(data_summary$columns, collapse = ", ") else "not recorded"),
    "",
    "## Variables and Metrics",
    metric_lines,
    "",
    "## Ordering",
    ordering_lines,
    "",
    "## Visual Design",
    paste("- preset:", preset),
    layout_lines,
    palette_lines,
    label_line,
    "- dependency policy: ggplot2 only; no PaperPlotR package dependency",
    "",
    "## Output Files",
    pp_format_output_files(output_files),
    "",
    "## Design Decisions",
    if (length(design_decisions) > 0) paste0("- ", design_decisions) else "- Not recorded",
    "",
    "## QA Gate",
    qa_lines,
    "",
    "## Known Limitations",
    paste0("- ", remaining_issues),
    "",
    "## Remaining Issues",
    paste0("- ", remaining_issues)
  )
  writeLines(lines, con = path)
  pp_assert_output(path)
  invisible(path)
}

# Design-intelligence modules are loaded after base helpers so they can reuse
# pp_to_json(), pp_qa_result(), and output assertion helpers while preserving
# backward compatibility for existing templates.
pp_helper_script_dir <- local({
  env_path <- Sys.getenv("PAPERPLOT_HELPER")
  if (nzchar(env_path) && file.exists(env_path)) return(dirname(normalizePath(env_path, mustWork = FALSE)))
  if (!is.null(pp_helper_source_file) && file.exists(pp_helper_source_file)) return(dirname(pp_helper_source_file))
  if (exists("helper_path", inherits = TRUE)) {
    hp <- get("helper_path", inherits = TRUE)
    if (nzchar(hp) && file.exists(hp)) return(dirname(normalizePath(hp, mustWork = FALSE)))
  }
  file.path(getwd(), "paperplot-skills", "scripts")
})

pp_source_helper_module <- function(filename) {
  path <- file.path(pp_helper_script_dir, "lib", filename)
  if (file.exists(path)) source(path, local = FALSE)
  invisible(path)
}

invisible(lapply(c("design-brief.R", "label-strategy.R", "design-qa.R"), pp_source_helper_module))

# Override metadata writer to include design-intelligence fields while keeping
# the old call signature valid for templates that have not yet been upgraded.
pp_write_metadata <- function(path, figure_spec, metric_spec = NULL, output_files,
                              layout = list(), palette = list(), ordering = list(),
                              qa = list(), data_summary = list(), design_brief = NULL,
                              design_plan = NULL, data_profile = NULL,
                              visual_budget = NULL, label_strategy = NULL,
                              palette_plan = NULL, panel_hierarchy = list(),
                              redraw_strategy = list(), statistical_plan = list(),
                              optional_dependencies = list(), sidecars = list()) {
  if (file.exists(path)) stop("Refusing to overwrite existing metadata file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  pp_validate_figure_spec(figure_spec)
  if (!is.null(metric_spec)) pp_validate_metric_spec(metric_spec)
  design_brief <- design_brief %||% pp_design_brief(
    scientific_message = figure_spec$scientific_message,
    figure_role = figure_spec$figure_role %||% "main",
    data_roles = list(sample_id = figure_spec$sample_id, group_var = figure_spec$group_var),
    acceptable_simplifications = "not specified by template",
    must_show = "scientific message",
    may_move_to_metadata = "lookup details"
  )
  design_plan <- design_plan %||% pp_design_plan(
    chart_family = figure_spec$plot_type,
    figure_role = design_brief$figure_role,
    layout_plan = layout,
    label_strategy = label_strategy %||% list(strategy = "not recorded"),
    palette_plan = palette_plan %||% palette,
    panel_hierarchy = panel_hierarchy,
    statistical_plan = statistical_plan,
    visible_simplifications = design_brief$acceptable_simplifications,
    risks = character()
  )
  pattern_reference <- design_plan$pattern_reference
  if (is.null(pattern_reference) || length(pattern_reference) == 0) {
    pattern_reference <- pp_pattern_reference(figure_spec$plot_type, template_id = figure_spec$template_id)
    design_plan$pattern_reference <- pattern_reference
  }
  data_profile <- data_profile %||% data_summary
  visual_budget <- visual_budget %||% list(status = "not recorded")
  qa_loop <- list(
    available = attr(output_files, "qa_available") %||% FALSE,
    initial_status = attr(output_files, "qa_initial_status") %||% "not_run",
    final_status = attr(output_files, "qa_final_status") %||% "not_run",
    iterations = attr(output_files, "qa_iterations") %||% 0L,
    machine_fixes = attr(output_files, "qa_machine_fixes") %||% character(),
    rejected_machine_fixes = attr(output_files, "qa_machine_fixes_rejected") %||% character(),
    context = attr(output_files, "qa_context") %||% list(),
    final_qa_dir = attr(output_files, "qa_final_dir") %||% NULL,
    error = attr(output_files, "qa_error") %||% NULL
  )
  payload <- list(
    figure_id = figure_spec$figure_id,
    template_id = figure_spec$template_id,
    backend = figure_spec$backend,
    helper_version = figure_spec$helper_version,
    task_type = figure_spec$task_type,
    figure_role = figure_spec$figure_role,
    scientific_message = figure_spec$scientific_message,
    plot_type = figure_spec$plot_type,
    figure_spec = figure_spec,
    metric_spec = metric_spec,
    design_brief = design_brief,
    design_plan = design_plan,
    pattern_reference = pattern_reference,
    data_profile = data_profile,
    data = data_summary,
    metrics = metric_spec,
    ordering = ordering,
    visual_budget = visual_budget,
    label_strategy = label_strategy,
    palette_plan = palette_plan %||% palette,
    style = list(theme = "pp_theme", palette = palette),
    panel_hierarchy = panel_hierarchy,
    redraw_strategy = redraw_strategy,
    statistical_plan = statistical_plan,
    optional_dependencies = optional_dependencies,
    layout = layout,
    export = as.list(output_files),
    sidecars = sidecars,
    qa = qa,
    qa_loop = qa_loop,
    outputs = as.list(output_files)
  )
  writeLines(pp_to_json(payload), con = path)
  pp_assert_output(path)
  invisible(path)
}

# Override notes writer so old and new templates both emit the design-aware
# sections required by validate-figure-output.R.
pp_write_notes <- function(path, figure_id, input_path, output_files, preset,
                           design_decisions = character(), qa_checks = character(),
                           remaining_issues = "None", figure_spec = NULL,
                           metric_spec = NULL, layout = list(), palette = list(),
                           ordering = list(), label_strategy = NULL,
                           data_summary = list(), design_brief = NULL,
                           design_plan = NULL) {
  if (file.exists(path)) stop("Refusing to overwrite existing notes file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (is.null(design_brief) && !is.null(figure_spec)) {
    design_brief <- pp_design_brief(
      scientific_message = figure_spec$scientific_message,
      figure_role = figure_spec$figure_role %||% "main",
      data_roles = list(sample_id = figure_spec$sample_id, group_var = figure_spec$group_var),
      acceptable_simplifications = "not specified by template",
      must_show = "scientific message",
      may_move_to_metadata = "lookup details"
    )
  }
  if (is.null(design_plan) && !is.null(figure_spec)) {
    design_plan <- pp_design_plan(
      chart_family = figure_spec$plot_type,
      figure_role = figure_spec$figure_role %||% "main",
      layout_plan = layout,
      label_strategy = label_strategy %||% list(strategy = "not recorded"),
      palette_plan = palette,
      visible_simplifications = if (!is.null(design_brief)) design_brief$acceptable_simplifications else "not specified",
      risks = character()
    )
  }
  pattern_reference <- NULL
  if (!is.null(design_plan)) {
    pattern_reference <- design_plan$pattern_reference
    if (is.null(pattern_reference) || length(pattern_reference) == 0) {
      pattern_reference <- pp_pattern_reference(design_plan$chart_family %||% figure_spec$plot_type, template_id = figure_spec$template_id)
      design_plan$pattern_reference <- pattern_reference
    }
  }
  metric_lines <- if (!is.null(metric_spec)) {
    c("| metric | label | unit | direction | transform | role |", "|---|---|---|---|---|---|",
      apply(metric_spec, 1, function(row) paste0("| ", paste(row[c("metric", "label", "unit", "direction", "transform", "role")], collapse = " | "), " |")))
  } else {
    "- No metric_spec recorded"
  }
  qa_lines <- if (length(qa_checks) > 0) paste0("- ", qa_checks) else "- Not recorded"
  layout_lines <- if (length(layout) > 0) paste0("- ", names(layout), ": ", unlist(layout, use.names = FALSE)) else "- Not recorded"
  palette_lines <- if (length(palette) > 0) paste0("- ", names(palette), ": ", unlist(palette, use.names = FALSE)) else "- Not recorded"
  ordering_lines <- if (length(ordering) > 0) paste0("- ", names(ordering), ": ", unlist(ordering, use.names = FALSE)) else "- Not recorded"
  label_lines <- if (!is.null(label_strategy)) paste0("- ", names(label_strategy), ": ", unlist(label_strategy, use.names = FALSE)) else "- strategy: not recorded"
  moved <- if (!is.null(design_brief) && length(design_brief$may_move_to_metadata) > 0) paste0("- ", design_brief$may_move_to_metadata) else "- Not recorded"
  visible <- if (!is.null(design_plan) && length(design_plan$visible_simplifications) > 0) paste0("- ", design_plan$visible_simplifications) else "- Not recorded"
  pattern_lines <- if (!is.null(pattern_reference) && length(pattern_reference) > 0) {
    vapply(names(pattern_reference), function(nm) {
      paste0("- ", nm, ": ", paste(unlist(pattern_reference[[nm]], use.names = FALSE), collapse = ", "))
    }, character(1))
  } else {
    "- Not recorded"
  }
  lines <- c(
    "# Figure Notes",
    "",
    "## Scientific Message",
    paste("-", if (!is.null(design_brief)) design_brief$scientific_message else figure_spec$scientific_message %||% "not recorded"),
    "",
    "## Figure Role",
    paste("-", if (!is.null(design_brief)) design_brief$figure_role else figure_spec$figure_role %||% "not recorded"),
    "",
    "## Visible Design Choices",
    visible,
    "",
    "## Information Moved Out Of The Visible Figure",
    moved,
    "",
    "## Label Strategy",
    label_lines,
    "",
    "## Sample Order / Rank Index",
    ordering_lines,
    "",
    "## Palette Semantics",
    palette_lines,
    "",
    "## Pattern Library Reference",
    pattern_lines,
    "",
    "## Statistical Expression",
    "- Not recorded unless supplied by template",
    "",
    "## Redraw Strategy",
    "- Not recorded unless supplied by template",
    "",
    "## Data",
    paste("- input data:", input_path),
    paste("- rows:", data_summary$n_rows %||% "not recorded"),
    paste("- columns:", if (length(data_summary$columns %||% character()) > 0) paste(data_summary$columns, collapse = ", ") else "not recorded"),
    "",
    "## Variables and Metrics",
    metric_lines,
    "",
    "## Layout",
    layout_lines,
    "",
    "## Output Files",
    pp_format_output_files(output_files),
    "",
    "## Design Decisions",
    if (length(design_decisions) > 0) paste0("- ", design_decisions) else "- Not recorded",
    "",
    "## QA Gate",
    qa_lines,
    "",
    "## Known Limitations",
    paste0("- ", remaining_issues),
    "",
    "## Files Generated",
    pp_format_output_files(output_files),
    "",
    "## Remaining Issues",
    paste0("- ", remaining_issues)
  )
  writeLines(lines, con = path)
  pp_assert_output(path)
  invisible(path)
}

# Additional design-intelligence modules loaded after initial Phase 1 modules.
invisible(lapply(c("redraw-strategy.R", "layout-planner.R"), pp_source_helper_module))

# Statistical expression helpers.
invisible(lapply(c("statistical-expression.R"), pp_source_helper_module))

# Bioinformatics semantics helpers.
invisible(lapply(c("bioinformatics-semantics.R"), pp_source_helper_module))
