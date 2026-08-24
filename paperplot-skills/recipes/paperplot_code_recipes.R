# Executable code recipes distilled from the R replica archive.
# This file is intentionally standalone: base R + ggplot2 + paperplot_helpers.R.

pp_recipe_mock_data <- function(recipe_id, seed = 20260606) {
  set.seed(seed)
  n <- 240
  samples <- paste0("S", sprintf("%02d", seq_len(40)))
  groups <- c("Control", "Treatment", "Rescue")
  categories <- paste0("Category ", LETTERS[1:8])
  metrics <- c("Growth", "Defense", "Yield", "Stress", "Quality", "Signal")
  df <- data.frame(
    sample = rep(samples, length.out = n),
    group = factor(rep(groups, length.out = n), levels = groups),
    category = factor(rep(categories, length.out = n), levels = categories),
    metric = factor(rep(metrics, each = 40, length.out = n), levels = metrics),
    value = round(rnorm(n, mean = rep(c(0.2, 0.55, 0.85), length.out = n), sd = 0.16), 3),
    error = round(runif(n, 0.04, 0.12), 3),
    x = round(rnorm(n, mean = rep(c(-0.7, 0.2, 0.9), length.out = n), sd = 0.7), 3),
    y = round(rnorm(n, mean = rep(c(-0.3, 0.5, 0.9), length.out = n), sd = 0.8), 3),
    pc1 = round(rnorm(n, mean = rep(c(-1.2, 0.4, 1.0), length.out = n), sd = 0.55), 3),
    pc2 = round(rnorm(n, mean = rep(c(0.6, -0.4, 0.2), length.out = n), sd = 0.55), 3),
    feature = paste0("Gene", sprintf("%04d", seq_len(n))),
    log2fc = round(rnorm(n, mean = rep(c(-0.5, 0, 0.6), length.out = n), sd = 1.1), 3),
    base_mean = round(exp(rnorm(n, mean = 4.5, sd = 1.1)), 3),
    pvalue = pmax(runif(n, 0.0001, 0.95), .Machine$double.xmin),
    term = paste("Pathway", rep(seq_len(30), length.out = n)),
    ratio = round(runif(n, 0.03, 0.7), 3),
    count = sample(5:120, n, replace = TRUE),
    chr = factor(rep(paste0("Chr", seq_len(8)), each = 30, length.out = n), levels = paste0("Chr", seq_len(8))),
    position = rep(seq(1, 30), times = 8, length.out = n) * 1e6 + sample(1:99999, n, replace = TRUE),
    item = rep(paste0("Item", sprintf("%02d", seq_len(60))), length.out = n),
    set = factor(rep(paste0("Set", LETTERS[1:5]), length.out = n), levels = paste0("Set", LETTERS[1:5])),
    present = sample(c(0, 1), n, replace = TRUE, prob = c(0.45, 0.55)),
    source = factor(rep(paste0("Source", LETTERS[1:5]), length.out = n)),
    target = factor(rep(paste0("Target", LETTERS[1:5]), each = 3, length.out = n)),
    node = paste0("N", seq_len(n)),
    parent = c(NA, paste0("N", sample(seq_len(n - 1), n - 1, replace = TRUE))),
    time = rep(seq_len(12), length.out = n),
    bin = factor(rep(paste0("Bin", seq_len(10)), length.out = n)),
    longitude = round(runif(n, 70, 125), 4),
    latitude = round(runif(n, 15, 52), 4),
    start = rep(seq(1, 24), length.out = n) * 100000,
    end = rep(seq(1, 24), length.out = n) * 100000 + sample(20000:90000, n, replace = TRUE),
    track = factor(rep(paste0("Track", seq_len(4)), length.out = n)),
    segment = factor(rep(paste0("Segment", seq_len(6)), length.out = n)),
    weight = round(runif(n, 0.2, 2.8), 3),
    stringsAsFactors = FALSE
  )
  df$padj <- p.adjust(df$pvalue, method = "BH")
  df$qvalue <- p.adjust(runif(n, 0.0002, 0.45), method = "BH")
  df$estimate <- round(rnorm(n, sd = 0.55), 3)
  df$lower <- df$estimate - runif(n, 0.1, 0.35)
  df$upper <- df$estimate + runif(n, 0.1, 0.35)
  df$observed <- round(plogis(df$x + rnorm(n, sd = 0.4)), 3)
  df$predicted <- round(pmin(1, pmax(0, df$observed + rnorm(n, sd = 0.08))), 3)
  df$residual <- round(df$observed - df$predicted, 3)
  df$class <- ifelse(df$padj < 0.05 & df$log2fc > 1, "Up", ifelse(df$padj < 0.05 & df$log2fc < -1, "Down", "NS"))
  df$label <- ifelse(seq_len(n) <= 12, df$feature, "")
  if (grepl("manhattan", recipe_id)) {
    m <- 640
    df <- df[rep(seq_len(nrow(df)), length.out = m), , drop = FALSE]
    df$chr <- factor(rep(paste0("Chr", seq_len(8)), each = m / 8), levels = paste0("Chr", seq_len(8)))
    df$position <- rep(seq_len(m / 8), times = 8) * 350000 + sample(1:99999, m, replace = TRUE)
    df$pvalue <- pmax(runif(m, 0.0001, 0.95), .Machine$double.xmin)
    df$pvalue[sample(seq_len(m), 16)] <- runif(16, 1e-8, 1e-5)
    df$padj <- p.adjust(df$pvalue, method = "BH")
  }
  if (recipe_id %in% c("grouped_bar_errorbar_raw", "stacked_bar_fraction")) {
    keep_categories <- paste0("Category ", LETTERS[1:3])
    keep_groups <- groups[1:2]
    df <- df[df$category %in% keep_categories & df$group %in% keep_groups & df$sample %in% samples[1:24], , drop = FALSE]
    df$category <- factor(as.character(df$category), levels = keep_categories)
    df$group <- factor(as.character(df$group), levels = keep_groups)
  }
  if (recipe_id %in% c("correlation_heatmap", "annotated_heatmap", "matrix_dotplot")) {
    keep_categories <- paste0("Category ", LETTERS[1:5])
    keep_metrics <- metrics[1:5]
    keep_groups <- groups[1:2]
    df <- df[df$category %in% keep_categories & df$metric %in% keep_metrics & df$group %in% keep_groups, , drop = FALSE]
    df$category <- factor(as.character(df$category), levels = keep_categories)
    df$metric <- factor(as.character(df$metric), levels = keep_metrics)
    df$group <- factor(as.character(df$group), levels = keep_groups)
  }
  if (recipe_id == "upset_summary") {
    keep_sets <- paste0("Set", LETTERS[1:4])
    keep_items <- paste0("Item", sprintf("%02d", seq_len(24)))
    df <- df[df$set %in% keep_sets & df$item %in% keep_items, , drop = FALSE]
    df$set <- factor(as.character(df$set), levels = keep_sets)
  }
  if (grepl("time_series|calibration", recipe_id)) {
    df <- df[df$metric %in% metrics[1:3] & df$group %in% groups[1:3], , drop = FALSE]
    df$time <- rep(seq_len(12), length.out = nrow(df))
  }
  if (grepl("spatial|map", recipe_id)) {
    df$group <- factor(rep(groups, length.out = nrow(df)), levels = groups)
    df$value <- round(runif(nrow(df), 0, 1), 3)
  }
  if (grepl("genome|track|synteny|regional", recipe_id)) {
    df$chr <- factor(rep(paste0("Chr", seq_len(5)), length.out = nrow(df)), levels = paste0("Chr", seq_len(5)))
    df$start <- rep(seq_len(48), length.out = nrow(df)) * 150000
    df$end <- df$start + sample(40000:120000, nrow(df), replace = TRUE)
    df$position <- df$start + sample(1000:50000, nrow(df), replace = TRUE)
  }
  df
}

pp_recipe_base <- function() {
  pp_theme(base_size = 7, show_grid = FALSE) +
    ggplot2::theme(plot.title = ggplot2::element_blank())
}

pp_recipe_aggregate_mean <- function(df, by) {
  mean_df <- stats::aggregate(df$value, df[by], mean, na.rm = TRUE)
  names(mean_df)[ncol(mean_df)] <- "mean"
  sd_df <- stats::aggregate(df$value, df[by], stats::sd, na.rm = TRUE)
  names(sd_df)[ncol(sd_df)] <- "sd"
  n_df <- stats::aggregate(df$value, df[by], length)
  names(n_df)[ncol(n_df)] <- "n"
  out <- merge(merge(mean_df, sd_df, by = by), n_df, by = by)
  out$se <- out$sd / sqrt(pmax(out$n, 1))
  out
}

pp_recipe_top_terms <- function(df, n = 18) {
  e <- stats::aggregate(cbind(ratio, qvalue, count) ~ term + category, df, mean)
  e <- e[order(e$qvalue, -e$count), , drop = FALSE]
  e <- e[seq_len(min(n, nrow(e))), , drop = FALSE]
  e$term <- factor(e$term, levels = rev(unique(e$term)))
  e
}

pp_recipe_family_kind <- function(recipe_id) {
  if (grepl("bar|fraction|composition", recipe_id)) return("bar")
  if (grepl("box|violin|raincloud|ridge|density|histogram|beeswarm", recipe_id)) return("distribution")
  if (grepl("scatter|regression|bubble|time_series|calibration|model_residual|residual_diagnostic", recipe_id)) return("scatter_line")
  if (grepl("heatmap|matrix|correlation", recipe_id)) return("matrix")
  if (grepl("pca|pcoa|nmds|umap|tsne|ordination", recipe_id)) return("ordination")
  if (grepl("volcano|ma_|enrichment|gsea", recipe_id)) return("omics")
  if (grepl("manhattan|genome|regional|synteny|track", recipe_id)) return("genome")
  if (grepl("forest|lollipop|dumbbell|ranking|effect", recipe_id)) return("comparison")
  if (grepl("upset|set_", recipe_id)) return("set")
  if (grepl("network|sankey|chord|circos", recipe_id)) return("flow")
  if (grepl("spatial|map", recipe_id)) return("spatial")
  if (grepl("phylo|tree", recipe_id)) return("tree")
  if (grepl("multi_panel|inset|paired_line", recipe_id)) return("layout")
  "unknown"
}

pp_recipe_plot <- function(recipe_id, df = pp_recipe_mock_data(recipe_id)) {
  stopifnot(requireNamespace("ggplot2", quietly = TRUE))
  pal <- pp_palette(length(unique(df$group)), "graphpad_discrete")

  if (recipe_id == "grouped_bar_errorbar_raw") {
    s <- pp_recipe_aggregate_mean(df, c("category", "group"))
    dodge <- ggplot2::position_dodge(width = 0.62)
    return(ggplot2::ggplot(s, ggplot2::aes(category, mean, fill = group)) +
      ggplot2::geom_col(position = dodge, width = 0.54, colour = NA) +
      ggplot2::geom_errorbar(ggplot2::aes(ymin = mean - se, ymax = mean + se), position = dodge, width = 0.15, linewidth = 0.28) +
      ggplot2::geom_point(data = df, ggplot2::aes(category, value, colour = group), position = ggplot2::position_jitterdodge(jitter.width = 0.05, dodge.width = 0.62), size = pp_point_size("micro"), alpha = 0.28, inherit.aes = FALSE) +
      pp_scale_fill(levels(df$group)) + pp_scale_color(levels(df$group)) +
      pp_recipe_base() + ggplot2::labs(x = NULL, y = "Mean value (a.u.)", fill = "Group", colour = "Group"))
  }

  if (recipe_id == "stacked_bar_fraction") {
    s <- stats::aggregate(value ~ group + category, df, function(x) sum(abs(x), na.rm = TRUE))
    return(ggplot2::ggplot(s, ggplot2::aes(group, value, fill = category)) +
      ggplot2::geom_col(position = "fill", width = 0.54, colour = NA, linewidth = 0) +
      pp_scale_fill(levels(df$category)) + pp_recipe_base() +
      ggplot2::scale_y_continuous(labels = function(x) paste0(round(x * 100), "%")) +
      ggplot2::labs(x = NULL, y = "Fraction of total", fill = "Category"))
  }

  if (recipe_id == "boxplot_jitter") {
    return(ggplot2::ggplot(df, ggplot2::aes(group, value, colour = group)) +
      ggplot2::geom_boxplot(width = 0.42, outlier.shape = NA, linewidth = 0.35, fill = "white") +
      ggplot2::geom_jitter(width = 0.08, size = pp_point_size("dense"), alpha = 0.42) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::theme(legend.position = "none") + ggplot2::labs(x = NULL, y = "Value (a.u.)"))
  }

  if (recipe_id %in% c("violin_dot", "raincloud_violin_jitter")) {
    return(ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group, colour = group)) +
      ggplot2::geom_violin(width = 0.72, alpha = 0.26, linewidth = 0.32, trim = FALSE) +
      ggplot2::geom_boxplot(width = 0.18, outlier.shape = NA, fill = "white", linewidth = 0.34) +
      ggplot2::geom_jitter(width = 0.08, size = pp_point_size("micro"), alpha = 0.42) +
      pp_scale_fill(levels(df$group)) + pp_scale_color(levels(df$group)) +
      pp_recipe_base() + ggplot2::theme(legend.position = "none") + ggplot2::labs(x = NULL, y = "Value (a.u.)"))
  }

  if (recipe_id == "paired_comparison") {
    d <- df[df$group %in% levels(df$group)[1:2], ]
    d <- stats::aggregate(value ~ sample + group, d, mean)
    return(ggplot2::ggplot(d, ggplot2::aes(group, value, group = sample)) +
      ggplot2::geom_line(linewidth = 0.3, colour = "#9A9A9A", alpha = 0.55) +
      ggplot2::geom_point(ggplot2::aes(colour = group), size = pp_point_size("normal"), alpha = 0.85) +
      pp_scale_color(levels(d$group)) + pp_recipe_base() +
      ggplot2::theme(legend.position = "none") + ggplot2::labs(x = NULL, y = "Paired value (a.u.)"))
  }

  if (recipe_id == "scatter_regression") {
    return(ggplot2::ggplot(df, ggplot2::aes(x, y, colour = group)) +
      ggplot2::geom_point(size = pp_point_size("normal"), alpha = 0.62) +
      ggplot2::geom_smooth(method = "lm", se = TRUE, linewidth = 0.45, alpha = 0.14) +
      pp_scale_color(levels(df$group)) + pp_theme(base_size = 7, show_grid = FALSE) +
      ggplot2::labs(x = "Predictor (a.u.)", y = "Response (a.u.)", colour = "Group"))
  }

  if (recipe_id == "scatter_marginal_reference") {
    return(ggplot2::ggplot(df, ggplot2::aes(x, y, colour = group)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.58) +
      ggplot2::geom_rug(alpha = 0.22, linewidth = 0.24, sides = "bl") +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::labs(x = "X value (a.u.)", y = "Y value (a.u.)", colour = "Group"))
  }

  if (recipe_id %in% c("correlation_heatmap", "annotated_heatmap")) {
    h <- stats::aggregate(value ~ metric + category + group, df, mean)
    plot <- ggplot2::ggplot(h, ggplot2::aes(category, metric, fill = value)) +
      ggplot2::geom_tile(colour = NA, linewidth = 0) +
      ggplot2::scale_fill_gradientn(colours = pp_gradient_palette(256, "graphpad_heatmap"), name = "Value") +
      pp_recipe_base() + ggplot2::theme(axis.ticks = ggplot2::element_blank(), axis.line = ggplot2::element_blank(), legend.key.height = grid::unit(3.2, "mm")) +
      ggplot2::labs(x = NULL, y = NULL)
    if (recipe_id == "annotated_heatmap") plot <- plot + ggplot2::facet_grid(group ~ ., scales = "free_y", space = "free_y")
    return(plot)
  }

  if (recipe_id == "matrix_dotplot") {
    h <- stats::aggregate(cbind(value, count) ~ metric + category, df, mean)
    return(ggplot2::ggplot(h, ggplot2::aes(category, metric)) +
      ggplot2::geom_point(ggplot2::aes(size = count, colour = value), alpha = 0.82) +
      ggplot2::scale_colour_gradientn(colours = pp_gradient_palette(256, "graphpad_heatmap"), name = "Effect") +
      ggplot2::scale_size_continuous(name = "Count", range = c(0.8, 4.2)) +
      ggplot2::guides(
        colour = ggplot2::guide_colorbar(barheight = grid::unit(18, "mm"), barwidth = grid::unit(2.4, "mm")),
        size = ggplot2::guide_legend(override.aes = list(alpha = 0.85), keyheight = grid::unit(3, "mm"))
      ) +
      pp_recipe_base() + ggplot2::theme(legend.key.size = grid::unit(3.2, "mm")) + ggplot2::labs(x = NULL, y = NULL))
  }

  if (recipe_id %in% c("pca_pcoa_ordination", "pcoa_marginal_box")) {
    plot <- ggplot2::ggplot(df, ggplot2::aes(pc1, pc2, colour = group)) +
      ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "#D0D0D0") +
      ggplot2::geom_vline(xintercept = 0, linewidth = 0.25, colour = "#D0D0D0") +
      ggplot2::geom_point(size = pp_point_size("normal"), alpha = 0.74) +
      ggplot2::stat_ellipse(linewidth = 0.35, alpha = 0.55) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::labs(x = "Axis 1 (42%)", y = "Axis 2 (18%)", colour = "Group")
    if (recipe_id == "pcoa_marginal_box") plot <- plot + ggplot2::geom_rug(alpha = 0.18, linewidth = 0.22)
    return(plot)
  }

  if (recipe_id == "volcano_threshold") {
    d <- df
    d$neg_log10_padj <- -log10(pmax(d$padj, .Machine$double.xmin))
    d$class <- ifelse(d$padj < 0.05 & d$log2fc > 1, "Up", ifelse(d$padj < 0.05 & d$log2fc < -1, "Down", "NS"))
    key <- d[order(d$padj, -abs(d$log2fc)), ][seq_len(8), ]
    return(ggplot2::ggplot(d, ggplot2::aes(log2fc, neg_log10_padj, colour = class)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.55) +
      ggplot2::geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.28, colour = "#808080") +
      ggplot2::geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.28, colour = "#808080") +
      ggplot2::geom_text(data = key, ggplot2::aes(label = feature), size = pp_text_size("label"), vjust = -0.55, check_overlap = TRUE, colour = "#1F1F1F") +
      ggplot2::scale_colour_manual(values = c(Up = "#C95A4E", Down = "#4E79A7", NS = "#B8B8B2")) +
      pp_recipe_base() + ggplot2::labs(x = "log2 fold change", y = "-log10 adjusted p-value", colour = "Class"))
  }

  if (recipe_id == "ma_plot") {
    d <- df
    d$class <- ifelse(d$padj < 0.05 & abs(d$log2fc) > 1, "Significant", "NS")
    return(ggplot2::ggplot(d, ggplot2::aes(base_mean, log2fc, colour = class)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.56) +
      ggplot2::geom_hline(yintercept = c(-1, 0, 1), linetype = c("dashed", "solid", "dashed"), linewidth = c(0.25, 0.25, 0.25), colour = "#808080") +
      ggplot2::scale_x_log10() +
      ggplot2::scale_colour_manual(values = c(Significant = "#C95A4E", NS = "#B8B8B2")) +
      pp_recipe_base() + ggplot2::labs(x = "Mean abundance (log10)", y = "log2 fold change", colour = "Class"))
  }

  if (recipe_id == "enrichment_dotplot") {
    e <- stats::aggregate(cbind(ratio, qvalue, count) ~ term + category, df, mean)
    e <- e[order(e$qvalue), ][seq_len(18), ]
    e$term <- factor(e$term, levels = rev(unique(e$term)))
    return(ggplot2::ggplot(e, ggplot2::aes(ratio, term)) +
      ggplot2::geom_point(ggplot2::aes(size = count, colour = qvalue), alpha = 0.85) +
      ggplot2::scale_colour_gradientn(colours = rev(pp_gradient_palette(256, "graphpad_heatmap")), name = "q-value") +
      ggplot2::scale_size_continuous(name = "Count", range = c(1.2, 4.2)) +
      pp_recipe_base() + ggplot2::labs(x = "Gene ratio", y = NULL))
  }

  if (recipe_id == "forest_effect_size") {
    f <- stats::aggregate(cbind(estimate, lower, upper) ~ metric, df, mean)
    f$metric <- factor(f$metric, levels = f$metric[order(f$estimate)])
    f$direction <- ifelse(f$estimate >= 0, "Positive", "Negative")
    return(ggplot2::ggplot(f, ggplot2::aes(estimate, metric)) +
      ggplot2::geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.32, colour = "#555555") +
      ggplot2::geom_segment(ggplot2::aes(x = lower, xend = upper, y = metric, yend = metric), linewidth = 0.42) +
      ggplot2::geom_point(ggplot2::aes(colour = direction), size = pp_point_size("emphasis")) +
      ggplot2::scale_colour_manual(values = c(Positive = "#4E79A7", Negative = "#C95A4E"), guide = "none") +
      pp_recipe_base() + ggplot2::labs(x = "Effect size (95% CI)", y = NULL))
  }

  if (recipe_id == "model_validation_composite") {
    d1 <- data.frame(panel = "Observed vs predicted", group = df$group, x = df$x, y = df$y)
    d2 <- data.frame(panel = "Residuals", group = df$group, x = df$y, y = df$y - df$x)
    perf <- pp_recipe_aggregate_mean(transform(df, category = group), c("category", "group"))
    d3 <- data.frame(panel = "Model performance", group = perf$group, x = seq_len(nrow(perf)), y = pmin(1, pmax(0, perf$mean)))
    dd <- rbind(d1, d2, d3)
    dd$panel <- factor(dd$panel, levels = c("Observed vs predicted", "Residuals", "Model performance"))
    return(ggplot2::ggplot(dd, ggplot2::aes(x, y, colour = group)) +
      ggplot2::geom_hline(data = data.frame(panel = factor("Residuals", levels = levels(dd$panel)), yintercept = 0), ggplot2::aes(yintercept = yintercept), inherit.aes = FALSE, linetype = "dashed", linewidth = 0.28, colour = "#777777") +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.66) +
      ggplot2::facet_wrap(~panel, scales = "free", ncol = 3) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() + ggplot2::labs(x = NULL, y = "Validation value", colour = "Model"))
  }

  if (recipe_id == "lollipop_ranked") {
    s <- stats::aggregate(value ~ category, df, mean)
    s <- s[order(s$value), ]
    s$category <- factor(s$category, levels = s$category)
    return(ggplot2::ggplot(s, ggplot2::aes(value, category)) +
      ggplot2::geom_segment(ggplot2::aes(x = 0, xend = value, y = category, yend = category), linewidth = 0.35, colour = "#AEB7C2") +
      ggplot2::geom_point(size = pp_point_size("emphasis"), colour = "#4E79A7") +
      pp_recipe_base() + ggplot2::labs(x = "Ranked value (a.u.)", y = NULL))
  }

  if (recipe_id == "dumbbell_comparison") {
    d <- df[df$group %in% levels(df$group)[1:2], ]
    s <- stats::aggregate(value ~ category + group, d, mean)
    wide <- reshape(s, idvar = "category", timevar = "group", direction = "wide")
    names(wide) <- sub("^value\\.", "", names(wide))
    g1 <- levels(d$group)[1]; g2 <- levels(d$group)[2]
    wide$category <- factor(wide$category, levels = wide$category[order(wide[[g2]] - wide[[g1]])])
    return(ggplot2::ggplot(wide, ggplot2::aes(y = category)) +
      ggplot2::geom_segment(ggplot2::aes(x = .data[[g1]], xend = .data[[g2]], yend = category), linewidth = 0.38, colour = "#A0A7AE") +
      ggplot2::geom_point(ggplot2::aes(x = .data[[g1]]), colour = "#4E79A7", size = pp_point_size("emphasis")) +
      ggplot2::geom_point(ggplot2::aes(x = .data[[g2]]), colour = "#C95A4E", size = pp_point_size("emphasis")) +
      pp_recipe_base() + ggplot2::labs(x = "Mean value (a.u.)", y = NULL))
  }

  if (recipe_id == "manhattan_genomewide") {
    d <- df[order(df$chr, df$position), ]
    d$idx <- seq_len(nrow(d))
    d$neg_log10_p <- -log10(pmax(d$pvalue, .Machine$double.xmin))
    centers <- stats::aggregate(idx ~ chr, d, mean)
    return(ggplot2::ggplot(d, ggplot2::aes(idx, neg_log10_p, colour = chr)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.78) +
      ggplot2::geom_hline(yintercept = -log10(5e-8), linetype = "dashed", linewidth = 0.3, colour = "#777777") +
      ggplot2::scale_x_continuous(breaks = centers$idx, labels = sub("^Chr", "", centers$chr)) +
      ggplot2::scale_colour_manual(values = rep(c("#305F8C", "#8E8E8E"), length.out = length(unique(d$chr))), guide = "none") +
      pp_recipe_base() + ggplot2::labs(x = "Chromosome", y = "-log10 p-value"))
  }

  if (recipe_id == "ridgeline_density") {
    return(ggplot2::ggplot(df, ggplot2::aes(value, after_stat(density), fill = group)) +
      ggplot2::geom_density(alpha = 0.48, linewidth = 0.12, colour = "#5A5A5A") +
      ggplot2::facet_grid(group ~ ., scales = "free_y") +
      pp_scale_fill(levels(df$group)) + pp_recipe_base() +
      ggplot2::theme(legend.position = "none", axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank()) +
      ggplot2::labs(x = "Value (a.u.)", y = NULL))
  }

  if (recipe_id == "upset_summary") {
    m <- df[df$present == 1, ]
    set_counts <- stats::aggregate(present ~ set, m, length)
    names(set_counts)[2] <- "count"
    membership <- unique(m[c("set")])
    membership$cue_y <- -max(set_counts$count) * 0.08
    return(ggplot2::ggplot(set_counts, ggplot2::aes(set, count)) +
      ggplot2::geom_col(width = 0.55, fill = "#4E79A7") +
      ggplot2::geom_point(data = membership, ggplot2::aes(set, cue_y), inherit.aes = FALSE, size = pp_point_size("normal"), alpha = 0.72, colour = "#303030") +
      pp_recipe_base() + ggplot2::labs(x = NULL, y = "Set size"))
  }

  if (recipe_id == "phylo_annotation_reference") {
    nodes <- data.frame(node = paste0("N", seq_len(20)), x = rep(0:4, each = 4, length.out = 20), y = seq_len(20), group = rep(levels(df$group), length.out = 20))
    edges <- data.frame(x = pmax(0, nodes$x - 1), xend = nodes$x, y = pmax(1, nodes$y - 1), yend = nodes$y, group = nodes$group)
    return(ggplot2::ggplot() +
      ggplot2::geom_segment(data = edges, ggplot2::aes(x = x, xend = xend, y = y, yend = yend), linewidth = 0.34, colour = "#303030") +
      ggplot2::geom_point(data = nodes, ggplot2::aes(x, y, colour = group), size = pp_point_size("normal")) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::theme(axis.text = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(), axis.line = ggplot2::element_blank()) +
      ggplot2::labs(x = NULL, y = NULL, colour = "Annotation"))
  }

  if (recipe_id == "circos_chord_sankey_reference") {
    flow <- stats::aggregate(value ~ source + target, df, function(x) sum(abs(x)))
    flow <- flow[order(flow$value, decreasing = TRUE), ][seq_len(18), ]
    flow$x <- as.numeric(flow$source)
    flow$xend <- as.numeric(flow$target) + 7
    flow$y <- seq_len(nrow(flow))
    return(ggplot2::ggplot(flow) +
      ggplot2::geom_curve(ggplot2::aes(x = x, xend = xend, y = y, yend = y, linewidth = value, colour = source), curvature = 0.22, alpha = 0.58) +
      ggplot2::scale_linewidth_continuous(range = c(0.25, 1.6), guide = "none") +
      pp_scale_color(unique(flow$source)) + pp_recipe_base() +
      ggplot2::theme(axis.text = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(), axis.line = ggplot2::element_blank()) +
      ggplot2::labs(x = NULL, y = NULL, colour = "Source"))
  }

  kind <- pp_recipe_family_kind(recipe_id)

  if (kind == "bar") {
    s <- pp_recipe_aggregate_mean(df, c("category", "group"))
    if (grepl("stacked|fraction|composition|diverging", recipe_id)) {
      s$value <- abs(s$mean)
      if (grepl("diverging", recipe_id)) s$value <- ifelse(as.numeric(s$category) %% 2 == 0, -s$value, s$value)
      return(ggplot2::ggplot(s, ggplot2::aes(group, value, fill = category)) +
        ggplot2::geom_col(position = if (grepl("diverging", recipe_id)) "stack" else "fill", width = 0.55, colour = NA) +
        pp_scale_fill(levels(df$category)) + pp_recipe_base() +
        ggplot2::scale_y_continuous(labels = if (!grepl("diverging", recipe_id)) function(x) paste0(round(x * 100), "%") else ggplot2::waiver()) +
        ggplot2::labs(x = NULL, y = if (grepl("diverging", recipe_id)) "Signed contribution" else "Fraction of total", fill = "Category"))
    }
    dodge <- ggplot2::position_dodge(width = 0.62)
    plot <- ggplot2::ggplot(s, ggplot2::aes(category, mean, fill = group)) +
      ggplot2::geom_col(position = dodge, width = 0.54, colour = NA) +
      ggplot2::geom_errorbar(ggplot2::aes(ymin = mean - se, ymax = mean + se), position = dodge, width = 0.15, linewidth = 0.28) +
      pp_scale_fill(levels(df$group)) + pp_recipe_base() +
      ggplot2::labs(x = NULL, y = "Mean value (a.u.)", fill = "Group")
    if (grepl("dot|raw", recipe_id)) {
      plot <- plot + ggplot2::geom_point(data = df, ggplot2::aes(category, value, colour = group), position = ggplot2::position_jitterdodge(jitter.width = 0.06, dodge.width = 0.62), size = pp_point_size("micro"), alpha = 0.32, inherit.aes = FALSE) +
        pp_scale_color(levels(df$group))
    }
    return(plot)
  }

  if (kind == "distribution") {
    if (grepl("histogram", recipe_id)) {
      return(ggplot2::ggplot(df, ggplot2::aes(value, fill = group)) +
        ggplot2::geom_histogram(position = "identity", bins = 24, alpha = 0.35, linewidth = 0.15, colour = "white") +
        ggplot2::geom_density(ggplot2::aes(y = after_stat(count)), linewidth = 0.32, alpha = 0.25) +
        pp_scale_fill(levels(df$group)) + pp_recipe_base() +
        ggplot2::labs(x = "Value (a.u.)", y = "Count", fill = "Group"))
    }
    if (grepl("ridge|density", recipe_id)) {
      return(ggplot2::ggplot(df, ggplot2::aes(value, after_stat(density), fill = group)) +
        ggplot2::geom_density(alpha = 0.42, linewidth = 0.18, colour = "#4A4A4A") +
        ggplot2::facet_grid(group ~ ., scales = "free_y") +
        pp_scale_fill(levels(df$group)) + pp_recipe_base() +
        ggplot2::theme(legend.position = "none", axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank()) +
        ggplot2::labs(x = "Value (a.u.)", y = NULL))
    }
    plot <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group, colour = group)) +
      ggplot2::geom_violin(width = 0.72, alpha = 0.22, linewidth = 0.3, trim = FALSE) +
      ggplot2::geom_boxplot(width = 0.16, outlier.shape = NA, fill = "white", linewidth = 0.32) +
      ggplot2::geom_jitter(width = 0.08, size = pp_point_size("micro"), alpha = 0.38) +
      pp_scale_fill(levels(df$group)) + pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::theme(legend.position = "none") + ggplot2::labs(x = NULL, y = "Value (a.u.)")
    if (grepl("facet", recipe_id)) plot <- plot + ggplot2::facet_wrap(~metric, scales = "free_y", nrow = 1)
    return(plot)
  }

  if (kind == "scatter_line") {
    if (grepl("model_residual|residual_diagnostic", recipe_id)) {
      return(ggplot2::ggplot(df, ggplot2::aes(predicted, residual, colour = group)) +
        ggplot2::geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.28, colour = "#777777") +
        ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.62) +
        ggplot2::geom_smooth(method = "loess", se = FALSE, linewidth = 0.38, alpha = 0.2) +
        pp_scale_color(levels(df$group)) + pp_recipe_base() +
        ggplot2::labs(x = "Predicted value", y = "Residual", colour = "Group"))
    }
    if (grepl("time_series", recipe_id)) {
      t <- stats::aggregate(cbind(value, error) ~ time + group, df, mean)
      return(ggplot2::ggplot(t, ggplot2::aes(time, value, colour = group, fill = group)) +
        {if (grepl("ribbon", recipe_id)) ggplot2::geom_ribbon(ggplot2::aes(ymin = value - error, ymax = value + error), alpha = 0.14, colour = NA) else NULL} +
        ggplot2::geom_line(linewidth = 0.4) +
        ggplot2::geom_point(size = pp_point_size("normal")) +
        pp_scale_color(levels(df$group)) + pp_scale_fill(levels(df$group)) + pp_recipe_base() +
        ggplot2::labs(x = "Time", y = "Value (mean +/- SE)", colour = "Group", fill = "Group"))
    }
    if (grepl("calibration", recipe_id)) {
      cdf <- stats::aggregate(cbind(observed, predicted) ~ bin + group, df, mean)
      cdf$bin_x <- as.numeric(cdf$bin) / length(unique(cdf$bin))
      return(ggplot2::ggplot(cdf, ggplot2::aes(predicted, observed, colour = group)) +
        ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", linewidth = 0.28, colour = "#777777") +
        ggplot2::geom_line(linewidth = 0.42) +
        ggplot2::geom_point(size = pp_point_size("normal")) +
        pp_scale_color(levels(df$group)) + pp_recipe_base() +
        ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
        ggplot2::labs(x = "Predicted probability", y = "Observed fraction", colour = "Group"))
    }
    plot <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = group)) +
      {if (grepl("bubble", recipe_id)) ggplot2::geom_point(ggplot2::aes(size = count), alpha = 0.62) else ggplot2::geom_point(size = pp_point_size("normal"), alpha = 0.62)} +
      pp_scale_color(levels(df$group)) + pp_theme(base_size = 7, show_grid = FALSE) +
      ggplot2::labs(x = "Predictor (a.u.)", y = "Response (a.u.)", colour = "Group")
    if (grepl("regression|labelled|ci", recipe_id)) plot <- plot + ggplot2::geom_smooth(method = "lm", se = TRUE, linewidth = 0.42, alpha = 0.14)
    if (grepl("labelled", recipe_id)) plot <- plot + ggplot2::geom_text(data = df[df$label != "", ], ggplot2::aes(label = label), size = pp_text_size("minimum"), vjust = -0.6, check_overlap = TRUE, colour = "#202020")
    if (grepl("rug|marginal", recipe_id)) plot <- plot + ggplot2::geom_rug(alpha = 0.18, linewidth = 0.22, sides = "bl")
    return(plot)
  }

  if (kind == "matrix") {
    h <- stats::aggregate(cbind(value, count) ~ metric + category + group, df, mean)
    if (grepl("dotplot|two_scale", recipe_id)) {
      return(ggplot2::ggplot(h, ggplot2::aes(category, metric)) +
        ggplot2::geom_point(ggplot2::aes(size = count, colour = value), alpha = 0.82) +
        ggplot2::scale_colour_gradientn(colours = pp_gradient_palette(256, "graphpad_heatmap"), name = "Effect") +
        ggplot2::scale_size_continuous(name = "Support", range = c(0.8, 4.2)) +
        pp_recipe_base() + ggplot2::labs(x = NULL, y = NULL))
    }
    plot <- ggplot2::ggplot(h, ggplot2::aes(category, metric, fill = value)) +
      ggplot2::geom_tile(colour = if (grepl("cell_label|triangle", recipe_id)) "white" else NA, linewidth = 0.12) +
      ggplot2::scale_fill_gradientn(colours = pp_gradient_palette(256, "graphpad_heatmap"), name = "Value") +
      pp_recipe_base() + ggplot2::theme(axis.ticks = ggplot2::element_blank(), axis.line = ggplot2::element_blank()) +
      ggplot2::labs(x = NULL, y = NULL)
    if (grepl("label", recipe_id)) plot <- plot + ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", value)), size = pp_text_size("minimum"), colour = "#303030")
    if (grepl("annotation|cluster", recipe_id)) plot <- plot + ggplot2::facet_grid(group ~ ., scales = "free_y", space = "free_y")
    return(plot)
  }

  if (kind == "ordination") {
    axis_labels <- if (grepl("nmds", recipe_id)) c("NMDS1", "NMDS2") else if (grepl("umap", recipe_id)) c("UMAP1", "UMAP2") else if (grepl("tsne", recipe_id)) c("t-SNE1", "t-SNE2") else c("Axis 1 (42%)", "Axis 2 (18%)")
    plot <- ggplot2::ggplot(df, ggplot2::aes(pc1, pc2, colour = group)) +
      ggplot2::geom_hline(yintercept = 0, linewidth = 0.22, colour = "#D0D0D0") +
      ggplot2::geom_vline(xintercept = 0, linewidth = 0.22, colour = "#D0D0D0") +
      ggplot2::geom_point(size = pp_point_size("normal"), alpha = 0.72) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::labs(x = axis_labels[[1]], y = axis_labels[[2]], colour = "Group")
    if (!grepl("umap|tsne", recipe_id)) plot <- plot + ggplot2::stat_ellipse(linewidth = 0.32, alpha = 0.5)
    if (grepl("permanova|stress", recipe_id)) plot <- plot + ggplot2::annotate("text", x = min(df$pc1), y = max(df$pc2), label = if (grepl("stress", recipe_id)) "Stress = 0.08" else "PERMANOVA q = 0.012", hjust = 0, size = pp_text_size("minimum"))
    return(plot)
  }

  if (kind == "omics") {
    if (grepl("gsea", recipe_id)) {
      g <- data.frame(rank = seq_len(220), running = cumsum(rnorm(220, 0.002, 0.045)))
      return(ggplot2::ggplot(g, ggplot2::aes(rank, running)) +
        ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "#888888") +
        ggplot2::geom_line(linewidth = 0.46, colour = "#4E79A7") +
        pp_recipe_base() + ggplot2::labs(x = "Ranked genes", y = "Running enrichment score"))
    }
    if (grepl("enrichment", recipe_id)) {
      e <- pp_recipe_top_terms(df)
      plot <- ggplot2::ggplot(e, ggplot2::aes(ratio, term)) +
        ggplot2::geom_point(ggplot2::aes(size = count, colour = qvalue), alpha = 0.86) +
        ggplot2::scale_colour_gradientn(colours = rev(pp_gradient_palette(256, "graphpad_heatmap")), name = "q-value") +
        ggplot2::scale_size_continuous(name = "Count", range = c(1.2, 4.1)) +
        pp_recipe_base() + ggplot2::labs(x = "Gene ratio", y = NULL)
      if (grepl("bar", recipe_id)) plot <- plot + ggplot2::geom_segment(ggplot2::aes(x = 0, xend = ratio, yend = term), linewidth = 0.26, colour = "#AEB7C2")
      return(plot)
    }
    if (grepl("ma_", recipe_id)) {
      return(ggplot2::ggplot(df, ggplot2::aes(base_mean, log2fc, colour = class)) +
        ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.56) +
        ggplot2::geom_hline(yintercept = c(-1, 0, 1), linetype = c("dashed", "solid", "dashed"), linewidth = 0.25, colour = "#808080") +
        ggplot2::scale_x_log10() +
        ggplot2::scale_colour_manual(values = c(Up = "#C95A4E", Down = "#4E79A7", NS = "#B8B8B2")) +
        pp_recipe_base() + ggplot2::labs(x = "Mean abundance (log10)", y = "log2 fold change", colour = "Class"))
    }
    d <- df
    d$neg_log10_padj <- -log10(pmax(d$padj, .Machine$double.xmin))
    key <- d[order(d$padj, -abs(d$log2fc)), ][seq_len(8), ]
    return(ggplot2::ggplot(d, ggplot2::aes(log2fc, neg_log10_padj, colour = class)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.55) +
      ggplot2::geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.28, colour = "#808080") +
      ggplot2::geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.28, colour = "#808080") +
      {if (grepl("label", recipe_id)) ggplot2::geom_text(data = key, ggplot2::aes(label = feature), size = pp_text_size("minimum"), vjust = -0.55, check_overlap = TRUE, colour = "#202020") else NULL} +
      {if (grepl("facet", recipe_id)) ggplot2::facet_wrap(~group) else NULL} +
      ggplot2::scale_colour_manual(values = c(Up = "#C95A4E", Down = "#4E79A7", NS = "#B8B8B2")) +
      pp_recipe_base() + ggplot2::labs(x = "log2 fold change", y = "-log10 adjusted p-value", colour = "Class"))
  }

  if (kind == "genome") {
    if (grepl("track|synteny", recipe_id)) {
      g <- df[seq_len(min(80, nrow(df))), , drop = FALSE]
      return(ggplot2::ggplot(g) +
        ggplot2::geom_segment(ggplot2::aes(x = start, xend = end, y = track, yend = track, colour = chr), linewidth = 1.1, alpha = 0.72) +
        {if (grepl("synteny", recipe_id)) ggplot2::geom_curve(ggplot2::aes(x = start, xend = end, y = as.numeric(track), yend = as.numeric(track) + 0.45), curvature = 0.18, linewidth = 0.22, alpha = 0.35) else NULL} +
        pp_scale_color(levels(df$chr)) + pp_recipe_base() + ggplot2::labs(x = "Genomic coordinate", y = NULL, colour = "Chromosome"))
    }
    d <- df[order(df$chr, df$position), ]
    d$idx <- seq_len(nrow(d))
    d$neg_log10_p <- -log10(pmax(d$pvalue, .Machine$double.xmin))
    centers <- stats::aggregate(idx ~ chr, d, mean)
    return(ggplot2::ggplot(d, ggplot2::aes(idx, neg_log10_p, colour = chr)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.76) +
      ggplot2::geom_hline(yintercept = -log10(5e-8), linetype = "dashed", linewidth = 0.28, colour = "#777777") +
      ggplot2::scale_x_continuous(breaks = centers$idx, labels = sub("^Chr", "", centers$chr)) +
      ggplot2::scale_colour_manual(values = rep(c("#305F8C", "#8E8E8E"), length.out = length(unique(d$chr))), guide = "none") +
      {if (grepl("faceted|regional", recipe_id)) ggplot2::facet_wrap(~chr, scales = "free_x", nrow = 1) else NULL} +
      pp_recipe_base() + ggplot2::labs(x = "Chromosome", y = "-log10 p-value"))
  }

  if (kind == "comparison") {
    if (grepl("forest", recipe_id)) {
      f <- stats::aggregate(cbind(estimate, lower, upper) ~ metric + group, df, mean)
      f$metric <- factor(f$metric, levels = unique(f$metric[order(f$estimate)]))
      return(ggplot2::ggplot(f, ggplot2::aes(estimate, metric, colour = group)) +
        ggplot2::geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3, colour = "#555555") +
        ggplot2::geom_errorbarh(ggplot2::aes(xmin = lower, xmax = upper), height = 0.12, linewidth = 0.35, position = ggplot2::position_dodge(width = 0.42)) +
        ggplot2::geom_point(size = pp_point_size("normal"), position = ggplot2::position_dodge(width = 0.42)) +
        pp_scale_color(levels(df$group)) + pp_recipe_base() + ggplot2::labs(x = "Effect size (95% CI)", y = NULL, colour = "Group"))
    }
    if (grepl("dumbbell", recipe_id)) {
      d <- df[df$group %in% levels(df$group)[1:2], ]
      s <- stats::aggregate(value ~ category + group, d, mean)
      wide <- reshape(s, idvar = "category", timevar = "group", direction = "wide")
      names(wide) <- sub("^value\\.", "", names(wide))
      g1 <- levels(d$group)[1]; g2 <- levels(d$group)[2]
      wide$category <- factor(wide$category, levels = wide$category[order(wide[[g2]] - wide[[g1]])])
      return(ggplot2::ggplot(wide, ggplot2::aes(y = category)) +
        ggplot2::geom_segment(ggplot2::aes(x = .data[[g1]], xend = .data[[g2]], yend = category), linewidth = 0.36, colour = "#A0A7AE") +
        ggplot2::geom_point(ggplot2::aes(x = .data[[g1]]), colour = "#4E79A7", size = pp_point_size("normal")) +
        ggplot2::geom_point(ggplot2::aes(x = .data[[g2]]), colour = "#C95A4E", size = pp_point_size("normal")) +
        pp_recipe_base() + ggplot2::labs(x = "Mean value (a.u.)", y = NULL))
    }
    s <- stats::aggregate(value ~ category + group, df, mean)
    s <- s[order(s$value), , drop = FALSE]
    s$category <- factor(s$category, levels = unique(s$category))
    return(ggplot2::ggplot(s, ggplot2::aes(value, category, colour = group)) +
      ggplot2::geom_segment(ggplot2::aes(x = 0, xend = value, yend = category), linewidth = 0.3, colour = "#AEB7C2") +
      ggplot2::geom_point(size = pp_point_size("normal")) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() + ggplot2::labs(x = "Ranked value (a.u.)", y = NULL, colour = "Group"))
  }

  if (kind == "set") {
    m <- df[df$present == 1, ]
    set_counts <- stats::aggregate(present ~ set, m, length)
    names(set_counts)[2] <- "count"
    return(ggplot2::ggplot(set_counts, ggplot2::aes(set, count)) +
      ggplot2::geom_col(width = 0.55, fill = "#4E79A7") +
      ggplot2::geom_point(ggplot2::aes(y = -max(count) * 0.08), size = pp_point_size("normal"), alpha = 0.75, colour = "#303030") +
      pp_recipe_base() + ggplot2::labs(x = NULL, y = "Set size"))
  }

  if (kind == "flow") {
    flow <- stats::aggregate(weight ~ source + target, df, sum)
    flow <- flow[order(flow$weight, decreasing = TRUE), ][seq_len(min(22, nrow(flow))), ]
    flow$x <- as.numeric(flow$source)
    flow$xend <- as.numeric(flow$target) + 7
    flow$y <- seq_len(nrow(flow))
    return(ggplot2::ggplot(flow) +
      ggplot2::geom_curve(ggplot2::aes(x = x, xend = xend, y = y, yend = y, linewidth = weight, colour = source), curvature = 0.22, alpha = 0.56) +
      ggplot2::scale_linewidth_continuous(range = c(0.25, 1.5), guide = "none") +
      pp_scale_color(unique(flow$source)) + pp_recipe_base() +
      ggplot2::theme(axis.text = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(), axis.line = ggplot2::element_blank()) +
      ggplot2::labs(x = NULL, y = NULL, colour = "Source"))
  }

  if (kind == "spatial") {
    return(ggplot2::ggplot(df, ggplot2::aes(longitude, latitude, colour = value, size = count)) +
      ggplot2::geom_point(alpha = 0.68) +
      ggplot2::scale_colour_gradientn(colours = pp_gradient_palette(256, "graphpad_heatmap"), name = "Value") +
      ggplot2::scale_size_continuous(range = c(0.6, 3.2), name = "Count") +
      pp_recipe_base() + ggplot2::coord_equal() + ggplot2::labs(x = "Longitude", y = "Latitude"))
  }

  if (kind == "tree") {
    nodes <- data.frame(node = paste0("N", seq_len(28)), x = rep(0:6, each = 4, length.out = 28), y = seq_len(28), group = rep(levels(df$group), length.out = 28))
    edges <- data.frame(x = pmax(0, nodes$x - 1), xend = nodes$x, y = pmax(1, nodes$y - 1), yend = nodes$y, group = nodes$group)
    return(ggplot2::ggplot() +
      ggplot2::geom_segment(data = edges, ggplot2::aes(x = x, xend = xend, y = y, yend = yend), linewidth = 0.32, colour = "#303030") +
      ggplot2::geom_point(data = nodes, ggplot2::aes(x, y, colour = group), size = pp_point_size("normal")) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::theme(axis.text = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(), axis.line = ggplot2::element_blank()) +
      ggplot2::labs(x = NULL, y = NULL, colour = "Annotation"))
  }

  if (kind == "layout") {
    if (grepl("paired_line", recipe_id)) {
      d <- stats::aggregate(value ~ sample + group + metric, df, mean)
      return(ggplot2::ggplot(d, ggplot2::aes(group, value, group = sample)) +
        ggplot2::geom_line(linewidth = 0.25, colour = "#9A9A9A", alpha = 0.5) +
        ggplot2::geom_point(ggplot2::aes(colour = group), size = pp_point_size("normal")) +
        ggplot2::facet_wrap(~metric, scales = "free_y", nrow = 1) +
        pp_scale_color(levels(df$group)) + pp_recipe_base() + ggplot2::theme(legend.position = "none") +
        ggplot2::labs(x = NULL, y = "Paired value (a.u.)"))
    }
    return(ggplot2::ggplot(df, ggplot2::aes(x, y, colour = group)) +
      ggplot2::geom_point(size = pp_point_size("dense"), alpha = 0.58) +
      ggplot2::geom_smooth(method = "lm", se = FALSE, linewidth = 0.35) +
      ggplot2::facet_wrap(~metric, scales = "free", ncol = 3) +
      pp_scale_color(levels(df$group)) + pp_recipe_base() +
      ggplot2::labs(x = NULL, y = "Panel value", colour = "Group"))
  }

  stop("Unknown recipe_id: ", recipe_id, call. = FALSE)
}
