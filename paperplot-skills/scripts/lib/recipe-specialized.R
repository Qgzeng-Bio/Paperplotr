# Specialized vector backends. Every backend consumes the supplied structures.
pp_demo_vector <- function(grob,spec) grid::grobTree(grob,grid::textGrob('DEMO / simulated test data',x=.99,y=.99,hjust=1,vjust=1,
  gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$caption,col='#555555')))
pp_capture_vector <- function(draw, spec) {
  pp_require_backend('svglite')
  device <- function(width,height) svglite::svglite(file=tempfile(fileext='.svg'),width=width,height=height)
  # grid.grabExpr opens an isolated device: dimensions belong to this render.
  grid::grid.grabExpr(draw(),wrap=FALSE,width=spec$width_mm/25.4,height=spec$height_mm/25.4,device=device)
}

pp_recipe_specialized <- function(entry,d,params,spec) {
  d <- pp_validate_recipe_input(entry$recipe_id,d,params,spec$mode)
  switch(entry$handler,
    complex_heatmap = {
      pp_require_backend(c('ComplexHeatmap','circlize'))
      if(nlevels(droplevels(d$group))>1 && anyDuplicated(d[c('metric','category')])) stop('Complex heatmap requires unique cells; facet/group matrices explicitly before assembly.')
      rows <- levels(droplevels(d$metric)); cols <- levels(droplevels(d$category))
      mat <- matrix(NA_real_,length(rows),length(cols),dimnames=list(rows,cols))
      mat[cbind(match(d$metric,rows),match(d$category,cols))] <- d$value
      clustering <- entry$variant=='cluster'
      if(clustering && (is.null(params$distance) || is.null(params$linkage)) && (is.null(params$row_dendrogram)||is.null(params$column_dendrogram))) stop('Declare distance and linkage for heatmap clustering, or provide upstream row and column dendrograms.')
      annotations <- params$annotations
      axis <- params$annotation_axis %||% 'row'
      if(!axis%in%c('row','column')) stop('annotation_axis must be row or column.')
      annotation_ids <- if(axis=='row') rows else cols
      if(entry$variant=='annotation' && is.null(annotations)) {
        field <- if(axis=='row') 'metric' else 'category'
        map <- unique(d[c(field,'group')]); pp_assert_unique(map,field,'heatmap annotations')
        annotations <- data.frame(group=as.character(map$group[match(annotation_ids,map[[field]])]),row.names=annotation_ids)
      }
      if(!is.null(annotations) && !setequal(rownames(annotations),annotation_ids)) stop('Annotation row names must match the declared matrix axis IDs.')
      annotation_colors <- if(!is.null(annotations)) lapply(annotations,function(values) {
        if(is.numeric(values)) {
          bounds<-range(values,na.rm=TRUE);if(any(!is.finite(bounds))) stop('Annotation values need a finite scale.')
          if(diff(bounds)==0) bounds<-bounds+c(-.5,.5)
          circlize::colorRamp2(seq(bounds[1],bounds[2],length.out=5),pp_gradient_palette(5))
        } else pp_group_colors(sort(unique(as.character(values[!is.na(values)]))))
      }) else NULL
      bounds <- params$value_limits %||% range(mat,na.rm=TRUE)
      if(any(!is.finite(bounds))) stop('Heatmap needs at least one finite value.')
      if(diff(bounds)==0) bounds <- bounds+c(-.5,.5)
      palette <- circlize::colorRamp2(seq(bounds[1],bounds[2],length.out=5),pp_gradient_palette(5))
      heat <- ComplexHeatmap::Heatmap(mat,name=params$value_label %||% 'Value',col=palette,
        cluster_rows=if(!is.null(params$row_dendrogram)) params$row_dendrogram else clustering,
        cluster_columns=if(!is.null(params$column_dendrogram)) params$column_dendrogram else clustering,
        clustering_distance_rows=params$distance %||% 'euclidean',clustering_distance_columns=params$distance %||% 'euclidean',
        clustering_method_rows=params$linkage %||% 'complete',clustering_method_columns=params$linkage %||% 'complete',
        top_annotation=if(!is.null(annotations)&&axis=='column') ComplexHeatmap::HeatmapAnnotation(df=annotations[cols,,drop=FALSE],col=annotation_colors,annotation_name_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend),annotation_legend_param=list(title_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend,fontface='plain'),labels_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend))) else NULL,
        left_annotation=if(!is.null(annotations)&&axis=='row') ComplexHeatmap::rowAnnotation(df=annotations[rows,,drop=FALSE],col=annotation_colors,annotation_name_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend),annotation_legend_param=list(title_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend,fontface='plain'),labels_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend))) else NULL,
        row_names_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$tick),
        column_names_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$tick),
        heatmap_legend_param=list(title_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend),labels_gp=grid::gpar(fontfamily=spec$family,fontsize=spec$text_pt$legend)),
        use_raster=FALSE,na_col='#DDDDDD')
      pp_capture_vector(function() ComplexHeatmap::draw(heat),spec)
    },
    sets = {
      sets <- levels(droplevels(d$set)); items <- unique(as.character(d$item))
      mat <- matrix(FALSE,length(items),length(sets),dimnames=list(items,sets))
      mat[cbind(match(d$item,items),match(d$set,sets))] <- as.logical(d$present)
      wide <- as.data.frame(mat,check.names=FALSE)
      if(entry$variant=='upset') {
        pp_require_backend('ComplexUpset')
        ComplexUpset::upset(wide,intersect=sets,name='Intersection',min_size=1,sort_sets=FALSE,
          base_annotations=list('Intersection size'=ComplexUpset::intersection_size(counts=TRUE)))
      } else {
        pp_require_backend('patchwork')
        sizes <- data.frame(set=factor(sets,levels=sets),n=colSums(mat))
        bar <- ggplot2::ggplot(sizes,ggplot2::aes(set,n))+ggplot2::geom_col(fill='#4E79A7')+pp_theme()
        dots <- ggplot2::ggplot(d,ggplot2::aes(set,item,alpha=as.logical(present)))+ggplot2::geom_point()+
          ggplot2::scale_alpha_manual(values=c('FALSE'=.12,'TRUE'=1),guide='none')+pp_theme()
        patchwork::wrap_plots(list(bar,dots),ncol=1,heights=c(1,3))
      }
    },
    network = {
      pp_require_backend(c('igraph','ggraph'))
      if(!is.logical(params$directed)||length(params$directed)!=1L||is.na(params$directed)) stop('Declare network directed=TRUE/FALSE; arrow meaning cannot be guessed.')
      edges <- data.frame(from=as.character(d$source),to=as.character(d$target),weight=d$weight)
      vertices <- params$nodes
      if(!is.null(vertices) && (!'name'%in%names(vertices)||anyDuplicated(vertices$name))) stop('Node table requires unique name IDs.')
      graph <- igraph::graph_from_data_frame(edges,directed=isTRUE(params$directed),vertices=vertices)
      old <- if(exists('.Random.seed',.GlobalEnv,inherits=FALSE)) get('.Random.seed',.GlobalEnv) else NULL
      on.exit(if(!is.null(old)) assign('.Random.seed',old,.GlobalEnv) else if(exists('.Random.seed',.GlobalEnv,inherits=FALSE)) rm('.Random.seed',envir=.GlobalEnv),add=TRUE)
      set.seed(params$seed %||% 104729L)
      ggraph::ggraph(graph,layout=params$layout %||% 'fr')+
        ggraph::geom_edge_link(ggplot2::aes(width=weight),alpha=.55,
          arrow=if(isTRUE(params$directed)) grid::arrow(length=grid::unit(1.5,'mm')) else NULL)+
        ggraph::geom_node_point(size=pp_point_size('emphasis'),colour='#4E79A7')+
        ggraph::geom_node_text(ggplot2::aes(label=name),repel=TRUE,max.overlaps=Inf,seed=104729L,family=spec$family,size=spec$text_pt$annotation/ggplot2::.pt)+
        ggraph::scale_edge_width(range=c(.2,1.2))+ggplot2::theme_void(base_family=spec$family)
    },
    flow = {
      variant <- if(entry$variant=='choose') params$variant else entry$variant
      if(is.null(variant)||!variant%in%c('sankey','chord')) stop('Declare variant=sankey or chord for this multi-family legacy recipe.')
      value <- if('weight'%in%names(d)) d$weight else d$value
      if(any(value<0)) stop('Flow magnitudes must be nonnegative.')
      edges <- data.frame(source=as.character(d$source),target=as.character(d$target),weight=value)
      if(variant=='sankey') {
        pp_require_backend('ggalluvial')
        if('stage'%in%names(d)) {
          stages <- params$stage_order
          if(is.null(stages)||length(stages)<2||anyDuplicated(stages)||!'flow_id'%in%names(d)) stop('Multi-stage Sankey requires stage_order and complete flow_id trajectories; stage identifies the source stage.')
          if(!setequal(as.character(unique(d$stage)),head(stages,-1))) stop('Sankey stage columns must match all declared source stages.')
          pp_assert_unique(d,c('flow_id','stage'),'flow-stage observations')
          trajectories <- lapply(split(seq_len(nrow(d)),d$flow_id),function(index) {
            z <- d[index,,drop=FALSE];z$.weight<-value[index]
            if(!setequal(as.character(z$stage),head(stages,-1))) stop('Incomplete Sankey trajectory; no missing stage was invented.')
            z <- z[match(head(stages,-1),z$stage),,drop=FALSE]
            if(length(unique(z$.weight))!=1L || any(head(as.character(z$target),-1)!=tail(as.character(z$source),-1))) stop('Sankey flow weights or intermediate nodes do not conserve the declared trajectory.')
            data.frame(stage=factor(stages,levels=stages),node=c(as.character(z$source),tail(as.character(z$target),1)),weight=z$.weight[1],flow_id=as.character(z$flow_id[1]))
          })
          long <- do.call(rbind,trajectories)
          q <- ggplot2::ggplot(long,ggplot2::aes(x=stage,stratum=node,alluvium=flow_id,y=weight))+
            ggalluvial::geom_alluvium(fill='#4E79A7',alpha=.55,width=.18)+
            ggalluvial::geom_stratum(width=.18,fill='#DDDDDD')+
            ggalluvial::stat_stratum(geom='text',ggplot2::aes(label=ggplot2::after_stat(stratum)),size=pp_text_size('minimum'))+pp_theme()
          q
        } else ggplot2::ggplot(edges,ggplot2::aes(axis1=source,axis2=target,y=weight))+
          ggalluvial::geom_alluvium(ggplot2::aes(fill=source),alpha=.65,width=.18)+
          ggalluvial::geom_stratum(width=.18,fill='#DDDDDD')+
          ggalluvial::stat_stratum(geom='text',ggplot2::aes(label=ggplot2::after_stat(stratum)),size=pp_text_size('minimum'))+
          ggplot2::scale_x_discrete(limits=params$stage_order %||% c('Source','Target'),expand=c(.1,.1))+pp_theme()
      } else {
        pp_require_backend(c('circlize','gridGraphics'))
        if(is.null(params$directed)) stop('Declare directed for chord connections.')
        pp_capture_vector(function() gridGraphics::grid.echo(function() {
          old <- graphics::par(family=spec$family,ps=12,mar=c(1,1,1,1)); on.exit(graphics::par(old))
          circlize::circos.clear(); on.exit(circlize::circos.clear(),add=TRUE)
          circlize::chordDiagram(edges,directional=as.integer(isTRUE(params$directed)),annotationTrack='grid',grid.col=pp_group_colors(unique(c(edges$source,edges$target))),
            preAllocateTracks=list(track.height=.12))
          circlize::circos.trackPlotRegion(track.index=1,panel.fun=function(x,y) {
            sector <- circlize::get.cell.meta.data('sector.index'); xl <- circlize::get.cell.meta.data('xlim')
            circlize::circos.text(mean(xl),.5,sector,cex=spec$text_pt$annotation/12,facing='clockwise',niceFacing=TRUE)
          },bg.border=NA)
        },newpage=FALSE),spec)
      }
    },
    circos = {
      pp_require_backend(c('circlize','gridGraphics'))
      lengths <- params$chromosome_lengths
      chr <- unique(as.character(d$chr))
      if(is.null(lengths)||is.null(names(lengths))||!all(chr%in%names(lengths))) stop('Circos requires named chromosome_lengths; sector bounds cannot be invented.')
      if(any(d$end>lengths[as.character(d$chr)])) stop('Circos intervals exceed chromosome lengths.')
      pp_capture_vector(function() gridGraphics::grid.echo(function() {
        old <- graphics::par(family=spec$family,ps=12,mar=c(1,1,1,1)); on.exit(graphics::par(old))
        circlize::circos.clear(); on.exit(circlize::circos.clear(),add=TRUE)
        circlize::circos.par(cell.padding=c(.02,0,.02,0))
        circlize::circos.initialize(chr,xlim=cbind(0,lengths[chr]))
        circlize::circos.trackPlotRegion(ylim=c(0,1),track.height=.1,bg.border=NA,panel.fun=function(x,y) {
          sector <- circlize::get.cell.meta.data('sector.index'); xl <- circlize::get.cell.meta.data('xlim')
          circlize::circos.text(mean(xl),.5,sector,cex=spec$text_pt$annotation/12,facing='clockwise',niceFacing=TRUE)
        })
        tracks <- if('track'%in%names(d)) unique(d$track) else 'All'
        for(track in tracks) {
          rows <- if('track'%in%names(d)) d[d$track==track,,drop=FALSE] else d
          limits <- range(rows$value)
          if(diff(limits)==0) limits <- limits+c(-.5,.5)
          circlize::circos.trackPlotRegion(factors=rows$chr,x=(rows$start+rows$end)/2,y=rows$value,ylim=limits,
            panel.fun=function(x,y) {
              circlize::circos.points(x,y,pch=16,cex=.35,col='#4E79A7')
              xl <- circlize::get.cell.meta.data('xlim')
              ticks <- pretty(xl,n=2);ticks<-ticks[ticks>=xl[1]&ticks<=xl[2]]
              if(diff(xl)>max(lengths)/5) circlize::circos.axis(h='top',major.at=ticks,labels=format(ticks/1e6,trim=TRUE),labels.cex=spec$text_pt$tick/12)
            })
        }
        graphics::text(0,0,paste0(params$value_label %||% 'Value','\n',paste(signif(range(d$value),3),collapse=' to '),'\nPosition (Mb)'),cex=spec$text_pt$annotation/12)
      },newpage=FALSE),spec)
    },
    spatial = {
      pp_require_backend('sf')
      if(is.null(params$crs)) stop('Declare the input CRS; coordinate units cannot be inferred.')
      if(entry$variant=='polygon') {
        geometry <- params$geometry %||% attr(d,'pp_geometry')
        if(is.null(geometry)||!inherits(geometry,'sf')||!'region'%in%names(geometry)) stop('Polygon mapping requires sf geometry with a region key.')
        pp_assert_unique(d,'region','map values'); pp_assert_unique(geometry,'region','map features')
        if(!all(d$region%in%geometry$region)) stop('Map values contain unmatched region keys.')
        shape <- geometry[match(d$region,geometry$region),,drop=FALSE]; shape$value <- d$value
        if(is.na(sf::st_crs(shape))) stop('Geometry CRS missing; set it explicitly upstream.')
        if(sf::st_crs(shape)!=sf::st_crs(params$crs)) stop('Declared CRS conflicts with geometry; no reprojection was guessed.')
        if(!all(sf::st_is_valid(shape))) stop('Invalid spatial geometry; repair upstream with an explicit record.')
        ggplot2::ggplot(shape)+ggplot2::geom_sf(ggplot2::aes(fill=value),linewidth=.15)+ggplot2::scale_fill_gradientn(colours=pp_gradient_palette())+
          ggplot2::coord_sf(datum=sf::st_crs(params$crs))+ggplot2::scale_x_continuous(labels=function(x) format(x,trim=TRUE))+ggplot2::scale_y_continuous(labels=function(x) format(x,trim=TRUE))+
          ggplot2::labs(x=paste0('X (',sf::st_crs(params$crs)$units_gdal,')'),y=paste0('Y (',sf::st_crs(params$crs)$units_gdal,')'))+pp_theme()
      } else {
        if(isTRUE(sf::st_is_longlat(sf::st_crs(params$crs))) && any(d$latitude< -90|d$latitude>90|d$longitude< -180|d$longitude>180)) stop('Geographic coordinates exceed longitude [-180,180] / latitude [-90,90]; declare and transform alternate conventions upstream.')
        shape <- sf::st_as_sf(d,coords=c('longitude','latitude'),crs=params$crs,remove=FALSE)
        ggplot2::ggplot(shape)+ggplot2::geom_sf(ggplot2::aes(colour=value),size=pp_point_size('normal'))+
          ggplot2::scale_colour_gradientn(colours=pp_gradient_palette())+ggplot2::coord_sf(datum=sf::st_crs(params$crs))+
          ggplot2::scale_x_continuous(labels=function(x) format(x,trim=TRUE))+ggplot2::scale_y_continuous(labels=function(x) format(x,trim=TRUE))+
          ggplot2::labs(x=paste0('X (',sf::st_crs(params$crs)$units_gdal,')'),y=paste0('Y (',sf::st_crs(params$crs)$units_gdal,')'))+pp_theme()
      }
    },
    tree = {
      pp_require_backend(c('ape','ggtree','treeio'))
      tree <- params$tree
      if(is.null(tree)) {
        pp_assert_unique(d,'node','tree nodes')
        ids <- as.character(d$node); parent <- as.character(d$parent)
        root <- ids[is.na(parent)|!nzchar(parent)]
        if(length(root)!=1 || any(!is.na(parent)&nzchar(parent)&!parent%in%ids)) stop('Tree requires one root and valid parent IDs.')
        visited <- character()
        emit <- function(id,ancestors=character()) {
          if(id%in%ancestors) stop('Cycle in supplied tree.')
          visited <<- c(visited,id)
          kids <- ids[which(parent==id)]
          label <- paste0("'",gsub("'","''",id,fixed=TRUE),"'")
          text <- paste0(if(length(kids)) paste0('(',paste(vapply(kids,emit,character(1),ancestors=c(ancestors,id)),collapse=','),')') else '',label)
          if(id!=root) text <- paste0(text,':',if('branch_length'%in%names(d)) d$branch_length[match(id,ids)] else 1)
          text
        }
        newick <- paste0(emit(root),';')
        if(!setequal(visited,ids)) stop('Disconnected nodes in supplied tree.')
        tree <- ape::read.tree(text=newick)
        # ape preserves the quoting of Newick labels. Restore the original IDs
        # after parsing, not inferred species names or substituted labels.
        unquote <- function(x) gsub("''","'",sub("'$","",sub("^'","",x)),fixed=TRUE)
        tree$tip.label <- unquote(tree$tip.label)
        if(!is.null(tree$node.label)) tree$node.label <- unquote(tree$node.label)
      }
      if(!inherits(tree,'phylo')) stop('Provide an ape phylo tree or a valid node/parent table.')
      if(!all(tree$tip.label%in%as.character(d$node))) stop('Tree tips missing from the annotation table.')
      q <- ggtree::ggtree(tree,layout=if(entry$variant=='circular') 'circular' else 'rectangular',
        branch.length=if(is.null(params$tree)&&!'branch_length'%in%names(d)) 'none' else 'branch.length')+
        ggtree::geom_tiplab(size=spec$text_pt$species/ggplot2::.pt,family=spec$family)
      if(entry$variant%in%c('annotation','circular')) {
        annotations <- d[match(tree$tip.label,d$node),,drop=FALSE]
        values <- if(entry$variant=='circular') annotations['value'] else data.frame(group=as.character(annotations$group))
        rownames(values) <- tree$tip.label
        depth <- max(q$data$x,na.rm=TRUE)
        label_mm <- max(nchar(tree$tip.label))*spec$text_pt$species*25.4/72*.55
        available_mm <- if(entry$variant=='circular') min(spec$width_mm,spec$height_mm)/2-15 else spec$width_mm*.65
        gap <- params$annotation_gap %||% depth*label_mm/max(available_mm-label_mm,available_mm*.2)
        q <- ggtree::gheatmap(q,values,offset=gap,width=.12,colnames=FALSE,font.size=spec$text_pt$legend/ggplot2::.pt)
        if(entry$variant=='circular') q <- q+ggplot2::scale_fill_gradientn(colours=pp_gradient_palette(),name=params$annotation_label %||% 'Value')
      }
      q
    },
    stop('No specialized handler: ',entry$handler))
}
