# Design-aware QA helpers for paperplot-skills.

pp_visual_budget <- function(figure_role, n_panels = 1, n_labels = 0, n_legend_entries = 0) {
  figure_role <- match.arg(figure_role, c("main", "supplement", "diagnostic", "exploratory"))
  label_limit <- switch(figure_role, main = 12, supplement = 30, diagnostic = Inf, exploratory = 20)
  legend_limit <- switch(figure_role, main = 8, supplement = 12, diagnostic = Inf, exploratory = 10)
  panel_limit <- switch(figure_role, main = 6, supplement = 12, diagnostic = Inf, exploratory = 8)
  list(
    figure_role = figure_role,
    n_panels = n_panels,
    n_labels = n_labels,
    n_legend_entries = n_legend_entries,
    label_limit = label_limit,
    legend_limit = legend_limit,
    panel_limit = panel_limit,
    label_status = if (n_labels <= label_limit) "pass" else "warn",
    legend_status = if (n_legend_entries <= legend_limit) "pass" else "warn",
    panel_status = if (n_panels <= panel_limit) "pass" else "warn"
  )
}

pp_axis_burden_score <- function(labels, available_width_cm, font_size_pt = 6.5) {
  pp_label_burden_score(labels, available_width_cm, font_size_pt)
}

pp_legend_burden_score <- function(entries, max_entries = NULL, figure_role = "main") {
  entries <- unique(as.character(entries))
  max_entries <- max_entries %||% switch(figure_role, main = 8, supplement = 12, diagnostic = Inf, exploratory = 10)
  status <- if (length(entries) <= max_entries) "pass" else "warn"
  list(status = status, n_entries = length(entries), max_entries = max_entries)
}

pp_panel_burden_score <- function(n_panels, strip_labels = NULL, figure_role = "main") {
  max_panels <- switch(figure_role, main = 6, supplement = 12, diagnostic = Inf, exploratory = 8)
  long_strips <- if (is.null(strip_labels)) 0 else sum(nchar(as.character(strip_labels)) > 28)
  status <- if (n_panels <= max_panels && long_strips == 0) "pass" else "warn"
  list(status = status, n_panels = n_panels, max_panels = max_panels, long_strip_labels = long_strips)
}

pp_annotation_burden_score <- function(n_annotations, figure_role = "main") {
  max_annotations <- switch(figure_role, main = 3, supplement = 12, diagnostic = Inf, exploratory = 6)
  status <- if (n_annotations <= max_annotations) "pass" else "warn"
  list(status = status, n_annotations = n_annotations, max_annotations = max_annotations)
}

pp_qa_design_preflight <- function(design_brief, design_plan, visual_budget) {
  pp_validate_design_brief(design_brief)
  pp_validate_design_plan(design_plan)
  pp_qa_summary(
    pp_qa_result("design_brief", "pass", "scientific message and figure role recorded"),
    pp_qa_result("design_plan", "pass", "chart family and visible simplifications recorded"),
    pp_qa_result("visual_budget_labels", visual_budget$label_status, paste("visible labels:", visual_budget$n_labels, "limit:", visual_budget$label_limit)),
    pp_qa_result("visual_budget_legend", visual_budget$legend_status, paste("legend entries:", visual_budget$n_legend_entries, "limit:", visual_budget$legend_limit)),
    pp_qa_result("visual_budget_panels", visual_budget$panel_status, paste("panels:", visual_budget$n_panels, "limit:", visual_budget$panel_limit))
  )
}

pp_qa_label_strategy <- function(label_strategy, figure_role) {
  status <- "pass"
  note <- paste("strategy:", label_strategy$strategy)
  if (identical(figure_role, "main") && identical(label_strategy$strategy, "full_labels_diagnostic")) {
    status <- "fail"
    note <- "main figures must not use diagnostic full-label strategy"
  }
  if (identical(figure_role, "main") && identical(label_strategy$strategy, "rank_index_key_labels") && !isTRUE(label_strategy$needs_label_key)) {
    status <- "fail"
    note <- "rank-index main figure strategy must require a label key sidecar"
  }
  pp_qa_result("label_strategy", status, note)
}

pp_manuscript_readiness_score <- function(qa_results) {
  qa_results <- pp_as_qa_df(qa_results)
  if (any(qa_results$status == "fail")) return(0)
  score <- 10
  score <- score - sum(qa_results$status == "warn")
  max(0, min(10, score))
}

pp_qa_manuscript_readiness <- function(qa_results, design_brief, design_plan) {
  pp_validate_design_brief(design_brief)
  pp_validate_design_plan(design_plan)
  score <- pp_manuscript_readiness_score(qa_results)
  threshold <- if (identical(design_brief$figure_role, "main")) 8 else if (identical(design_brief$figure_role, "supplement")) 7 else 0
  status <- if (score >= threshold) "pass" else "warn"
  if (any(pp_as_qa_df(qa_results)$status == "fail")) status <- "fail"
  pp_qa_result("manuscript_readiness", status, paste("score:", score, "threshold:", threshold))
}
