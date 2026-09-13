# Physical production contract. Low-level pp_finalize() remains compatible.
pp_render_spec <- function(n_panels = 1L, case = NULL, width_mm = NULL, height_mm = NULL,
                           mode = Sys.getenv("PAPERPLOT_MODE", "production"),
                           text_pt = list(), ocr = "auto", human_review = "pending") {
  mode <- match.arg(mode, c("production", "preview", "demo"))
  if (length(n_panels) != 1L || !is.finite(n_panels) || n_panels < 1) stop("Invalid panel count.")
  sizes <- list(panel_tag = 12, panel_title = 7, axis_title = 7, species = 6.5,
                tick = 6, legend = 6, caption = 6, annotation = 6.5, body = 7)
  if (length(setdiff(names(text_pt), names(sizes)))) stop("Unknown text role.")
  sizes <- utils::modifyList(sizes, text_pt)
  if (any(!is.finite(unlist(sizes)) | unlist(sizes) <= 0)) stop("Invalid text sizes.")
  if (!is.null(case) && !identical(case, "igs")) stop("Unknown render case.")
  width_mm <- width_mm %||% if (identical(case, "igs")) 183 else if (n_panels > 1) 180 else 89
  height_mm <- height_mm %||% if (identical(case, "igs")) 105 else if (n_panels > 1) 120 else 62
  if (any(!is.finite(c(width_mm, height_mm))) || min(width_mm, height_mm) <= 0) stop("Invalid canvas size.")
  if (height_mm > 170) warning("Canvas exceeds 170 mm: consider splitting; text sizes are unchanged.", call. = FALSE)
  list(version = "1.0", mode = mode, case = case, n_panels = n_panels,
       width_mm = width_mm, height_mm = height_mm, dpi = 600, family = "Arial",
       text_pt = sizes, text_overrides = names(text_pt), ocr = match.arg(ocr, c("auto", "off", "required")),
       human_review = match.arg(human_review, c("pending", "pass", "fail")),
       stroke_pt = list(axis = 0.6, tick = 0.5, connector = 0.4, threshold = 0.5, separator = 0.25),
       tick_length_pt = 2.2, tolerance = list(page_mm = 0.1, font_pt = 0.2, row_mm = 0.2),
       identity_colors = c(">=0.95" = "#173B73", "0.90-0.95" = "#337FB8", "0.85-0.90" = "#73ADD0",
                           "0.80-0.85" = "#C2D7EA", "<0.80" = "#ECECEC"),
       markers = list(median = list(shape = 16, color = "#173B73", diameter_pt = 4.5),
                      max = list(shape = 17, color = "#D55E00", diameter_pt = 5)))
}

pp_arial_faces <- function(fonts = NULL) {
  if (is.null(fonts)) {
    if (!requireNamespace("systemfonts", quietly = TRUE)) return(stats::setNames(rep(FALSE, 3), c("regular", "bold", "italic")))
    fonts <- systemfonts::system_fonts()
  }
  styles <- tolower(fonts$style[tolower(fonts$family) == "arial"])
  c(regular = any(styles %in% c("regular", "normal", "roman")),
    bold = any(styles == "bold"), italic = any(styles %in% c("italic", "oblique")))
}

pp_check_environment <- function(composite = FALSE) {
  packages <- c("ggplot2", "jsonlite", "systemfonts", "ragg", "svglite", if (composite) "patchwork")
  available <- vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  faces <- pp_arial_faces()
  commands <- Sys.which(c("pdffonts", "pdftotext", "pdfinfo", "pdftoppm"))
  py <- pp_resolve_qa_python()
  pypdf <- !is.null(py) && identical(as.integer(suppressWarnings(system2(py,
    c("-c", shQuote("import pypdf")), stdout = FALSE, stderr = FALSE))), 0L)
  list(preview_available = isTRUE(available[["ggplot2"]]),
       production_available = all(available) && all(faces) && all(nzchar(commands)) && !is.null(py) && pypdf,
       packages = as.list(available), arial_faces = as.list(faces), commands = as.list(commands),
       python = py, pypdf = pypdf,
       instructions = "Install missing R packages in a matching R library; install licensed Arial Regular/Bold/Italic, Poppler, and Python Pillow/pypdf. No installation was performed.")
}

pp_production_theme <- function(spec) {
  s <- spec$text_pt
  pt_mm <- 25.4 / 72
  # ggplot linewidth uses its historical 0.75 mm unit; calibrate against PDF strokes.
  line_unit <- 0.75
  ggplot2::theme(
    text = ggplot2::element_text(family = "Arial", size = s$body, face = "plain", colour = "#222222"),
    axis.title = ggplot2::element_text(family = "Arial", size = s$axis_title, face = "plain"),
    axis.title.x = ggplot2::element_text(family = "Arial", size = s$axis_title, face = "plain"),
    axis.title.y = ggplot2::element_text(family = "Arial", size = s$axis_title, face = "plain"),
    axis.text = ggplot2::element_text(family = "Arial", size = s$tick, face = "plain"),
    legend.text = ggplot2::element_text(family = "Arial", size = s$legend, face = "plain"),
    legend.title = ggplot2::element_text(family = "Arial", size = s$legend, face = "plain"),
    strip.text = ggplot2::element_text(family = "Arial", size = s$panel_title, face = "plain"),
    plot.title = ggplot2::element_text(family = "Arial", size = s$panel_title, face = "plain"),
    plot.subtitle = ggplot2::element_text(family = "Arial", size = s$body, face = "plain"),
    plot.caption = ggplot2::element_text(family = "Arial", size = s$caption, face = "plain"),
    plot.tag = ggplot2::element_text(family = "Arial", size = s$panel_tag, face = "bold"),
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.key = ggplot2::element_rect(fill = "white", colour = NA),
    panel.border = ggplot2::element_blank(),
    axis.line = ggplot2::element_line(linewidth = spec$stroke_pt$axis * pt_mm / line_unit, colour = "#333333"),
    axis.ticks = ggplot2::element_line(linewidth = spec$stroke_pt$tick * pt_mm / line_unit, colour = "#333333"),
    axis.ticks.length = grid::unit(spec$tick_length_pt, "bigpts"),
    panel.grid = ggplot2::element_blank(), panel.grid.major = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank())
}

pp_normalize_production <- function(plot, spec) {
  if (!inherits(plot, "ggplot")) stop("Production renderer requires ggplot or patchwork; unsupported objects remain preview-only.")
  out <- unserialize(serialize(plot, NULL))
  changes <- list()
  normalize_one <- function(p) {
    if (inherits(p, "patchwork")) p$patches$plots <- lapply(p$patches$plots, normalize_one)
    theme <- p$theme
    changes[[length(changes) + 1L]] <<- lapply(theme[vapply(theme, inherits, logical(1), "element_text")], function(x) list(size = x$size, family = x$family))
    # Remove child size/family/face overrides while preserving blanks, margins and angles.
    for (nm in names(theme)) if (inherits(theme[[nm]], "element_text")) {
      theme[[nm]]$size <- NULL; theme[[nm]]$family <- NULL; theme[[nm]]$face <- NULL
    }
    p$theme <- theme + pp_production_theme(spec)
    for (nm in names(p$theme)) {
      if (grepl("^axis\\.(line|ticks)\\.", nm) && inherits(p$theme[[nm]], "element_line")) {
        p$theme[[nm]]$linewidth <- NULL; p$theme[[nm]]$colour <- NULL
      }
      if (grepl("^panel.grid", nm)) p$theme[[nm]] <- ggplot2::element_blank()
    }
    for (i in seq_along(p$layers)) {
      lr <- p$layers[[i]]
      if (any(class(lr$position) %in% c("PositionJitter", "PositionJitterdodge"))) lr$position$seed <- 104729L
      if (any(class(lr$geom) %in% c("GeomText", "GeomLabel", "GeomTextRepel", "GeomLabelRepel"))) {
        if (!is.null(lr$mapping$size) || !is.null(p$mapping$size)) stop("Mapped text size needs an explicit semantic design; normalization stopped.")
        role <- attr(lr, "pp_text_role") %||% "annotation"
        if (!role %in% names(spec$text_pt)) stop("Unknown text layer role.")
        changes[[length(changes) + 1L]] <<- list(layer = i, role = role, before_size = lr$aes_params$size, after_pt = spec$text_pt[[role]])
        lr$aes_params$family <- "Arial"
        lr$aes_params$size <- spec$text_pt[[role]] / ggplot2::.pt
        if (!is.null(lr$geom_params$size.unit)) lr$geom_params$size.unit <- "mm"
        lr$aes_params$fontface <- if (role == "panel_tag") "bold" else "plain"
      }
      p$layers[[i]] <- lr
    }
    if (isTRUE(attr(p, "pp_species_axis"))) p <- p + ggplot2::theme(axis.text.y = ggplot2::element_text(family = "Arial", size = spec$text_pt$species))
    p
  }
  out <- normalize_one(out)
  if (inherits(out, "patchwork")) {
    out <- out + patchwork::plot_annotation(tag_levels = "A", theme = pp_production_theme(spec))
    out <- out & ggplot2::theme(plot.tag = ggplot2::element_text(family = "Arial", size = spec$text_pt$panel_tag, face = "bold"))
  }
  if (spec$mode == "demo") out <- out + ggplot2::labs(caption = "DEMO / simulated test data")
  attr(out, "pp_style_changes") <- changes
  out
}

pp_plot_evidence <- function(plot) {
  old <- if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) get(".Random.seed", .GlobalEnv) else NULL
  on.exit(if (is.null(old)) { if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv) } else assign(".Random.seed", old, .GlobalEnv))
  set.seed(104729L)
  if (inherits(plot, "patchwork")) {
    last <- plot; last$patches <- NULL; class(last) <- setdiff(class(last), "patchwork")
    return(lapply(c(plot$patches$plots, list(last)), pp_plot_evidence))
  }
  built <- ggplot2::ggplot_build(plot)
  fields <- c("x", "y", "xmin", "xmax", "ymin", "ymax", "xend", "yend", "PANEL", "group", "count", "density", "value", "label")
  list(input = plot$data, layers = lapply(plot$layers, function(lr) lr$data),
       coordinates = lapply(built$data, function(d) d[intersect(fields, names(d))]))
}

pp_assert_data_unchanged <- function(before, after, tolerance = 1e-10) {
  if (!isTRUE(all.equal(before, after, tolerance = tolerance, check.attributes = TRUE))) {
    stop("Data integrity failure: input/order/statistics or plotted coordinates changed.", call. = FALSE)
  }
  invisible(TRUE)
}

pp_final_qa <- function(checks, human_review = "pending", mode = "production") {
  values <- unlist(checks, use.names = FALSE)
  if (any(!values %in% c("pass", "warn", "fail", "unverified"))) stop("Invalid QA state.")
  status <- if (any(values == "fail") || human_review == "fail") "fail" else if (any(values != "pass") || human_review != "pass" || mode != "production") "warn" else "pass"
  list(status = status, tier = if (status == "pass") "manuscript-ready" else if (status == "fail") "analysis sketch" else "manuscript candidate",
       checks = checks, human_review = human_review, mode = mode, score_deprecated = TRUE)
}

pp_scientific_labels <- function(genus_species, suffix = rep("", length(genus_species))) {
  if (length(suffix) != length(genus_species)) stop("Species/suffix length mismatch.")
  as.expression(Map(function(name, extra) bquote(italic(.(name)) ~ plain(.(extra))), genus_species, suffix))
}

pp_shared_rows <- function(plots, species_order, labels = species_order) {
  if (anyDuplicated(species_order)) stop("Species order must be unique.")
  lapply(plots, function(p) p + ggplot2::scale_y_discrete(limits = rev(species_order), labels = rev(labels), drop = FALSE,
                                                       expand = ggplot2::expansion(add = 0.6)))
}

pp_compose_manuscript <- function(plots, design = NULL, widths = NULL, heights = NULL,
                                  species_order = NULL, species_labels = species_order) {
  if (!requireNamespace("patchwork", quietly = TRUE)) stop("patchwork is required for heterogeneous manuscript panels.")
  if (!is.null(species_order)) plots <- pp_shared_rows(plots, species_order, species_labels)
  out <- patchwork::wrap_plots(plots, design = design, widths = widths, heights = heights,
                                ncol = if (is.null(design)) 2 else NULL, guides = "keep")
  attr(out, "pp_expected_panels") <- length(plots)
  if (!is.null(species_order) && is.character(species_labels)) attr(out, "pp_shared_row_labels") <- species_labels
  out
}

pp_text_role <- function(layer, role) {
  attr(layer, "pp_text_role") <- role
  layer
}

pp_marker_size_pt <- function(size_pt, shape = 16L) {
  # grid filled symbols: circle diameter is .75 em, triangle height .875 em.
  # Use stroke=0 with these filled markers; SVG tests verify physical output.
  factor <- switch(as.character(shape), "16" = .75, "17" = .875, stop("No calibrated physical size for this marker shape."))
  size_pt / (factor * ggplot2::.pt)
}

pp_direct_labels <- function(mapping, data, gap_mm = 0.8, ...) {
  if (!requireNamespace("ggrepel", quietly = TRUE)) {
    stop("Collision-aware direct labels require ggrepel; otherwise supply a manually reviewed label layout. No labels were silently dropped.")
  }
  if (!is.numeric(gap_mm) || length(gap_mm) != 1L || !is.finite(gap_mm) || gap_mm < 0) stop("Invalid physical label clearance.")
  ggrepel::geom_text_repel(mapping = mapping, data = data, family = "Arial",
    size = 6.5 / ggplot2::.pt, seed = 104729L, max.overlaps = Inf,
    point.padding = grid::unit(gap_mm, "mm"), box.padding = grid::unit(gap_mm, "mm"), ...)
}

pp_apply_rank_labels <- function(plot, categories, strategy, sidecar) {
  if (!isTRUE(strategy$needs_label_key)) return(plot)
  key <- pp_rank_index_map(categories)
  pp_write_label_key(sidecar, key)
  replacements <- stats::setNames(as.character(key$rank_index), key$sample)
  # Relabel ticks without changing the data, factor order, or numeric positions.
  plot + ggplot2::scale_y_discrete(labels = function(x) unname(replacements[x]))
}

pp_igs_figure <- function(data, original_annotations = NULL) {
  required <- c("species", "suffix", "n", "p_ge95", "p90_95", "p85_90", "p80_85", "p_lt80", "median", "max")
  if (length(setdiff(required, names(data)))) stop("IGS data requires: ", paste(required, collapse = ", "))
  if (!nrow(data) || anyDuplicated(paste(data$species, data$suffix))) stop("IGS rows must have unique species/suffix keys.")
  numeric_fields <- setdiff(required, c("species", "suffix"))
  if (any(!vapply(data[numeric_fields], is.numeric, logical(1))) || any(!is.finite(as.matrix(data[numeric_fields])))) stop("IGS numeric fields must be finite.")
  pcols <- c("p_ge95", "p90_95", "p85_90", "p80_85", "p_lt80")
  if (any(as.matrix(data[pcols]) < 0) || any(abs(rowSums(data[pcols]) - 100) > 1e-6)) stop("IGS percentages must sum to 100; no normalization was performed.")
  if (any(data$n < 1 | data$n != floor(data$n) | data$median < 0 | data$max > 1 | data$median > data$max)) stop("Invalid IGS counts or summary values.")
  if (!is.null(original_annotations)) pp_assert_data_unchanged(original_annotations, data[names(original_annotations)])
  spec <- pp_render_spec(2, case = "igs")
  nrows <- nrow(data)
  d <- data; d$row <- rev(seq_len(nrows))
  labels <- pp_scientific_labels(d$species, d$suffix)
  rectangles <- do.call(rbind, lapply(seq_len(nrows), function(i) {
    edges <- c(0, cumsum(as.numeric(d[i, pcols])))
    data.frame(row = d$row[i], xmin = head(edges, -1), xmax = tail(edges, -1), band = names(spec$identity_colors))
  }))
  d$pct_label <- paste0(formatC(d$p_ge95, digits = 0, format = "f"), "%")
  # Small/zero bands are labelled outside their own band with a short leader.
  d$inside <- d$p_ge95 >= 10
  d$label_x <- ifelse(d$inside, d$p_ge95 / 2, d$p_ge95 + 4)
  d$label_color <- ifelse(d$inside, "white", "#173B73")
  yscale <- function() ggplot2::scale_y_continuous(breaks = d$row, labels = labels,
    limits = c(0.4, nrows + 0.6), expand = ggplot2::expansion(mult = 0))
  a <- ggplot2::ggplot() +
    ggplot2::geom_rect(data = rectangles, ggplot2::aes(xmin = xmin, xmax = xmax, ymin = row - .35, ymax = row + .35, fill = band),
                       colour = "white", linewidth = .25 * 25.4 / 72 / .75) +
    ggplot2::geom_text(data = d, ggplot2::aes(x = label_x, y = row, label = pct_label, colour = label_color)) +
    ggplot2::geom_segment(data = d[!d$inside, , drop = FALSE],
      ggplot2::aes(x = p_ge95, xend = label_x - 1.5, y = row - .18, yend = row - .18),
      linewidth = .25 * 25.4 / 72 / .75, colour = "#173B73") +
    ggplot2::scale_colour_identity() +
    ggplot2::geom_text(data = d, ggplot2::aes(x = 111, y = row, label = n), hjust = 1) +
    ggplot2::annotate("text", x = 111, y = nrows + .52, label = "n", hjust = 1) +
    ggplot2::scale_fill_manual(values = spec$identity_colors, breaks = names(spec$identity_colors), name = NULL) +
    ggplot2::scale_x_continuous(breaks = c(0, 25, 50, 75, 100), limits = c(0, 113), expand = ggplot2::expansion(mult = 0)) +
    yscale() + pp_theme() + ggplot2::theme(legend.position = "bottom") +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2)) +
    ggplot2::labs(x = "Comparable IGS units (%)", y = NULL, title = "Composition of IGS identity bands")
  b <- ggplot2::ggplot(d, ggplot2::aes(y = row)) +
    ggplot2::geom_segment(ggplot2::aes(x = median, xend = max, yend = row), colour = "#C9C9C9", linewidth = .4 * 25.4 / 72 / .75) +
    ggplot2::geom_vline(xintercept = .95, linetype = "dashed", colour = "#9A9A9A", linewidth = .5 * 25.4 / 72 / .75) +
    ggplot2::geom_point(ggplot2::aes(x = median, shape = "Median", colour = "Median"), size = pp_marker_size_pt(4.5, 16), stroke = 0) +
    ggplot2::geom_point(ggplot2::aes(x = max, shape = "Max", colour = "Max"), size = pp_marker_size_pt(5, 17), stroke = 0) +
    ggplot2::scale_shape_manual(values = c(Median = 16, Max = 17), breaks = c("Median", "Max"), name = NULL) +
    ggplot2::scale_colour_manual(values = c(Median = "#173B73", Max = "#D55E00"), breaks = c("Median", "Max"), name = NULL) +
    ggplot2::annotate("text", x = .95, y = nrows + .52, label = "0.95") +
    ggplot2::scale_x_continuous(limits = c(min(.7, min(d$median) - .02), 1.01), breaks = seq(.7, 1, .1), expand = ggplot2::expansion(mult = 0)) +
    yscale() + pp_theme() + ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(x = "Identity to B-type reference", y = NULL, title = "Median and maximum identity")
  attr(a, "pp_species_axis") <- TRUE; attr(b, "pp_species_axis") <- TRUE
  out <- pp_compose_manuscript(list(a, b), widths = c(1.15, 1))
  attr(out, "pp_render_spec") <- spec
  attr(out, "pp_shared_row_labels") <- d$species
  out
}

pp_read_recipe_data <- function(input_path, recipe_id, mode = "production") {
  manifest <- utils::read.csv(file.path(pp_helper_script_dir, "..", "recipes", "recipe_manifest.csv"), stringsAsFactors = FALSE)
  row <- manifest[manifest$recipe_id == recipe_id, , drop = FALSE]
  if (nrow(row) != 1L) stop("Unknown recipe id.")
  if (mode != "demo" && row$status %in% c("specialized_reference", "optional_backend_recipe", "reference_recipe", "benchmark_recipe")) {
    stop("This reference recipe needs a reviewed data-backed adapter; use demo only for simulated previews.")
  }
  if (!file.exists(input_path)) {
    if (mode != "demo") stop("Input file missing; synthetic fallback is only allowed in explicit demo mode.")
    return(pp_recipe_mock_data(recipe_id))
  }
  df <- utils::read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
  required <- strsplit(row$required_roles, ";", fixed = TRUE)[[1]]
  missing <- setdiff(required, names(df))
  if (length(missing)) stop("Missing required recipe fields: ", paste(missing, collapse = ", "))
  if (!nrow(df)) stop("Input data has no rows.")
  attr(df, "pp_input_md5") <- unname(tools::md5sum(input_path))
  df
}

pp_run_export_audit <- function(outputs, spec, output_stem) {
  py <- pp_resolve_qa_python()
  report <- paste0(output_stem, "_export_audit.json")
  if (is.null(py)) return(list(status = "unverified", reason = "Python/Pillow unavailable"))
  config <- paste0(output_stem, "_render_spec.json")
  writeLines(pp_to_json(spec), config)
  script <- file.path(pp_helper_script_dir, "export-audit.py")
  result <- suppressWarnings(system2(py, c(shQuote(script), "--spec", shQuote(config), "--out", shQuote(report),
    shQuote(unname(outputs[names(outputs) %in% c("pdf", "svg", "png")]))), stdout = TRUE, stderr = TRUE))
  if (!file.exists(report) || !requireNamespace("jsonlite", quietly = TRUE)) return(list(status = "unverified", reason = paste(result, collapse = "\n")))
  jsonlite::fromJSON(report, simplifyVector = FALSE)
}
