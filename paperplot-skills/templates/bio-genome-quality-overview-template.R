#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
sample_col <- "TODO_sample"
metric_col <- "TODO_metric"
value_col <- "TODO_value"
group_col <- "TODO_group"
unit_col <- "TODO_unit"
score_col <- "TODO_score"
figure_id <- "bio_genome_quality_overview"
figure_role <- "main"
scientific_message <- "Compare genome or assembly quality across samples using heterogeneous metrics without hiding raw units."

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

df <- read.csv(input_csv, check.names = FALSE)
required <- c(sample_col, metric_col, value_col)
if (!is.null(group_col) && group_col %in% names(df)) required <- c(required, group_col)
missing_cols <- setdiff(required, names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[sample_col]] <- as.character(df[[sample_col]])
df[[metric_col]] <- as.character(df[[metric_col]])
df[[value_col]] <- as.numeric(df[[value_col]])
df <- df[!is.na(df[[sample_col]]) & !is.na(df[[metric_col]]) & !is.na(df[[value_col]]), , drop = FALSE]
metric_levels <- unique(df[[metric_col]])
metric_spec <- pp_bio_genome_quality_spec(metric_levels)
if (unit_col %in% names(df)) {
  unit_map <- tapply(as.character(df[[unit_col]]), df[[metric_col]], function(x) x[which(nzchar(x))[1]] %||% "a.u.")
  metric_spec$unit <- as.character(unit_map[metric_spec$metric])
  metric_spec$unit[is.na(metric_spec$unit) | !nzchar(metric_spec$unit)] <- "a.u."
  pp_validate_metric_spec(metric_spec)
}
metric_label_map <- setNames(paste0(metric_spec$label, " (", metric_spec$unit, ")"), metric_spec$metric)
df$facet_label <- metric_label_map[df[[metric_col]]]

sample_order <- pp_bio_rank_samples(df, metrics = metric_levels, sample_col = sample_col, metric_col = metric_col, value_col = value_col, score_col = if (score_col %in% names(df)) score_col else NULL, group_col = if (group_col %in% names(df)) group_col else NULL)
df <- pp_prepare_rank_axis(df, sample_col = sample_col, sample_order = sample_order, index_col = "rank_index")
key_samples <- pp_bio_select_key_samples(df, sample_col = sample_col, metrics = metric_levels, group_col = if (group_col %in% names(df)) group_col else NULL, value_col = value_col, max_labels = 8)
key_df <- df[df[[sample_col]] %in% key_samples, , drop = FALSE]

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
label_key_path <- paste0(output_stem, "_label_key.csv")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path, label_key_path))
pp_write_label_key(label_key_path, attr(df, "rank_map"))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "bio-genome-quality-overview-template", task_type = "new", figure_role = figure_role, scientific_message = scientific_message, plot_type = "bio_genome_quality_small_multiples", sample_id = sample_col, group_var = if (group_col %in% names(df)) group_col else NULL, output_preset = "double_column")
data_profile <- pp_data_profile(df, sample_col = sample_col, group_col = if (group_col %in% names(df)) group_col else NULL, metric_col = metric_col, value_col = value_col)
label_strategy <- list(status = "warn", strategy = "rank_index_key_labels", visible_label_policy = "rank index plus selected key labels", sample_identity_role = "lookup", needs_label_key = TRUE, direct_label_mode = "selected_key_samples", sidecar = label_key_path, message = "Dense sample names moved to label key sidecar.")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = length(metric_levels), n_labels = length(key_samples), n_legend_entries = if (group_col %in% names(df)) length(unique(df[[group_col]])) else 0)

design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(samples = sample_col, metrics = metric_levels, group = group_col), data_roles = list(sample = "lookup identity", metric = "heterogeneous genome quality measure", value = "raw metric value"), metric_semantics = list(metrics = metric_spec), label_burden = list(strategy = label_strategy$strategy), acceptable_simplifications = c("Full sample names moved to label-key sidecar.", "Rank index preserves manuscript rhythm without dumping labels."), must_show = c("metric-specific values", "group pattern", "key samples"), may_move_to_metadata = c("full sample names", "complete sample order", "ranking rule"))
layout <- pp_recommend_facet_grid(length(metric_levels), plot_type = "small_multiples")
design_plan <- pp_design_plan(chart_family = "bio_genome_quality_small_multiples", figure_role = figure_role, layout_plan = layout, label_strategy = label_strategy, palette_plan = list(color_role = group_col, consistent_across_panels = TRUE), statistical_plan = list(type = "descriptive"), visible_simplifications = design_brief$acceptable_simplifications, risks = c("dense sample labels", "heterogeneous units"))

color_aes <- if (group_col %in% names(df)) aes(color = .data[[group_col]]) else aes()
# Overlap-safe labels (WP4): ggrepel when available, legacy fallback otherwise.
sample_label_layer <- if (requireNamespace("ggrepel", quietly = TRUE)) {
  ggrepel::geom_text_repel(
    data = key_df, ggplot2::aes(label = .data[[sample_col]]),
    size = 1.8, color = "#2F2F2D", max.overlaps = 20,
    segment.size = 0.25, min.segment.length = 0, seed = 42
  )
} else {
  ggplot2::geom_text(data = key_df, ggplot2::aes(label = .data[[sample_col]]), size = 1.8, vjust = -0.75, check_overlap = TRUE, color = "#2F2F2D")
}
plot <- ggplot(df, aes(x = rank_index, y = .data[[value_col]])) +
  geom_point(color_aes, size = 1.7, alpha = 0.88) +
  sample_label_layer +
  facet_wrap(~facet_label, scales = "free_y", nrow = layout$nrow) +
  labs(x = "Sample rank index", y = NULL, color = "Group") +
  pp_theme(base_size = 7) +
  theme(legend.position = if (group_col %in% names(df)) "bottom" else "none")
if (group_col %in% names(df)) plot <- plot + pp_scale_color(unique(df[[group_col]]))

qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("bio_metric_semantics", "pass", "Genome quality metric directions and units recorded."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))

pp_write_notes(notes_path, figure_id = figure_id, input_path = input_csv, output_files = outputs, preset = figure_spec$output_preset, design_decisions = c("2x3-style small multiples used for heterogeneous metrics.", "Raw units retained in facet labels.", "Full sample names moved to label-key sidecar."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm metric direction and ranking weights before final manuscript use.", figure_spec = figure_spec, metric_spec = metric_spec, layout = layout, palette = design_plan$palette_plan, ordering = list(rule = "bio quality rank", sample_order = paste(sample_order, collapse = ", ")), label_strategy = label_strategy, data_summary = data_profile, design_brief = design_brief, design_plan = design_plan)
pp_write_metadata(metadata_path, figure_spec, metric_spec, outputs, layout = layout, palette = design_plan$palette_plan, ordering = list(rule = "bio quality rank", sample_order = sample_order), qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)), data_summary = data_profile, design_brief = design_brief, design_plan = design_plan, data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy, palette_plan = design_plan$palette_plan, sidecars = list(label_key = label_key_path))
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
