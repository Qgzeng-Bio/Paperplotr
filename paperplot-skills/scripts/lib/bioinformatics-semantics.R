# Bioinformatics figure semantics for paperplot-skills.
# Keep this module dependency-free: base R only.

pp_bio_metric_registry <- function() {
  data.frame(
    pattern = c("n50", "busco.*complete|complete", "busco.*duplicat|duplicated", "contamination", "gap", "qv|quality", "telomere", "gene_count|genes", "genome_size|assembly_size", "gc"),
    label = c("N50", "BUSCO complete", "BUSCO duplicated", "Contamination", "Gaps", "Assembly quality", "Telomeres", "Gene count", "Genome size", "GC content"),
    unit = c("Mb", "%", "%", "%", "count", "score", "count", "count", "Mb", "%"),
    direction = c("higher_better", "higher_better", "neutral", "lower_better", "lower_better", "higher_better", "higher_better", "neutral", "neutral", "neutral"),
    role = c("contiguity", "completeness", "duplication", "quality_risk", "assembly_risk", "integrated_quality", "chromosome_end_support", "annotation", "assembly_scale", "composition"),
    stringsAsFactors = FALSE
  )
}

pp_bio_match_metric <- function(metric) {
  registry <- pp_bio_metric_registry()
  key <- tolower(as.character(metric))
  idx <- which(vapply(registry$pattern, function(pattern) grepl(pattern, key, ignore.case = TRUE), logical(1)))
  if (length(idx) < 1) {
    return(list(label = as.character(metric), unit = "a.u.", direction = "neutral", role = "bio_metric"))
  }
  as.list(registry[idx[[1]], c("label", "unit", "direction", "role")])
}

pp_bio_genome_quality_spec <- function(metrics = NULL) {
  if (is.null(metrics)) {
    metrics <- c("N50", "BUSCO complete", "BUSCO duplicated", "contamination", "gaps", "assembly quality")
  }
  matches <- lapply(metrics, pp_bio_match_metric)
  pp_metric_spec(
    metric = metrics,
    label = vapply(matches, function(x) x$label, character(1)),
    unit = vapply(matches, function(x) x$unit, character(1)),
    direction = vapply(matches, function(x) x$direction, character(1)),
    transform = "none",
    role = vapply(matches, function(x) x$role, character(1))
  )
}

pp_bio_rank_samples <- function(data, metrics, direction_map = NULL, sample_col = "sample", metric_col = "metric", value_col = "value", score_col = NULL, group_col = NULL) {
  if (!is.null(score_col) && score_col %in% names(data)) {
    score <- tapply(as.numeric(data[[score_col]]), data[[sample_col]], mean, na.rm = TRUE)
    return(names(sort(score, decreasing = TRUE)))
  }
  if (is.null(direction_map)) {
    spec <- pp_bio_genome_quality_spec(metrics)
    direction_map <- setNames(spec$direction, spec$metric)
  }
  samples <- unique(as.character(data[[sample_col]]))
  scores <- setNames(rep(0, length(samples)), samples)
  counts <- setNames(rep(0, length(samples)), samples)
  for (metric in intersect(metrics, unique(as.character(data[[metric_col]])))) {
    d <- data[as.character(data[[metric_col]]) == metric, , drop = FALSE]
    vals <- as.numeric(d[[value_col]])
    if (all(is.na(vals))) next
    ranks <- rank(vals, ties.method = "average", na.last = "keep") / sum(!is.na(vals))
    direction <- direction_map[[metric]] %||% "neutral"
    if (identical(direction, "lower_better")) ranks <- 1 - ranks
    if (identical(direction, "neutral")) ranks <- rep(0.5, length(ranks))
    for (i in seq_len(nrow(d))) {
      sample <- as.character(d[[sample_col]][[i]])
      if (!is.na(ranks[[i]])) {
        scores[[sample]] <- scores[[sample]] + ranks[[i]]
        counts[[sample]] <- counts[[sample]] + 1
      }
    }
  }
  scores <- scores / pmax(counts, 1)
  names(sort(scores, decreasing = TRUE))
}

pp_bio_select_key_samples <- function(data, sample_col, metrics = NULL, group_col = NULL, value_col = NULL, max_labels = 8) {
  samples <- unique(as.character(data[[sample_col]]))
  selected <- character()
  if (!is.null(group_col) && group_col %in% names(data)) {
    by_group <- split(as.character(data[[sample_col]]), data[[group_col]])
    selected <- unique(unlist(lapply(by_group, function(x) head(unique(x), 1)), use.names = FALSE))
  }
  if (!is.null(value_col) && value_col %in% names(data)) {
    sample_score <- tapply(as.numeric(data[[value_col]]), data[[sample_col]], mean, na.rm = TRUE)
    sample_score <- sample_score[!is.na(sample_score)]
    if (length(sample_score) > 0) {
      selected <- unique(c(selected, names(sort(sample_score, decreasing = TRUE))[1], names(sort(sample_score, decreasing = FALSE))[1]))
    }
  }
  unique(head(c(selected, samples), max_labels))
}

pp_bio_template_recommendation <- function(task_type, data_profile = list()) {
  task <- tolower(task_type)
  if (grepl("genome|assembly|quality", task)) return("bio-genome-quality-overview-template.R")
  if (grepl("volcano|differential", task)) return("volcano-plot-template.R")
  if (grepl("ma plot|mean.*fold|base mean", task)) return("ma-plot-template.R")
  if (grepl("enrichment|go|kegg", task)) return("enrichment-dotplot-template.R")
  if (grepl("duplication|wgd|tandem|trd|dsd", task)) return("bio-duplication-mode-comparison-template.R")
  "multi-metric-small-multiples-template.R"
}
