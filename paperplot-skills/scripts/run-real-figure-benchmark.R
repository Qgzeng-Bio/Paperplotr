#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
})

parse_args <- function(args) {
  out <- list(
    recipes_dir = "paperplot-skills/recipes",
    out = "paperplot-skills/reports/real-figure-benchmark/rendered",
    limit = NA_integer_
  )
  i <- 1
  while (i <= length(args)) {
    key <- args[[i]]
    if (identical(key, "--recipes-dir")) {
      i <- i + 1; out$recipes_dir <- args[[i]]
    } else if (identical(key, "--out")) {
      i <- i + 1; out$out <- args[[i]]
    } else if (identical(key, "--limit")) {
      i <- i + 1; out$limit <- as.integer(args[[i]])
    } else {
      stop("Unknown argument: ", key, call. = FALSE)
    }
    i <- i + 1
  }
  out
}

args <- parse_args(commandArgs(trailingOnly = TRUE))

helper_path <- Sys.getenv("PAPERPLOT_HELPER")
if (!nzchar(helper_path)) helper_path <- "paperplot-skills/scripts/paperplot_helpers.R"
if (!file.exists(helper_path)) stop("Missing helper: ", helper_path, call. = FALSE)
source(helper_path)

recipe_engine <- file.path(args$recipes_dir, "paperplot_code_recipes.R")
manifest_path <- file.path(args$recipes_dir, "recipe_manifest.csv")
if (!file.exists(recipe_engine)) stop("Missing recipe engine: ", recipe_engine, call. = FALSE)
if (!file.exists(manifest_path)) stop("Missing recipe manifest: ", manifest_path, call. = FALSE)
source(recipe_engine)

manifest <- read.csv(manifest_path, check.names = FALSE, stringsAsFactors = FALSE)
renderable <- manifest[manifest$status %in% c("production_recipe", "template_candidate", "benchmark_recipe"), , drop = FALSE]
if (!is.na(args$limit)) renderable <- renderable[seq_len(min(args$limit, nrow(renderable))), , drop = FALSE]

dir.create(args$out, recursive = TRUE, showWarnings = FALSE)

render_case <- function(row) {
  recipe_id <- row[["recipe_id"]]
  out_dir <- file.path(args$out, recipe_id)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  output_stem <- file.path(out_dir, recipe_id)
  df <- pp_recipe_mock_data(recipe_id, seed = 20260607)
  plot <- pp_recipe_plot(recipe_id, df)
  outputs <- pp_save_all(
    plot,
    output_stem,
    preset = if (as.numeric(row[["default_width_cm"]]) > 10) "nature" else "nature_half",
    width = as.numeric(row[["default_width_cm"]]),
    height = as.numeric(row[["default_height_cm"]]),
    overwrite = TRUE
  )
  data.frame(
    recipe_id = recipe_id,
    family = row[["figure_family"]],
    status = row[["status"]],
    pdf = outputs[["pdf"]],
    png = outputs[["png"]],
    rendered = TRUE,
    stringsAsFactors = FALSE
  )
}

results <- do.call(rbind, lapply(seq_len(nrow(renderable)), function(i) {
  tryCatch(render_case(renderable[i, , drop = FALSE]), error = function(e) {
    data.frame(
      recipe_id = renderable$recipe_id[[i]],
      family = renderable$figure_family[[i]],
      status = renderable$status[[i]],
      pdf = NA_character_,
      png = NA_character_,
      rendered = FALSE,
      stringsAsFactors = FALSE
    )
  })
}))

write.csv(results, file.path(args$out, "real-figure-render-index.csv"), row.names = FALSE)
print(results, row.names = FALSE)
if (!all(results$rendered)) stop("One or more benchmark recipes failed to render.", call. = FALSE)
cat("Rendered ", nrow(results), " benchmark recipe figures into ", args$out, "\n", sep = "")
