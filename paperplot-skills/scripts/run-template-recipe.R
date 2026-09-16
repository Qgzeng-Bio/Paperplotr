pp_run_recipe_template <- function(recipe_id,
                                   template_id,
                                   family_label,
                                   input_path,
                                   output_dir,
                                   width_cm = NULL,
                                   height_cm = NULL,
                                   output_stem = NULL,
                                   y_label = NULL,
                                   mode = Sys.getenv("PAPERPLOT_MODE", "production"),
                                   render_spec = NULL, params = list()) {
  mode <- match.arg(mode, c("production", "preview", "demo"))
  if (!exists("helper_path", inherits = TRUE)) {
    helper_path <- Sys.getenv("PAPERPLOT_HELPER")
    if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
  }
  recipe_engine <- file.path(dirname(helper_path), "..", "recipes", "paperplot_code_recipes.R")
  if (!file.exists(recipe_engine)) stop("Missing recipe engine: ", recipe_engine, call. = FALSE)
  source(recipe_engine)
  entry <- pp_recipe_entry(recipe_id)
  if(!is.null(render_spec) && ((!is.null(width_cm) && abs(width_cm*10-render_spec$width_mm)>.001) || (!is.null(height_cm) && abs(height_cm*10-render_spec$height_mm)>.001))) stop('Legacy dimensions conflict with render_spec.')
  width_cm <- width_cm %||% entry$default_width_cm
  height_cm <- height_cm %||% entry$default_height_cm
  render_spec <- render_spec %||% pp_render_spec(width_mm=width_cm*10,height_mm=height_cm*10,mode=mode,panel_tags=FALSE)
  width_cm <- render_spec$width_mm/10; height_cm <- render_spec$height_mm/10
  if(!is.null(y_label)) params$y_label <- y_label
  params$render_spec <- render_spec

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (mode != "demo") {
    df <- pp_read_recipe_data(input_path, recipe_id, mode)
    if ("group" %in% names(df)) df$group <- factor(df$group, levels = unique(df$group))
    if ("category" %in% names(df)) df$category <- factor(df$category, levels = unique(df$category))
    if ("metric" %in% names(df)) df$metric <- factor(df$metric, levels = unique(df$metric))
    if ("chr" %in% names(df)) df$chr <- factor(df$chr, levels = unique(df$chr))
    if ("set" %in% names(df)) df$set <- factor(df$set, levels = unique(df$set))
    if ("track" %in% names(df)) df$track <- factor(df$track, levels = unique(df$track))
  } else {
    df <- pp_recipe_mock_data(recipe_id)
  }
  plot <- pp_recipe_plot(recipe_id, df, params=params,mode=mode)

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
  required_roles <- strsplit(entry$required_roles,';',fixed=TRUE)[[1]]
  measures <- required_roles[vapply(df[required_roles],is.numeric,logical(1))]
  if(!length(measures)) measures <- required_roles[[1]]
  units <- vapply(measures,function(name) params$units[[name]] %||%
    if(name%in%c('pvalue','padj','qvalue','ratio','present')) 'unitless' else
      if(name%in%c('start','end','position','target_start','target_end')) 'bp' else
        if(name=='count') 'count' else 'not supplied; requires scientific review',character(1))
  metric_spec <- pp_metric_spec(metric=measures,label=measures,unit=units,direction='neutral',transform='none',role='primary')
  label_col_candidates <- intersect(c("category", "metric", "term", "sample", "group"), names(df))
  label_col <- if (length(label_col_candidates) > 0) label_col_candidates[[1]] else names(df)[[1]]
  label_strategy <- pp_label_strategy_v2(
    unique(c(as.character(df[[label_col]]))),
    figure_role = "main",
    available_width_cm = width_cm
  )
  visual_budget <- pp_visual_budget(
    figure_role = "main",
    n_panels = pp_infer_panel_count(plot),
    n_labels = length(unique(df[[label_col]])),
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
    statistical_plan = list(recipe_id = recipe_id, parameters=params, statistics=attr(plot,'pp_statistics')),
    visible_simplifications = design_brief$acceptable_simplifications,
    risks = character(),
    pattern_reference = pp_pattern_reference(family_label, template_id = template_id, source = "code-recipe-library")
  )

  if (is.null(output_stem)) output_stem <- file.path(output_dir, template_id)
  render_spec$n_panels <- pp_infer_panel_count(plot)
  outputs <- pp_save_all_with_qa_loop(plot, output_stem, preset = figure_spec$output_preset,
    qa_context = list(family = figure_spec$plot_type), render_spec = render_spec, overwrite = FALSE)
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
