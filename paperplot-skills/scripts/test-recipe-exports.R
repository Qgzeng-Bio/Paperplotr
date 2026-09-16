#!/usr/bin/env Rscript
# Explicitly simulated export regression catalog. It cannot certify manuscripts.
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
if(!pp_check_environment(TRUE)$production_available) stop('Complete physical export environment required; no skip-as-success.')
args <- commandArgs(TRUE)
out <- if(length(args)) args[[1]] else file.path('visual-checks','recipe-exports-0.7.0')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
catalog <- pp_recipe_manifest()
selected <- Sys.getenv('PAPERPLOT_TEST_RECIPES','')
if(nzchar(selected)) catalog <- catalog[catalog$recipe_id %in% strsplit(selected,',',fixed=TRUE)[[1]],,drop=FALSE]
results <- lapply(catalog$recipe_id,function(id) {
  cat('Exporting',id,'\n'); flush.console()
  tryCatch({
    data <- pp_recipe_mock_data(id)
    p <- pp_recipe_plot(id,data,mode='demo')
    spec <- attr(p,'pp_render_spec')
    spec$n_panels <- pp_infer_panel_count(p)
    spec$panel_tags <- inherits(p,'patchwork') && pp_recipe_entry(id)$handler %in% c('layout','model')
    spec$expected_tags <- if(spec$panel_tags) as.list(LETTERS[seq_len(spec$n_panels)]) else list()
    spec$ocr <- 'off'
    stem <- file.path(out,id,id)
    files <- pp_save_all_with_qa_loop(p,stem,render_spec=spec,max_iterations=0,overwrite=TRUE,
      qa_context=list(family=pp_recipe_entry(id)$figure_family,layout_profile=if(inherits(p,'patchwork')) 'hierarchical' else 'auto'))
    audit <- attr(files,'qa_export_audit')
    exact <- c('pdf_page_mm','svg_page_mm','png_pixels','pdf_typography','svg_typography','pdf_font_embedding','svg_editable_text','svg_panel_tags')
    required <- setdiff(exact,if(!spec$panel_tags) 'svg_panel_tags' else character())
    bad <- required[!vapply(required,function(k) identical(audit$checks[[k]],'pass'),logical(1))]
    bad <- unique(c(bad,names(audit$checks)[vapply(audit$checks,identical,logical(1),'fail')]))
    data.frame(recipe=id,generated=TRUE,physical_pass=!length(bad),mode='demo',
      detail=if(length(bad)) paste(bad,collapse=',') else 'physical checks passed; not scientific acceptance',
      png=files[['png']],stringsAsFactors=FALSE)
  },error=function(e) data.frame(recipe=id,generated=FALSE,physical_pass=FALSE,mode='demo',detail=conditionMessage(e),png='',stringsAsFactors=FALSE))
})
results <- do.call(rbind,results)
utils::write.csv(results,file.path(out,'validation.csv'),row.names=FALSE)
print(results[,c('recipe','generated','physical_pass','detail')],row.names=FALSE)
cat(sum(results$generated),'/',nrow(results),'generated;',sum(results$physical_pass),'physical checks passed\n')
if(!all(results$physical_pass)) stop('Recipe physical export regressions remain; see validation.csv.')
