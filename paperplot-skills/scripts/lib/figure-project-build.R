# Builds are immutable artifacts. Only successful attempts update current pointers.
ppp_untag <- function(p, declared = integer()) {
  if (length(declared) && any(!as.integer(unlist(declared)) %in% seq_along(p$layers))) stop("Manual tag layer indices must identify existing layers.")
  if (length(declared)) p$layers <- p$layers[-as.integer(unlist(declared))]
  p$labels$tag <- NULL
  if (identical(p$labels$caption, "DEMO / simulated test data")) p$labels$caption <- NULL
  if (inherits(p, "patchwork")) {
    p$patches$plots <- lapply(p$patches$plots, ppp_untag)
    p$patches$annotation$tag_levels <- NULL
  }
  p
}
ppp_build <- function(x, root, id, kind = "style", reason = "build") {
  if (!identical(x$layout_confirmed, x$layout_version)) stop("Confirm the current layout before building panels.")
  p <- x$panels[[id]]
  f <- ppp_fresh(x, root, id)
  if (isTRUE(f$fresh)) return(list(state = x, revision = p$current, reused = TRUE, success = TRUE))
  rev <- ppp_next_revision(root, file.path("panels", id, "revisions"))
  warnings <- character(); log <- character(); ctx <- NULL
  outcome <- tryCatch({
    ctx <- ppp_context(x, root, id)
    ppp_json(ctx, file.path(rev$path, "context.json"))
    file.copy(ctx$script, file.path(rev$path, "builder.R"))
    if (length(ctx$sources)) {
      dir.create(file.path(rev$path, "sources"))
      for (i in seq_along(ctx$sources)) file.copy(ctx$sources[[i]], file.path(rev$path, "sources", paste0(i, "-", basename(ctx$sources[[i]]))))
    }
    oldwd <- getwd(); on.exit(setwd(oldwd), add = TRUE); setwd(root)
    old_seed <- if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) get(".Random.seed", .GlobalEnv) else NULL
    on.exit(if (is.null(old_seed)) { if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv) } else assign(".Random.seed", old_seed, .GlobalEnv), add = TRUE)
    set.seed(ctx$seed)
    env <- new.env(parent = globalenv())
    log <- capture.output(value <- withCallingHandlers({
      for (source_file in ctx$sources) sys.source(source_file, env)
      sys.source(file.path(rev$path, "builder.R"), env)
      if (!exists("build_panel", env, inherits = FALSE) || !is.function(env$build_panel)) stop("Builder must define build_panel(inputs, context).")
      env$build_panel(ctx$inputs, ctx)
    }, warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }))
    plot <- if (inherits(value, "ggplot")) value else value$plot
    if (!inherits(plot, "ggplot")) stop("Only ggplot2/patchwork objects are supported; external images are not panel objects.")
    plot <- ppp_untag(plot, p$manual_tag_layers %||% integer())
    normalized <- pp_normalize_production(plot, ctx$render_spec)
    evidence <- pp_plot_evidence(normalized)
    statistics <- if (inherits(value, "ggplot")) NULL else value$evidence
    if (!is.null(p$current) && kind == "style") {
      old <- readRDS(file.path(root, p$revisions[[p$current]]$dir, "evidence.rds"))
      pp_assert_data_unchanged(old, list(plot = evidence, statistics = statistics))
    }
    # A builder must not modify registered inputs or dependencies while executing.
    after <- ppp_context(x, root, id)
    if (!identical(ctx$key, after$key)) stop("Registered dependency changed during build; result discarded.")
    saveRDS(normalized, file.path(rev$path, "plot.rds"))
    saveRDS(list(plot = evidence, statistics = statistics), file.path(rev$path, "evidence.rds"))
    saveRDS(list(inputs = lapply(ctx$inputs, function(path) list(path = path, md5 = ppp_file_hash(path))),
                 used_shared = ctx$shared, environment = ctx$fingerprint$environment), file.path(rev$path, "provenance.rds"))
    outputs <- pp_save_all_with_qa_loop(normalized, file.path(rev$path, "preview"), render_spec = ctx$render_spec, max_iterations = 0)
    if (!isTRUE(p$dependencies_declared)) warnings <- c(warnings, "Dependency tracking is unverified: declare all data and source files before reproducibility approval.")
    warnings <- c(warnings, unlist(ctx$fingerprint$dependency_warnings))
    result <- list(success = TRUE, key = ctx$key, dir = rev$dir, kind = kind, reason = reason,
                   dependency_complete = isTRUE(p$dependencies_declared) && !length(ctx$fingerprint$dependency_warnings),
                   environment = ctx$fingerprint$environment, warnings = as.list(warnings),
                   object_md5 = ppp_file_hash(file.path(rev$path, "plot.rds")),
                   evidence_md5 = ppp_file_hash(file.path(rev$path, "evidence.rds")),
                   qa = attr(outputs, "qa_contract"), layout_version = x$layout_version)
    result
  }, error = function(e) list(success = FALSE, dir = rev$dir, kind = kind, reason = reason, error = conditionMessage(e)))
  writeLines(c(log, warnings, outcome$error %||% "Build completed."), file.path(rev$path, "build.log"))
  ppp_json(outcome, file.path(rev$path, "revision.json"))
  x$panels[[id]]$revisions[[rev$id]] <- outcome
  if (isTRUE(outcome$success)) {
    x$panels[[id]]$current <- rev$id; x$panels[[id]]$review <- NULL
  }
  x <- ppp_event(x, if (isTRUE(outcome$success)) "build_panel" else "build_failed", list(panel = id, revision = rev$id))
  ppp_save(x, root)
  list(state = x, revision = rev$id, success = outcome$success, error = outcome$error, reused = FALSE)
}

pp_project_build_panel <- function(project, panel, change_type = "style", reason = "build") {
  change_type <- match.arg(change_type, c("style", "scientific"))
  if (change_type == "scientific" && (!nzchar(reason) || reason == "build")) stop("Scientific revisions require an explicit reason.")
  ppp_locked(project, function(x, root) ppp_build(x, root, ppp_panel_id(x, panel), change_type, reason))
}

ppp_placeholder <- function(label, reason) {
  ggplot2::ggplot(data.frame(x = 0, y = 0), ggplot2::aes(x, y)) +
    ggplot2::geom_text(label = paste("INCOMPLETE", label, reason, sep = "\n"), size = 2.5, colour = "#777777") +
    ggplot2::theme_void()
}

ppp_validate_shared_order <- function(plot, order) {
  scales <- ggplot2::ggplot_build(plot)$layout$panel_scales_y
  for (scale in scales) {
    if (!scale$is_discrete()) stop("Shared species rows require discrete Y axes in project v1.")
    if (length(setdiff(scale$get_limits(), order))) stop("Shared row order omits plotted categories; no data were dropped.")
  }
}

ppp_row_alignment <- function(geometry, groups) {
  checks <- list()
  for (group in groups) {
    members <- unlist(group$panels); n <- length(unlist(group$order))
    regions <- geometry$data_regions[members]
    if (any(vapply(regions, is.null, logical(1)))) {
      checks <- c(checks, list(list(status = "unverified", panels = as.list(members))))
    } else {
      positions <- lapply(regions, function(r) r$top_mm + r$height_mm * (1 - (seq_len(n) - .4)/(n + .2)))
      differences <- apply(do.call(cbind, positions), 1, function(y) max(y)-min(y))
      checks <- c(checks, list(list(status = if (all(differences <= .2)) "pass" else "fail",
        panels = as.list(members), maximum_difference_mm = max(differences), positions_mm = positions)))
    }
  }
  list(status = if (any(vapply(checks, function(x) x$status == "fail", logical(1)))) "fail" else
    if (any(vapply(checks, function(x) x$status == "unverified", logical(1)))) "unverified" else "pass", checks = checks)
}

ppp_measure <- function(plot, spec, root) {
  if (!requireNamespace("svglite", quietly = TRUE)) return(list(status = "unverified", reason = "svglite unavailable"))
  filename <- tempfile(fileext = ".svg"); on.exit(unlink(filename))
  svglite::svglite(filename, width = spec$width_mm / 25.4, height = spec$height_mm / 25.4)
  on.exit(grDevices::dev.off(), add = TRUE)
  normalized <- pp_normalize_production(plot, spec)
  gt <- patchwork::patchworkGrob(normalized)
  grid::grid.newpage(); grid::grid.draw(gt)
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(length(gt$heights), length(gt$widths),
    widths = gt$widths, heights = gt$heights, respect = gt$respect)))
  measure <- function(t, l, b, r) {
    grid::pushViewport(grid::viewport(layout.pos.row = t:b, layout.pos.col = l:r))
    loc <- grid::deviceLoc(grid::unit(0, "npc"), grid::unit(1, "npc"), valueOnly = TRUE)
    result <- list(left_mm = loc$x * 25.4, top_mm = spec$height_mm - loc$y * 25.4,
      width_mm = grid::convertWidth(grid::unit(1, "npc"), "mm", valueOnly = TRUE),
      height_mm = grid::convertHeight(grid::unit(1, "npc"), "mm", valueOnly = TRUE))
    grid::popViewport(); result
  }
  ws <- vapply(seq_along(gt$widths), function(i) measure(1, i, length(gt$heights), i)$width_mm, numeric(1))
  hs <- vapply(seq_along(gt$heights), function(i) measure(i, 1, i, length(gt$widths))$height_mm, numeric(1))
  regions <- list(); outer <- list()
  for (i in seq_len(spec$n_panels)) {
    rows <- gt$layout[grepl(paste0("-", i, "$"), gt$layout$name), , drop = FALSE]
    if (nrow(rows)) outer[[as.character(i)]] <- measure(min(rows$t), min(rows$l), max(rows$b), max(rows$r))
    data_rows <- gt$layout[gt$layout$name == paste0("panel-", i), , drop = FALSE]
    if (nrow(data_rows) == 1) regions[[as.character(i)]] <- measure(data_rows$t, data_rows$l, data_rows$b, data_rows$r)
  }
  grid::popViewport()
  gt$widths <- grid::unit(ws, "mm"); gt$heights <- grid::unit(hs, "mm")
  previews <- list()
  for (i in seq_len(spec$n_panels)) {
    allocation <- outer[[as.character(i)]]
    if (is.null(allocation)) next
    cell <- gtable::gtable_filter(gt, paste0("-", i, "$"), trim = TRUE)
    path <- file.path(root, paste0("context-", LETTERS[i], ".png"))
    ggplot2::ggsave(path, cell, width = allocation$width_mm, height = allocation$height_mm, units = "mm", dpi = 300, bg = "white")
    previews[[as.character(i)]] <- basename(path)
  }
  list(status = if (length(regions) == spec$n_panels) "measured" else "unverified",
       outer_slots = outer, data_regions = regions, context_previews = previews,
       note = "Context previews use the assembled gtable with resolved physical tracks; nested panels may require manual region review.")
}

ppp_assemble <- function(x, root, final = FALSE) {
  if (!identical(x$layout_confirmed, x$layout_version)) stop("Confirm the current layout before assembling.")
  ids <- unlist(x$layout$order, use.names = FALSE)
  if (final && ppp_failed_panel_review(x)) stop("Resolve current failed panel reviews before requesting final assembly.")
  freshness <- lapply(ids, function(id) ppp_fresh(x, root, id))
  if (final && any(!vapply(freshness, function(f) f$fresh, logical(1)))) stop("Final assembly requires complete, fresh panels; rebuild first.")
  if (!final) for (id in ids) {
    f <- ppp_fresh(x, root, id)
    if (!f$fresh && !is.null(x$panels[[id]]$script)) {
      # External data changes are never silently treated as styling.
      old <- x$panels[[id]]$revisions[[x$panels[[id]]$current %||% ""]]
      ctx <- tryCatch(ppp_context(x, root, id), error = function(e) NULL)
      if (!is.null(old) && !is.null(ctx)) {
        oldctx <- jsonlite::fromJSON(file.path(root, old$dir, "context.json"), simplifyVector = FALSE)
        if (!identical(oldctx$fingerprint$inputs, ctx$fingerprint$inputs)) next
      }
      attempt <- ppp_build(x, root, id, "style", "draft dependency refresh")
      x <- attempt$state
    }
  }
  plots <- list(); chosen <- list(); incomplete <- character()
  for (id in ids) {
    f <- ppp_fresh(x, root, id); p <- x$panels[[id]]
    if (!f$fresh) {
      incomplete <- c(incomplete, id); plots[[id]] <- ppp_placeholder(x$layout$slots[[id]]$label, f$reason)
    } else {
      plots[[id]] <- ppp_untag(readRDS(file.path(root, p$revisions[[p$current]]$dir, "plot.rds")))
      chosen[[id]] <- list(revision = p$current, key = f$key, object_md5 = p$revisions[[p$current]]$object_md5)
    }
  }
  if (x$layout$guides == "collect") {
    meanings <- vapply(ids, function(id) x$panels[[id]]$guide_semantics %||% "", character(1))
    colors <- lapply(ids, function(id) ppp_shared(x, root, x$panels[[id]])$colors)
    if (any(!nzchar(meanings)) || length(unique(meanings)) != 1 || !all(vapply(colors, identical, logical(1), colors[[1]]))) stop("Shared legends require identical declared meaning and color mapping.")
  }
  for (group in x$layout$shared_rows) {
    members <- unlist(group$panels); order <- unlist(group$order, use.names = FALSE)
    if (!all(members %in% ids) || !length(order)) stop("Invalid shared-row declaration.")
    if (!any(members %in% incomplete)) {
      invisible(lapply(plots[members], ppp_validate_shared_order, order = order))
      plots[members] <- pp_shared_rows(plots[members], order)
    }
  }
  for (group in x$layout$shared_axes) {
    members <- unlist(group$panels); limits <- as.numeric(unlist(group$limits))
    if (!all(members %in% ids) || !group$axis %in% c("x", "y") || length(limits) != 2 || any(!is.finite(limits))) stop("Invalid shared-axis declaration.")
    for (id in setdiff(members, incomplete)) {
      if (!inherits(plots[[id]]$coordinates, "CoordCartesian")) stop("Shared limits require Cartesian panels.")
      args <- stats::setNames(list(limits), paste0(group$axis, "lim"))
      plots[[id]] <- plots[[id]] + do.call(ggplot2::coord_cartesian, args)
    }
  }
  spec <- pp_render_spec(length(ids), width_mm = x$layout$width_mm, height_mm = x$layout$height_mm,
    mode = x$mode, text_pt = x$style$text_pt %||% list())
  combined <- pp_compose_manuscript(plots, design = x$layout$design,
    widths = as.numeric(unlist(x$layout$widths)), heights = as.numeric(unlist(x$layout$heights)))
  combined <- combined + patchwork::plot_layout(guides = x$layout$guides)
  rev <- ppp_next_revision(root, "assemblies")
  result <- tryCatch({
    geometry <- tryCatch(ppp_measure(combined, spec, rev$path), error = function(e) list(status = "unverified", reason = conditionMessage(e)))
    for (field in c("outer_slots", "data_regions", "context_previews")) {
      if (length(geometry[[field]])) names(geometry[[field]]) <- ids[as.integer(names(geometry[[field]]))]
    }
    row_alignment <- ppp_row_alignment(geometry, x$layout$shared_rows)
    geometry$shared_rows <- row_alignment
    checks <- list(panels_complete = if (length(incomplete)) "fail" else "pass",
      geometry = if (geometry$status == "measured") "pass" else "unverified", shared_rows = row_alignment$status,
      dependencies = if (!length(incomplete) && all(vapply(x$panels, function(p) isTRUE(p$revisions[[p$current]]$dependency_complete), logical(1)))) "pass" else "unverified")
    outputs <- pp_save_all_with_qa_loop(combined, file.path(rev$path, "figure"), render_spec = spec, max_iterations = 0,
      project_context = list(figure_id = x$figure_id, layout_version = x$layout_version, panels = chosen, checks = checks))
    qa <- attr(outputs, "qa_contract")
    manifest <- list(success = TRUE, dir = rev$dir, panels = chosen, incomplete = as.list(incomplete),
      layout_version = x$layout_version, layout = x$layout, render_spec = spec, geometry = geometry,
      qa = qa, requested_final = final, environment = ppp_environment())
    ppp_json(manifest, file.path(rev$path, "assembly.json"))
    writeLines(c("# Figure assembly", paste("Revision:", rev$id), paste("Final status:", qa$status),
      paste("Tier:", qa$tier), paste("Incomplete panels:", paste(incomplete, collapse = ", ")),
      "Inspect assembly.json for exact panel revisions, physical geometry and outstanding checks."), file.path(rev$path, "delivery.md"))
    manifest
  }, error = function(e) list(success = FALSE, dir = rev$dir, error = conditionMessage(e)))
  if (!isTRUE(result$success)) ppp_json(result, file.path(rev$path, "failed.json"))
  x$assemblies[[rev$id]] <- result
  if (isTRUE(result$success)) x$current_assembly <- rev$id
  ppp_save(ppp_event(x, "assemble", list(revision = rev$id, success = result$success)), root)
  list(state = x, revision = rev$id, success = result$success, result = result)
}
pp_project_assemble <- function(project, final = FALSE) {
  ppp_locked(project, function(x, root) ppp_assemble(x, root, final))
}
pp_project_revise_panel <- function(project, panel, script = NULL, change_type = "style", reason) {
  if (!nzchar(reason)) stop("Record the reason for revision.")
  change_type <- match.arg(change_type, c("style", "scientific"))
  ppp_locked(project, function(x, root) {
    id <- ppp_panel_id(x, panel)
    if (!is.null(script)) {
      ppp_backup_working(x, root, id)
      dest <- x$panels[[id]]$script %||% file.path("working", paste0(id, ".R"))
      if (!file.copy(script, file.path(root, dest), overwrite = TRUE)) stop("Cannot update working script.")
      x$panels[[id]]$script <- dest
    }
    built <- ppp_build(x, root, id, change_type, reason)
    if (!built$success) return(built)
    ppp_assemble(built$state, root, FALSE)
  })
}
pp_project_review <- function(project, target, decision = "pass", reviewer) {
  decision <- match.arg(decision, c("pass", "fail"))
  if (!nzchar(reviewer)) stop("Reviewer must be recorded.")
  ppp_locked(project, function(x, root) {
    if (target == "figure") {
      if (decision == "pass" && ppp_failed_panel_review(x)) stop("Resolve current failed panel reviews before approving the figure.")
      a <- x$assemblies[[x$current_assembly %||% ""]]
      if (is.null(a) || !identical(a$layout_version, x$layout_version) || length(a$incomplete)) stop("No complete current assembly to review.")
      for (id in names(a$panels)) if (!isTRUE(ppp_fresh(x, root, id)$fresh) || !identical(a$panels[[id]]$revision, x$panels[[id]]$current)) stop("Assembly is stale.")
      x$assembly_review <- list(revision = x$current_assembly, reviewer = reviewer, decision = decision,
                               result = pp_final_qa(a$qa$checks, decision, x$mode))
    } else {
      id <- ppp_panel_id(x, target); f <- ppp_fresh(x, root, id)
      if (!f$fresh) stop("Cannot approve stale panel.")
      x$panels[[id]]$review <- list(revision = x$panels[[id]]$current, key = f$key,
        layout_version = x$layout_version, layout_key = ppp_review_context(x, id), reviewer = reviewer, decision = decision)
    }
    record <- if (target == "figure") x$assembly_review else x$panels[[id]]$review
    ppp_save(ppp_event(x, "review", list(target = target, record = record)), root)
  })
}

ppp_failed_panel_review <- function(x) {
  any(vapply(x$panels, function(p) identical(p$review$revision, p$current) && identical(p$review$decision, "fail"), logical(1)))
}
pp_project_restore <- function(project, target, revision) {
  ppp_locked(project, function(x, root) {
    if (target == "layout") {
      old <- x$layout_history[[revision]]
      if (is.null(old)) stop("Unknown layout revision.")
      x$layout <- old; x$layout_version <- revision; x$layout_confirmed <- NULL
    } else {
      id <- ppp_panel_id(x, target); old <- x$panels[[id]]$revisions[[revision]]
      if (is.null(old) || !isTRUE(old$success)) stop("Unknown or failed panel revision.")
      ppp_backup_working(x, root, id)
      file.copy(file.path(root, old$dir, "builder.R"), file.path(root, x$panels[[id]]$script), overwrite = TRUE)
      x$panels[[id]]$current <- revision; x$panels[[id]]$review <- NULL
    }
    ppp_save(ppp_event(x, "restore", list(target = target, revision = revision)), root)
  })
}
