#!/usr/bin/env Rscript

suppressPackageStartupMessages({ library(ggplot2) })
helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER to paperplot_helpers.R or run from repository root.", call. = FALSE)
source(helper_path)
recipe_path <- Sys.getenv("PAPERPLOT_RECIPE_ENGINE")
if (!nzchar(recipe_path)) recipe_path <- "paperplot-skills/recipes/paperplot_code_recipes.R"
if (!file.exists(recipe_path)) stop("Missing recipe engine: ", recipe_path, call. = FALSE)
source(recipe_path)

input_csv <- "TODO_input.csv"
output_dir <- "outputs"
chrom_col <- "TODO_chr"
position_col <- "TODO_position"
pvalue_col <- "TODO_pvalue"
feature_col <- "TODO_gene"
figure_id <- "manhattan_genomewide"
figure_role <- "main"
scientific_message <- "Show genome-wide association signal by chromosome position with an explicit significance threshold."
recipe_id <- "manhattan_genomewide"
genomewide_threshold <- 5e-8

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv, call. = FALSE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
df <- read.csv(input_csv, check.names = FALSE)
missing_cols <- setdiff(c(chrom_col, position_col, pvalue_col), names(df)); if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
if (!feature_col %in% names(df)) df[[feature_col]] <- paste0("Variant", seq_len(nrow(df)))
df[[position_col]] <- as.numeric(df[[position_col]])
df[[pvalue_col]] <- pmax(as.numeric(df[[pvalue_col]]), .Machine$double.xmin)
df <- df[!is.na(df[[chrom_col]]) & !is.na(df[[position_col]]) & !is.na(df[[pvalue_col]]), , drop = FALSE]
if (nrow(df) < 20) stop("Manhattan template needs at least 20 genomic points.", call. = FALSE)

base <- pp_recipe_mock_data(recipe_id)
recipe_df <- base[rep(seq_len(nrow(base)), length.out = nrow(df)), ]
recipe_df$chr <- factor(df[[chrom_col]], levels = unique(df[[chrom_col]]))
recipe_df$position <- df[[position_col]]
recipe_df$pvalue <- df[[pvalue_col]]
recipe_df$feature <- as.character(df[[feature_col]])
recipe_df$padj <- p.adjust(recipe_df$pvalue, method = "BH")

timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
output_stem <- file.path(output_dir, paste0(figure_id, "_", timestamp))
notes_path <- paste0(output_stem, "_notes.md")
metadata_path <- paste0(output_stem, "_metadata.json")
qa_path <- paste0(output_stem, "_qa.md")
pp_stop_if_outputs_exist(c(paste0(output_stem, ".pdf"), paste0(output_stem, ".png"), notes_path, metadata_path, qa_path))

figure_spec <- pp_figure_spec(figure_id = figure_id, template_id = "manhattan-plot-template", task_type = "new", figure_role = figure_role, scientific_message = scientific_message, plot_type = "manhattan_genomewide", output_preset = "nature")
metric_spec <- pp_metric_spec(metric = c(pvalue_col, position_col), label = c("p-value", "Genomic position"), unit = c("unitless", "bp"), direction = c("lower_better", "neutral"), transform = c("log10", "none"), role = c("significance", "coordinate"))
label_strategy <- pp_label_strategy_v2(levels(recipe_df$chr), figure_role = figure_role, available_width_cm = 18, sample_identity_role = "supporting")
visual_budget <- pp_visual_budget(figure_role = figure_role, n_panels = 1, n_labels = length(levels(recipe_df$chr)), n_legend_entries = 0)
design_brief <- pp_design_brief(scientific_message = scientific_message, figure_role = figure_role, main_comparison = list(chromosomes = levels(recipe_df$chr), threshold = genomewide_threshold), data_roles = list(chromosome = chrom_col, position = position_col, pvalue = pvalue_col, feature = feature_col), metric_semantics = list(metrics = metric_spec), label_burden = list(strategy = label_strategy$strategy, score = label_strategy$score), acceptable_simplifications = c("Variant labels are omitted by default; label only validated lead loci."), must_show = c("chromosome order", "p-value scale", "threshold line"), may_move_to_metadata = c("full variant table", "lead-locus annotation"))
design_plan <- pp_design_plan(chart_family = "manhattan_genomewide", figure_role = figure_role, layout_plan = list(type = "single_panel_genomewide", width_cm = 18, height_cm = 7, canvas_override_reason = "Genome-wide Manhattan tracks read better wide and short than the default nature 18x12 canvas; deviation from preset height is deliberate and recorded here."), label_strategy = label_strategy, palette_plan = list(type = "alternating chromosome", name = "blue_gray"), statistical_plan = list(genomewide_threshold = genomewide_threshold), visible_simplifications = design_brief$acceptable_simplifications, risks = c("Confirm genome-wide threshold and genome build before manuscript use."), pattern_reference = pp_pattern_reference("manhattan_genomewide", template_id = "manhattan-plot-template"))

plot <- pp_recipe_plot(recipe_id, recipe_df)
qa_results <- pp_qa_summary(pp_qa_preflight(figure_spec, metric_spec), pp_qa_design_preflight(design_brief, design_plan, visual_budget), pp_qa_label_strategy(label_strategy, figure_role), pp_qa_result("genomic_coordinate_semantics", "warn", "Confirm genome build, threshold, and chromosome filtering."))
readiness <- pp_qa_manuscript_readiness(qa_results, design_brief, design_plan)
qa_results <- pp_qa_summary(qa_results, readiness)
outputs <- pp_save_all_with_qa_loop(plot, output_stem, preset = figure_spec$output_preset, qa_context = list(family = figure_spec$plot_type), width = 18, height = 7, overwrite = FALSE)
invisible(lapply(outputs, pp_assert_output))
pp_write_notes(notes_path, figure_id, input_csv, outputs, figure_spec$output_preset, design_decisions = c("Pattern reference: manhattan-genomewide.", "Chromosomes use alternating restrained colors.", "Threshold line is visible but low-weight."), qa_checks = paste(qa_results$gate, qa_results$status, qa_results$note, sep = ": "), remaining_issues = "Confirm genome build, threshold choice, and lead-locus labels.", figure_spec = figure_spec, metric_spec = metric_spec, design_brief = design_brief, design_plan = design_plan, layout = design_plan$layout_plan, palette = design_plan$palette_plan, label_strategy = label_strategy, data_summary = pp_data_profile(recipe_df, sample_col = "feature", value_col = "pvalue"))
pp_write_metadata(metadata_path, figure_spec, metric_spec, pp_extend_output_files(outputs, notes = notes_path, qa = qa_path), layout = design_plan$layout_plan, palette = design_plan$palette_plan, qa = list(status = pp_qa_status(qa_results), manuscript_readiness = readiness), data_summary = pp_data_summary(recipe_df), design_brief = design_brief, design_plan = design_plan, data_profile = pp_data_profile(recipe_df, sample_col = "feature", value_col = "pvalue"), visual_budget = visual_budget, label_strategy = label_strategy, statistical_plan = design_plan$statistical_plan)
qa_results <- pp_qa_summary(qa_results, pp_qa_postflight(outputs, notes_path = notes_path, metadata_path = metadata_path))
pp_write_qa_report(qa_path, qa_results)
