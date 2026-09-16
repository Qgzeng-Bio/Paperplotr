#!/usr/bin/env Rscript
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
check <- function(x,label) if(!isTRUE(x)) stop(label,call.=FALSE)
fails <- function(expr,label) check(inherits(tryCatch(force(expr),error=identity),'error'),label)

# Science regressions: values are supplied, not filled in by the plot engine.
d <- data.frame(pc1=1:8,pc2=sin(1:8),group='A',stress=.42)
p <- pp_recipe_plot('nmds_stress_ordination',d)
check(identical(p$layers[[2]]$aes_params$label,'Stress = 0.42'),'Real stress propagated')
check(!grepl('%',pp_recipe_plot('pca_pcoa_ordination',d)$labels$x),'No invented variance')
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

raw <- data.frame(subject=letters[1:4],group='A',value=1:4)
s <- pp_summary_statistics(raw,method='mean',interval='se',unit_id='subject')
check(abs(s$estimate-2.5)<1e-10 && s$n==4,'Explicit mean and n')
check(abs((s$upper-s$estimate)-stats::sd(1:4)/2)<1e-10,'Explicit SE')
fails(pp_summary_statistics(raw,method='mean',interval='se'),'Independent unit required')
check(is.finite(pp_statistical_test(data.frame(x=1:10,y=(1:10)^2),method='pearson',x='x',y='y')$pvalue),'Explicit correlation')

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
    p <- pp_recipe_plot(id,data,mode='demo')
    if(inherits(p,'ggplot')) {
      if(inherits(p,'patchwork')) patchwork::patchworkGrob(p) else ggplot2::ggplotGrob(p)
    } else check(grid::is.grob(p),'Vector output required')
    TRUE
  },error=function(e) conditionMessage(e))
  if(isTRUE(result)) passed <- c(passed,id) else broken <- c(broken,paste(id,result,sep=': '))
}
cat('Recipe builds:',length(passed),'passed;',length(skipped),'skipped;',length(broken),'failed\n')
if(length(broken)) stop(paste(broken,collapse='\n'),call.=FALSE)
cat('Scientific contract regressions passed.\n')
