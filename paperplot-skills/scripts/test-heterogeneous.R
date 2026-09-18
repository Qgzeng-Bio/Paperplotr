#!/usr/bin/env Rscript
# Fixed public-data layout fixtures; not confirmation of a user's manuscript.
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
out <- Sys.getenv('PAPERPLOT_HETEROGENEOUS_OUTPUT',file.path('visual-checks','heterogeneous-0.7.0'))
dir.create(out,recursive=TRUE,showWarnings=FALSE)
iris_data<-data.frame(x=iris$Sepal.Length,y=iris$Petal.Length,group=iris$Species,value=iris$Sepal.Length)
mat<-cor(iris[,1:4]);dimnames(mat)<-rep(list(c('Sepal L','Sepal W','Petal L','Petal W')),2)
long<-as.data.frame(as.table(mat));names(long)<-c('metric','category','value')
flow<-as.data.frame(margin.table(HairEyeColor,c(1,2)));names(flow)<-c('source','target','weight')
flow$source<-paste0('Hair:',flow$source);flow$target<-paste0('Eye:',flow$target)
effects<-pp_summary_statistics(data.frame(sample=seq_len(nrow(ToothGrowth)),group=ToothGrowth$supp,metric=ToothGrowth$dose,value=ToothGrowth$len),by=c('metric','group'),method='mean',interval='ci',unit_id='sample')
for(n in c(4L,6L)) {
  slot<-pp_render_spec(width_mm=if(n==4) 90 else 60,height_mm=75,panel_tags=FALSE)
  plots<-list(
    pp_recipe_plot('scatter_regression',iris_data,list(render_spec=slot,x_label='Sepal length (cm)',y_label='Petal length (cm)')),
    pp_recipe_plot('heatmap_cluster_reference',long,list(render_spec=slot,distance='euclidean',linkage='complete',value_label='Pearson r',value_limits=c(-1,1))),
    pp_recipe_plot('chord_adjacency_reference',flow,list(render_spec=slot,directed=FALSE)),
    pp_recipe_plot('forest_grouped_effect',effects,list(render_spec=slot,interval_label='Mean tooth length (95% CI)')))
  if(n==6) plots<-c(plots,list(
    pp_recipe_plot('boxplot_jitter',iris_data,list(render_spec=slot,y_label='Sepal length (cm)')),
    pp_recipe_plot('time_series_line',data.frame(time=as.numeric(time(UKgas)),value=as.numeric(UKgas),group='UK gas'),list(render_spec=slot))))
  combined<-pp_compose_manuscript(plots,design=if(n==4) 'AB\nCD' else 'ABC\nDEF')
  spec<-pp_render_spec(n,width_mm=180,height_mm=150,ocr='off')
  files<-pp_save_all_with_qa_loop(combined,file.path(out,paste0('public-',n,'-panel')),render_spec=spec,max_iterations=0,overwrite=TRUE)
  audit<-attr(files,'qa_export_audit')
  keys<-c('pdf_page_mm','svg_page_mm','png_pixels','svg_typography','pdf_typography','svg_panel_tags')
  if(!all(vapply(keys,function(k) identical(audit$checks[[k]],'pass'),logical(1)))) stop('Heterogeneous physical regression: ',n)
  if(attr(files,'qa_contract')$status=='pass') stop('A public fixture without actual review cannot self-approve.')
  cat(n,'-panel ggplot / ComplexHeatmap / circlize object assembly passed physical checks; human review pending.\n')
}
