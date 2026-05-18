# Standalone manuscript four-panel template with panel hierarchy

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to scripts/paperplot_helpers.R.", call. = FALSE)
source(helper_path)

input_path <- "TODO-input.csv"
output_dir <- "figures"
figure_id <- "manuscript_four_panel_todo"
preset <- "nature"

x_col <- "TODO_x"
y_col <- "TODO_y"
panel_col <- "TODO_panel"
group_col <- NULL
x_label <- "TODO x label with units"
y_label <- "TODO y label with units"
figure_role <- "main"

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
label_key_path <- paste0(output_stem, "_label_key.csv")
pp_stop_if_outputs_exist(c(paste0(output_stem, c(".pdf", ".png")), notes_path, metadata_path, qa_path, label_key_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "manuscript-four-panel-template",
  task_type = "new",
  figure_role = figure_role,
  scientific_message = "Show a primary result and three supporting views as a coherent four-panel manuscript figure.",
  plot_type = "manuscript_four_panel",
  sample_id = x_col,
  group_var = group_col,
  output_preset = preset
)

if (!file.exists(input_path)) stop("Set input_path to an existing CSV file.", call. = FALSE)
df <- read.csv(input_path, check.names = FALSE)

required_cols <- c(x_col, y_col, panel_col, group_col)
required_cols <- required_cols[!is.na(required_cols) & nzchar(required_cols)]
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)

panel_ids <- unique(as.character(df[[panel_col]]))
if (length(panel_ids) < 1) stop("panel_col must contain at least one panel.", call. = FALSE)
panel_specs <- lapply(seq_along(panel_ids), function(i) {
  pp_panel_spec(
    panel_id = panel_ids[[i]],
    message = paste("Panel", panel_ids[[i]], "supports the figure message"),
    role = if (i == 1) "primary" else if (i == 2) "secondary" else "supporting",
    plot_type = "scatter",
    metric = y_col
  )
})
panel_hierarchy <- pp_panel_hierarchy(panel_specs)
layout_budget <- pp_layout_budget(panel_hierarchy, figure_role = figure_role)
layout <- pp_recommend_manuscript_layout(panel_hierarchy, available_width_cm = 18, available_height_cm = 12)
shared_guide_plan <- pp_shared_guide_plan(panel_specs, palette_plan = list(type = if (!is.null(group_col)) "group" else "none"))

metric_spec <- pp_metric_spec(metric = y_col, label = y_label, unit = "a.u.", direction = "neutral")
data_profile <- pp_data_profile(df, sample_col = x_col, group_col = group_col, metric_col = panel_col, value_col = y_col)
label_strategy <- pp_label_strategy_v2(unique(df[[x_col]]), figure_role = figure_role, available_width_cm = layout$width_cm / max(1, layout$ncol), sample_identity_role = "lookup")
rank_map <- pp_rank_index_map(unique(as.character(df[[x_col]])))
if (isTRUE(label_strategy)) pp_write_label_key(label_key_path, rank_map)
visual_budget <- pp_visual_budget(figure_role, n_panels = length(panel_ids), n_labels = if (identical(label_strategy$strategy, "direct")) length(unique(df[[x_col]])) else 0, n_legend_entries = if (!is.null(group_col)) length(unique(df[[group_col]])) else 0)

design_brief <- pp_design_brief(
  scientific_message = figure_spec$scientific_message,
  figure_role = figure_role,
  main_comparison = "primary panel plus supporting panels",
  data_roles = list(sample_id = "lookup", group = group_col, panel = panel_col, value = y_col),
  panel_hierarchy = panel_hierarchy,
  label_burden = label_strategy$burden,
  acceptable_simplifications = c("shared guide preferred", "panel messages recorded in metadata", "lookup labels can move to metadata"),
  must_show = c("primary panel", "supporting panel context", "shared legend when grouped"),
  may_move_to_metadata = c("full sample labels", "panel design rationale")
)

design_plan <- pp_design_plan(
  chart_family = "manuscript_four_panel",
  figure_role = figure_role,
  layout_plan = layout,
  label_strategy = label_strategy,
  palette_plan = shared_guide_plan$palette_plan,
  panel_hierarchy = panel_hierarchy,
  visible_simplifications = design_brief$acceptable_simplifications,
  risks = c("panel hierarchy may be unclear if all panels receive equal visual weight", "shared legend should not dominate")
)

mapping <- aes(x = .data[[x_col]], y = .data[[y_col]])
if (!is.null(group_col)) mapping <- aes(x = .data[[x_col]], y = .data[[y_col]], colour = .data[[group_col]])

p <- ggplot(df, mapping) +
  geom_point(size = 1.35, alpha = 0.82) +
  facet_wrap(stats::as.formula(paste("~", panel_col)), ncol = layout$ncol, scales = "free_y") +
  pp_theme(show_grid = FALSE) +
  labs(x = x_label, y = y_label, colour = group_col)
if (!is.null(group_col)) p <- p + pp_scale_color(groups = df[[group_col]]) + theme(legend.position = shared_guide_plan$legend_position)

output_files <- pp_save_all(p, output_stem, preset = preset, width = layout$width_cm, height = layout$height_cm)
invisible(lapply(output_files, pp_assert_output))

palette_check <- if (!is.null(group_col)) pp_validate_palette(df[[group_col]], "discrete") else pp_qa_result("palette", "pass", "no group colors")
layout_check <- pp_qa_result("panel_hierarchy", "pass", paste("primary panels:", paste(panel_hierarchy$primary, collapse = ", ")))
qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec, list(status = label_strategy$status, message = label_strategy$message), palette_check, layout_check),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role)
)

pp_write_notes(notes_path, figure_id, input_path, output_files, preset,
  design_decisions = c("four-panel manuscript layout", "panel hierarchy recorded", "shared guide preferred", "lookup labels can move to metadata"),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "If panels need asymmetric sizes, use optional patchwork in a future tier",
  figure_spec = figure_spec, metric_spec = metric_spec, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "none", name = "graphpad_discrete"),
  ordering = list(rule = "input order"), label_strategy = label_strategy, data_summary = pp_data_summary(df),
  design_brief = design_brief, design_plan = design_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout,
  palette = list(type = if (!is.null(group_col)) "discrete" else "none", name = "graphpad_discrete"),
  ordering = list(rule = "input order"), qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)),
  data_summary = pp_data_summary(df), design_brief = design_brief, design_plan = design_plan,
  data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy,
  palette_plan = shared_guide_plan$palette_plan, panel_hierarchy = panel_hierarchy, sidecars = list(label_key = if (file.exists(label_key_path)) label_key_path else NULL))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(output_files, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
