#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })
helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
gene_col <- "TODO_gene"
log2fc_col <- "TODO_log2fc"
padj_col <- "TODO_padj"
figure_id <- "volcano_plot"
figure_role <- "main"
scientific_message <- "Show differential signal by effect direction, magnitude, and adjusted significance."
log2fc_threshold <- 1
padj_threshold <- 0.05

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(gene_col, log2fc_col, padj_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[log2fc_col]] <- as.numeric(df[[log2fc_col]])
df[[padj_col]] <- pmax(as.numeric(df[[padj_col]]), .Machine$double.xmin)
df$neg_log10_padj <- -log10(df[[padj_col]])
df$volcano_class <- ifelse(df[[padj_col]] <= padj_threshold & df[[log2fc_col]] >= log2fc_threshold, "up", ifelse(df[[padj_col]] <= padj_threshold & df[[log2fc_col]] <= -log2fc_threshold, "down", "not_significant"))
key_idx <- order(df[[padj_col]], -abs(df[[log2fc_col]]))[seq_len(min(8, nrow(df)))]
key_df <- df[key_idx, , drop = FALSE]

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "volcano-plot-template", figure_role = figure_role, scientific_message = scientific_message, plot_type = "volcano", output_preset = "nature_half")
metric_spec <- pp_metric_spec(metric = c(log2fc_col, padj_col), label = c("log2 fold change", "adjusted p-value"), unit = c("log2 ratio", "unitless"), direction = c("neutral", "lower_better"), transform = c("none", "log10"), role = c("effect_size", "significance"))
data_profile <- pp_data_profile(df, sample_col = gene_col, value_col = log2fc_col)
label_strategy <- list(status = "pass", strategy = "selected_extreme_labels", visible_label_policy = "label top differential features only", needs_label_key = FALSE, direct_label_mode = "selected genes", message = "Only selected genes are directly labeled.")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = nrow(key_df), n_legend_entries = 3)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(effect = log2fc_col, significance = padj_col), data_roles = list(feature = "lookup identity", effect = "x-axis", significance = "y-axis"), metric_semantics = list(metrics = metric_spec), acceptable_simplifications = c("Only top differential features are labeled."), must_show = c("effect direction", "adjusted significance", "thresholds"), may_move_to_metadata = c("full feature table", "all gene labels"))
design_plan <- pp_design_plan(chart_family = "volcano", figure_role = figure_role, layout_plan = list(type = "single_panel"), label_strategy = label_strategy, palette_plan = list(color_role = "differential class"), statistical_plan = list(thresholds = list(log2fc = log2fc_threshold, padj = padj_threshold)), visible_simplifications = design_brief$acceptable_simplifications, risks = character())

plot <- ggplot(df, aes(x = .data[[log2fc_col]], y = neg_log10_padj, color = volcano_class)) +
  geom_point(alpha = 0.54, size = 0.85) +
  geom_vline(xintercept = c(-log2fc_threshold, log2fc_threshold), linetype = "dashed", linewidth = 0.28, color = "#888888") +
  geom_hline(yintercept = -log10(padj_threshold), linetype = "dashed", linewidth = 0.28, color = "#888888") +
  geom_text(data = key_df, aes(label = .data[[gene_col]]), size = 1.8, vjust = -0.7, check_overlap = TRUE, color = "#1D1D1B") +
  scale_color_manual(values = c(up = "#C95A4E", down = "#4E79A7", not_significant = "#B8B8B2"), name = "Class") +
  labs(x = "log2 fold change", y = "-log10 adjusted p-value") +
  pp_theme(base_size = 7) + theme(legend.position = "bottom")
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("bio_volcano_semantics", "pass", "Effect size and adjusted significance are encoded on separate axes."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id = figure_id, input_path = input_csv, output_files = outputs, preset = figure_spec$output_preset, design_decisions = c("Pattern reference: volcano-ma-enrichment.", "Neutral background points are muted.", "Color encodes differential class.", "Only selected top genes are labeled.", "Threshold lines are shown explicitly."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm fold-change and adjusted p-value thresholds match the analysis plan.", figure_spec = figure_spec, metric_spec = metric_spec, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = data_profile, design_brief = design_brief, design_plan = design_plan)
pp_write_metadata(metadata_path, figure_spec, metric_spec, outputs, layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)), data_summary = data_profile, design_brief = design_brief, design_plan = design_plan, data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy, palette_plan = design_plan$palette_plan, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
