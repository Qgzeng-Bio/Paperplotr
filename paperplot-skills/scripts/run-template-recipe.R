pp_run_recipe_template <- function(recipe_id,
                                   template_id,
                                   family_label,
                                   input_path,
                                   output_dir,
                                   width_cm = 8.9,
                                   height_cm = 6.2,
                                   output_stem = NULL,
                                   y_label = "Value (a.u.)") {
  if (!exists("helper_path", inherits = TRUE)) {
    helper_path <- Sys.getenv("PAPERPLOT_HELPER")
    if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
  }
  recipe_engine <- file.path(dirname(helper_path), "..", "recipes", "paperplot_code_recipes.R")
  if (!file.exists(recipe_engine)) stop("Missing recipe engine: ", recipe_engine, call. = FALSE)
  source(recipe_engine)

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(input_path)) {
    df <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
    if ("group" %in% names(df)) df$group <- factor(df$group)
    if ("category" %in% names(df)) df$category <- factor(df$category)
    if ("metric" %in% names(df)) df$metric <- factor(df$metric)
    if ("chr" %in% names(df)) df$chr <- factor(df$chr)
    if ("set" %in% names(df)) df$set <- factor(df$set)
    if ("track" %in% names(df)) df$track <- factor(df$track)
  } else {
    df <- pp_recipe_mock_data(recipe_id)
  }
  n <- nrow(df)
  if (!"label" %in% names(df)) df$label <- if ("gene" %in% names(df)) ifelse(seq_len(n) <= 8, df$gene, "") else ""
  if (!"time" %in% names(df)) df$time <- rep(seq_len(max(1, min(12, n))), length.out = n)
  if (!"longitude" %in% names(df)) df$longitude <- seq(70, 125, length.out = n)
  if (!"latitude" %in% names(df)) df$latitude <- seq(15, 52, length.out = n)
  if (!"weight" %in% names(df)) df$weight <- if ("value" %in% names(df)) abs(df$value) else rep(1, n)
  if (!"source" %in% names(df)) df$source <- factor(rep(paste0("Source", LETTERS[1:5]), length.out = n))
  if (!"target" %in% names(df)) df$target <- factor(rep(paste0("Target", LETTERS[1:5]), each = 2, length.out = n))
  if (!"track" %in% names(df)) df$track <- factor(rep(paste0("Track", seq_len(4)), length.out = n))
  if (!"start" %in% names(df)) df$start <- seq_len(n) * 100000
  if (!"end" %in% names(df)) df$end <- df$start + 50000
  if (!"observed" %in% names(df)) {
    base_value <- if ("value" %in% names(df)) df$value else seq_len(n)
    df$observed <- pmin(1, pmax(0, stats::pnorm(base_value)))
  }
  if (!"predicted" %in% names(df)) df$predicted <- pmin(1, pmax(0, df$observed + stats::rnorm(n, sd = 0.05)))
  if (!"residual" %in% names(df)) df$residual <- df$observed - df$predicted
  plot <- pp_recipe_plot(recipe_id, df)

  figure_spec <- pp_figure_spec(
    figure_id = template_id,
    template_id = template_id,
    task_type = "new",
    figure_role = "main",
    scientific_message = paste("Render", family_label, "with a code-recipe-driven manuscript template."),
    plot_type = family_label,
    # Report a preset that actually matches the exported canvas instead of
    # silently fighting preset metadata (WP2 canvas-truthfulness gate).
    output_preset = if (width_cm > 10) "nature" else if (isTRUE(all.equal(c(width_cm, height_cm), c(8.9, 6.2)))) "single_column" else "nature_half"
  )
  metric_spec <- pp_metric_spec(
    metric = c("value", "group", "category"),
    label = c(y_label, "Group", "Category"),
    unit = c("a.u.", "unitless", "unitless"),
    direction = c("neutral", "neutral", "neutral"),
    transform = "none",
    role = c("primary", "grouping", "grouping")
  )
  label_col_candidates <- intersect(c("category", "metric", "term", "sample", "group"), names(df))
  label_col <- if (length(label_col_candidates) > 0) label_col_candidates[[1]] else names(df)[[1]]
  label_strategy <- pp_label_strategy_v2(
    unique(c(as.character(df[[label_col]]))),
    figure_role = "main",
    available_width_cm = width_cm
  )
  visual_budget <- pp_visual_budget(
    figure_role = "main",
    n_panels = if ("metric" %in% names(df)) min(6, length(unique(df$metric))) else 1,
    n_labels = 8,
    n_legend_entries = if ("group" %in% names(df)) length(unique(df$group)) else 0
  )
  design_brief <- pp_design_brief(
    scientific_message = figure_spec$scientific_message,
    figure_role = "main",
    main_comparison = list(recipe_id = recipe_id, family = family_label),
    data_roles = list(required = "See recipe manifest", optional = "See recipe manifest"),
    metric_semantics = list(metrics = metric_spec),
    label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score),
    acceptable_simplifications = c("Recipe template uses generalized code structure; user data must be mapped to required roles."),
    must_show = c("core data encoding", "legend semantics", "target-size readable typography"),
    may_move_to_metadata = c("full source provenance", "dense labels")
  )
  design_plan <- pp_design_plan(
    chart_family = family_label,
    figure_role = "main",
    layout_plan = list(type = "recipe_template", width_cm = width_cm, height_cm = height_cm),
    label_strategy = label_strategy,
    palette_plan = list(type = "recipe default", name = "Nature-like restrained palette"),
    statistical_plan = list(recipe_id = recipe_id, role_mapping_required = TRUE),
    visible_simplifications = design_brief$acceptable_simplifications,
    risks = character(),
    pattern_reference = pp_pattern_reference(family_label, template_id = template_id, source = "code-recipe-library")
  )

  if (is.null(output_stem)) output_stem <- file.path(output_dir, template_id)
  outputs <- pp_save_all_with_qa_loop(plot, output_stem, preset = figure_spec$output_preset, qa_context = list(family = figure_spec$plot_type), width = width_cm, height = height_cm, overwrite = TRUE)
  invisible(lapply(outputs, pp_assert_output))
  notes_path <- paste0(output_stem, "_notes.md")
  metadata_path <- paste0(output_stem, "_metadata.json")
  qa_path <- paste0(output_stem, "_qa.md")
  qa_results <- pp_qa_summary(
    pp_qa_preflight(figure_spec, metric_spec),
    pp_qa_design_preflight(design_brief, design_plan, visual_budget),
    pp_qa_label_strategy(label_strategy, "main"),
    pp_qa_result("code_recipe_template", "pass", paste("Template uses recipe:", recipe_id))
  )
  readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
  qa_results <- pp_qa_summary(qa_results, readiness)
  pp_write_notes(
    notes_path,
    figure_id = template_id,
    input_path = input_path,
    output_files = outputs,
    preset = figure_spec$output_preset,
    design_decisions = c(paste("Recipe:", recipe_id), paste("Family:", family_label), "Generated through the 9.0 code-recipe template runner."),
    qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
    remaining_issues = "Map user data roles, units, n, and statistical semantics before publication.",
    figure_spec = figure_spec,
    metric_spec = metric_spec,
    design_brief = design_brief,
    design_plan = design_plan,
    layout = design_plan$layout_plan,
    palette = design_plan$palette_plan,
    label_strategy = label_strategy,
    data_summary = pp_data_profile(df, group_col = if ("group" %in% names(df)) "group" else NULL, metric_col = if ("metric" %in% names(df)) "metric" else NULL, value_col = if ("value" %in% names(df)) "value" else NULL)
  )
  pp_write_metadata(
    metadata_path,
    figure_spec = figure_spec,
    metric_spec = metric_spec,
    output_files = pp_extend_output_files(outputs, notes = notes_path, qa = qa_path),
    layout = design_plan$layout_plan,
    palette = design_plan$palette_plan,
    qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness),
    data_summary = pp_data_summary(df),
    design_brief = design_brief,
    design_plan = design_plan,
    data_profile = pp_data_profile(df, group_col = if ("group" %in% names(df)) "group" else NULL, metric_col = if ("metric" %in% names(df)) "metric" else NULL, value_col = if ("value" %in% names(df)) "value" else NULL),
    visual_budget = visual_budget,
    label_strategy = label_strategy,
    statistical_plan = design_plan$statistical_plan,
    optional_dependencies = list(recipe_id = recipe_id)
  )
  qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
  pp_write_qa_report(qa_path, qa_results)
  invisible(outputs)
}
