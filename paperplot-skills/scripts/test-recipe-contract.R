#!/usr/bin/env Rscript
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
check <- function(x,label) if(!isTRUE(x)) stop(label,call.=FALSE)
fails <- function(expr,label) check(inherits(tryCatch(force(expr),error=identity),'error'),label)

# Science regressions: values are supplied, not filled in by the plot engine.
d <- data.frame(pc1=1:8,pc2=sin(1:8),group='A',stress=.42)
p <- pp_recipe_plot('nmds_stress_ordination',d)
check(identical(p$layers[[2]]$aes_params$label,'Stress = 0.42'),'Real stress propagated')
check(!grepl('%',pp_recipe_plot('pca_pcoa_ordination',d,list(variant='pca'))$labels$x),'No invented variance')
fails(pp_recipe_plot('pca_pcoa_ordination',d),'Mixed-method recipe requires an explicit variant')
fails(pp_recipe_plot('nmds_stress_ordination',d,params=list(stress=.08)),'Conflicting statistics rejected')
fails(pp_recipe_plot('pca_pcoa_ordination'),'No default mock data')
fails(pp_recipe_plot('pca_pcoa_ordination',pp_recipe_mock_data('pca_pcoa_ordination')),'Demo cannot be production')

effects <- data.frame(metric='m',group=c('A','B'),estimate=c(1,9),lower=c(0,8),upper=c(2,10))
p <- pp_recipe_plot('forest_effect_size',effects)
check(nrow(p$data)==2 && identical(p$data$estimate,c(1,9)),'Forest rows and intervals preserved')
fails(pp_recipe_plot('forest_effect_size',rbind(effects,effects[1,])),'Duplicate effects rejected')
fails(pp_recipe_plot('stacked_bar_fraction',data.frame(group='A',category=c('a','b'),value=c(-2,3)),list(input_scale='counts')),'Negative composition rejected')
fails(pp_recipe_plot('stacked_bar_fraction',data.frame(group='A',category=c('a','b'),value=c(.2,.3)),list(input_scale='fraction')),'No silent fraction normalization')
check(inherits(pp_recipe_plot('correlation_heatmap',data.frame(metric='a',category='b',value=1)),'ggplot'),'Optional group omitted')
check(inherits(pp_recipe_plot('enrichment_dotplot',data.frame(term='t',ratio=.1,qvalue=.01,count=2)),'ggplot'),'Optional category omitted')
fails(pp_recipe_plot('paired_comparison',data.frame(sample=c('a','a','b'),group=c('A','B','A'),value=1:3)),'Incomplete pairing rejected')
fails(pp_recipe_plot('volcano_threshold',data.frame(feature='g',log2fc=1,padj=-.1),list(alpha=.05,effect_threshold=1)),'Invalid probability rejected')
fails(pp_recipe_plot('violin_dot',data.frame(group='A',value=1)),'Tiny density groups fail explicitly')
fails(pp_recipe_plot('dumbbell_comparison',data.frame(category='a',group=rep(c('A','B'),2),metric=rep(c('m1','m2'),each=2),value=1:4)),'Extra metric must not hide duplicate dumbbell keys')
fails(pp_recipe_plot('correlation_heatmap',data.frame(metric='a',category='b',value=1.2)),'Invalid correlation rejected')
fails(pp_recipe_plot('gsea_running_score',data.frame(rank=1.5,running_score=.1)),'Fractional gene rank rejected')
fails(pp_recipe_plot('lollipop_ranked',data.frame(category='a',value=1),list(statistical_result=list(method='upstream',n=3,pvalue=1.2))),'Invalid upstream statistics rejected')

raw <- data.frame(subject=letters[1:4],group='A',value=1:4)
s <- pp_summary_statistics(raw,method='mean',interval='se',unit_id='subject')
check(abs(s$estimate-2.5)<1e-10 && s$n==4,'Explicit mean and n')
check(abs((s$upper-s$estimate)-stats::sd(1:4)/2)<1e-10,'Explicit SE')
fails(pp_summary_statistics(raw,method='mean',interval='se'),'Independent unit required')
check(is.finite(pp_statistical_test(data.frame(x=1:10,y=(1:10)^2),method='pearson',x='x',y='y')$pvalue),'Explicit correlation')
fails(pp_statistical_test(data.frame(x=1:2,y=1:2),method='lm',x='x',y='y'),'Undefined regression uncertainty rejected')
fails(pp_recipe_plot('scatter_regression',data.frame(x=1:2,y=1:2,group='a'),list(fit='lm')),'Cannot silently omit an unavailable confidence band')
ordered <- data.frame(value=c(4,5,7,1,2,4),group=factor(rep(c('treated','control'),each=3),levels=c('control','treated')))
ordered_test <- pp_statistical_test(ordered,method='welch_t')
check(identical(unlist(ordered_test$group_order),c('control','treated')) && ordered_test$estimate[[1]]<ordered_test$estimate[[2]],'Declared contrast order governs result direction')
effect_data <- data.frame(group=rep(c('a','b'),each=4),value=c(1,2,3,4,1,10,20,30))
effect <- pp_effect_size(effect_data,'group','value',method='mean_difference')
expected <- stats::t.test(effect_data$value[1:4],effect_data$value[5:8])$conf.int
check(isTRUE(all.equal(unname(c(effect$ci_low,effect$ci_high)),as.numeric(expected))),'Welch interval includes uncertainty from both groups')
check(pp_model_metrics(1:3,3:5)$r_squared == -5,'R-squared is not squared correlation and is not clipped')
check(pp_model_metrics(1:3,3:5)$interval == 'not supplied','No invented model interval')

# Every catalog ID routes deterministically; a core-only developer run reports
# specialized cases as skipped and is not full catalog acceptance.
core_only <- '--core' %in% commandArgs(TRUE)
catalog <- pp_recipe_manifest()
check(nrow(catalog)==84 && !anyDuplicated(catalog$recipe_id),'84 unique stable recipe IDs')
special <- c('complex_heatmap','sets','network','flow','circos','spatial','tree')
passed <- character(); skipped <- character(); broken <- character()
for(id in catalog$recipe_id) {
  entry <- pp_recipe_entry(id)
  dependencies <- strsplit(entry$backend,';',fixed=TRUE)[[1]]
  if(core_only && (entry$handler%in%special || any(!vapply(dependencies,requireNamespace,logical(1),quietly=TRUE)))) {
    skipped <- c(skipped,id); next
  }
  result <- tryCatch({
    data <- pp_recipe_mock_data(id)
    required <- strsplit(entry$required_roles,';',fixed=TRUE)[[1]]
    parameters <- attr(data,'pp_demo_params')
    conditional <- intersect(parameters$unit_id %||% character(),names(data))
    if(entry$handler=='bar' && identical(parameters$data_kind,'summary')) conditional <- c(conditional,'error')
    minimal <- data[unique(c(required,conditional))]
    attr(minimal,'pp_demo') <- TRUE; attr(minimal,'pp_demo_params') <- parameters
    minimal_plot <- pp_recipe_plot(id,minimal,mode='demo')
    minimal_device <- tempfile(fileext='.pdf');grDevices::cairo_pdf(minimal_device,width=7,height=5)
    if(inherits(minimal_plot,'patchwork')) patchwork::patchworkGrob(minimal_plot) else if(inherits(minimal_plot,'ggplot')) ggplot2::ggplotGrob(minimal_plot) else grid::grid.draw(minimal_plot)
    grDevices::dev.off();unlink(minimal_device)
    malformed <- minimal; malformed[[required[[1]]]] <- NULL
    fails(pp_recipe_plot(id,malformed,mode='demo'),paste(id,'missing required field must fail'))
    p <- pp_recipe_plot(id,data,mode='demo')
    device <- tempfile(fileext='.pdf')
    grDevices::cairo_pdf(device,width=7,height=5)
    if(inherits(p,'ggplot')) {
      if(inherits(p,'patchwork')) patchwork::patchworkGrob(p) else ggplot2::ggplotGrob(p)
    } else check(grid::is.grob(p),'Vector output required')
    grDevices::dev.off(); unlink(device)
    TRUE
  },error=function(e) conditionMessage(e))
  if(isTRUE(result)) passed <- c(passed,id) else broken <- c(broken,paste(id,result,sep=': '))
}
cat('Recipe builds:',length(passed),'passed;',length(skipped),'skipped;',length(broken),'failed\n')
if(length(broken)) stop(paste(broken,collapse='\n'),call.=FALSE)
cat('Scientific contract regressions passed.\n')
