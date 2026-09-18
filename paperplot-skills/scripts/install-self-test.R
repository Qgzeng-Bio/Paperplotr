#!/usr/bin/env Rscript
script <- sub('^--file=','',commandArgs(FALSE)[grepl('^--file=',commandArgs(FALSE))])
root <- normalizePath(file.path(dirname(script[[1]]),'..'))
source(file.path(root,'scripts','paperplot_helpers.R'))
source(file.path(root,'recipes','paperplot_code_recipes.R'))
if(!pp_check_environment(TRUE)$production_available) stop('Installed runtime is incomplete.')
output <- tempfile('paperplot-install-');dir.create(output)
p <- pp_recipe_plot('lollipop_ranked',data.frame(category=c('fixture-a','fixture-b'),value=c(1,2)),mode='demo')
files <- pp_save_all_with_qa_loop(p,file.path(output,'install-fixture'),max_iterations=0)
checks <- attr(files,'qa_export_audit')$checks
required <- c('pdf_page_mm','svg_page_mm','png_pixels','pdf_typography','svg_typography','pdf_font_embedding')
if(!all(vapply(required,function(k) identical(checks[[k]],'pass'),logical(1)))) stop('Installed export test failed: ',output)
for(name in c('family-qa-score.py','vision-review-adapter.py','export-audit.py','visual-qa-rendered-image.py')) {
  if(system2(pp_resolve_qa_python(),c(shQuote(file.path(root,'scripts',name)),'--help'),stdout=FALSE,stderr=FALSE)!=0) stop('Installed command is not runnable: ',name)
}
project<-file.path(output,'project')
rscript<-file.path(R.home('bin'),'Rscript')
if(system2(rscript,shQuote(c(file.path(root,'scripts','create-example-project.R'),project)),stdout=FALSE,stderr=FALSE)!=0) stop('Installed project creation is not runnable.')
if(system2(rscript,shQuote(c(file.path(root,'scripts','figure-project.R'),'status',file.path(project,'figure-demo'))),stdout=FALSE,stderr=FALSE)!=0) stop('Installed project status is not runnable.')
receipt <- list(skill_version=pp_helper_version,commit=Sys.getenv('PAPERPLOT_INSTALL_COMMIT','unknown'),
  dirty_source=Sys.getenv('PAPERPLOT_INSTALL_DIRTY','unknown'),
  environment=Sys.getenv('PAPERPLOT_ENV',path.expand('~/.local/share/paperplot/runtime-0.7.0')),
  R=as.character(getRversion()),installed_at=format(Sys.time(),tz='UTC',usetz=TRUE),
  acceptance='actual demo PDF/SVG/PNG physical export; not manuscript approval',
  hashes=as.list(tools::md5sum(file.path(root,c('renv.lock','requirements.lock','scripts/paperplot_helpers.R','recipes/recipe_manifest.csv')))))
if(nzchar(Sys.getenv('PAPERPLOT_INSTALL_COMMIT'))) writeLines(pp_to_json(receipt),file.path(root,'installation.json'))
cat('Installed commands and physical exports passed outside the project. Receipt:',file.path(root,'installation.json'),'\n')
unlink(output,recursive=TRUE)
