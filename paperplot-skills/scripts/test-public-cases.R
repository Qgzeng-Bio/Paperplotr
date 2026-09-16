#!/usr/bin/env Rscript
# Upstream fixture preparation is explicit here; recipes only render its results.
# Real public cases do not substitute for the user's private IGS/main figure.
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
if(!pp_check_environment(TRUE)$production_available) stop('Full environment required; no skipped formal acceptance.')
args <- commandArgs(TRUE)
out <- if(length(args)) args[[1]] else 'visual-checks/public-cases-0.7.0'
inputs <- 'visual-checks/public-inputs'
dir.create(out,recursive=TRUE,showWarnings=FALSE)
cases <- list()
add <- function(id,recipe,data,params=list(),source,preparation) {
  cases[[id]] <<- list(recipe=recipe,data=data,params=params,source=source,preparation=preparation)
}
dataset_source <- 'https://stat.ethz.ch/R-manual/R-devel/library/datasets/html/00Index.html'
iris_data <- data.frame(sample=seq_len(nrow(iris)),group=iris$Species,category='Sepal length',value=iris$Sepal.Length,x=iris$Sepal.Length,y=iris$Petal.Length)
for(recipe in c('boxplot_jitter','violin_dot','raincloud_violin_jitter','ridgeline_density','beeswarm_box_reference','scatter_regression','scatter_marginal_reference'))
  add(recipe,recipe,iris_data,list(fit='lm',x_label=if(grepl('scatter',recipe)||recipe=='ridgeline_density') 'Sepal length (cm)' else 'Species',y_label=if(grepl('scatter',recipe)) 'Petal length (cm)' else if(recipe=='ridgeline_density') 'Species' else 'Sepal length (cm)'),dataset_source,'Iris measurements; linear regression explicitly requested only for scatter recipes.')
add('raw_summary','grouped_bar_errorbar_raw',iris_data,list(data_kind='raw',summary='mean',unit_id='sample',error_type='ci'),dataset_source,'Independent flower rows; mean and 95% t interval, not inferred statistical significance.')
hair <- as.data.frame(margin.table(HairEyeColor,c(1,2)))
flow <- data.frame(source=paste0('Hair:',hair$Hair),target=paste0('Eye:',hair$Eye),weight=hair$Freq)
add('composition','stacked_bar_fraction',data.frame(group=hair$Hair,category=hair$Eye,value=hair$Freq),list(input_scale='counts'),dataset_source,'HairEyeColor counts summed over sex, explicitly converted to conditional proportions within hair colour.')
add('sankey','sankey_flow_reference',flow,list(),dataset_source,'HairEyeColor two-stage cross-tabulation; widths are counts, not longitudinal transitions.')
add('chord','chord_adjacency_reference',flow,list(directed=FALSE),dataset_source,'HairEyeColor undirected associations, same observed cross-tabulation.')
paired <- data.frame(sample=sleep$ID,group=sleep$group,value=sleep$extra)
add('paired','paired_comparison',paired,list(group_order=c('1','2')),dataset_source,'sleep: same patient ID under two drug conditions; original order retained.')
add('dumbbell','dumbbell_comparison',transform(paired,category=as.character(sample)),list(group_order=c('1','2')),dataset_source,'sleep: one record per patient and condition; no group averaging.')
tooth <- data.frame(sample=seq_len(nrow(ToothGrowth)),group=ToothGrowth$supp,metric=as.character(ToothGrowth$dose),value=ToothGrowth$len)
effects <- pp_summary_statistics(tooth,by=c('metric','group'),method='mean',interval='ci',unit_id='sample')
add('forest','forest_grouped_effect',effects,list(interval_label='Mean tooth length (95% CI)',y_label='Dose (mg/day)'),dataset_source,'ToothGrowth: explicitly prepared group means and 95% t intervals by supplement and dose; supplied intervals preserved.')
add('rank','lollipop_ranked',data.frame(category=rownames(mtcars),value=mtcars$mpg),list(render_spec=pp_render_spec(width_mm=120,height_mm=160)),dataset_source,'mtcars measured fuel economy; sorted ranking, no composite score.')
gas <- data.frame(time=as.numeric(time(UKgas)),value=as.numeric(UKgas),group='UK gas')
add('time_series','time_series_line',gas,list(),dataset_source,'Quarterly UK gas consumption at actual time coordinates.')
pc <- stats::prcomp(iris[,1:4],scale.=TRUE)
coords <- data.frame(pc1=pc$x[,1],pc2=pc$x[,2],group=iris$Species)
add('ordination','pca_pcoa_ordination',coords,list(variant='pca',variance_percent=round(100*pc$sdev[1:2]^2/sum(pc$sdev^2),3)),dataset_source,'Upstream fixture preparation only: scaled iris PCA with prcomp; render receives coordinates and actual explained variance.')
mat <- stats::cor(iris[,1:4]); long <- as.data.frame(as.table(mat));names(long)<-c('metric','category','value')
add('matrix','correlation_heatmap',long,list(),dataset_source,'Pearson correlations explicitly computed upstream over all iris observations.')
add('complex_heatmap','heatmap_cluster_reference',long,list(distance='euclidean',linkage='complete'),dataset_source,'Iris correlation matrix; explicit Euclidean distance/complete-linkage clustering of correlation profiles.')
model <- stats::lm(mpg~wt,mtcars)
pred <- data.frame(observed=mtcars$mpg,predicted=as.numeric(fitted(model)),residual=as.numeric(residuals(model)),group='Training data')
performance <- data.frame(group='Training data',metric='RMSE',value=sqrt(mean(pred$residual^2)))
add('model','model_validation_composite',pred,list(performance=performance),dataset_source,'In-sample mtcars lm(mpg~wt), explicitly not external model validation; supplied residuals and training RMSE.')
sets <- data.frame(item=rep(rownames(mtcars),3),set=rep(c('cyl=4','mpg>=20','manual'),each=nrow(mtcars)),present=as.integer(c(mtcars$cyl==4,mtcars$mpg>=20,mtcars$am==1)))
add('sets','upset_summary',sets,list(),dataset_source,'Prespecified mtcars memberships: four cylinders, mpg>=20, manual transmission; exact intersections.')
graph <- igraph::make_graph('Zachary'); edge <- as.data.frame(igraph::as_edgelist(graph));names(edge)<-c('source','target');edge$weight<-1
add('network','network_edge_list_reference',edge,list(directed=FALSE,render_spec=pp_render_spec(width_mm=180,height_mm=120)),
  'https://r.igraph.org/reference/make_graph.html','Zachary karate-club graph; unit weight per observed undirected edge. Force layout does not encode biological distance.')
shape <- sf::st_read(system.file('shape/nc.shp',package='sf'),quiet=TRUE)
shape$region <- as.character(shape$NAME)
add('spatial','spatial_tile_map_reference',data.frame(region=shape$region,value=shape$BIR74),list(crs=sf::st_crs(shape),geometry=shape,render_spec=pp_render_spec(width_mm=180,height_mm=100)),
  'https://r-spatial.github.io/sf/articles/sf1.html','North Carolina births in 1974, original polygons and NAD27 geographic CRS; counts, not standardized risk.')
tree_env <- new.env();utils::data('bird.orders',package='ape',envir=tree_env); tree <- tree_env$bird.orders
ids <- c(tree$tip.label,paste0('internal-',seq_len(tree$Nnode)))
tree_table <- data.frame(node=ids,parent=NA_character_,group=c(rep('tip',length(tree$tip.label)),rep('internal',tree$Nnode)),value=0)
tree_table$parent[tree$edge[,2]]<-ids[tree$edge[,1]];tree_table$value[tree$edge[,2]]<-tree$edge.length
for(recipe in c('phylo_tree_segments_reference','phylo_annotation_reference','phylo_ring_annotation_reference'))
  add(recipe,recipe,tree_table,list(tree=tree,annotation_label='Terminal branch length',render_spec=pp_render_spec(width_mm=180,height_mm=150)),
    'https://rdrr.io/cran/ape/man/bird.orders.html','ape bird.orders supplied tree; annotations are topology role and actual terminal branch length, no inferred traits or topology.')
load(file.path(inputs,'CMplot/data/pig60K.rda'))
pig <- data.frame(chr=factor(pig60K$Chromosome,levels=sort(unique(pig60K$Chromosome))),position=pig60K$Position,pvalue=pig60K$trait1,feature=pig60K$SNP)
add('manhattan','manhattan_genomewide',pig,list(threshold=5e-8),
  'https://github.com/YinLiLin/CMplot','CMplot 4.5.1 pig60K trait1 MLM p-values and actual bp; chromosome extent explicitly observed maxima; user-selected 5e-8 reference threshold.')
intervals <- data.frame(chr=pig$chr,start=pig$position,end=pig$position+1,value=-log10(pig$pvalue),track='MLM trait1')
extent <- tapply(intervals$end,intervals$chr,max)
add('circos','circos_ring_reference',intervals,list(chromosome_lengths=extent,value_label='-log10(p)',render_spec=pp_render_spec(width_mm=180,height_mm=160)),
  'https://github.com/YinLiLin/CMplot','Point markers represented as 1-bp intervals; values=-log10(trait1 p); sector bounds are observed maxima, not asserted chromosome assembly lengths.')
de <- read.csv(file.path(inputs,'airway.csv'))
valid <- complete.cases(de[c('row','baseMean','log2FoldChange','padj')]) & de$baseMean>0
de_plot <- data.frame(feature=de$row[valid],base_mean=de$baseMean[valid],log2fc=de$log2FoldChange[valid],padj=de$padj[valid])
for(recipe in c('volcano_threshold','ma_plot')) add(recipe,recipe,de_plot,list(alpha=.05,effect_threshold=1,p_display_floor=1e-300),
  'https://github.com/stephenturner/deseq-to-fgsea',paste('Supplied airway DESeq2 output; explicitly excluded',sum(!valid),'rows with missing results or nonpositive abundance. padj used unchanged.'))
load(file.path(inputs,'exampleRanks.rda'));load(file.path(inputs,'examplePathways.rda'))
ranks <- sort(exampleRanks,decreasing=TRUE); universe <- names(ranks)
pathway <- names(examplePathways)[which.max(vapply(examplePathways,function(x) length(intersect(x,universe)),integer(1)))]
hits <- universe %in% examplePathways[[pathway]]
walk <- cumsum(ifelse(hits,abs(ranks)/sum(abs(ranks[hits])),-1/sum(!hits)))
add('gsea','gsea_running_score',data.frame(rank=seq_along(ranks),running_score=walk,hit=hits),list(),
  'https://bioconductor.org/packages/release/bioc/vignettes/fgsea/inst/doc/fgsea-tutorial.html',paste('Upstream fixture weighted enrichment walk, exponent 1, from actual fgsea exampleRanks and pathway',pathway,'; no NES or p-value claimed.'))
foreground <- head(universe,100)
enrichment <- do.call(rbind,lapply(names(examplePathways),function(term) {
  members <- intersect(examplePathways[[term]],universe); a<-length(intersect(members,foreground));b<-length(foreground)-a;c<-length(members)-a;d<-length(universe)-a-b-c
  data.frame(term=term,ratio=a/length(foreground),qvalue=stats::fisher.test(matrix(c(a,b,c,d),2,byrow=TRUE),alternative='greater')$p.value,count=a)
}))
enrichment$qvalue<-p.adjust(enrichment$qvalue,'BH');enrichment<-enrichment[order(enrichment$qvalue),][1:8,]
enrichment$term<-vapply(enrichment$term,function(s) paste(strwrap(s,width=38),collapse='\n'),character(1))
add('enrichment','enrichment_dotplot',enrichment,list(render_spec=pp_render_spec(width_mm=180,height_mm=150)),
  'https://github.com/alserglab/fgsea','Explicit upstream overrepresentation fixture: top 100 ranked genes, ranking universe, one-sided Fisher exact test, BH across all provided pathways; eight smallest adjusted p-values shown.')
layout_data <- rbind(transform(iris_data,metric='Petal length'),transform(iris_data,y=iris$Petal.Width,metric='Petal width'))
add('layout','multi_panel_shared_legend',layout_data,list(),dataset_source,'Two real iris measurements with identical Species legend meaning and mapping.')

selected <- Sys.getenv('PAPERPLOT_PUBLIC_CASES','')
if(nzchar(selected)) cases <- cases[intersect(names(cases),strsplit(selected,',',fixed=TRUE)[[1]])]
results <- lapply(names(cases),function(id) {
  case <- cases[[id]];cat('Public case:',id,'\n');flush.console()
  folder<-file.path(out,id);dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  saveRDS(case,file.path(folder,'input-and-provenance.rds'))
  writeLines(pp_to_json(list(source=case$source,preparation=case$preparation,input_hash=pp_content_hash(case$data),parameters=case$params[names(case$params)!='geometry'])),file.path(folder,'provenance.json'))
  tryCatch({
    plot<-pp_recipe_plot(case$recipe,case$data,case$params)
    spec<-attr(plot,'pp_render_spec');spec$ocr<-'off';spec$n_panels<-pp_infer_panel_count(plot)
    spec$panel_tags<-inherits(plot,'patchwork') && pp_recipe_entry(case$recipe)$handler%in%c('model','layout')
    spec$expected_tags<-if(spec$panel_tags) as.list(LETTERS[seq_len(spec$n_panels)]) else list()
    files<-pp_save_all_with_qa_loop(plot,file.path(folder,id),render_spec=spec,max_iterations=0,overwrite=TRUE)
    exact<-c('pdf_page_mm','svg_page_mm','png_pixels','pdf_typography','svg_typography','pdf_font_embedding','svg_editable_text')
    audit<-attr(files,'qa_export_audit')
    bad<-exact[!vapply(exact,function(k) identical(audit$checks[[k]],'pass'),logical(1))]
    bad<-unique(c(bad,names(audit$checks)[vapply(audit$checks,identical,logical(1),'fail')]))
    data.frame(case=id,recipe=case$recipe,physical_pass=!length(bad),status=attr(files,'qa_contract')$status,detail=paste(bad,collapse=','))
  },error=function(e) data.frame(case=id,recipe=case$recipe,physical_pass=FALSE,status='error',detail=conditionMessage(e)))
})
results<-do.call(rbind,results);write.csv(results,file.path(out,'validation.csv'),row.names=FALSE);print(results,row.names=FALSE)
if(!all(results$physical_pass)) stop('Public case export regressions remain.')
cat('Real public cases passed physical checks; item-level visual/source review is still required.\n')
