.example_cohort_samples <- paste0("S", sprintf("%02d", 1:12))

.build_example_pca_scatter <- function() {
    samples <- .example_cohort_samples
    groups <- rep(c("Reference", "Intermediate", "Responder"), each = 4)
    df <- data.frame(
        Sample = samples,
        PC1 = c(-2.8, -2.1, -1.5, -0.9, -0.4, 0.2, 0.8, 1.3, 1.7, 2.1, 2.5, 3.0),
        PC2 = c(1.8, 1.2, 0.9, 0.4, -0.1, -0.4, -0.9, -1.1, 1.0, 0.6, -0.8, -1.4),
        Group = groups
    )
    df$Group <- factor(df$Group, levels = c("Reference", "Intermediate", "Responder"))

    ggplot2::ggplot(df, ggplot2::aes(PC1, PC2, color = Group)) +
        ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, linetype = "dashed", color = "#BFBFBF") +
        ggplot2::geom_vline(xintercept = 0, linewidth = 0.25, linetype = "dashed", color = "#BFBFBF") +
        ggplot2::geom_point(size = 2.6) +
        ggplot2::geom_text(ggplot2::aes(label = Sample), nudge_x = 0.08, size = 2.3, show.legend = FALSE) +
        scale_color_lab(palette = "main") +
        theme_lab() +
        ggplot2::theme(legend.position = "top") +
        ggplot2::labs(
            title = "Example cohort structure",
            subtitle = "PCA-like scatter across three study groups",
            x = "PC1 (28.4%)",
            y = "PC2 (16.7%)",
            color = "Group"
        )
}

.build_example_state_composition_bar <- function() {
    samples <- .example_cohort_samples
    composition <- data.frame(
        Sample = rep(samples, each = 3),
        State = rep(c("State A", "State B", "State C"), times = length(samples)),
        Value = c(
            0.72, 0.18, 0.10,
            0.69, 0.19, 0.12,
            0.63, 0.23, 0.14,
            0.55, 0.28, 0.17,
            0.50, 0.31, 0.19,
            0.43, 0.36, 0.21,
            0.35, 0.38, 0.27,
            0.30, 0.41, 0.29,
            0.28, 0.48, 0.24,
            0.19, 0.58, 0.23,
            0.16, 0.61, 0.23,
            0.13, 0.66, 0.21
        )
    )
    composition$Sample <- factor(composition$Sample, levels = samples)
    composition$State <- factor(composition$State, levels = c("State A", "State B", "State C"))

    ggplot2::ggplot(composition, ggplot2::aes(Sample, Value, fill = State)) +
        ggplot2::geom_col(width = 0.92, color = "white", linewidth = 0.15) +
        scale_fill_lab(palette = "main") +
        ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
        theme_lab() +
        ggplot2::theme(
            axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1),
            legend.position = "top"
        ) +
        ggplot2::labs(
            title = "Cell-state composition",
            subtitle = "Example stacked proportions across a study cohort",
            x = NULL,
            y = "Fraction of cells",
            fill = "State"
        )
}

.build_example_violin_box <- function() {
    batches <- paste("Batch", LETTERS[1:6])
    means <- c(2.1, 2.0, 2.3, 2.5, 1.8, 2.2)
    sds <- c(0.35, 0.30, 0.38, 0.42, 0.28, 0.33)

    df <- do.call(
        rbind,
        lapply(seq_along(batches), function(i) {
            data.frame(
                Batch = batches[[i]],
                MarkerIntensity = 10 ^ stats::rnorm(90, mean = means[[i]], sd = sds[[i]])
            )
        })
    )
    df$Batch <- factor(df$Batch, levels = batches)

    ggplot2::ggplot(df, ggplot2::aes(Batch, MarkerIntensity, fill = Batch)) +
        ggplot2::geom_violin(width = 0.95, alpha = 0.7, color = NA) +
        ggplot2::geom_boxplot(width = 0.14, outlier.size = 0.35, fill = "white", linewidth = 0.25) +
        scale_fill_lab(palette = "floral") +
        ggplot2::scale_y_log10(labels = scales::label_number(accuracy = 1)) +
        theme_lab() +
        ggplot2::theme(legend.position = "none") +
        ggplot2::labs(
            title = "Marker distribution",
            subtitle = "Violin + box display on a log10 intensity scale",
            x = NULL,
            y = "Marker intensity (log10 scale)"
        )
}

.build_example_feature_heatmap <- function() {
    samples <- paste("Sample", 1:6)
    features <- paste("Feature", 1:10)

    grid <- expand.grid(
        Sample = factor(samples, levels = rev(samples)),
        Feature = factor(features, levels = features),
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors = FALSE
    )
    grid$Signal <- c(
        0.42, 0.50, 0.61, 0.65, 0.81, 0.37, 0.44, 0.58, 0.54, 0.63,
        0.39, 0.43, 0.52, 0.56, 0.68, 0.31, 0.37, 0.48, 0.46, 0.59,
        0.26, 0.30, 0.41, 0.44, 0.49, 0.22, 0.27, 0.35, 0.32, 0.38,
        0.48, 0.55, 0.67, 0.74, 0.93, 0.41, 0.47, 0.64, 0.59, 0.71,
        0.28, 0.34, 0.45, 0.51, 0.57, 0.24, 0.31, 0.39, 0.36, 0.42,
        0.33, 0.39, 0.47, 0.52, 0.60, 0.29, 0.35, 0.43, 0.40, 0.48
    )

    ggplot2::ggplot(grid, ggplot2::aes(Feature, Sample, fill = Signal)) +
        ggplot2::geom_tile(color = "white", linewidth = 0.25) +
        ggplot2::scale_fill_gradientn(
            colours = lab_gradient_palette(7, palette = "blue_red"),
            labels = scales::label_percent(accuracy = 1)
        ) +
        theme_lab() +
        ggplot2::theme(
            axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1),
            panel.grid = ggplot2::element_blank()
        ) +
        ggplot2::labs(
            title = "Feature heatmap",
            subtitle = "Example enrichment profile across samples and features",
            x = NULL,
            y = NULL,
            fill = "Signal"
        )
}

.build_example_class_composition <- function() {
    samples <- paste("Sample", 1:6)
    composition <- data.frame(
        Sample = rep(samples, each = 3),
        Class = rep(c("Class A", "Class B", "Class C"), times = length(samples)),
        Value = c(
            0.31, 0.43, 0.26,
            0.29, 0.46, 0.25,
            0.34, 0.40, 0.26,
            0.26, 0.49, 0.25,
            0.32, 0.39, 0.29,
            0.28, 0.44, 0.28
        )
    )
    composition$Sample <- factor(composition$Sample, levels = samples)
    composition$Class <- factor(composition$Class, levels = c("Class A", "Class B", "Class C"))

    ggplot2::ggplot(composition, ggplot2::aes(Sample, Value, fill = Class)) +
        ggplot2::geom_col(width = 0.72) +
        scale_fill_lab(palette = "prism_light") +
        ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
        theme_lab() +
        ggplot2::theme(legend.position = "top") +
        ggplot2::labs(
            title = "Class composition",
            subtitle = "Example stacked composition for three classes",
            x = NULL,
            y = "Fraction",
            fill = "Class"
        )
}

.comparison_example_data <- function() {
    data.frame(
        Condition = rep(c("Control", "Treatment", "Rescue"), each = 36),
        Value = c(
            stats::rnorm(36, mean = 4.8, sd = 0.45),
            stats::rnorm(36, mean = 6.3, sd = 0.55),
            stats::rnorm(36, mean = 5.5, sd = 0.50)
        ),
        Batch = rep(c("Batch 1", "Batch 2"), each = 18, times = 3)
    )
}

.paired_example_data <- function() {
    data.frame(
        Sample = rep(paste0("S", sprintf("%02d", 1:16)), times = 2),
        Condition = rep(c("Before", "After"), each = 16),
        Value = c(
            stats::rnorm(16, mean = 4.7, sd = 0.35),
            stats::rnorm(16, mean = 5.6, sd = 0.35)
        )
    )
}

.build_example_box_compare <- function() {
    df <- .comparison_example_data()
    df$Condition <- factor(df$Condition, levels = c("Control", "Treatment", "Rescue"))

    plot_box_paper(
        df,
        Condition,
        Value,
        palette = "main",
        show_signif = TRUE,
        comparisons = list(c("Control", "Treatment"), c("Treatment", "Rescue"))
    ) +
        ggplot2::labs(
            title = "Grouped comparison box plot",
            subtitle = "High-level box plot with raw points and significance",
            y = "Relative signal"
        )
}

.build_example_violin_compare <- function() {
    df <- .comparison_example_data()
    df$Condition <- factor(df$Condition, levels = c("Control", "Treatment", "Rescue"))

    plot_violin_paper(
        df,
        Condition,
        Value,
        palette = "main",
        summary_type = "median_iqr",
        facet = Batch
    ) +
        ggplot2::labs(
            title = "Faceted violin comparison",
            subtitle = "Median + IQR overlay using the high-level violin API",
            y = "Relative signal"
        )
}

.build_example_dot_compare <- function() {
    df <- .paired_example_data()
    df$Condition <- factor(df$Condition, levels = c("Before", "After"))

    plot_dot_paper(
        df,
        Condition,
        Value,
        paired = TRUE,
        id = Sample,
        palette = "gray",
        show_signif = TRUE,
        comparisons = list(c("Before", "After"))
    ) +
        ggplot2::labs(
            title = "Paired dot comparison",
            subtitle = "Connected raw points with summary overlay and significance",
            y = "Relative signal"
        )
}

#' Render a gallery of paper-style example figures
#'
#' Generates a reusable gallery of publication-style example figures,
#' including scatter, stacked composition, violin-plus-box, heatmap, and
#' grouped comparison plots.
#'
#' @param output_dir Directory where the example figures will be written.
#' @param device Output device extension, such as `"png"` or `"pdf"`.
#'
#' @return A named character vector of generated file paths.
#' @export
render_paperplotr_examples <- function(output_dir = file.path(tempdir(), "paperplotr-gallery"), device = "png") {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    file_ext <- sub("^\\.", "", tolower(device))
    if (!file_ext %in% c("png", "pdf", "tiff", "tif", "svg")) {
        cli::cli_abort("{.arg device} must be one of png, pdf, tiff, tif, or svg.")
    }

    plots <- list(
        pca_scatter = .build_example_pca_scatter(),
        state_composition_bar = .build_example_state_composition_bar(),
        violin_box = .build_example_violin_box(),
        feature_heatmap = .build_example_feature_heatmap(),
        class_composition = .build_example_class_composition(),
        box_compare = .build_example_box_compare(),
        violin_compare = .build_example_violin_compare(),
        dot_compare = .build_example_dot_compare()
    )

    output_paths <- c(
        pca_scatter = file.path(output_dir, paste0("cohort_pca_scatter.", file_ext)),
        state_composition_bar = file.path(output_dir, paste0("cell_state_composition_bar.", file_ext)),
        violin_box = file.path(output_dir, paste0("marker_distribution_violin_box.", file_ext)),
        feature_heatmap = file.path(output_dir, paste0("feature_enrichment_heatmap.", file_ext)),
        class_composition = file.path(output_dir, paste0("class_composition_bar.", file_ext)),
        box_compare = file.path(output_dir, paste0("paper_box_compare.", file_ext)),
        violin_compare = file.path(output_dir, paste0("paper_violin_compare.", file_ext)),
        dot_compare = file.path(output_dir, paste0("paper_dot_compare.", file_ext))
    )

    save_lab_plot(plots$pca_scatter, output_paths[["pca_scatter"]], preset = "cell_half", width = 9.2, height = 7.2)
    save_lab_plot(plots$state_composition_bar, output_paths[["state_composition_bar"]], preset = "nature", width = 17.4, height = 6.8)
    save_lab_plot(plots$violin_box, output_paths[["violin_box"]], preset = "cell_half", width = 9.2, height = 7.0)
    save_lab_plot(plots$feature_heatmap, output_paths[["feature_heatmap"]], preset = "nature", width = 17.4, height = 7.0)
    save_lab_plot(plots$class_composition, output_paths[["class_composition"]], preset = "ncomms_half", width = 9.2, height = 6.5)
    save_lab_plot(plots$box_compare, output_paths[["box_compare"]], preset = "cell_half", width = 9.2, height = 7.0)
    save_lab_plot(plots$violin_compare, output_paths[["violin_compare"]], preset = "nature_half", width = 9.0, height = 7.2)
    save_lab_plot(plots$dot_compare, output_paths[["dot_compare"]], preset = "cell_half", width = 9.2, height = 7.0)

    output_paths
}
