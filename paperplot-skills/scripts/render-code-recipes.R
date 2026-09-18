#!/usr/bin/env Rscript
# Compatibility demo gallery. The same production chain handles every recipe.
script <- sub('^--file=','',commandArgs(FALSE)[grepl('^--file=',commandArgs(FALSE))])
source(file.path(dirname(normalizePath(script[[1]])),'paperplot_helpers.R'))
source(file.path(pp_helper_script_dir,'run-template-recipe.R'))
args <- commandArgs(TRUE); output <- 'visual-checks/recipe-gallery'; limit<-84L
while(length(args)) {
  key<-args[[1]]; if(length(args)<2) stop('Each supported option needs a value.')
  value<-args[[2]];args<-args[-c(1,2)]
  if(key=='--out') output<-value else if(key=='--limit') limit<-as.integer(value) else
    if(key=='--recipes-dir') {
      if(normalizePath(value)!=normalizePath(file.path(pp_helper_script_dir,'..','recipes'))) stop('Use the installed manifest; custom directory dispatch is not supported.')
    } else stop('Unknown option: ',key,'. Visual QA cannot be bypassed.')
}
catalog<-head(pp_recipe_manifest(),limit)
rows<-lapply(seq_len(nrow(catalog)),function(i) {
  entry<-catalog[i,];id<-entry$recipe_id;folder<-file.path(output,id)
  tryCatch({
    files<-pp_run_recipe_template(id,id,entry$figure_family,input_path='explicit-demo-constructor',output_dir=folder,mode='demo')
    stem<-file.path(folder,id)
    data.frame(recipe_id=id,family=entry$figure_family,status='demo only',pdf=files[['pdf']],png=files[['png']],
      notes=paste0(stem,'_notes.md'),metadata=paste0(stem,'_metadata.json'),qa=paste0(stem,'_qa.md'),
      visual_qa=attr(files,'qa_contract')$status)
  },error=function(e) data.frame(recipe_id=id,family=entry$figure_family,status='demo error',pdf=NA,png=NA,notes=NA,metadata=NA,qa=NA,visual_qa=paste('error:',conditionMessage(e))))
})
dir.create(output,recursive=TRUE,showWarnings=FALSE)
result<-do.call(rbind,rows);write.csv(result,file.path(output,'recipe-gallery-index.csv'),row.names=FALSE)
print(result[,c('recipe_id','visual_qa')],row.names=FALSE)
if(any(grepl('^error:',result$visual_qa))) stop('Gallery generation failed; no acceptance claimed.')
cat('Demo gallery generated; not manuscript acceptance.\n')
