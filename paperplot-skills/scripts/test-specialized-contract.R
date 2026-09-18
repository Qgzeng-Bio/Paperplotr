#!/usr/bin/env Rscript
source('paperplot-skills/scripts/paperplot_helpers.R')
source('paperplot-skills/recipes/paperplot_code_recipes.R')
check <- function(x,label) if(!isTRUE(x)) stop(label)
fails <- function(x,label) check(inherits(tryCatch(force(x),error=identity),'error'),label)
spec <- pp_render_spec(mode='demo')
demo <- function(id) {d<-pp_recipe_mock_data(id);list(d=d,p=attr(d,'pp_demo_params'))}
v <- demo('heatmap_cluster_reference');v$p$distance <- NULL
fails(pp_recipe_plot('heatmap_cluster_reference',v$d,v$p,mode='production'),'Demo cannot bypass the direct entry')
v <- demo('annotated_heatmap');v$p$annotations <- data.frame(group='wrong',row.names='not-a-row')
fails(pp_recipe_plot('annotated_heatmap',v$d,v$p,mode='demo'),'ComplexHeatmap rejects unmatched annotations')
v <- demo('upset_summary');v$d$present[1]<-2
fails(pp_recipe_plot('upset_summary',v$d,mode='demo'),'UpSet preserves binary membership')
v <- demo('network_edge_list_reference');v$d$weight[1]<- -1
fails(pp_recipe_plot('network_edge_list_reference',v$d,mode='demo'),'Network rejects negative strength')
v <- demo('chord_adjacency_reference');v$d$weight[1]<- -1
fails(pp_recipe_plot('chord_adjacency_reference',v$d,mode='demo'),'Chord rejects negative flow')
v <- demo('circos_ring_reference');v$d$end[1]<-1001
fails(pp_recipe_plot('circos_ring_reference',v$d,mode='demo'),'Circos interval bounds')
v <- demo('spatial_tile_map_reference');v$p$crs<-3857
fails(pp_recipe_plot('spatial_tile_map_reference',v$d,v$p,mode='demo'),'sf CRS mismatch is not silently reprojected')
v <- demo('spatial_point_map_reference');v$d$latitude[1]<-91
fails(pp_recipe_plot('spatial_point_map_reference',v$d,mode='demo'),'Invalid geographic latitude rejected')
v <- demo('phylo_tree_segments_reference');v$d$parent[3]<-'unknown'
fails(pp_recipe_plot('phylo_tree_segments_reference',v$d,mode='demo'),'Tree rejects invented or disconnected ancestors')
v <- demo('phylo_tree_segments_reference');p <- pp_recipe_plot('phylo_tree_segments_reference',v$d,mode='demo')
check(setequal(as.character(p$data$label[p$data$isTip]),c('a','b','c')),'Tree tip identities retained')
check(isTRUE(all.equal(sort(p$data$branch.length[-which(p$data$node==p$data$parent)]),sort(c(.2,.3,.4,.5)),check.attributes=FALSE)),'Tree branch lengths retained')
flow <- data.frame(flow_id=rep(c('f1','f2'),each=2),stage=rep(c('before','middle'),2),source=c('A','B','C','D'),target=c('B','C','D','E'),weight=c(2,2,3,3))
params<-list(stage_order=c('before','middle','after'))
p<-pp_recipe_plot('sankey_flow_reference',flow,params)
check(nrow(p$data)==6 && sum(p$data$weight[p$data$stage=='before'])==5,'Multi-stage real flows retained')
flow$weight[2]<-4
fails(pp_recipe_plot('sankey_flow_reference',flow,params),'Flow conservation is explicit')
cat('All specialized-backend positive/negative contracts passed.\n')
