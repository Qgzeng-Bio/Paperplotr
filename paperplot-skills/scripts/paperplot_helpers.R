# Standalone helper functions for paperplot-skills.
# Dependencies: base R, grDevices, grid, tools, and ggplot2.

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("The standalone paperplot skill requires ggplot2.", call. = FALSE)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

pp_helper_version <- "standalone-0.5.0"
pp_figure_spec_schema_version <- 2L
pp_profile_last_checked <- "2026-08-12"

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
  cell = list(width_cm = 17.4, height_cm = 12.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  cell_half = list(width_cm = 8.5, height_cm = 6.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  nature = list(width_cm = 18.0, height_cm = 12.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  nature_half = list(width_cm = 8.9, height_cm = 6.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  ncomms = list(width_cm = 18.0, height_cm = 12.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  ncomms_half = list(width_cm = 9.0, height_cm = 6.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  single_column = list(width_cm = 8.8, height_cm = 6.2, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  double_column = list(width_cm = 17.8, height_cm = 12.0, dpi = 600, target_text_pt = 9, min_text_pt = 6),
  square = list(width_cm = 8.8, height_cm = 8.8, dpi = 600, target_text_pt = 9, min_text_pt = 6)
)

pp_journal_profiles <- list(
  general_scientific = list(
    single_cm = 8.8, intermediate_cm = 12.7, double_cm = 17.8, max_height_cm = 24.1,
    scope = "General research fallback",
    source_url = "", source_status = "local_fallback", last_checked = pp_profile_last_checked
  ),
  nature_like = list(
    single_cm = 8.9, intermediate_cm = NA_real_, double_cm = 18.0, max_height_cm = 17.0,
    scope = "Nature-like life-science and genomics layouts",
    source_url = "https://research-figure-guide.nature.com/", source_status = "project_baseline_verify_title", last_checked = pp_profile_last_checked
  ),
  nature_communications = list(
    single_cm = 9.0, intermediate_cm = NA_real_, double_cm = 18.0, max_height_cm = 17.0,
    scope = "Nature Communications project layouts",
    source_url = "https://research-figure-guide.nature.com/", source_status = "project_profile_verify_title", last_checked = pp_profile_last_checked
  ),
  cell_press = list(
    single_cm = 8.5, intermediate_cm = 11.4, double_cm = 17.4, max_height_cm = 20.0,
    scope = "Cell Press two-column research figures",
    source_url = "https://www.cell.com/information-for-authors/figure-guidelines", source_status = "official_reviewed", last_checked = pp_profile_last_checked
  ),
  medical_radiology = list(
    single_cm = 8.56, intermediate_cm = 12.8, double_cm = 17.35, max_height_cm = 23.34,
    scope = "Radiology-family journal figures",
    source_url = "", source_status = "imported_unverified", last_checked = pp_profile_last_checked
  )
)

pp_journal_profile <- function(name = "general_scientific") {
  key <- tolower(gsub("-", "_", as.character(name)))
  profile <- pp_journal_profiles[[key]]
  if (is.null(profile)) {
    stop("Unknown journal profile: ", name, ". See references/journal-specs-matrix.md.", call. = FALSE)
  }
  c(list(name = key), profile)
}

pp_profile_for_preset <- function(output_preset) {
  switch(tolower(pp_nonempty_scalar(output_preset, "output_preset")),
    cell =, cell_half = "cell_press",
    nature =, nature_half = "nature_like",
    ncomms =, ncomms_half = "nature_communications",
    "general_scientific"
  )
}

pp_preset_column_class <- function(output_preset) {
  switch(tolower(pp_nonempty_scalar(output_preset, "output_preset")),
    cell_half =, nature_half =, ncomms_half =, single_column =, square = "single",
    cell =, nature =, ncomms =, double_column = "double",
    "double"
  )
}

pp_validate_profile_geometry <- function(output_preset, journal_profile, width_cm = NULL, height_cm = NULL) {
  output_preset <- pp_nonempty_scalar(output_preset, "output_preset")
  profile <- pp_journal_profile(journal_profile)
  inferred <- pp_profile_for_preset(output_preset)
  branded <- tolower(output_preset) %in% c("cell", "cell_half", "nature", "nature_half", "ncomms", "ncomms_half")
  if (branded && !identical(profile$name, inferred)) {
    stop("Journal profile ", profile$name, " conflicts with branded preset ", output_preset, " (expected ", inferred, ").", call. = FALSE)
  }
  preset <- pp_output_presets[[tolower(output_preset)]]
  if (is.null(preset)) stop("Unknown output preset: ", output_preset, call. = FALSE)
  width_cm <- width_cm %||% preset$width_cm
  height_cm <- height_cm %||% preset$height_cm
  if (!is.numeric(width_cm) || length(width_cm) != 1L || !is.finite(width_cm) || width_cm <= 0 ||
      !is.numeric(height_cm) || length(height_cm) != 1L || !is.finite(height_cm) || height_cm <= 0) {
    stop("Export width_cm and height_cm must be positive finite scalars.", call. = FALSE)
  }
  column_class <- pp_preset_column_class(output_preset)
  max_width <- if (identical(column_class, "single")) profile$single_cm else profile$double_cm
  tolerance <- 1e-8
  if (width_cm > max_width + tolerance) {
    stop("Export width ", width_cm, " cm exceeds the ", profile$name, " ", column_class, "-column envelope of ", max_width, " cm.", call. = FALSE)
  }
  if (height_cm > profile$max_height_cm + tolerance) {
    stop("Export height ", height_cm, " cm exceeds the ", profile$name, " envelope of ", profile$max_height_cm, " cm.", call. = FALSE)
  }
  list(
    profile = profile,
    geometry = list(width_cm = as.numeric(width_cm), height_cm = as.numeric(height_cm), column_class = column_class,
                    max_width_cm = as.numeric(max_width), max_height_cm = as.numeric(profile$max_height_cm))
  )
}

pp_file_md5 <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  unname(tools::md5sum(path)[[1L]])
}

pp_file_record <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (file.access(path, 4L) != 0L || dir.exists(path)) stop("Provenance path must be a readable file: ", path, call. = FALSE)
  list(path = path, md5 = pp_file_md5(path), size_bytes = unname(file.info(path)[["size"]]))
}

pp_write_plotting_data <- function(path, data) {
  if (!is.data.frame(data)) stop("Plotting data must be a data.frame.", call. = FALSE)
  unsafe_names <- grepl("[\\t\\r\\n]", names(data), perl = TRUE)
  unsafe_values <- vapply(data, function(column) any(grepl("[\\t\\r\\n]", as.character(column), perl = TRUE), na.rm = TRUE), logical(1))
  if (any(unsafe_names) || any(unsafe_values)) stop("Plotting data contains tabs or line breaks that would corrupt TSV structure.", call. = FALSE)
  if (!grepl("_plotting_data\\.tsv$", path)) stop("Plotting-data sidecar must end with _plotting_data.tsv: ", path, call. = FALSE)
  if (file.exists(path)) stop("Refusing to overwrite existing plotting-data sidecar: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(data, file = path, sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE, na = "NA")
  pp_assert_output(path)
  invisible(path)
}

pp_bioinformatics_scaffold <- function(input_paths, plotting_data_path, plotting_data,
                                       organism = "TODO organism", reference_version = "TODO reference/build",
                                       coordinate_system = "not_applicable_nonpositional",
                                       sample_order = "TODO document sample/feature order",
                                       units_transforms_denominators = "TODO document units, transforms, and denominators",
                                       statistics = "TODO document tests and correction",
                                       notes = "Complete provenance fields and change status to pass only after scientific validation.") {
  pp_write_plotting_data(plotting_data_path, plotting_data)
  pp_bioinformatics_validation(
    status = "not_recorded", input_paths = input_paths, organism = organism,
    reference_version = reference_version, coordinate_system = coordinate_system,
    sample_order = sample_order, units_transforms_denominators = units_transforms_denominators,
    statistics = statistics, plotting_data_path = plotting_data_path, notes = notes
  )
}

pp_bioinformatics_validation <- function(status = c("pass", "warn", "block", "not_recorded", "not_applicable"),
                                         input_paths = character(), organism = "", reference_version = "",
                                         coordinate_system = "", sample_order = "",
                                         units_transforms_denominators = "", statistics = "",
                                         plotting_data_path = "", notes = "",
                                         source_records_checked = FALSE, sample_order_checked = FALSE,
                                         units_checked = FALSE, statistics_checked = FALSE,
                                         plotting_data_checked = FALSE) {
  status <- match.arg(status)
  input_paths <- as.character(input_paths)
  input_paths <- input_paths[nzchar(trimws(input_paths))]
  existing_inputs <- file.exists(input_paths)
  input_paths[existing_inputs] <- vapply(input_paths[existing_inputs], normalizePath, character(1), mustWork = TRUE)
  plotting_data_path <- as.character(plotting_data_path)
  if (length(plotting_data_path) == 1L && nzchar(trimws(plotting_data_path)) && file.exists(plotting_data_path)) plotting_data_path <- normalizePath(plotting_data_path, mustWork = TRUE)
  input_files <- lapply(input_paths[existing_inputs], pp_file_record)
  plotting_data <- if (length(plotting_data_path) == 1L && nzchar(trimws(plotting_data_path)) && file.exists(plotting_data_path)) pp_file_record(plotting_data_path) else list()
  validation_evidence <- list(
    source_records_checked = isTRUE(source_records_checked),
    sample_order_checked = isTRUE(sample_order_checked),
    units_checked = isTRUE(units_checked),
    statistics_checked = isTRUE(statistics_checked),
    plotting_data_checked = isTRUE(plotting_data_checked),
    recorded_at = if (status == "pass") format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z") else "not_recorded"
  )
  out <- list(
    status = status,
    input_paths = as.list(input_paths),
    input_files = input_files,
    organism = as.character(organism),
    reference_version = as.character(reference_version),
    coordinate_system = as.character(coordinate_system),
    sample_order = as.character(sample_order),
    units_transforms_denominators = as.character(units_transforms_denominators),
    statistics = as.character(statistics),
    plotting_data_path = plotting_data_path,
    plotting_data = plotting_data,
    validation_evidence = validation_evidence,
    notes = as.character(notes)
  )
  if (status == "pass") {
    allowed_coordinates <- c("0-based_half-open", "1-based_closed", "not_applicable_gene_level", "not_applicable_nonpositional", "mixed_documented")
    required <- c("organism", "reference_version", "coordinate_system", "sample_order", "units_transforms_denominators", "statistics", "plotting_data_path")
    placeholder <- function(value) grepl("^(todo|unknown|not[ _-]?recorded|tbd)(?:$|[ _:-])", trimws(as.character(value)), ignore.case = TRUE, perl = TRUE)
    missing <- required[!vapply(required, function(key) length(out[[key]]) == 1L && !is.na(out[[key]]) && nzchar(trimws(out[[key]])) && !placeholder(out[[key]]), logical(1))]
    if (length(input_paths) == 0L || length(input_files) != length(input_paths)) missing <- c("readable input_paths", missing)
    if (length(plotting_data) == 0L) missing <- c("readable plotting_data_path", missing)
    evidence_keys <- c("source_records_checked", "sample_order_checked", "units_checked", "statistics_checked", "plotting_data_checked")
    unchecked <- evidence_keys[!vapply(evidence_keys, function(key) isTRUE(validation_evidence[[key]]), logical(1))]
    if (length(unchecked) > 0L) missing <- c(missing, paste0("validation_evidence.", unchecked))
    if (length(missing) > 0L) stop("PASS bioinformatics validation is missing: ", paste(unique(missing), collapse = ", "), call. = FALSE)
    if (!out$coordinate_system %in% allowed_coordinates) stop("Unknown coordinate_system for PASS bioinformatics validation: ", out$coordinate_system, call. = FALSE)
    if (!grepl("_plotting_data\\.tsv$", out$plotting_data_path)) stop("PASS plotting_data_path must be a stem-matched _plotting_data.tsv sidecar.", call. = FALSE)
  }
  out
}

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

pp_text_size_mm <- function(pt = 8) {
  if (!is.numeric(pt) || length(pt) != 1 || is.na(pt) || pt < 6) {
    stop("Text size must be one numeric value at or above the 6 pt absolute floor.", call. = FALSE)
  }
  pt * 25.4 / 72.27
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
    barplot = "references/pattern-library/grouped-bar-errorbar.md",
    grouped_bar = "references/pattern-library/grouped-bar-errorbar.md",
    grouped_bar_errorbar = "references/pattern-library/grouped-bar-errorbar.md",
    bio_duplication_mode_four_panel = "references/pattern-library/grouped-bar-errorbar.md",
    scatter_regression = "references/pattern-library/scatter-regression-marginal.md",
    association = "references/pattern-library/scatter-regression-marginal.md",
    ordination_scatter = "references/pattern-library/pca-pcoa-ordination.md",
    heatmap = "references/pattern-library/correlation-heatmap.md",
    multi_metric_small_multiples_rank_index = "references/pattern-library/multi-panel-manuscript-layout.md",
    multi_metric_rank_small_multiples = "references/pattern-library/multi-panel-manuscript-layout.md",
    manuscript_four_panel = "references/pattern-library/multi-panel-manuscript-layout.md",
    bio_genome_quality_small_multiples = "references/pattern-library/multi-panel-manuscript-layout.md",
    volcano = "references/pattern-library/volcano-ma-enrichment.md",
    volcano_plot = "references/pattern-library/volcano-ma-enrichment.md",
    ma_plot = "references/pattern-library/volcano-ma-enrichment.md",
    enrichment_dotplot = "references/pattern-library/volcano-ma-enrichment.md",
    effect_size_forest = "references/pattern-library/model-validation-figures.md"
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
                           output_preset = "nature_half", journal_profile = NULL,
                           analysis_domain = "general", old_figure_path = NULL) {
  output_preset <- pp_nonempty_scalar(output_preset, "output_preset")
  inferred_profile <- pp_profile_for_preset(output_preset)
  journal_profile <- journal_profile %||% inferred_profile
  spec <- list(
    figure_id = pp_nonempty_scalar(figure_id, "figure_id"),
    template_id = pp_nonempty_scalar(template_id, "template_id"),
    backend = "R/ggplot2",
    helper_version = pp_helper_version,
    figure_spec_schema_version = pp_figure_spec_schema_version,
    task_type = pp_nonempty_scalar(task_type, "task_type"),
    figure_role = pp_nonempty_scalar(figure_role, "figure_role"),
    scientific_message = pp_nonempty_scalar(scientific_message, "scientific_message"),
    plot_type = pp_nonempty_scalar(plot_type, "plot_type"),
    sample_id = sample_id,
    group_var = group_var,
    output_preset = output_preset,
    journal_profile = pp_journal_profile(pp_nonempty_scalar(journal_profile, "journal_profile"))$name,
    analysis_domain = match.arg(analysis_domain, c("general", "bioinformatics")),
    old_figure_path = if (is.null(old_figure_path)) NULL else normalizePath(pp_nonempty_scalar(old_figure_path, "old_figure_path"), mustWork = TRUE),
    created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
  spec <- pp_validate_figure_spec(spec)
  class(spec) <- c("pp_figure_spec", class(spec))
  spec
}

pp_validate_figure_spec <- function(figure_spec) {
  if (!is.list(figure_spec)) stop("figure_spec must be a list.", call. = FALSE)
  raw_schema <- figure_spec$figure_spec_schema_version
  schema <- if (is.null(raw_schema)) 1L else raw_schema
  if (!is.numeric(schema) || length(schema) != 1L || is.na(schema) || !is.finite(schema) || schema != as.integer(schema)) {
    stop("figure_spec_schema_version must be one supported integer.", call. = FALSE)
  }
  schema <- as.integer(schema)
  if (!schema %in% c(1L, pp_figure_spec_schema_version)) {
    stop("Unsupported figure_spec_schema_version: ", schema, ". Supported input versions are 1 and ", pp_figure_spec_schema_version, ".", call. = FALSE)
  }

  figure_spec$output_preset <- pp_nonempty_scalar(figure_spec$output_preset, "output_preset")
  if (schema == 1L) {
    original_helper <- figure_spec$helper_version %||% "not_recorded"
    figure_spec$journal_profile <- figure_spec$journal_profile %||% pp_profile_for_preset(figure_spec$output_preset)
    figure_spec$analysis_domain <- figure_spec$analysis_domain %||% "general"
    figure_spec$original_helper_version <- original_helper
    figure_spec$helper_version <- pp_helper_version
    figure_spec$figure_spec_schema_version <- pp_figure_spec_schema_version
    figure_spec$migrated_from_schema <- 1L
    figure_spec$migration_note <- "Explicit v1-to-v2 migration: journal profile inferred when absent; analysis domain defaulted to general when absent."
  } else {
    if (is.null(figure_spec$journal_profile) || is.null(figure_spec$analysis_domain)) {
      stop("Schema v2 figure_spec must explicitly contain journal_profile and analysis_domain.", call. = FALSE)
    }
    figure_spec$figure_spec_schema_version <- pp_figure_spec_schema_version
  }

  profile_geometry <- pp_validate_profile_geometry(figure_spec$output_preset, figure_spec$journal_profile)
  figure_spec$journal_profile <- profile_geometry$profile$name
  figure_spec$journal_profile_snapshot <- profile_geometry$profile
  figure_spec$analysis_domain <- match.arg(figure_spec$analysis_domain, c("general", "bioinformatics"))
  required <- c("figure_id", "template_id", "backend", "helper_version", "task_type", "figure_role", "scientific_message", "plot_type", "output_preset", "journal_profile", "analysis_domain")
  missing <- required[!vapply(required, function(x) !is.null(figure_spec[[x]]) && length(figure_spec[[x]]) == 1L && !is.na(figure_spec[[x]]) && nzchar(trimws(as.character(figure_spec[[x]]))), logical(1))]
  if (length(missing) > 0) {
    stop("figure_spec is missing required fields: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  figure_spec
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

pp_theme <- function(base_size = 9, base_family = pp_resolve_family(), line_width = 0.35,
                     axis_title_margin = 4, show_grid = FALSE) {
  if (!is.numeric(base_size) || length(base_size) != 1 || is.na(base_size) || base_size < 6) {
    stop("pp_theme base_size must be one numeric value at or above the 6 pt absolute floor.", call. = FALSE)
  }
  grid_major <- if (isTRUE(show_grid)) {
    ggplot2::element_line(linewidth = 0.25, colour = "#D9D9D9")
  } else {
    ggplot2::element_blank()
  }

  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(family = base_family, size = base_size, colour = "#1F1F1F"),
      axis.title = ggplot2::element_text(
        size = base_size,
        margin = ggplot2::margin(
          t = axis_title_margin, r = axis_title_margin,
          b = axis_title_margin, l = axis_title_margin
        )
      ),
      axis.text = ggplot2::element_text(size = max(8, base_size - 1), colour = "#303030"),
      axis.line = ggplot2::element_line(linewidth = line_width, colour = "#1F1F1F"),
      axis.ticks = ggplot2::element_line(linewidth = line_width, colour = "#1F1F1F"),
      axis.ticks.length = grid::unit(1.5, "mm"),
      legend.title = ggplot2::element_text(size = max(8, base_size - 1)),
      legend.text = ggplot2::element_text(size = max(8, base_size - 1)),
      legend.key = ggplot2::element_blank(),
      legend.key.size = grid::unit(4.2, "mm"),
      legend.spacing.x = grid::unit(1, "mm"),
      panel.grid.major = grid_major,
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(size = base_size, face = "bold"),
      plot.tag = ggplot2::element_text(size = 12, face = "bold"),
      plot.title = ggplot2::element_text(size = base_size + 1, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = base_size),
      plot.caption = ggplot2::element_text(size = max(8, base_size - 1), colour = "#6A6A6A"),
      plot.title.position = "plot",
      plot.margin = ggplot2::margin(6, 6, 6, 6)
    )
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

pp_assess_label_density <- function(labels, available_width_cm, font_size_pt = 8) {
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

pp_label_strategy <- function(labels, available_width_cm, font_size_pt = 8, max_chars = 14) {
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
  switch(ext, pdf = 5000, png = 1000, jpg = 1000, jpeg = 1000, tiff = 1000, tif = 1000, svg = 100, json = 50, md = 50, tsv = 20, 100)
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
  ext <- tolower(tools::file_ext(filename))
  if (ext == "pdf") {
    signature <- readBin(filename, what = "raw", n = 5L)
    if (!identical(signature, charToRaw("%PDF-"))) stop("Output does not have a valid PDF signature: ", filename, call. = FALSE)
  }
  if (ext == "png") {
    signature <- readBin(filename, what = "raw", n = 8L)
    expected <- as.raw(c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L))
    if (!identical(signature, expected)) stop("Output does not have a valid PNG signature: ", filename, call. = FALSE)
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

pp_save_plot <- function(plot, filename, preset = "nature_half", width = NULL, height = NULL,
                         dpi = NULL, units = "cm", overwrite = FALSE, validate_output = TRUE, ...) {
  if (!isTRUE(overwrite) && file.exists(filename)) {
    stop("Refusing to overwrite existing output file: ", filename, call. = FALSE)
  }
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  preset_values <- pp_output_preset(preset)
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
                        overwrite = FALSE, width = NULL, height = NULL, dpi = NULL, ...) {
  formats <- unique(tolower(formats))
  preset_values <- pp_output_preset(preset)
  export_spec <- list(
    preset = tolower(preset),
    width_cm = as.numeric(width %||% preset_values$width_cm),
    height_cm = as.numeric(height %||% preset_values$height_cm),
    dpi = as.numeric(dpi %||% preset_values$dpi),
    formats = formats
  )
  output_files <- stats::setNames(paste0(output_stem, ".", formats), formats)
  if (!isTRUE(overwrite)) pp_stop_if_outputs_exist(output_files)
  for (fmt in formats) {
    pp_save_plot(plot, output_files[[fmt]], preset = preset, width = export_spec$width_cm, height = export_spec$height_cm, dpi = export_spec$dpi,
                 overwrite = overwrite, ...)
  }
  attr(output_files, "export_spec") <- export_spec
  output_files
}

pp_format_output_files <- function(paths) {
  sizes <- file.info(unname(paths))[["size"]]
  paste0("- ", names(paths), ": ", unname(paths), " (", sizes, " bytes)")
}

pp_data_summary <- function(df) {
  list(n_rows = nrow(df), n_columns = ncol(df), columns = names(df))
}

pp_json_object <- function(x = list()) {
  if (!is.list(x)) stop("JSON object input must be a list.", call. = FALSE)
  if (length(x) > 0L && (is.null(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x)))) stop("JSON object keys must be complete, non-empty, and unique.", call. = FALSE)
  if (length(x) == 0L) names(x) <- character()
  structure(x, class = c("pp_json_object", "list"))
}
pp_json_array <- function(x = list()) {
  if (!is.list(x)) x <- as.list(x)
  names(x) <- NULL
  structure(x, class = c("pp_json_array", "list"))
}
pp_json_escape <- function(x) {
  if (length(x) != 1L || is.na(x)) stop("JSON string must be one non-missing value.", call. = FALSE)
  codepoints <- utf8ToInt(enc2utf8(as.character(x)))
  pieces <- vapply(codepoints, function(code) {
    if (code == 34L) return("\\\"")
    if (code == 92L) return("\\\\")
    if (code == 8L) return("\\b")
    if (code == 9L) return("\\t")
    if (code == 10L) return("\\n")
    if (code == 12L) return("\\f")
    if (code == 13L) return("\\r")
    if (code < 32L) return(sprintf("\\u%04X", code))
    intToUtf8(code)
  }, character(1))
  paste(pieces, collapse = "")
}

pp_json_number <- function(x) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x)) return("null")
  old_outdec <- getOption("OutDec", ".")
  on.exit(options(OutDec = old_outdec), add = TRUE)
  options(OutDec = ".")
  value <- trimws(formatC(x, digits = 17L, format = "g", decimal.mark = "."))
  if (!grepl("^-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?$", value, perl = TRUE)) stop("Could not serialize a locale-independent JSON number.", call. = FALSE)
  value
}

pp_to_json <- function(x, indent = 0) {
  sp <- paste(rep(" ", indent), collapse = "")
  sp2 <- paste(rep(" ", indent + 2), collapse = "")
  if (is.null(x) || inherits(x, "pp_json_null") || (is.atomic(x) && length(x) == 1L && is.na(x))) return("null")
  if (is.atomic(x) && length(x) == 0L) return("[]")
  if (is.atomic(x) && length(x) > 1L) return(pp_to_json(pp_json_array(as.list(x)), indent = indent))
  if (inherits(x, "data.frame")) {
    rows <- lapply(seq_len(nrow(x)), function(i) pp_json_object(as.list(x[i, , drop = FALSE])))
    return(pp_to_json(pp_json_array(rows), indent = indent))
  }
  if (is.list(x) && !is.data.frame(x)) {
    nms <- names(x)
    is_object <- inherits(x, "pp_json_object") || (!inherits(x, "pp_json_array") && !is.null(nms))
    if (is_object) {
      if (length(x) > 0L && (any(!nzchar(nms)) || anyDuplicated(nms))) stop("JSON object keys must be complete, non-empty, and unique.", call. = FALSE)
      if (length(x) == 0L) return("{}")
      parts <- vapply(seq_along(x), function(i) paste0(sp2, '"', pp_json_escape(nms[[i]]), '": ', pp_to_json(x[[i]], indent + 2)), character(1))
      return(paste0("{\n", paste(parts, collapse = ",\n"), "\n", sp, "}"))
    }
    if (length(x) == 0L) return("[]")
    parts <- vapply(x, pp_to_json, character(1), indent = indent + 2)
    return(paste0("[\n", paste(paste0(sp2, parts), collapse = ",\n"), "\n", sp, "]"))
  }
  if (is.logical(x)) return(if (x) "true" else "false")
  if (is.numeric(x)) return(pp_json_number(x))
  paste0('"', pp_json_escape(x), '"')
}

pp_write_review_sidecar <- function(path, metadata_path, qa_path,
                                    visual_qa_path = NULL,
                                    visual_status = c("not_recorded", "pass", "accepted_warn"),
                                    visual_exception_reason = "",
                                    old_vs_new_path = NULL) {
  visual_status <- match.arg(visual_status)
  if (!grepl("_review\\.json$", path)) stop("Review sidecar must end with _review.json: ", path, call. = FALSE)
  if (file.exists(path)) stop("Refusing to overwrite existing review sidecar: ", path, call. = FALSE)
  expected_metadata <- sub("_review\\.json$", "_metadata.json", path)
  expected_qa <- sub("_review\\.json$", "_qa.md", path)
  if (!file.exists(metadata_path) || !identical(normalizePath(metadata_path, mustWork = TRUE), normalizePath(expected_metadata, mustWork = TRUE))) {
    stop("Review sidecar requires stem-matched metadata: ", expected_metadata, call. = FALSE)
  }
  if (!file.exists(qa_path) || !identical(normalizePath(qa_path, mustWork = TRUE), normalizePath(expected_qa, mustWork = TRUE))) {
    stop("Review sidecar requires stem-matched QA report: ", expected_qa, call. = FALSE)
  }
  visual_exception_reason <- trimws(as.character(visual_exception_reason))
  if (visual_status == "accepted_warn" && !nzchar(visual_exception_reason)) {
    stop("accepted_warn requires a non-empty visual_exception_reason.", call. = FALSE)
  }
  if (visual_status != "not_recorded" && (is.null(visual_qa_path) || !file.exists(visual_qa_path))) {
    stop("Recorded visual review requires an existing visual_qa.json path.", call. = FALSE)
  }
  visual_review <- list(
    status = visual_status,
    exception_recorded = identical(visual_status, "accepted_warn"),
    exception_reason = if (visual_status == "accepted_warn") visual_exception_reason else "",
    evidence_path = if (is.null(visual_qa_path)) "" else normalizePath(visual_qa_path, mustWork = TRUE),
    evidence_md5 = if (is.null(visual_qa_path)) "" else pp_file_md5(visual_qa_path)
  )
  old_review <- list(
    status = if (is.null(old_vs_new_path)) "not_applicable" else "provided",
    evidence_path = if (is.null(old_vs_new_path)) "" else normalizePath(old_vs_new_path, mustWork = TRUE),
    evidence_md5 = if (is.null(old_vs_new_path)) "" else pp_file_md5(old_vs_new_path)
  )
  payload <- list(
    review_schema_version = 1L,
    created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    metadata = pp_file_record(metadata_path),
    qa = pp_file_record(qa_path),
    visual_qa_review = visual_review,
    old_vs_new_review = old_review
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(pp_to_json(payload), con = path)
  pp_assert_output(path)
  invisible(path)
}

pp_write_metadata <- function(path, figure_spec, metric_spec = NULL, output_files,
                              layout = list(), palette = list(), ordering = list(),
                              qa = list(), data_summary = list()) {
  if (file.exists(path)) stop("Refusing to overwrite existing metadata file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  figure_spec <- pp_validate_figure_spec(figure_spec)
  if (!is.null(metric_spec)) pp_validate_metric_spec(metric_spec)
  payload <- list(
    figure_id = figure_spec$figure_id,
    template_id = figure_spec$template_id,
    backend = figure_spec$backend,
    helper_version = figure_spec$helper_version,
    figure_spec_schema_version = figure_spec$figure_spec_schema_version,
    task_type = figure_spec$task_type,
    figure_role = figure_spec$figure_role,
    scientific_message = figure_spec$scientific_message,
    plot_type = figure_spec$plot_type,
    journal_profile = figure_spec$journal_profile,
    analysis_domain = figure_spec$analysis_domain,
    data = data_summary,
    metrics = metric_spec,
    ordering = ordering,
    style = list(theme = "pp_theme", palette = palette, target_text_pt = 9, compact_text_pt = 8, panel_label_pt = 12, min_text_pt = 6),
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
                            palette_check = NULL, layout_check = NULL,
                            cognitive_load_review = NULL,
                            bioinformatics_validation = NULL) {
  figure_spec <- pp_validate_figure_spec(figure_spec)
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
  results <- c(results, list(pp_qa_cognitive_load_review(cognitive_load_review)))
  results <- c(results, list(pp_qa_bioinformatics_validation(figure_spec, bioinformatics_validation)))
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
                              optional_dependencies = list(), sidecars = list(),
                              cognitive_load_review = NULL,
                              bioinformatics_validation = NULL,
                              visual_qa_review = NULL,
                              old_vs_new_review = NULL) {
  if (file.exists(path)) stop("Refusing to overwrite existing metadata file: ", path, call. = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  figure_spec <- pp_validate_figure_spec(figure_spec)
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
  cognitive_load_review <- cognitive_load_review %||% list(
    status = "not_recorded",
    review_limits = list(elements = 7, colors = 3, shapes = 3, legend_entries = 4),
    action = "assess per panel before manuscript-ready classification"
  )
  bioinformatics_validation <- bioinformatics_validation %||% pp_bioinformatics_validation(
    if (identical(figure_spec$analysis_domain, "bioinformatics")) "not_recorded" else "not_applicable"
  )
  visual_qa_review <- visual_qa_review %||% list(status = "not_recorded", exception_recorded = FALSE, exception_reason = "")
  old_vs_new_review <- old_vs_new_review %||% list(
    status = if (is.null(figure_spec$old_figure_path)) "not_applicable" else "not_recorded",
    evidence_path = ""
  )
  export_spec <- attr(output_files, "export_spec")
  if (is.null(export_spec)) {
    preset_values <- pp_output_preset(figure_spec$output_preset)
    export_spec <- list(
      preset = figure_spec$output_preset,
      width_cm = layout$width_cm %||% preset_values$width_cm,
      height_cm = layout$height_cm %||% preset_values$height_cm,
      dpi = preset_values$dpi,
      formats = intersect(names(output_files), c("pdf", "png"))
    )
  }
  if (!identical(tolower(export_spec$preset), tolower(figure_spec$output_preset))) {
    stop("Export preset does not match figure_spec$output_preset.", call. = FALSE)
  }
  profile_geometry <- pp_validate_profile_geometry(
    figure_spec$output_preset, figure_spec$journal_profile,
    width_cm = export_spec$width_cm, height_cm = export_spec$height_cm
  )
  export_geometry <- c(export_spec, list(
    journal_profile = profile_geometry$profile$name,
    column_class = profile_geometry$geometry$column_class,
    max_width_cm = profile_geometry$geometry$max_width_cm,
    max_height_cm = profile_geometry$geometry$max_height_cm
  ))
  payload <- list(
    figure_id = figure_spec$figure_id,
    template_id = figure_spec$template_id,
    backend = figure_spec$backend,
    helper_version = figure_spec$helper_version,
    figure_spec_schema_version = figure_spec$figure_spec_schema_version,
    task_type = figure_spec$task_type,
    figure_role = figure_spec$figure_role,
    scientific_message = figure_spec$scientific_message,
    plot_type = figure_spec$plot_type,
    journal_profile = figure_spec$journal_profile,
    journal_profile_snapshot = profile_geometry$profile,
    analysis_domain = figure_spec$analysis_domain,
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
    cognitive_load_review = cognitive_load_review,
    bioinformatics_validation = bioinformatics_validation,
    visual_qa_review = visual_qa_review,
    old_vs_new_review = old_vs_new_review,
    label_strategy = label_strategy,
    palette_plan = palette_plan %||% palette,
    style = list(theme = "pp_theme", palette = palette, target_text_pt = 9, compact_text_pt = 8, panel_label_pt = 12, min_text_pt = 6),
    panel_hierarchy = panel_hierarchy,
    redraw_strategy = redraw_strategy,
    statistical_plan = statistical_plan,
    optional_dependencies = optional_dependencies,
    layout = layout,
    export = as.list(output_files),
    export_geometry = export_geometry,
    sidecars = sidecars,
    qa = qa,
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
