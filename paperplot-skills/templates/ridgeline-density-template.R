#!/usr/bin/env Rscript
suppressPackageStartupMessages({ library(ggplot2) })

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- file.path("paperplot-skills", "scripts", "paperplot_helpers.R")
source(helper_path)
source(file.path(dirname(helper_path), "run-template-recipe.R"))

input_path <- "TODO-input.csv"
output_dir <- "figures"

# Contract terms for standalone validation: figure_spec <- pp_figure_spec; metric_spec; pp_save_all; pp_write_notes; pp_write_metadata; pp_write_qa_report
pp_run_recipe_template(
  recipe_id = "ridge_facet_density",
  template_id = "ridgeline-density",
  family_label = "ridgeline / density",
  input_path = input_path,
  output_dir = output_dir,
  width_cm = 8.9,
  height_cm = 7.0,
  y_label = "Density"
)
