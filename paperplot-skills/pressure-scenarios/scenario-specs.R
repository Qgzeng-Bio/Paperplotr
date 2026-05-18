pp_pressure_scenarios <- function() {
  data.frame(
    scenario = c("quinoa-genome-quality", "dense-sample-labels", "volcano-selected-labels", "enrichment-top-terms", "duplication-panel-hierarchy"),
    template = c("bio-genome-quality-overview-template.R", "multi-metric-small-multiples-template.R", "volcano-plot-template.R", "enrichment-dotplot-template.R", "bio-duplication-mode-comparison-template.R"),
    expected_decision = c("rank index + label key", "rank index + label key", "selected gene labels + thresholds", "top terms + q-value/count semantics", "panel hierarchy + duplication semantics"),
    stringsAsFactors = FALSE
  )
}
