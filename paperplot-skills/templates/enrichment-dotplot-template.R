#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })
helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
term_col <- "TODO_term"
ratio_col <- "TODO_ratio"
qvalue_col <- "TODO_qvalue"
count_col <- "TODO_count"
category_col <- "TODO_category"
figure_id <- "enrichment_dotplot"
figure_role <- "main"
scientific_message <- "Summarize enriched terms by enrichment ratio, supporting count, and adjusted significance."
max_terms <- 20

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(term_col, ratio_col, qvalue_col, count_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
df[[ratio_col]] <- as.numeric(df[[ratio_col]])
df[[qvalue_col]] <- pmax(as.numeric(df[[qvalue_col]]), .Machine$double.xmin)
df[[count_col]] <- as.numeric(df[[count_col]])
df <- df[order(df[[qvalue_col]], -df[[ratio_col]]), , drop = FALSE]
df <- head(df, max_terms)
df[[term_col]] <- factor(df[[term_col]], levels = rev(unique(df[[term_col]])))
df$neg_log10_q <- -log10(df[[qvalue_col]])

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "enrichment-dotplot-template", figure_role = figure_role, scientific_message = scientific_message, plot_type = "enrichment_dotplot", group_var = if (category_col %in% names(df)) category_col else NULL, output_preset = "nature_half")
metric_spec <- pp_metric_spec(metric = c(ratio_col, qvalue_col, count_col), label = c("enrichment ratio", "q-value", "count"), unit = c("ratio", "unitless", "count"), direction = c("higher_better", "lower_better", "neutral"), transform = c("none", "log10", "none"), role = c("effect_size", "significance", "support"))
data_profile <- pp_data_profile(df, group_col = if (category_col %in% names(df)) category_col else NULL, value_col = ratio_col)
label_strategy <- list(status = "warn", strategy = "top_term_labels_visible", visible_label_policy = "show selected top terms", needs_label_key = FALSE, direct_label_mode = "none", message = "Only top enrichment terms are shown to protect label budget.")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = nrow(df), n_legend_entries = 2)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(term = term_col, ratio = ratio_col, qvalue = qvalue_col), data_roles = list(term = "y-axis category", ratio = "x-axis", count = "point size", qvalue = "color"), metric_semantics = list(metrics = metric_spec), acceptable_simplifications = c("Only the top enriched terms are shown."), must_show = c("term", "ratio", "count", "q-value"), may_move_to_metadata = c("full enrichment table", "terms beyond max_terms"))
design_plan <- pp_design_plan(chart_family = "enrichment_dotplot", figure_role = figure_role, layout_plan = list(type = "single_panel"), label_strategy = label_strategy, palette_plan = list(color_role = "-log10 q-value", size_role = "count"), statistical_plan = list(max_terms = max_terms), visible_simplifications = design_brief$acceptable_simplifications, risks = c("long term labels"))

plot <- ggplot(df, aes(x = .data[[ratio_col]], y = .data[[term_col]], size = .data[[count_col]], color = neg_log10_q)) +
  geom_point(alpha = 0.86) +
  scale_color_gradient(low = "#9FB7C9", high = "#B33A2B", name = "-log10 q") +
  labs(x = "Enrichment ratio", y = NULL, size = "Count") +
  pp_theme(base_size = 7) + theme(legend.position = "right")
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("bio_enrichment_semantics", "pass", "Ratio, count, and q-value use distinct visual channels."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all(plot, output_stem, preset = figure_spec$output_preset, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id = figure_id, input_path = input_csv, output_files = outputs, preset = figure_spec$output_preset, design_decisions = c("Dot size encodes count.", "Color encodes adjusted significance.", "Only top enriched terms are shown to protect label budget."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm term filtering and ontology source before final submission.", figure_spec = figure_spec, metric_spec = metric_spec, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = data_profile, design_brief = design_brief, design_plan = design_plan)
pp_write_metadata(metadata_path, figure_spec, metric_spec, outputs, layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), readiness_score = pp_manuscript_readiness_score(qa_results)), data_summary = data_profile, design_brief = design_brief, design_plan = design_plan, data_profile = data_profile, visual_budget = visual_budget, label_strategy = label_strategy, palette_plan = design_plan$palette_plan, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
