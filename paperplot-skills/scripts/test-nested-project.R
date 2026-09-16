#!/usr/bin/env Rscript
# Real public data; simulated review events exercise mechanics, not human approval.
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
check<-function(x,label) if(!isTRUE(x)) stop(label)
root<-Sys.getenv('PAPERPLOT_NESTED_TEST_OUTPUT',tempfile('nested-project-'))
dir.create(root,recursive=TRUE,showWarnings=FALSE);root<-normalizePath(root)
values<-file.path(root,'mtcars.csv');write.csv(data.frame(x=mtcars$wt,y=mtcars$mpg),values,row.names=FALSE)
mat<-as.data.frame(as.table(cor(iris[,1:4])));names(mat)<-c('metric','category','value')
matrix_file<-file.path(root,'iris-correlations.csv');write.csv(mat,matrix_file,row.names=FALSE)
nested_script<-file.path(root,'nested.R')
writeLines(c('build_panel <- function(inputs, context) {',
  'd<-read.csv(inputs$values)',
  'p<-ggplot2::ggplot(d,ggplot2::aes(x,y))+ggplot2::geom_point()+ggplot2::labs(x="Weight (1000 lb)",y="Fuel economy (mpg)")',
  'list(plot=patchwork::wrap_plots(list(p,p),ncol=1),evidence=d,backend="patchwork",dependencies=inputs)',
  '}'),nested_script)
native_script<-file.path(root,'native.R')
writeLines(c('build_panel <- function(inputs, context) {',
  'd<-read.csv(inputs$values)',
  'p<-pp_recipe_plot("heatmap_cluster_reference",d,list(distance="euclidean",linkage="complete",render_spec=context$render_spec))',
  'list(plot=p,evidence=d,backend="ComplexHeatmap",dependencies=inputs)',
  '}'),native_script)
project<-file.path(root,'project')
panels<-list(list(id='nested',title='Nested plot',question='Nested vector fixture, not a scientific composite claim',script=nested_script,inputs=list(values=values),dependencies_declared=TRUE),
  list(id='native',title='Native heatmap',question='Native vector fixture with supplied correlations',script=native_script,inputs=list(values=matrix_file),dependencies_declared=TRUE))
invisible(pp_project_create('nested-real-fixture','Test nested/native object assembly on public observations.',panels,project=project,layout=list(design='AB',width_mm=180,height_mm=100)))
pp_project_confirm_layout(project,'AUTOMATED LAYOUT FIXTURE')
for(id in c('nested','native')) {b<-pp_project_build_panel(project,id);check(b$success,paste(id,b$error))}
a<-pp_project_assemble(project);check(a$success,paste('Nested assembly',a$result$error))
check(a$result$qa$checks$export_svg_panel_tags=='pass','Exactly two outer tags, not one tag per nested subchart')
check(a$result$qa$checks$project_geometry=='unverified','Opaque data regions are not incorrectly measured as empty ggplot scaffolds')
check('project_geometry'%in%unlist(a$result$qa$reviewable),'Specific geometry blind spot is reviewable')
pp_project_review(project,'figure','pass','AUTOMATED REVIEW FIXTURE - NOT HUMAN APPROVAL',checks=unlist(a$result$qa$reviewable),reason='Mechanism test only; not a publication or human-science approval.')
check(pp_project_status(project)$assembly_status$status=='pass','Bound review can resolve supported native/nested geometry blind spots')
pp_project_review(project,'A','fail','AUTOMATED REJECTION FIXTURE')
check(pp_project_status(project)$assembly_status$status=='fail','Rejecting a current nested panel invalidates the approved composite')
files<-names(ppp_environment()$helper_hashes)
check(all(c('recipe_manifest.csv','paperplot_code_recipes.R')%in%basename(files)),'Recipe routing/entry implementation participates in build freshness')
cat('Nested/native public project, tag count, source freshness and review transitions passed.\n')
