#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
})

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Set PAPERPLOT_HELPER or run from the package root.", call. = FALSE)
source(helper_path)

out_root <- file.path("paperplot-skills", "reports", "redraw-benchmark")
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

# Author-private benchmark inputs live outside the repo. Set PAPERPLOT_FIXTURE_DIR
# to the base directory holding them; without it this benchmark is skipped
# (no hardcoded machine-specific path).
fixture_base <- Sys.getenv("PAPERPLOT_FIXTURE_DIR")
if (!nzchar(fixture_base)) {
  message("PAPERPLOT_FIXTURE_DIR not set; skipping author-private redraw benchmark.")
  quit(save = "no", status = 0)
}
fx <- function(rel) file.path(fixture_base, rel)
old_fig4 <- fx("10-GS/final_results/figures/fig4_quality_traits.png")
fig4_data <- fx("10-GS/final_results/tables/quality_nonlinear_summary.tsv")
old_nlr <- fx("7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/figures/high_nlr_count_by_sample.svg")
nlr_data <- fx("7-Pangenome/3-Structure/NLR/FINAL_NLR_ANALYSIS_RELEASE/03_pangenome_results/plots/data/high_nlr_sample_counts_for_plot.tsv")

read_tsv <- function(path) {
  read.delim(path, sep = "\t", header = TRUE, quote = "", check.names = FALSE, comment.char = "")
}

model_colors <- c(
  GBLUP = "#4E79A7",
  RKHS = "#59A14F",
  BayesB = "#E6A157",
  BayesCpi = "#C95A4E"
)

trait_labels <- c(
  "分枝情况" = "Branching habit",
  "叶片边缘" = "Leaf margin",
  "果穗形状" = "Panicle shape",
  "茎秆条纹" = "Stem striation"
)

quality <- read_tsv(fig4_data)
quality$Trait_label <- unname(trait_labels[quality$Trait])
quality$Trait_label[is.na(quality$Trait_label)] <- quality$Trait[is.na(quality$Trait_label)]
quality$Trait_label <- factor(quality$Trait_label, levels = rev(unname(trait_labels)))
quality$Model <- factor(quality$Model, levels = names(model_colors))
trait_index <- stats::setNames(seq_along(levels(quality$Trait_label)), levels(quality$Trait_label))
model_offset <- stats::setNames(seq(-0.27, 0.27, length.out = length(model_colors)), names(model_colors))
quality$y_pos <- unname(trait_index[as.character(quality$Trait_label)] + model_offset[as.character(quality$Model)])
quality$xmin <- pmax(quality$mean_cor - quality$sd_cor, 0)
quality$xmax <- quality$mean_cor + quality$sd_cor
fig4_plot <- ggplot(quality) +
  geom_segment(aes(x = xmin, xend = xmax, y = y_pos, yend = y_pos, colour = Model), linewidth = 0.42, alpha = 0.8) +
  geom_point(aes(x = mean_cor, y = y_pos, colour = Model), size = 1.9, alpha = 0.92) +
  scale_colour_manual(values = model_colors, name = "Model") +
  scale_y_continuous(breaks = seq_along(levels(quality$Trait_label)), labels = levels(quality$Trait_label), expand = expansion(mult = c(0.08, 0.08))) +
  scale_x_continuous(limits = c(0, max(quality$xmax) * 1.04), breaks = seq(0, 0.5, by = 0.1), expand = expansion(mult = c(0, 0.04))) +
  labs(x = "Prediction accuracy (mean correlation +/- SD)", y = NULL) +
  pp_theme(base_size = 7, show_grid = FALSE) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    legend.title = element_text(size = 6),
    legend.text = element_text(size = 6),
    axis.text.y = element_text(size = 6.5),
    plot.margin = margin(4, 7, 4, 4)
  )

fig4_stem <- file.path(out_root, "fig4_quality_traits_pattern_redraw")
fig4_outputs <- pp_save_all(fig4_plot, fig4_stem, preset = "nature", overwrite = TRUE, width = 12.2, height = 6.2)

nlr <- read_tsv(nlr_data)
nlr$Sample <- factor(nlr$Sample, levels = rev(nlr$Sample[order(nlr$High_NLR_total, decreasing = TRUE)]))
nlr$rank <- rank(-nlr$High_NLR_total, ties.method = "first")
top_label <- nlr$rank <= 3

nlr_plot <- ggplot(nlr, aes(x = High_NLR_total, y = Sample)) +
  geom_segment(aes(x = 0, xend = High_NLR_total, yend = Sample), linewidth = 0.38, colour = "#A8B5C3") +
  geom_point(size = 2.0, colour = "#4E79A7") +
  geom_text(
    data = nlr[top_label, , drop = FALSE],
    aes(label = High_NLR_total),
    hjust = -0.2,
    size = 2.0,
    colour = "#2D2D2D"
  ) +
  scale_x_continuous(limits = c(0, max(nlr$High_NLR_total) * 1.08), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "High-confidence NLR genes", y = NULL) +
  pp_theme(base_size = 7, show_grid = FALSE) +
  theme(
    axis.text.y = element_text(size = 5.8),
    plot.margin = margin(4, 7, 4, 4)
  )

nlr_stem <- file.path(out_root, "high_nlr_count_by_sample_pattern_redraw")
nlr_outputs <- pp_save_all(nlr_plot, nlr_stem, preset = "single_column", overwrite = TRUE, width = 8.9, height = 8.2)

manifest <- data.frame(
  case = c("fig4_quality_traits", "high_nlr_count_by_sample"),
  old_figure = c(old_fig4, old_nlr),
  data_path = c(fig4_data, nlr_data),
  new_pdf = c(fig4_outputs[["pdf"]], nlr_outputs[["pdf"]]),
  new_png = c(fig4_outputs[["png"]], nlr_outputs[["png"]]),
  pattern = c(
    "references/pattern-library/model-validation-figures.md + grouped-bar-errorbar.md",
    "references/pattern-library/grouped-bar-errorbar.md"
  ),
  redraw_strategy = c(
  "replace thick grouped bars with compact horizontal point-ranges and a shared model legend",
    "replace sample-name rotated bar chart with sorted horizontal lollipop and top-count labels"
  ),
  stringsAsFactors = FALSE
)
write.table(manifest, file.path(out_root, "redraw_benchmark_manifest.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

cat("redraw benchmark figures written to ", out_root, "\n", sep = "")
print(manifest)
