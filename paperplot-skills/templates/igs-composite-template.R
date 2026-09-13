# Data-backed IGS redraw. Percentages/statistics must already be verified.
suppressPackageStartupMessages(library(ggplot2))
helper_path <- Sys.getenv("PAPERPLOT_HELPER", "paperplot-skills/scripts/paperplot_helpers.R")
source(helper_path)
input_path <- "TODO-input.csv"
output_dir <- "figures"
if (!file.exists(input_path)) stop("Provide the original IGS plotting table; screenshots are not data.")
data <- read.csv(input_path, check.names = FALSE)
plot <- pp_igs_figure(data)
render_spec <- pp_render_spec(2, case = "igs")
output_stem <- file.path(output_dir, paste0("igs_", format(Sys.time(), "%Y%m%d-%H%M%S")))
outputs <- pp_save_all_with_qa_loop(plot, output_stem, render_spec = render_spec,
  qa_context = list(family = "multi-panel", expected_panels = 2))
figure_spec <- pp_figure_spec(figure_id = "igs", template_id = "igs-composite-template", task_type = "redraw",
  figure_role = "main", scientific_message = "Compare verified IGS identity composition and summary statistics in the supplied species order.",
  plot_type = "multi-panel", output_preset = "nature")
metric_spec <- pp_metric_spec(metric = "identity", label = "Identity to B-type reference", unit = "fraction", direction = "neutral")
notes <- paste0(output_stem, "_notes.md")
metadata <- paste0(output_stem, "_metadata.json")
pp_write_notes(notes, "igs", input_path, outputs, "nature", figure_spec = figure_spec, metric_spec = metric_spec,
  design_decisions = "Shared species rows, fixed identity bins, Median/Max connectors, one n column, Arial role typography.",
  remaining_issues = "Original data and old annotation consistency must be reviewed before manuscript acceptance.")
pp_write_metadata(metadata, figure_spec, metric_spec, outputs, data_summary = pp_data_summary(data),
  ordering = list(species = data$species), qa = attr(outputs, "qa_contract"))
pp_write_qa_report(paste0(output_stem, "_qa.md"), pp_qa_postflight(outputs, notes, metadata))
print(unname(outputs))
