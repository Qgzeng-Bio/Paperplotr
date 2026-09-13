#!/usr/bin/env Rscript
# Explicitly simulated project; never reconstructs research values from images.
arg <- sub("^--file=", "", commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))])
source(file.path(dirname(normalizePath(arg[[1]])), "paperplot_helpers.R"))
args <- commandArgs(TRUE)
destination <- if (length(args)) args[[1]] else file.path("figures", "example-project")
if (dir.exists(destination) && length(list.files(destination, all.files = TRUE, no.. = TRUE))) stop("Choose a new empty example directory.")
dir.create(destination, recursive = TRUE, showWarnings = FALSE)
destination <- normalizePath(destination)
csv <- file.path(destination, "simulated.csv")
d <- data.frame(x = rep(1:12, 2), group = rep(c("Control", "Treatment"), each = 12))
d$y <- sin(d$x / 3) + ifelse(d$group == "Treatment", .5, 0)
write.csv(d, csv, row.names = FALSE)
builder <- file.path(destination, "example-builder.R")
writeLines(c(
  "build_panel <- function(inputs, context) {",
  "  d <- read.csv(inputs$values)",
  "  d$group <- factor(d$group, levels = names(context$shared$colors))",
  "  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = group))",
  "  if (context$panel_id == 'distribution') {",
  "    p <- ggplot2::ggplot(d, ggplot2::aes(group, y, fill = group)) + ggplot2::geom_boxplot(width=.5, linewidth=.25) + ggplot2::scale_fill_manual(values=unlist(context$shared$colors))",
  "  } else if (context$panel_id == 'profile') {",
  "    p <- p + ggplot2::geom_line()",
  "  } else if (context$panel_id == 'density') {",
  "    p <- ggplot2::ggplot(d, ggplot2::aes(y, colour=group)) + ggplot2::geom_density(key_glyph='path')",
  "  } else p <- p + ggplot2::geom_point()",
  "  if (context$panel_id != 'distribution') p <- p + ggplot2::scale_colour_manual(values=unlist(context$shared$colors))",
  "  p <- p + ggplot2::labs(title=context$question, colour=NULL, fill=NULL)",
  "  list(plot=p, evidence=d)",
  "}"
), builder)
ids <- c("association", "distribution", "profile", "density")
panels <- lapply(seq_along(ids), function(i) list(id = ids[i], title = ids[i], question = paste("Simulated", ids[i]),
  role = if (i == 1) "primary" else "supporting", script = builder, inputs = list(values = csv),
  guide_semantics = "simulated treatment", dependencies_declared = TRUE))
root <- file.path(destination, "figure-demo")
invisible(pp_project_create("figure-demo", "Demonstrate four independently editable simulated panels.", panels,
  project = root, shared = list(colors = list(Control = "#173B73", Treatment = "#D55E00")), mode = "demo"))
if ("--run-demo" %in% args) {
  pp_project_confirm_layout(root, "simulated walkthrough, not research approval")
  for (id in ids) pp_project_build_panel(root, id)
  invisible(pp_project_assemble(root))
  pp_project_review(root, "A", "pass", "simulated panel review")
  revised <- file.path(destination, "example-builder-B.R")
  writeLines(sub("list(plot=p, evidence=d)", "list(plot = p + ggplot2::theme(legend.position='bottom'), evidence = d)", readLines(builder), fixed = TRUE), revised)
  changed <- pp_project_revise_panel(root, "B", script = revised, reason = "Simulated walkthrough: move only B legend")
  if (!isTRUE(changed$success) || pp_project_status(root)$panels$distribution$current == "r000001") stop("The simulated B revision did not complete.")
}
cat("Example project:", root, "\n")
