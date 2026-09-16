# Recipe input contracts and explicitly requested statistics. No data synthesis.
pp_recipe_manifest <- function() {
  utils::read.csv(file.path(pp_helper_script_dir, '..', 'recipes', 'recipe_manifest.csv'),
                 stringsAsFactors = FALSE, check.names = FALSE)
}

pp_recipe_entry <- function(id) {
  m <- pp_recipe_manifest(); row <- m[m$recipe_id == id, , drop = FALSE]
  if (nrow(row) != 1L) stop('Unknown recipe_id: ', id, call. = FALSE)
  as.list(row[1, ])
}

pp_require_backend <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop('Backend unavailable: ', paste(missing, collapse = ', '),
    '. Restore the PaperPlot environment; no substitute figure was generated.', call. = FALSE)
}

pp_recipe_scalar <- function(df, params, name, default = NULL) {
  supplied <- params[[name]]
  from_data <- if (name %in% names(df)) unique(df[[name]][!is.na(df[[name]])]) else NULL
  if (length(from_data) > 1L) stop(name, ' must be constant within a panel; split panels for distinct results.')
  if (!is.null(supplied) && length(from_data) && !isTRUE(all.equal(supplied, from_data, check.attributes = FALSE))) {
    stop('Conflicting supplied ', name, ' and input column; no result was replaced.')
  }
  supplied %||% if (length(from_data)) from_data[[1]] else default
}

pp_assert_unique <- function(df, keys, what = 'records') {
  keys <- intersect(keys, names(df))
  if (!length(keys) || anyDuplicated(df[keys])) stop('Duplicate ', what, ' for key ',
    paste(keys, collapse = '+'), '; preserve groups or supply an explicit aggregation method.', call. = FALSE)
  invisible(TRUE)
}

pp_validate_recipe_input <- function(recipe_id, df, params = list(), mode = 'production') {
  mode <- match.arg(mode, c('production', 'preview', 'demo'))
  if (missing(df) || !is.data.frame(df) || !nrow(df)) stop('Provide a nonempty input table. Demo data must be constructed explicitly.')
  if (!is.list(params)) stop('params must be a named list.')
  entry <- pp_recipe_entry(recipe_id)
  required <- strsplit(entry$required_roles, ';', fixed = TRUE)[[1]]
  missing_cols <- setdiff(required, names(df))
  if (length(missing_cols)) stop('Missing required fields for ', recipe_id, ': ', paste(missing_cols, collapse = ', '))
  numeric_roles <- c('value','x','y','pc1','pc2','count','ratio','pvalue','padj','qvalue','base_mean',
    'log2fc','estimate','lower','upper','error','weight','time','position','start','end',
    'target_start','target_end','longitude','latitude','rank','running_score','observed','predicted','residual','branch_length')
  numeric_roles <- intersect(numeric_roles, names(df))
  for (name in numeric_roles) {
    if (!is.numeric(df[[name]])) stop('Numeric field required: ', name, '; no coercion was performed.')
    if (any(is.infinite(df[[name]]))) stop('Infinite value in ', name)
  }
  na_action <- match.arg(params$na_action %||% 'error', c('error','omit','keep'))
  complete_fields <- setdiff(required, 'parent')
  bad <- !stats::complete.cases(df[complete_fields])
  omitted <- which(bad)
  if (any(bad)) {
    if (na_action == 'error') stop('Missing required values at rows ', paste(head(omitted, 10), collapse = ', '), '; declare na_action explicitly.')
    if (na_action == 'omit') df <- df[!bad, , drop = FALSE]
    if (na_action == 'keep' && !entry$handler %in% c('matrix','complex_heatmap')) stop('na_action=keep is supported only for matrix missing cells.')
  }
  if (!nrow(df)) stop('No observations remain after the declared missing-value policy.')
  for (name in intersect(c('pvalue','padj','qvalue','ratio'), names(df))) {
    if (any(df[[name]] < 0 | df[[name]] > 1, na.rm = TRUE)) stop(name, ' must lie in [0,1].')
  }
  for (name in intersect(c('count','error','weight','branch_length'), names(df))) {
    if (any(df[[name]] < 0, na.rm = TRUE)) stop(name, ' must be nonnegative.')
  }
  if (all(c('lower','estimate','upper') %in% names(df)) &&
      any(df$lower > df$estimate | df$upper < df$estimate, na.rm = TRUE)) stop('Invalid supplied interval: require lower <= estimate <= upper.')
  if (all(c('start','end') %in% names(df)) && any(df$start > df$end, na.rm = TRUE)) stop('Genomic start must not exceed end.')
  for (name in intersect(c('position','start','end','target_start','target_end'), names(df))) {
    if (any(df[[name]] < 0 | df[[name]] != floor(df[[name]]), na.rm = TRUE)) stop(name, ' must contain nonnegative integer coordinates.')
  }
  if ('present' %in% names(df) && any(!df$present %in% c(0,1,FALSE,TRUE))) stop('present must be binary.')
  for (name in intersect(c('group','category','metric','chr','set','track','subgroup','panel'), names(df))) {
    if (!is.factor(df[[name]])) df[[name]] <- factor(df[[name]], levels = unique(df[[name]]))
  }
  # Optional grouping means one unnamed group, not an invented scientific result.
  if (!'group' %in% names(df)) df$group <- factor(rep('All', nrow(df)))
  if (entry$handler == 'enrichment' && !'category' %in% names(df)) df$category <- factor(rep('All', nrow(df)))
  if (!is.null(params$group_order)) {
    if (!setequal(params$group_order, as.character(unique(df$group)))) stop('group_order must contain exactly the input groups.')
    df$group <- factor(df$group, levels = params$group_order)
  }
  if (entry$handler == 'composition') {
    if (entry$variant != 'diverging' && any(df$value < 0)) stop('Composition cannot contain negative values; no absolute-value conversion was performed.')
    input_scale <- params$input_scale
    if (is.null(input_scale)) stop('Composition requires input_scale=counts, fraction, percent, or signed (diverging only).')
    if (!input_scale %in% c('counts','fraction','percent','signed')) stop('Invalid composition input_scale.')
    if (input_scale == 'signed' && entry$variant != 'diverging') stop('Signed input requires a diverging composition recipe.')
    pp_assert_unique(df, c('group','category','panel'), 'composition rows')
    totals <- tapply(df$value, interaction(df[intersect(c('group','panel'), names(df))], drop = TRUE), sum)
    target <- switch(input_scale, fraction=1, percent=100, NULL)
    if (!is.null(target) && any(abs(totals-target) > 1e-6)) stop('Supplied composition totals do not match ', input_scale, '; no normalization performed.')
    if (input_scale == 'counts' && any(totals <= 0)) stop('Count denominators must be positive.')
  }
  if (entry$handler %in% c('paired','dumbbell')) {
    identity <- if (entry$handler == 'paired') 'sample' else 'category'
    pp_assert_unique(df, c(identity,'group','metric','panel'), 'paired observations')
    groups <- levels(droplevels(df$group))
    if (length(groups) < 2 || (entry$handler == 'dumbbell' && length(groups) != 2)) stop('Supply the explicitly selected comparison groups; dumbbell requires exactly two.')
    pair_groups <- split(df, interaction(df[intersect(c(identity,'metric','panel'), names(df))], drop = TRUE))
    if (any(!vapply(pair_groups, function(d) setequal(as.character(d$group), groups), logical(1)))) stop('Incomplete pairing; no incomplete subjects were silently removed.')
  }
  if (entry$handler == 'forest') pp_assert_unique(df, c('metric','group','subgroup','panel'), 'effect estimates')
  if (entry$handler == 'enrichment') pp_assert_unique(df, c('term','group','category'), 'enrichment results')
  if (entry$handler %in% c('matrix','complex_heatmap')) pp_assert_unique(df, c('metric','category','group'), 'matrix cells')
  if (entry$handler == 'timeseries') pp_assert_unique(df, c('time','group','panel'), 'time-series summaries')
  if (entry$handler == 'sets') pp_assert_unique(df, c('item','set'), 'set memberships')
  if (entry$handler == 'rank') pp_assert_unique(df, c('category','group','panel'), 'ranked values')
  if (entry$handler == 'model' && entry$variant == 'residual' &&
      !isTRUE(all.equal(df$residual, df$observed-df$predicted, tolerance=1e-10, check.attributes=FALSE))) stop('Residuals conflict with observed - predicted.')
  attr(df, 'pp_input_policy') <- list(recipe_id=recipe_id, mode=mode, na_action=na_action,
    omitted_rows=if(na_action=='omit') omitted else integer(), params=params)
  df
}

pp_summary_statistics <- function(df, value = 'value', by = 'group', method,
                                  interval = 'none', conf_level = .95, unit_id = NULL,
                                  na_action = 'error') {
  method <- match.arg(method, c('mean','median')); interval <- match.arg(interval, c('none','sd','se','ci'))
  if (method == 'median' && interval != 'none') stop('Median intervals require upstream results; mean SD/SE/t intervals are not median intervals.')
  if (length(setdiff(c(value,by,unit_id), names(df)))) stop('Summary columns missing.')
  if (!is.numeric(df[[value]]) || any(!is.finite(df[[value]]) & !is.na(df[[value]]))) stop('Invalid summary measurements.')
  if (!is.numeric(conf_level) || length(conf_level)!=1 || conf_level<=0 || conf_level>=1) stop('conf_level must be in (0,1).')
  if (anyNA(df[[value]]) && na_action != 'omit') stop('Missing measurements require explicit na_action=omit.')
  if (is.null(unit_id)) stop('Raw summaries require an explicit unit_id to define the independent observation.')
  pp_assert_unique(df, c(by,unit_id), 'independent experimental units')
  groups <- split(df, interaction(df[by], drop=TRUE, lex.order=TRUE))
  out <- do.call(rbind, lapply(groups, function(d) {
    x <- d[[value]]; n_missing <- sum(is.na(x)); x <- x[!is.na(x)]; n <- length(x)
    if (!n || (interval != 'none' && n < 2)) stop('Insufficient independent observations for requested summary/interval.')
    estimate <- if (method=='mean') mean(x) else stats::median(x)
    spread <- if(n>1) stats::sd(x) else NA_real_
    error <- switch(interval, none=0, sd=spread, se=spread/sqrt(n), ci=stats::qt((1+conf_level)/2,n-1)*spread/sqrt(n))
    cbind(d[1,by,drop=FALSE], data.frame(estimate=estimate,lower=estimate-error,upper=estimate+error,
      n=n,n_missing=n_missing,error_type=interval,method=method,conf_level=if(interval=='ci') conf_level else NA_real_))
  }))
  rownames(out) <- NULL; out
}

pp_statistical_test <- function(df, method, x = 'value', group = 'group', y = NULL,
                                pair_id = NULL, conf_level = .95, na_action = 'error') {
  method <- match.arg(method, c('welch_t','paired_t','wilcoxon','paired_wilcoxon','pearson','spearman','lm'))
  needed <- if(method %in% c('pearson','spearman','lm')) c(x,y) else c(x,group,pair_id)
  if (is.null(y) && method %in% c('pearson','spearman','lm')) stop('Provide y for correlation/regression.')
  if(length(setdiff(needed,names(df)))) stop('Statistical test columns missing.')
  bad <- !stats::complete.cases(df[needed]); omitted <- sum(bad)
  if(any(bad) && na_action != 'omit') stop('Missing observations require na_action=omit.')
  df <- df[!bad,,drop=FALSE]
  if(method=='lm') {
    fit <- stats::lm(stats::reformulate(x,y),data=df)
    return(list(method='lm',n=nrow(df),n_missing=omitted,conf_level=conf_level,
      coefficients=summary(fit)$coefficients,interval=stats::confint(fit,level=conf_level),model=fit))
  }
  if(method %in% c('pearson','spearman')) result <- stats::cor.test(df[[x]],df[[y]],method=method,conf.level=conf_level,exact=FALSE) else {
    levels <- unique(as.character(df[[group]])); if(length(levels)!=2) stop('Explicitly select exactly two groups.')
    a <- df[as.character(df[[group]])==levels[1],,drop=FALSE]; b <- df[as.character(df[[group]])==levels[2],,drop=FALSE]
    paired <- method %in% c('paired_t','paired_wilcoxon')
    if(paired) {
      if(is.null(pair_id)) stop('Paired statistics require pair_id.')
      pp_assert_unique(a,pair_id); pp_assert_unique(b,pair_id)
      if(!setequal(a[[pair_id]],b[[pair_id]])) stop('Incomplete pairs after missing-value handling.')
      b <- b[match(a[[pair_id]],b[[pair_id]]),,drop=FALSE]
    }
    result <- if(method %in% c('welch_t','paired_t')) stats::t.test(a[[x]],b[[x]],paired=paired,conf.level=conf_level) else
      stats::wilcox.test(a[[x]],b[[x]],paired=paired,conf.int=TRUE,conf.level=conf_level,exact=FALSE)
  }
  list(method=method,n=nrow(df),n_missing=omitted,conf_level=conf_level,
    statistic=unname(result$statistic),estimate=result$estimate,pvalue=result$p.value,
    interval=result$conf.int,adjustment='none',pair_id=pair_id)
}

pp_adjust_pvalues <- function(pvalues,method) {
  if(missing(method) || !method %in% stats::p.adjust.methods) stop('Choose an explicit multiple-testing correction method.')
  if(!is.numeric(pvalues) || any(!is.finite(pvalues)|pvalues<0|pvalues>1)) stop('Supply finite probabilities in [0,1].')
  list(raw=pvalues,adjusted=stats::p.adjust(pvalues,method=method),method=method,family_size=length(pvalues))
}
