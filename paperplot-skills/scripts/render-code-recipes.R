#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
})

parse_args <- function(args) {
  out <- list(
    recipes_dir = "paperplot-skills/recipes",
    out = "paperplot-skills/reports/code-recipe-gallery",
    limit = NA_integer_,
    skip_visual_qa = FALSE
  )
  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    if (identical(key, "--recipes-dir")) {
      i <- i + 1; out$recipes_dir <- args[[i]]
    } else if (identical(key, "--out")) {
      i <- i + 1; out$out <- args[[i]]
    } else if (identical(key, "--limit")) {
      i <- i + 1; out$limit <- as.integer(args[[i]])
    } else if (identical(key, "--skip-visual-qa")) {
      out$skip_visual_qa <- TRUE
    } else {
      stop("Unknown argument: ", key, call. = FALSE)
    }
    i <- i + 1
  }
  out
}

args <- parse_args(commandArgs(trailingOnly = TRUE))

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Missing helper: ", helper_path, call. = FALSE)
source(helper_path)

recipe_engine <- file.path(args$recipes_dir, "paperplot_code_recipes.R")
manifest_path <- file.path(args$recipes_dir, "recipe_manifest.csv")
if (!file.exists(recipe_engine)) stop("Missing recipe engine: ", recipe_engine, call. = FALSE)
if (!file.exists(manifest_path)) stop("Missing recipe manifest: ", manifest_path, call. = FALSE)
source(recipe_engine)

manifest <- read.csv(manifest_path, check.names = FALSE, stringsAsFactors = FALSE)
if (!is.na(args$limit)) manifest <- manifest[seq_len(min(args$limit, nrow(manifest))), , drop = FALSE]
dir.create(args$out, recursive = TRUE, showWarnings = FALSE)

run_visual_qa <- function(png_path, qa_dir, family, target_width_mm = 89) {
  if (isTRUE(args$skip_visual_qa)) return(list(status = "skipped", detail = "visual QA skipped by flag"))
  script <- file.path("paperplot-skills", "scripts", "visual-qa-rendered-image.py")
  family_script <- file.path("paperplot-skills", "scripts", "family-qa-score.py")
  if (!file.exists(script)) return(list(status = "skipped", detail = "visual QA script not found"))
  dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)
  qa_out <- system2("python3", c(script, png_path, "--out", qa_dir, "--target-width-mm", as.character(target_width_mm), "--journal-profile", "nature", "--allow-grid", "auto"), stdout = TRUE, stderr = TRUE)
  qa_status <- attr(qa_out, "status")
  if (is.null(qa_status)) qa_status <- 0L
  visual_json <- file.path(qa_dir, "visual_qa.json")
  family_out <- character()
  family_status <- 0L
  if (file.exists(visual_json) && file.exists(family_script)) {
    family_json <- file.path(qa_dir, "family_qa.json")
    family_out <- system2("python3", c(family_script, "--qa-json", visual_json, "--family", family, "--out", family_json), stdout = TRUE, stderr = TRUE)
    family_status <- attr(family_out, "status")
    if (is.null(family_status)) family_status <- 0L
  }
  list(
    status = if (qa_status == 0L && family_status == 0L) "ok" else "warn",
    detail = paste(c(qa_out, family_out), collapse = " | ")
  )
}

render_one <- function(row) {
  recipe_id <- row[["recipe_id"]]
  recipe_dir <- file.path(args$out, recipe_id)
  dir.create(recipe_dir, recursive = TRUE, showWarnings = FALSE)
  input_path <- file.path(recipe_dir, "mock_data.csv")
  output_stem <- file.path(recipe_dir, recipe_id)
  notes_path <- paste0(output_stem, "_notes.md")
  metadata_path <- paste0(output_stem, "_metadata.json")
  qa_path <- paste0(output_stem, "_qa.md")
  unlink(c(notes_path, metadata_path, qa_path))

  df <- pp_recipe_mock_data(recipe_id)
  write.csv(df, input_path, row.names = FALSE)
  plot <- pp_recipe_plot(recipe_id, df)

  figure_spec <- pp_figure_spec(
    figure_id = recipe_id,
    template_id = "code-recipe-library",
    task_type = "new",
    figure_role = "main",
    scientific_message = paste("Demonstrate reusable", row[["figure_family"]], "code recipe."),
    plot_type = row[["figure_family"]],
    output_preset = if (as.numeric(row[["default_width_cm"]]) > 10) "nature" else "nature_half"
  )
  metric_spec <- pp_metric_spec(
    metric = c("value", "group", "category"),
    label = c("Value", "Group", "Category"),
    unit = c("a.u.", "unitless", "unitless"),
    direction = c("neutral", "neutral", "neutral"),
    transform = "none",
    role = c("primary", "grouping", "grouping")
  )
  label_strategy <- pp_label_strategy_v2(unique(c(as.character(df$category), as.character(df$metric))), figure_role = "main", available_width_cm = as.numeric(row[["default_width_cm"]]))
  visual_budget <- pp_visual_budget(figure_role = "main", n_panels = if (grepl("composite|multi|validation", recipe_id)) 3 else 1, n_labels = 8, n_legend_entries = length(unique(df$group)))
  design_brief <- pp_design_brief(
    scientific_message = figure_spec$scientific_message,
    figure_role = "main",
    main_comparison = list(recipe_id = recipe_id, family = row[["figure_family"]]),
    data_roles = list(required = row[["required_roles"]], optional = row[["optional_roles"]]),
    metric_semantics = list(metrics = metric_spec),
    label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score),
    acceptable_simplifications = c("Recipe uses mock data and must be remapped to user data roles before publication."),
    must_show = c("core encoding", "legend semantics", "target-size readable typography"),
    may_move_to_metadata = c("source replica case details", "full code archive provenance")
  )
  design_plan <- pp_design_plan(
    chart_family = row[["figure_family"]],
    figure_role = "main",
    layout_plan = list(type = "recipe_gallery", width_cm = row[["default_width_cm"]], height_cm = row[["default_height_cm"]]),
    label_strategy = label_strategy,
    palette_plan = list(type = "recipe default", name = "graphpad_discrete / graphpad_heatmap"),
    statistical_plan = list(input_schema = row[["required_roles"]], qa_profile = row[["qa_profile"]]),
    visible_simplifications = design_brief$acceptable_simplifications,
    risks = if (identical(row[["status"]], "specialized_reference")) "Specialized reference recipe; do not use ordinary statistical-plot thresholds alone." else character(),
    pattern_reference = pp_pattern_reference(row[["figure_family"]], template_id = recipe_id, source = "code-recipe-library")
  )

  outputs <- pp_save_all(
    plot,
    output_stem,
    preset = figure_spec$output_preset,
    width = as.numeric(row[["default_width_cm"]]),
    height = as.numeric(row[["default_height_cm"]]),
    overwrite = TRUE
  )
  invisible(lapply(outputs, pp_assert_output))
  qa_results <- pp_qa_summary(
    pp_qa_preflight(figure_spec, metric_spec),
    pp_qa_design_preflight(design_brief, design_plan, visual_budget),
    pp_qa_label_strategy(label_strategy, "main"),
    pp_qa_result("code_recipe_contract", "pass", paste("Recipe status:", row[["status"]]))
  )
  readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
  qa_results <- pp_qa_summary(qa_results, readiness)

  pp_write_notes(
    notes_path,
    figure_id = recipe_id,
    input_path = input_path,
    output_files = outputs,
    preset = figure_spec$output_preset,
    design_decisions = c(
      paste("Recipe family:", row[["figure_family"]]),
      paste("Required input roles:", row[["required_roles"]]),
      paste("Source evidence:", row[["source_evidence"]]),
      "The recipe is generalized from code structure and rendered with mock data."
    ),
    qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
    remaining_issues = "Map the recipe roles to real data, units, n, and statistical semantics before manuscript use.",
    figure_spec = figure_spec,
    metric_spec = metric_spec,
    design_brief = design_brief,
    design_plan = design_plan,
    layout = design_plan$layout_plan,
    palette = design_plan$palette_plan,
    label_strategy = label_strategy,
    data_summary = pp_data_profile(df, group_col = "group", metric_col = "metric", value_col = "value")
  )
  pp_write_metadata(
    metadata_path,
    figure_spec = figure_spec,
    metric_spec = metric_spec,
    output_files = c(outputs, notes = notes_path, qa = qa_path),
    layout = design_plan$layout_plan,
    palette = design_plan$palette_plan,
    qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness),
    data_summary = pp_data_summary(df),
    design_brief = design_brief,
    design_plan = design_plan,
    data_profile = pp_data_profile(df, group_col = "group", metric_col = "metric", value_col = "value"),
    visual_budget = visual_budget,
    label_strategy = label_strategy,
    statistical_plan = design_plan$statistical_plan,
    optional_dependencies = list(recipe_status = row[["status"]], source_evidence = row[["source_evidence"]])
  )
  qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
  pp_write_qa_report(qa_path, qa_results)

  target_width_mm <- max(89, round(as.numeric(row[["default_width_cm"]]) * 10))
  visual <- run_visual_qa(outputs[["png"]], file.path(recipe_dir, "visual_qa"), row[["figure_family"]], target_width_mm = target_width_mm)
  data.frame(
    recipe_id = recipe_id,
    family = row[["figure_family"]],
    status = row[["status"]],
    pdf = outputs[["pdf"]],
    png = outputs[["png"]],
    notes = notes_path,
    metadata = metadata_path,
    qa = qa_path,
    visual_qa = visual$status,
    stringsAsFactors = FALSE
  )
}

results <- do.call(rbind, lapply(seq_len(nrow(manifest)), function(i) {
  tryCatch(render_one(manifest[i, , drop = FALSE]), error = function(e) {
    data.frame(
      recipe_id = manifest$recipe_id[[i]],
      family = manifest$figure_family[[i]],
      status = manifest$status[[i]],
      pdf = NA_character_,
      png = NA_character_,
      notes = NA_character_,
      metadata = NA_character_,
      qa = NA_character_,
      visual_qa = paste("error:", conditionMessage(e)),
      stringsAsFactors = FALSE
    )
  })
}))

write.csv(results, file.path(args$out, "recipe-gallery-index.csv"), row.names = FALSE)
print(results, row.names = FALSE)
if (any(grepl("^error:", results$visual_qa))) {
  stop("One or more recipes failed to render.", call. = FALSE)
}
cat("Rendered ", nrow(results), " code recipes into ", args$out, "\n", sep = "")
