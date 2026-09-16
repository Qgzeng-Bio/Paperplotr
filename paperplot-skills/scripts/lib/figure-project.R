# Persistent figure projects. project.json is authoritative; RDS files are caches.
ppp_require <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Figure projects require jsonlite.")
}
ppp_hash <- function(x) {
  f <- tempfile(); on.exit(unlink(f)); saveRDS(x, f, version = 2)
  unname(tools::md5sum(f))
}
ppp_json <- function(x, path) {
  ppp_require()
  temp <- tempfile(".project-write-", tmpdir = dirname(path))
  on.exit(unlink(temp))
  writeLines(as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", pretty = TRUE, digits = 12)), temp)
  if (!file.rename(temp, path)) stop("Atomic state replacement failed; previous state retained.")
}
ppp_read <- function(root) {
  ppp_require()
  x <- jsonlite::fromJSON(file.path(root, "project.json"), simplifyVector = FALSE)
  if (!x$schema_version %in% c(1L,2L)) stop("Unsupported project schema.")
  x
}
ppp_event <- function(x, action, target = NULL) {
  x$events <- c(x$events, list(list(time = format(Sys.time(), tz = "UTC", usetz = TRUE), action = action, target = target)))
  x
}
ppp_locked <- function(project, fun, allow_legacy = FALSE) {
  root <- normalizePath(project, mustWork = TRUE)
  lock <- file.path(root, ".project-lock")
  if (!dir.create(lock, showWarnings = FALSE)) stop("Project is locked by another writer; inspect .project-lock/owner.json before manual recovery.")
  on.exit(unlink(lock, recursive = TRUE))
  ppp_json(list(pid = Sys.getpid(), time = as.character(Sys.time())), file.path(lock, "owner.json"))
  state <- ppp_read(root)
  if(state$schema_version==1L && !isTRUE(allow_legacy)) stop('Schema 1 is read-only. Run pp_project_migrate(project, dry_run=TRUE) before an explicit migration.')
  fun(state, root)
}
ppp_path <- function(path, root) {
  if (grepl("^(/|[A-Za-z]:[/\\\\])", path)) path else file.path(root, path)
}
ppp_stored_path <- function(path,root) {
  absolute <- normalizePath(ppp_path(path,root),mustWork=TRUE)
  prefix <- paste0(normalizePath(root),.Platform$file.sep)
  if(startsWith(absolute,prefix)) substring(absolute,nchar(prefix)+1L) else absolute
}
ppp_file_hash <- function(path) {
  if (!file.exists(path) || dir.exists(path)) stop("Registered dependency missing: ", path)
  unname(tools::md5sum(path))
}
ppp_environment <- function() {
  pkgs <- unique(c("ggplot2", "patchwork", "jsonlite", "systemfonts", "ragg", "svglite", "ggrepel",'ape','treeio','gridGraphics','igraph',
    unlist(strsplit(pp_recipe_manifest()$backend,';',fixed=TRUE))))
  list(R = R.version.string, platform = R.version$platform, helper = pp_helper_version,
    helper_hashes = as.list(tools::md5sum(c(file.path(pp_helper_script_dir, "paperplot_helpers.R"),
      list.files(file.path(pp_helper_script_dir, "lib"), pattern = "\\.R$", full.names = TRUE)))),
    packages = as.list(stats::setNames(vapply(pkgs, function(p) if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else "unavailable", character(1)), pkgs)))
}
ppp_layout <- function(layout, ids, column = "double") {
  limit <- if (column == "single") 89 else 180
  layout$width_mm <- layout$width_mm %||% limit
  layout$height_mm <- layout$height_mm %||% 120
  if (layout$width_mm > limit && !nzchar(layout$width_exception %||% "")) stop("Canvas exceeds column limit; record width_exception explicitly.")
  if (any(!is.finite(c(layout$width_mm, layout$height_mm))) || min(layout$width_mm, layout$height_mm) <= 0) stop("Invalid canvas dimensions.")
  if (layout$height_mm > 170) warning("Height exceeds 170 mm; consider splitting without shrinking text.")
  if (length(ids) > 26) stop("Version 1 supports up to 26 labelled panels.")
  order <- unlist(layout$order %||% ids, use.names = FALSE)
  if (!setequal(order, ids) || anyDuplicated(order)) stop("Layout order must contain every panel ID exactly once.")
  if (is.null(layout$design)) {
    letters <- LETTERS[seq_along(ids)]
    if (length(letters) == 1) layout$design <- "A" else {
      if (length(letters) %% 2) letters <- c(letters, "#")
      layout$design <- paste(vapply(seq(1, length(letters), 2), function(i) paste0(letters[i], letters[i + 1]), character(1)), collapse = "\n")
    }
  }
  rows <- strsplit(layout$design, "\n", fixed = TRUE)[[1]]
  if (length(unique(nchar(rows))) != 1) stop("Design rows must have equal width.")
  cells <- do.call(rbind, strsplit(rows, "", fixed = TRUE))
  labels <- LETTERS[seq_along(order)]
  if (!setequal(setdiff(unique(as.vector(cells)), "#"), labels)) stop("Design must contain each display letter exactly once as a rectangular area.")
  weights <- function(x, n) {
    x <- as.numeric(unlist(x %||% rep(1, n)))
    if (length(x) != n || any(!is.finite(x) | x <= 0)) stop("Layout weights must be positive and match tracks.")
    x / sum(x)
  }
  ws <- weights(layout$widths, ncol(cells)); hs <- weights(layout$heights, nrow(cells))
  xe <- c(0, cumsum(ws)) * layout$width_mm; ye <- c(0, cumsum(hs)) * layout$height_mm
  slots <- lapply(seq_along(order), function(i) {
    at <- which(cells == labels[i], arr.ind = TRUE)
    rs <- range(at[, 1]); cs <- range(at[, 2])
    if (any(cells[rs[1]:rs[2], cs[1]:cs[2]] != labels[i])) stop("Each panel area must be rectangular.")
    list(id = order[i], label = labels[i], left_mm = xe[cs[1]], top_mm = ye[rs[1]],
         width_mm = xe[cs[2] + 1] - xe[cs[1]], height_mm = ye[rs[2] + 1] - ye[rs[1]])
  })
  names(slots) <- order
  layout$order <- as.list(order); layout$widths <- as.list(ws); layout$heights <- as.list(hs); layout$slots <- slots
  layout$guides <- match.arg(layout$guides %||% "keep", c("keep", "collect"))
  layout$shared_rows <- layout$shared_rows %||% list()
  layout$shared_axes <- layout$shared_axes %||% list()
  layout
}
ppp_shared <- function(x, root, panel) {
  shared <- x$shared %||% list()
  if (!is.null(x$shared_config)) shared <- utils::modifyList(shared,
    jsonlite::fromJSON(ppp_path(x$shared_config, root), simplifyVector = FALSE))
  keys <- unlist(panel$shared_keys, use.names = FALSE)
  if (length(keys)) {
    if (length(setdiff(keys, names(shared)))) stop("A declared shared key is missing.")
    shared <- shared[keys]
  }
  shared
}
ppp_context <- function(x, root, id) {
  p <- x$panels[[id]]
  files <- lapply(p$inputs %||% list(), ppp_path, root = root)
  sources <- lapply(p$sources %||% list(), ppp_path, root = root)
  slot <- x$layout$slots[[id]]
  # Position/label changes invalidate assembly review, not unrelated panel code.
  placement <- slot[c("width_mm", "height_mm")]
  spec <- pp_render_spec(width_mm = slot$width_mm, height_mm = slot$height_mm,
                         mode = x$mode, text_pt = x$style$text_pt %||% list())
  spec$panel_tags <- FALSE
  shared <- ppp_shared(x, root, p)
  links <- c(x$layout$shared_rows, x$layout$shared_axes)
  links <- Filter(function(g) id %in% unlist(g$panels), links)
  code <- ppp_path(p$script, root)
  dependency_warnings <- ppp_dependency_warnings(c(code, unlist(sources, use.names = FALSE)))
  fingerprint <- list(script = ppp_file_hash(code), inputs = lapply(files, ppp_file_hash),
    paths = list(inputs = files, sources = sources),
    sources = lapply(sources, ppp_file_hash), environment = ppp_environment(), shared = shared,
    placement = placement, style = spec, links = links, seed = p$seed,
    panel_id = id, question = p$question, title = p$title, role = p$role,
    dependencies_declared = p$dependencies_declared, dependency_warnings = dependency_warnings,
    guide_semantics = p$guide_semantics, manual_tag_layers = p$manual_tag_layers)
  list(key = ppp_hash(fingerprint), fingerprint = fingerprint, inputs = files, sources = sources,
       script = code, render_spec = spec, slot = slot, shared = shared, links = links,
       seed = p$seed, panel_id = id, question = p$question, title = p$title, role = p$role)
}

ppp_dependency_warnings <- function(files) {
  warnings <- character()
  readers <- c("read.csv", "read.delim", "read.table", "readRDS", "load", "source", "sys.source",
               "read_csv", "read_tsv", "read_delim", "read_excel", "read.xlsx", "readLines")
  walk <- function(node, filename) {
    if (is.call(node)) {
      head <- node[[1]]
      name <- if (is.symbol(head)) as.character(head) else if (is.call(head) && as.character(head[[1]]) %in% c("::", ":::")) as.character(head[[3]]) else ""
      if (name %in% readers) {
        arg <- if (length(node) >= 2) node[[2]] else NULL
        registered <- is.call(arg) && as.character(arg[[1]]) %in% c("$", "[[") && identical(arg[[2]], as.name("inputs"))
        if (!registered) warnings <<- c(warnings, paste(basename(filename), name, "uses an input not directly referenced through inputs; review its dependency registration"))
      }
      if (name %in% c("Sys.getenv", "getOption", "Sys.time", "Sys.Date", "system", "system2")) warnings <<- c(warnings, paste(basename(filename), name, "uses an external or dynamic dependency"))
      invisible(lapply(as.list(node)[-1], function(child) if (!missing(child)) walk(child, filename)))
    } else if (is.expression(node) || is.pairlist(node)) invisible(lapply(as.list(node), function(child) if (!missing(child)) walk(child, filename)))
  }
  for (file in files) walk(parse(file), file)
  as.list(unique(warnings))
}
ppp_panel_id <- function(x, panel) {
  if (panel %in% names(x$panels)) return(panel)
  slots <- x$layout$slots
  matches <- names(slots)[vapply(slots, function(s) identical(s$label, panel), logical(1))]
  if (length(matches) != 1) stop("Unknown or ambiguous panel ID/label: ", panel)
  matches[[1]]
}
ppp_fresh <- function(x, root, id) {
  p <- x$panels[[id]]
  if(isTRUE(p$migration_rebuild_required)) return(list(fresh=FALSE,reason='schema migration requires scientific revalidation'))
  if (is.null(p$script)) return(list(fresh = FALSE, reason = "planned: no script"))
  ctx <- tryCatch(ppp_context(x, root, id), error = identity)
  if (inherits(ctx, "error")) return(list(fresh = FALSE, reason = conditionMessage(ctx)))
  rev <- p$revisions[[p$current %||% ""]]
  cache <- if (!is.null(rev)) file.path(root, rev$dir, "plot.rds") else ""
  evidence <- if(!is.null(rev)) file.path(root,rev$dir,'evidence.rds') else ''
  good <- !is.null(rev) && identical(ctx$key, rev$key) && file.exists(cache) && identical(ppp_file_hash(cache), rev$object_md5) &&
    file.exists(evidence) && identical(ppp_file_hash(evidence),rev$evidence_md5)
  list(fresh = good, reason = if (good) "current" else "dependencies or placement changed / not built", key = ctx$key)
}
ppp_summary <- function(x, root) {
  lines <- c(paste0("# ", x$figure_id), "", x$message, "",
    paste("Layout:", x$layout_version, if (identical(x$layout_confirmed, x$layout_version)) "confirmed" else "pending confirmation"),
    paste("Canvas:", x$layout$width_mm, "x", x$layout$height_mm, "mm; Arial; ordinary text 6-8 pt; tags 12 pt"), "",
    "| Label | Stable ID | Revision | State | Review |", "|---|---|---|---|---|")
  for (id in unlist(x$layout$order)) {
    p <- x$panels[[id]]; f <- ppp_fresh(x, root, id)
    reviewed <- !is.null(p$review) && identical(p$review$revision, p$current) &&
      identical(p$review$key, f$key) && identical(p$review$layout_key, ppp_review_context(x, id))
    lines <- c(lines, paste0("| ", x$layout$slots[[id]]$label, " | ", id, " | ", p$current %||% "none", " | ",
      f$reason, " | ", if (reviewed) p$review$decision else "pending", " |"))
  }
  a <- ppp_assembly_status(x, root)
  c(lines, "", paste("Assembly:", x$current_assembly %||% "none", "-", a$status),
    "Read project.json and recompute status before continuing: external dependencies may have changed since this summary.")
}
ppp_save <- function(x, root) {
  x$state_generation <- (x$state_generation %||% 0L) + 1L
  ppp_json(x, file.path(root, "project.json"))
  tryCatch(writeLines(ppp_summary(x, root), file.path(root, "project_summary.md")),
    error = function(e) warning("Project state saved; summary could not be refreshed: ", conditionMessage(e)))
  invisible(x)
}
ppp_next_revision <- function(root, relative) {
  parent <- file.path(root, relative); dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  existing <- list.files(parent, pattern = "^r[0-9]+$")
  n <- if (length(existing)) max(as.integer(sub("^r", "", existing))) + 1L else 1L
  id <- sprintf("r%06d", n); path <- file.path(parent, id)
  if (!dir.create(path)) stop("Revision allocation failed.")
  list(id = id, dir = file.path(relative, id), path = path)
}
ppp_sketch <- function(x, root) {
  slots <- x$layout$slots
  d <- do.call(rbind, lapply(slots, function(s) data.frame(x = s$left_mm, y = s$top_mm,
    width = s$width_mm, height = s$height_mm,
    label = paste(s$label, x$panels[[s$id]]$title, x$panels[[s$id]]$role,
      sprintf("%.1f x %.1f mm (including axes/guides)", s$width_mm, s$height_mm), "Guide space: reserved within slot", sep = "\n"))))
  p <- ggplot2::ggplot(d) + ggplot2::geom_rect(ggplot2::aes(xmin = x + 1, xmax = x + width - 1, ymin = y + 1, ymax = y + height - 1), fill = "#F2F4F5", colour = "#777777") +
    ggplot2::geom_text(ggplot2::aes(x = x + width / 2, y = y + height / 2, label = label), size = 2.5) +
    ggplot2::scale_y_reverse(limits = c(x$layout$height_mm, 0)) + ggplot2::scale_x_continuous(limits = c(0, x$layout$width_mm)) +
    ggplot2::coord_fixed(expand = FALSE) + ggplot2::theme_void() + ggplot2::labs(caption = "LAYOUT DRAFT: no scientific data or figure approval")
  ggplot2::ggsave(file.path(root, "layouts", x$layout_version, "sketch.png"), p,
    width = x$layout$width_mm, height = x$layout$height_mm, units = "mm", dpi = 150, bg = "white")
}

pp_project_create <- function(figure_id, message, panels, project = file.path("figures", figure_id),
                              layout = list(), column = "double", shared = list(), shared_config = NULL,
                              mode = "production") {
  ppp_require()
  if (file.exists(file.path(project, "project.json"))) return(pp_project_status(project))
  if (!grepl("^[A-Za-z0-9_-]+$", figure_id) || !nzchar(trimws(message)) || grepl("TODO", message)) stop("Provide a stable figure ID and actual scientific message.")
  column <- match.arg(column, c("single", "double")); mode <- match.arg(mode, c("production", "preview", "demo"))
  ids <- vapply(panels, function(p) p$id, character(1))
  if (!length(ids) || anyDuplicated(ids) || any(!grepl("^[a-z][a-z0-9_-]*$", ids))) stop("Panel IDs must be unique lowercase identifiers.")
  layout <- ppp_layout(layout, ids, column)
  for (p in panels) {
    if (!nzchar(p$title %||% "") || !nzchar(p$question %||% "")) stop("Each panel needs a title and scientific question.")
    match.arg(p$role %||% "supporting", c("primary", "secondary", "supporting"))
    if (!is.null(p$script)) normalizePath(p$script, mustWork = TRUE)
    for (field in c("inputs", "sources")) invisible(lapply(p[[field]] %||% list(), normalizePath, mustWork = TRUE))
  }
  if (dir.exists(project) && length(list.files(project, all.files = TRUE, no.. = TRUE))) stop("Project destination is nonempty and has no project.json.")
  dir.create(project, recursive = TRUE, showWarnings = FALSE)
  root <- normalizePath(project)
  skill_root <- normalizePath(file.path(pp_helper_script_dir, ".."))
  if (root == skill_root || startsWith(root, paste0(skill_root, .Platform$file.sep))) stop("Research projects must be outside the Skill installation.")
  lock <- file.path(root, ".project-lock")
  if (!dir.create(lock, showWarnings = FALSE)) stop("Project initialization is locked.")
  on.exit(unlink(lock, recursive = TRUE))
  ppp_json(list(pid = Sys.getpid(), operation = "create"), file.path(lock, "owner.json"))
  dir.create(file.path(root, "working")); dir.create(file.path(root, "layouts", "r000001"), recursive = TRUE)
  ps <- lapply(panels, function(p) {
    if (!nzchar(p$title %||% "") || !nzchar(p$question %||% "")) stop("Each panel needs a title and scientific question.")
    if (!is.null(p$script)) {
      src <- normalizePath(p$script, mustWork = TRUE)
      dest <- file.path("working", paste0(p$id, ".R"))
      if (!file.copy(src, file.path(root, dest))) stop("Cannot initialize panel working script.")
      p$script <- dest
    }
    for (field in c("inputs", "sources")) p[[field]] <- lapply(p[[field]] %||% list(), normalizePath, mustWork = TRUE)
    p$role <- match.arg(p$role %||% "supporting", c("primary", "secondary", "supporting"))
    p$seed <- p$seed %||% 104729L; p$dependencies_declared <- isTRUE(p$dependencies_declared)
    p$current <- NULL; p$revisions <- list(); p$review <- NULL
    p
  }); names(ps) <- ids
  x <- list(schema_version = 2L, figure_id = figure_id, message = message, mode = mode, column = column,
    panels = ps, layout = layout, layout_version = "r000001", layout_confirmed = NULL,
    layout_history = list(r000001 = layout), shared = shared,
    shared_config = if (!is.null(shared_config)) normalizePath(shared_config, mustWork = TRUE) else NULL,
    style = list(), assemblies = list(), current_assembly = NULL, events = list(), state_generation = 0L)
  ppp_json(layout, file.path(root, "layouts", "r000001", "layout.json"))
  ppp_save(ppp_event(x, "create"), root); ppp_sketch(x, root)
  pp_project_status(root)
}
pp_project_status <- function(project) {
  root <- normalizePath(project, mustWork = TRUE); x <- ppp_read(root)
  x$panel_status <- lapply(names(x$panels), function(id) ppp_fresh(x, root, id)); names(x$panel_status) <- names(x$panels)
  x$assembly_status <- ppp_assembly_status(x, root)
  x$build_fresh <- all(vapply(x$panel_status,function(p) isTRUE(p$fresh),logical(1)))
  x$qa_fresh <- isTRUE(x$assembly_status$qa_fresh)
  x$summary <- ppp_summary(x, root)
  x
}

ppp_assembly_status <- function(x, root) {
  a <- x$assemblies[[x$current_assembly %||% ""]]
  if (is.null(a)) return(list(status = "not_built"))
  stale <- !identical(a$layout_version, x$layout_version) || !identical(x$layout_confirmed, x$layout_version) || length(a$incomplete) > 0
  for (id in names(a$panels)) {
    f <- ppp_fresh(x, root, id)
    stale <- stale || !f$fresh || !identical(a$panels[[id]]$revision, x$panels[[id]]$current)
  }
  if (stale) return(list(status = "stale", build_fresh=FALSE,qa_fresh=FALSE,revision = x$current_assembly))
  valid <- ppp_assembly_artifacts(a,root)
  if(!valid$valid) return(list(status='stale',build_fresh=TRUE,qa_fresh=FALSE,reason=valid$reason,revision=x$current_assembly))
  if(ppp_failed_panel_review(x)) return(list(status='fail',build_fresh=TRUE,qa_fresh=TRUE,reason='A current panel review failed',revision=x$current_assembly))
  review <- x$assembly_review
  qa <- if (!is.null(review) && identical(review$revision, x$current_assembly) && identical(review$evidence_hash,a$qa$evidence_hash)) review$result else a$qa
  list(status = qa$status,build_fresh=TRUE,qa_fresh=TRUE,revision = x$current_assembly, qa = qa)
}

ppp_assembly_artifacts <- function(assembly, root) {
  provenance <- assembly$provenance
  if(is.null(provenance$detectors)||!identical(provenance$detectors,pp_detector_fingerprint())) return(list(valid=FALSE,reason='Detector/configuration changed or legacy QA lacks fingerprints; rerun QA.'))
  hashes <- provenance$output_md5
  if(!length(hashes)) return(list(valid=FALSE,reason='Missing export hashes.'))
  for(name in names(hashes)) {
    path <- file.path(root,assembly$dir,name)
    if(!file.exists(path)||!identical(unname(tools::md5sum(path)),hashes[[name]])) return(list(valid=FALSE,reason=paste('Export missing or changed:',name)))
  }
  list(valid=TRUE)
}

pp_project_migrate <- function(project,dry_run=TRUE) {
  root <- normalizePath(project,mustWork=TRUE); state <- ppp_read(root)
  if(state$schema_version==2L) return(invisible(list(from=2L,to=2L,changed=FALSE)))
  plan <- list(from=1L,to=2L,changed=TRUE,historical_revisions='preserved',historical_approvals='retained as history, invalid for new acceptance',raw_inputs='unchanged')
  if(isTRUE(dry_run)) return(plan)
  ppp_locked(root,function(x,root) {
    backup <- tempfile('project-schema1-',tmpdir=root,fileext='.json')
    if(!file.copy(file.path(root,'project.json'),backup)) stop('Cannot back up legacy project; migration stopped.')
    x$schema_version <- 2L
    x$legacy_assembly_review <- x$assembly_review; x$assembly_review <- NULL
    for(id in names(x$panels)) {
      x$panels[[id]]$legacy_review <- x$panels[[id]]$review; x$panels[[id]]$review <- NULL
      # Keep the historical pointer, but require an explicit first scientific
      # rebuild: schema-1 evidence lacks the new scale/statistical contract.
      x$panels[[id]]$migration_rebuild_required <- !is.null(x$panels[[id]]$current)
      for(field in c('inputs','sources')) x$panels[[id]][[field]] <- lapply(x$panels[[id]][[field]] %||% list(),function(path) {
        if(file.exists(ppp_path(path,root))) ppp_stored_path(path,root) else path
      })
    }
    ppp_save(ppp_event(x,'migrate',list(from=1L,to=2L,backup=basename(backup))),root)
    c(plan,list(backup=backup))
  },allow_legacy=TRUE)
}
pp_project_confirm_layout <- function(project, reviewer) {
  if (!nzchar(reviewer)) stop("Record who confirmed the layout.")
  ppp_locked(project, function(x, root) {
    x$layout_confirmed <- x$layout_version
    ppp_save(ppp_event(x, "confirm_layout", list(version = x$layout_version, reviewer = reviewer)), root)
  })
}
pp_project_set_layout <- function(project, layout) {
  ppp_locked(project, function(x, root) {
    value <- ppp_layout(layout, names(x$panels), x$column)
    rev <- ppp_next_revision(root, "layouts")
    ppp_json(value, file.path(rev$path, "layout.json"))
    x$layout <- value; x$layout_version <- rev$id; x$layout_confirmed <- NULL
    x$layout_history[[rev$id]] <- value
    ppp_save(ppp_event(x, "set_layout", rev$id), root); ppp_sketch(x, root)
  })
}

ppp_review_context <- function(x, id) {
  a <- x$assemblies[[x$current_assembly %||% ""]]
  measured <- NULL
  if (!is.null(a) && identical(a$layout_version, x$layout_version) && identical(a$panels[[id]]$revision, x$panels[[id]]$current)) {
    measured <- list(outer = a$geometry$outer_slots[[id]], data = a$geometry$data_regions[[id]])
  }
  ppp_hash(list(slot = x$layout$slots[[id]], guides = x$layout$guides, measured = measured))
}

ppp_backup_working <- function(x, root, id) {
  script <- x$panels[[id]]$script
  if (!is.null(script) && file.exists(file.path(root, script))) {
    revision <- ppp_next_revision(root, file.path("working_history", id))
    if (!file.copy(file.path(root, script), file.path(revision$path, "builder.R"))) stop("Cannot preserve the current working script.")
  }
}

pp_project_configure <- function(project, settings, panel = NULL) {
  ppp_locked(project, function(x, root) {
    if (is.null(panel)) {
      if (length(setdiff(names(settings), c("style", "shared", "shared_config")))) stop("Only style/shared/shared_config are project settings; use set_layout for canvas changes.")
      if (!is.null(settings$shared_config)) settings$shared_config <- ppp_stored_path(settings$shared_config,root)
      for (key in names(settings)) x[[key]] <- settings[[key]]
    } else {
      id <- ppp_panel_id(x, panel)
      allowed <- c("inputs", "sources", "shared_keys", "guide_semantics", "dependencies_declared", "seed", "title", "question", "role", "manual_tag_layers")
      if (length(setdiff(names(settings), allowed))) stop("Unsupported panel setting.")
      for (field in intersect(names(settings), c("inputs", "sources"))) settings[[field]] <- lapply(settings[[field]],ppp_stored_path,root=root)
      for (key in names(settings)) x$panels[[id]][[key]] <- settings[[key]]
    }
    ppp_save(ppp_event(x, "configure", list(panel = panel, fields = as.list(names(settings)))), root)
  })
}
