#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })
helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
gene_col <- "TODO_gene"
base_mean_col <- "TODO_base_mean"
log2fc_col <- "TODO_log2fc"
padj_col <- "TODO_padj"
figure_id <- "ma_plot"
figure_role <- "main"
scientific_message <- "Show fold-change behavior across expression abundance while keeping low-abundance uncertainty visible."
padj_threshold <- 0.05

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(gene_col, base_mean_col, log2fc_col, padj_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[base_mean_col]] <- pmax(as.numeric(df[[base_mean_col]]), 0)
df[[log2fc_col]] <- as.numeric(df[[log2fc_col]])
df[[padj_col]] <- as.numeric(df[[padj_col]])
df$log10_base_mean <- log10(df[[base_mean_col]] + 1)
df$significant <- ifelse(df[[padj_col]] <= padj_threshold, "significant", "not_significant")
key_idx <- order(df[[padj_col]], -abs(df[[log2fc_col]]))[seq_len(min(8, nrow(df)))]
key_df <- df[key_idx, , drop = FALSE]

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "ma-plot-template", figure_role = figure_role, scientific_message = scientific_message, plot_type = "ma_plot", output_preset = "nature_half")
metric_spec <- pp_metric_spec(metric = c(base_mean_col, log2fc_col, padj_col), label = c("base mean", "log2 fold change", "adjusted p-value"), unit = c("count", "log2 ratio", "unitless"), direction = c("neutral", "neutral", "lower_better"), transform = c("log10", "none", "none"), role = c("abundance", "effect_size", "significance"))
data_profile <- pp_data_profile(df, sample_col = gene_col, value_col = log2fc_col)
label_strategy <- list(status = "pass", strategy = "selected_extreme_labels", visible_label_policy = "label top differential features only", needs_label_key = FALSE, direct_label_mode = "selected genes", message = "Only selected genes are directly labeled.")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = nrow(key_df), n_legend_entries = 2)
# WP3: legend placement decided from estimated physical footprint, not hardcoded.
legend_plan <- pp_legend_plan(entries = 2, labels = c("significant", "not_significant"),
                              canvas_width_cm = pp_output_preset("nature_half")$width_cm,
                              canvas_height_cm = pp_output_preset("nature_half")$height_cm,
                              has_title = TRUE)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(abundance = base_mean_col, effect = log2fc_col), data_roles = list(feature = "lookup identity", abundance = "x-axis", effect = "y-axis"), metric_semantics = list(metrics = metric_spec), acceptable_simplifications = c("Only selected genes are labeled."), must_show = c("abundance", "fold-change", "significance class"), may_move_to_metadata = c("full feature labels"))
design_plan <- pp_design_plan(chart_family = "ma_plot", figure_role = figure_role, layout_plan = list(type = "single_panel"), label_strategy = label_strategy, palette_plan = list(color_role = "adjusted significance"), statistical_plan = list(padj_threshold = padj_threshold), visible_simplifications = design_brief$acceptable_simplifications, risks = c("low abundance estimates may be noisy"))

plot <- ggplot(df, aes(x = log10_base_mean, y = .data[[log2fc_col]], color = significant)) +
  geom_hline(yintercept = 0, linewidth = 0.35, color = "#4D4D4A") +
  geom_point(alpha = 0.72, size = 1.25) +
  geom_text(data = key_df, aes(label = .data[[gene_col]]), size = 1.8, vjust = -0.7, check_overlap = TRUE, color = "#1D1D1B") +
  scale_color_manual(values = c(significant = "#D9342B", not_significant = "#B8B8B2"), name = "Class") +
  labs(x = "log10(base mean + 1)", y = "log2 fold change") +
  pp_theme(base_size = 7) +
  pp_apply_legend_plan(plan = legend_plan)
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("bio_ma_semantics", "pass", "Abundance and fold change are separated on x/y axes."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id = figure_id, input_path = input_csv, output_files = outputs, preset = figure_spec$output_preset, design_decisions = c("MA plot separates abundance from fold-change.", "Only selected top genes are labeled."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm whether low-count filtering was applied upstream.", figure_spec = figure_spec, metric_spec = metric_spec, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = data_profile, design_brief = design_brief, design_plan = design_plan)
pp_write_metadata(metadata_path, figure_spec, metric_spec, outputs, layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)), data_summary = data_profile, design_brief = design_brief, design_plan = design_plan, data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy, palette_plan = design_plan$palette_plan, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
