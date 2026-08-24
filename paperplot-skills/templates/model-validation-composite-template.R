#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) {
  stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from the repository root.", call. = FALSE)
}
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
x_col <- "TODO_x"
y_col <- "TODO_y"
group_col <- "TODO_group"
error_col <- NULL
figure_id <- "model_validation_composite"
figure_role <- "main"
scientific_message <- "Assess prediction performance using observed-vs-predicted fit, residual structure, and model-level summary metrics."

if (!file.exists(input_csv)) {
  stop("Input CSV not found: ", input_csv, call. = FALSE)
}
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

df <- read.csv(input_csv, check.names = FALSE)
required_cols <- c(x_col, y_col, group_col)
missing_cols <- setdiff(required_cols, names(df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
if (!is.null(error_col) && !error_col %in% names(df)) error_col <- NULL

df[[x_col]] <- as.numeric(df[[x_col]])
df[[y_col]] <- as.numeric(df[[y_col]])
df[[group_col]] <- factor(df[[group_col]])
df <- df[!is.na(df[[x_col]]) & !is.na(df[[y_col]]) & !is.na(df[[group_col]]), , drop = FALSE]
if (nrow(df) < 4) stop("Model-validation composite needs at least four complete observations.", call. = FALSE)

df$residual <- df[[y_col]] - df[[x_col]]
group_levels <- levels(df[[group_col]])

perf_parts <- lapply(seq_along(group_levels), function(i) {
  g <- group_levels[[i]]
  d <- df[df[[group_col]] == g, , drop = FALSE]
  r2 <- if (nrow(d) >= 3 && stats::sd(d[[x_col]]) > 0 && stats::sd(d[[y_col]]) > 0) {
    stats::cor(d[[x_col]], d[[y_col]], use = "complete.obs")^2
  } else {
    NA_real_
  }
  rmse <- sqrt(mean((d[[y_col]] - d[[x_col]])^2, na.rm = TRUE))
  interval <- if (!is.null(error_col)) {
    min(0.12, max(0.03, mean(abs(as.numeric(d[[error_col]])), na.rm = TRUE) / 5))
  } else {
    0.04
  }
  data.frame(
    panel = "Model performance",
    group = g,
    x_value = i,
    y_value = r2,
    lower = pmax(0, r2 - interval),
    upper = pmin(1, r2 + interval),
    rmse = rmse,
    stringsAsFactors = FALSE
  )
})
perf_df <- do.call(rbind, perf_parts)
perf_df$panel <- factor(perf_df$panel, levels = c("Observed vs predicted", "Residuals", "Model performance"))

scatter_df <- rbind(
  data.frame(panel = "Observed vs predicted", group = df[[group_col]], x_value = df[[x_col]], y_value = df[[y_col]], stringsAsFactors = FALSE),
  data.frame(panel = "Residuals", group = df[[group_col]], x_value = df[[y_col]], y_value = df$residual, stringsAsFactors = FALSE)
)
scatter_df$panel <- factor(scatter_df$panel, levels = levels(perf_df$panel))

identity_ref <- data.frame(panel = factor("Observed vs predicted", levels = levels(perf_df$panel)), intercept = 0, slope = 1)
zero_ref <- data.frame(panel = factor("Residuals", levels = levels(perf_df$panel)), yintercept = 0)

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(
  figure_id = figure_id,
  template_id = "model-validation-composite-template",
  task_type = "new",
  figure_role = figure_role,
  scientific_message = scientific_message,
  plot_type = "model_validation_composite",
  group_var = group_col,
  output_preset = "nature"
)
metric_spec <- pp_metric_spec(
  metric = c("observed", "predicted", "residual", "r_squared", "rmse"),
  label = c("Observed", "Predicted", "Residual", "R-squared", "RMSE"),
  unit = c("input unit", "input unit", "input unit", "proportion", "input unit"),
  direction = c("neutral", "neutral", "neutral", "higher_better", "lower_better"),
  transform = "none",
  role = c("primary", "primary", "diagnostic", "summary", "metadata")
)
data_profile <- pp_data_profile(df, group_col = group_col, value_col = y_col)
label_strategy <- pp_label_strategy_v2(group_levels, figure_role = figure_role, available_width_cm = 18, sample_identity_role = "core")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 3, n_labels = 0, n_legend_entries = length(group_levels))
statistical_plan <- list(
  plot_type = "model_validation_composite",
  observed_col = x_col,
  predicted_col = y_col,
  residual = "predicted - observed",
  residual_target = "centered around zero",
  summary_metrics = perf_df[, c("group", "y_value", "lower", "upper", "rmse"), drop = FALSE]
)

design_brief <- pp_design_brief(
  scientific_message = scientific_message,
  figure_role = figure_role,
  main_comparison = list(groups = group_levels, metrics = c("fit", "residual", "performance")),
  data_roles = list(observed = x_col, predicted = y_col, model_or_split = group_col),
  metric_semantics = list(metrics = metric_spec),
  label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score),
  acceptable_simplifications = c("show model-level R-squared in the visible composite", "move RMSE and interval method details to metadata"),
  must_show = c("observed-vs-predicted fit", "residual centering", "model-level performance"),
  may_move_to_metadata = c("RMSE table", "complete residual table", "interval computation details")
)

design_plan <- pp_design_plan(
  chart_family = "model_validation_composite",
  figure_role = figure_role,
  layout_plan = list(type = "three_panel_validation_composite", nrow = 1, ncol = 3, width_cm = 18, height_cm = 8.5),
  label_strategy = label_strategy,
  palette_plan = list(type = "model_or_split", name = "graphpad_discrete", max_groups = length(group_levels)),
  statistical_plan = statistical_plan,
  visible_simplifications = design_brief$acceptable_simplifications,
  risks = c("summary intervals are approximate unless the input provides resampling uncertainty"),
  pattern_reference = pp_pattern_reference("model-validation", template_id = "model-validation-composite-template")
)

p <- ggplot() +
  geom_abline(data = identity_ref, aes(intercept = intercept, slope = slope), inherit.aes = FALSE, linewidth = 0.35, linetype = "dashed", color = "#6D6D6D") +
  geom_hline(data = zero_ref, aes(yintercept = yintercept), inherit.aes = FALSE, linewidth = 0.35, linetype = "dashed", color = "#6D6D6D") +
  geom_point(data = scatter_df, aes(x = x_value, y = y_value, colour = group), size = pp_point_size("normal"), alpha = 0.76) +
  geom_segment(data = perf_df, aes(x = x_value, xend = x_value, y = lower, yend = upper, colour = group), linewidth = 0.45, inherit.aes = FALSE, na.rm = TRUE) +
  geom_point(data = perf_df, aes(x = x_value, y = y_value, colour = group), size = pp_point_size("emphasis"), inherit.aes = FALSE, na.rm = TRUE) +
  facet_wrap(~ panel, scales = "free", ncol = 3) +
  pp_scale_color(groups = group_levels) +
  pp_theme(base_size = 7, show_grid = FALSE) +
  labs(x = "Observed, predicted, or model index", y = "Model-validation value", colour = group_col)

qa_results <- pp_qa_summary(
  pp_qa_preflight(figure_spec, metric_spec, list(status = label_strategy$status, message = label_strategy$message)),
  pp_qa_design_preflight(design_brief, design_plan, visual_budget),
  pp_qa_label_strategy(label_strategy, figure_role),
  pp_qa_result("statistical_expression", "warn", "Composite shows fit, residuals, and R-squared; confirm interval definition before final manuscript use.")
)

outputs <- pp_save_all_with_qa_loop(p, output_stem, preset = figure_spec$output_preset, qa_context = list(family = figure_spec$plot_type), width = 18, height = 8.5, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))

qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)

pp_write_notes(
  notes_path,
  figure_id = figure_id,
  input_path = input_csv,
  output_files = outputs,
  preset = figure_spec$output_preset,
  design_decisions = c(
    "Code recipe link: model_validation_composite.",
    "Three-panel composite follows the model-validation pattern: fit, residuals, and performance summary.",
    "Reference lines are dashed and low-weight to support interpretation without dominating the panel.",
    "RMSE and interval details are preserved in metadata rather than overloading the visible figure."
  ),
  qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "),
  remaining_issues = "Confirm observed/predicted units and interval method before manuscript submission.",
  figure_spec = figure_spec,
  metric_spec = metric_spec,
  design_brief = design_brief,
  design_plan = design_plan,
  layout = design_plan$layout_plan,
  palette = design_plan$palette_plan,
  label_strategy = label_strategy,
  data_summary = data_profile
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
  data_profile = data_profile,
  visual_budget = visual_budget,
  label_strategy = label_strategy,
  statistical_plan = statistical_plan
)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
