#!/usr/bin/env Rscript
file_arg <- sub("^--file=", "", commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
source(file.path(dirname(normalizePath(file_arg[[1]])), "paperplot_helpers.R"))
args <- commandArgs(TRUE)
if (length(args) < 2) stop("Usage: figure-project.R create config.json | status/build/revise/assemble/confirm-layout/set-layout/review/restore/configure project [arguments]")
read_json <- function(path) jsonlite::fromJSON(path, simplifyVector = FALSE)
action <- args[[1]]; target <- args[[2]]
result <- switch(action,
  create = do.call(pp_project_create, read_json(target)),
  status = pp_project_status(target),
  build = pp_project_build_panel(target, args[[3]]),
  revise = do.call(pp_project_revise_panel, c(list(project = target, panel = args[[3]]), read_json(args[[4]]))),
  assemble = pp_project_assemble(target, final = length(args) > 2 && args[[3]] == "final"),
  `confirm-layout` = pp_project_confirm_layout(target, args[[3]]),
  `set-layout` = pp_project_set_layout(target, read_json(args[[3]])),
  review = pp_project_review(target, args[[3]], args[[4]], args[[5]]),
  restore = pp_project_restore(target, args[[3]], args[[4]]),
  configure = pp_project_configure(target, read_json(args[[3]]), if (length(args) > 3) args[[4]] else NULL),
  stop("Unknown project operation."))
if (!is.null(result$summary)) cat(paste(result$summary, collapse = "\n"), "\n") else {
  cat(pp_to_json(list(success = result$success %||% TRUE, revision = result$revision,
    error = result$error %||% result$result$error)), "\n")
}
if (identical(result$success, FALSE)) quit(status = 1)
