# Table-backed recipe implementations. Data transformations are explicit.
pp_recipe_labels <- function(p, df, label = 'label') {
  if (!label %in% names(df)) return(p)
  d <- df[!is.na(df[[label]]) & nzchar(as.character(df[[label]])),,drop=FALSE]
  if (!nrow(d)) return(p)
  pp_require_backend('ggrepel')
  p + pp_direct_labels(ggplot2::aes(label=.data[[label]]), d)
}

pp_recipe_logp <- function(x, params) {
  if (any(x == 0)) {
    floor <- params$p_display_floor
    if (is.null(floor) || length(floor)!=1 || !is.finite(floor) || floor<=0 || floor>1) stop('Zero p-values require an explicit p_display_floor; the source values are preserved.')
    return(-log10(ifelse(x==0,floor,x)))
  }
  -log10(x)
}

pp_recipe_interval <- function(df, params, by) {
  kind <- params$data_kind %||% if(all(c('estimate','lower','upper') %in% names(df))) 'summary' else NULL
  if(is.null(kind)) stop('Declare data_kind=raw or summary for an interval plot.')
  if(kind=='raw') {
    if(is.null(params$summary)) stop('Raw observations require an explicit summary (mean or median).')
    return(pp_summary_statistics(df,by=by,method=params$summary,interval=params$error_type %||% 'none',
      conf_level=params$conf_level %||% .95,unit_id=params$unit_id,na_action=params$na_action %||% 'error'))
  }
  if(kind!='summary') stop('Unknown data_kind.')
  pp_assert_unique(df,by,'supplied summaries')
  if(!'estimate' %in% names(df)) df$estimate <- df$value
  if(!all(c('lower','upper') %in% names(df))) {
    if(!'error' %in% names(df) || is.null(params$error_type)) stop('Supplied errors need error and an explicit error_type.')
    df$lower <- df$estimate-df$error; df$upper <- df$estimate+df$error
  }
  if(any(df$lower>df$estimate | df$upper<df$estimate)) stop('Invalid interval bounds.')
  df
}

pp_recipe_core <- function(entry, d, params) {
  d <- pp_validate_recipe_input(entry$recipe_id,d,params,attr(d,'pp_input_policy')$mode %||% 'production')
  variant <- entry$variant; h <- entry$handler
  p <- switch(h,
    bar = {
      s <- pp_recipe_interval(d,params,c('category','group'))
      dodge <- ggplot2::position_dodge(width=.7)
      q <- ggplot2::ggplot(s,ggplot2::aes(category,estimate,fill=group)) +
        ggplot2::geom_col(position=dodge,width=.6) +
        ggplot2::geom_errorbar(ggplot2::aes(ymin=lower,ymax=upper),position=dodge,width=.16,linewidth=pp_line_width('interval'))
      if(variant=='raw' && identical(params$data_kind,'raw')) q <- q +
        ggplot2::geom_point(data=d,ggplot2::aes(y=value,colour=group),position=ggplot2::position_jitterdodge(jitter.width=.07,dodge.width=.7,seed=104729),size=pp_point_size('micro'))
      if(variant=='horizontal') q <- q + ggplot2::coord_flip()
      q + ggplot2::labs(y=params$y_label %||% 'Estimate',fill=NULL,colour=NULL)
    },
    composition = {
      values <- d$value
      if(params$input_scale=='counts') {
        denominator <- ave(values, interaction(d[intersect(c('group','panel'),names(d))],drop=TRUE), FUN=sum)
        d$value <- values/denominator; d$denominator <- denominator
      }
      q <- ggplot2::ggplot(d,ggplot2::aes(group,value,fill=category)) + ggplot2::geom_col(width=.6)
      if(params$input_scale %in% c('counts','fraction')) q <- q + ggplot2::scale_y_continuous(labels=function(x) paste0(x*100,'%'))
      if(params$input_scale=='percent') q <- q + ggplot2::scale_y_continuous(labels=function(x) paste0(x,'%'))
      if(variant=='labels') q <- q + ggplot2::geom_text(ggplot2::aes(label=if('label'%in%names(d)) label else signif(value,3)),position=ggplot2::position_stack(vjust=.5),size=pp_text_size('minimum'))
      q + ggplot2::labs(y=if(params$input_scale=='signed') 'Signed contribution' else 'Composition',fill=NULL)
    },
    distribution = {
      if(variant=='ridge') {
        pp_require_backend('ggridges')
        q <- ggplot2::ggplot(d,ggplot2::aes(value,group,fill=group)) +
          ggridges::geom_density_ridges(scale=params$ridge_scale %||% .9,rel_min_height=0,bandwidth=params$bandwidth,alpha=.6)
      } else if(variant=='histogram') {
        if(is.null(params$binwidth)) stop('Histogram overlay requires an explicit binwidth shared by count and density layers.')
        q <- ggplot2::ggplot(d,ggplot2::aes(value,fill=group)) +
          ggplot2::geom_histogram(ggplot2::aes(y=ggplot2::after_stat(density)),binwidth=params$binwidth,position='identity',alpha=.3) +
          ggplot2::geom_density(alpha=.1,bw=params$bandwidth %||% 'nrd0')
      } else if(variant %in% c('raincloud','raincloud_facet')) {
        polygons <- do.call(rbind,lapply(split(d,interaction(d[c('group',if(variant=='raincloud_facet') 'metric')],drop=TRUE)),function(s) {
          if(nrow(s)<2 || stats::sd(s$value)==0) stop('Raincloud density needs at least two nonconstant observations per group.')
          den <- stats::density(s$value,bw=params$bandwidth %||% 'nrd0')
          pos <- match(as.character(s$group[1]),levels(d$group))
          data.frame(px=c(pos,pos+.4*den$y/max(den$y),pos),py=c(den$x[1],den$x,tail(den$x,1)),group=s$group[1],metric=if('metric'%in%names(s)) s$metric[1] else 'All')
        }))
        d$.position <- as.numeric(d$group)
        q <- ggplot2::ggplot(d,ggplot2::aes(.position,value,group=group,fill=group)) +
          ggplot2::geom_polygon(data=polygons,ggplot2::aes(px,py),alpha=.5) +
          ggplot2::geom_boxplot(width=.12,outlier.shape=NA,position=ggplot2::position_nudge(x=-.12)) +
          ggplot2::geom_point(ggplot2::aes(x=.position-.25),position=ggplot2::position_jitter(width=.045,height=0,seed=104729),size=pp_point_size('micro'),alpha=.7) +
          ggplot2::scale_x_continuous(breaks=seq_along(levels(d$group)),labels=levels(d$group))
      } else {
        q <- ggplot2::ggplot(d,ggplot2::aes(group,value,fill=group))
        if(variant %in% c('violin','quantile')) q <- q + ggplot2::geom_violin(alpha=.35,trim=FALSE)
        q <- q + ggplot2::geom_boxplot(width=.2,outlier.shape=NA,alpha=.6)
        if(variant=='beeswarm') {
          pp_require_backend('ggbeeswarm'); q <- q + ggbeeswarm::geom_quasirandom(size=pp_point_size('dense'))
        } else q <- q + ggplot2::geom_point(position=ggplot2::position_jitter(width=.08,height=0,seed=104729),size=pp_point_size('dense'),alpha=.65)
        if(variant=='quantile') q <- q + ggplot2::stat_summary(fun=stats::median,geom='point',size=pp_point_size('emphasis'))
      }
      if(variant %in% c('box_facet','raincloud_facet')) q <- q + ggplot2::facet_wrap(~metric,scales='free_y')
      q + ggplot2::labs(x=NULL,y=params$y_label %||% 'Value',fill=NULL) + ggplot2::theme(legend.position='none')
    },
    paired = {
      q <- ggplot2::ggplot(d,ggplot2::aes(group,value,group=sample)) + ggplot2::geom_line(colour='#999999',linewidth=pp_line_width('reference')) +
        ggplot2::geom_point(ggplot2::aes(colour=group),size=pp_point_size('normal'))
      if(variant=='facet') q <- q + ggplot2::facet_wrap(~metric,scales='free_y')
      q
    },
    scatter = {
      q <- ggplot2::ggplot(d,ggplot2::aes(x,y,colour=group))
      q <- q + if(variant=='bubble') ggplot2::geom_point(ggplot2::aes(size=count),alpha=.7) else ggplot2::geom_point(size=pp_point_size('normal'),alpha=.7)
      if(!is.null(params$fit)) {
        if(params$fit!='lm') stop('Supported explicit fit is lm; supply other fits upstream.')
        q <- q + ggplot2::geom_smooth(method='lm',formula=y~x,se=TRUE,level=params$conf_level %||% .95,linewidth=pp_line_width('interval'))
      }
      if(variant=='ribbon' && is.null(params$fit) && !all(c('lower','upper')%in%names(d))) stop('Regression ribbon needs explicit fit=lm or supplied lower/upper bounds.')
      if(variant=='ribbon' && is.null(params$fit)) q <- q + ggplot2::geom_ribbon(ggplot2::aes(ymin=lower,ymax=upper,fill=group),alpha=.15,colour=NA)
      if(variant=='labels') q <- pp_recipe_labels(q,d)
      if(variant=='rug') q <- q + ggplot2::geom_rug(alpha=.2)
      if(variant=='grid') q <- q + ggplot2::facet_wrap(~facet,scales='free')
      if(variant=='marginal') {
        pp_require_backend('patchwork')
        top <- ggplot2::ggplot(d,ggplot2::aes(x,fill=group))+ggplot2::geom_density(alpha=.3)+pp_theme()+ggplot2::theme(legend.position='none')
        right <- ggplot2::ggplot(d,ggplot2::aes(y,fill=group))+ggplot2::geom_density(alpha=.3)+ggplot2::coord_flip()+pp_theme()+ggplot2::theme(legend.position='none')
        q <- patchwork::wrap_plots(list(top,q,right),design='A#\nBC',widths=c(4,1),heights=c(1,4))
      }
      q
    },
    timeseries = {
      q <- ggplot2::ggplot(d,ggplot2::aes(time,value,colour=group,group=group))
      if(variant=='ribbon') {
        if(is.null(params$error_type)) stop('Time-series ribbon requires declared error_type; supplied errors are not assumed to be SE.')
        q <- q + ggplot2::geom_ribbon(ggplot2::aes(ymin=value-error,ymax=value+error,fill=group),alpha=.2,colour=NA)
      }
      q + ggplot2::geom_line(linewidth=pp_line_width('interval')) + ggplot2::geom_point(size=pp_point_size('normal'))
    },
    matrix = {
      if(variant=='triangle') {
        if(!setequal(as.character(d$metric),as.character(d$category))) stop('Triangular heatmap requires the same row/column variables.')
        order <- levels(d$metric); d <- d[match(d$metric,order)>=match(d$category,order),,drop=FALSE]
      }
      q <- ggplot2::ggplot(d,ggplot2::aes(category,metric))
      if(variant=='dots') q <- q + ggplot2::geom_point(ggplot2::aes(size=count,colour=value)) + ggplot2::scale_colour_gradientn(colours=pp_gradient_palette()) else
        q <- q + ggplot2::geom_tile(ggplot2::aes(fill=value)) + ggplot2::scale_fill_gradientn(colours=pp_gradient_palette(),na.value='#DDDDDD')
      if(variant=='labels') q <- q + ggplot2::geom_text(ggplot2::aes(label=ifelse(is.na(value),'NA',signif(value,3))),size=pp_text_size('minimum'))
      if(nlevels(d$group)>1) q <- q + ggplot2::facet_wrap(~group)
      q + ggplot2::labs(x=NULL,y=NULL)
    },
    ordination = {
      if(entry$recipe_id=='pca_pcoa_ordination' && (is.null(params$variant)||!params$variant%in%c('pca','pcoa'))) stop('This legacy mixed-method recipe requires variant=pca or pcoa; method is never guessed.')
      q <- ggplot2::ggplot(d,ggplot2::aes(pc1,pc2,colour=group)) + ggplot2::geom_point(size=pp_point_size('normal'))
      labels <- switch(variant,nmds=c('NMDS1','NMDS2'),umap=c('UMAP1','UMAP2'),tsne=c('t-SNE1','t-SNE2'),c('Axis 1','Axis 2'))
      if(entry$recipe_id=='pca_pcoa_ordination') labels <- paste0(if(params$variant=='pca') 'PC' else 'PCoA',1:2)
      variance <- params$variance_percent
      if(!is.null(variance)) {
        if(length(variance)!=2 || any(!is.finite(variance)|variance<0|variance>100) || sum(variance)>100+1e-6) stop('Invalid variance_percent.')
        labels <- paste0(labels,' (',variance,'%)')
      }
      q <- q + ggplot2::labs(x=labels[1],y=labels[2])
      if(variant=='ellipse') {
        if(is.null(params$ellipse_level)) stop('Explicit ellipse_level required; no inferential region is guessed.')
        q <- q + ggplot2::stat_ellipse(level=params$ellipse_level)
      }
      metric <- if(variant=='nmds') 'stress' else if(variant=='permanova') 'permanova_p' else NULL
      value <- if(!is.null(metric)) pp_recipe_scalar(d,params,metric) else NULL
      if(!is.null(value)) {
        if(!is.numeric(value) || length(value)!=1 || !is.finite(value) || value<0 || (metric=='permanova_p'&&value>1)) stop('Invalid supplied ordination statistic.')
        q <- q + ggplot2::annotate('text',x=Inf,y=Inf,hjust=1.05,vjust=1.2,label=paste(if(metric=='stress') 'Stress =' else 'PERMANOVA p =',value),size=pp_text_size('label'))
      }
      if(variant=='marginal') {
        pp_require_backend('patchwork')
        top <- ggplot2::ggplot(d,ggplot2::aes(pc1,group,fill=group))+ggplot2::geom_boxplot()+pp_theme()+ggplot2::theme(legend.position='none')
        right <- ggplot2::ggplot(d,ggplot2::aes(group,pc2,fill=group))+ggplot2::geom_boxplot()+pp_theme()+ggplot2::theme(legend.position='none')
        q <- patchwork::wrap_plots(list(top,q,right),design='A#\nBC',widths=c(4,1),heights=c(1,4))
      }
      q
    },
    differential = {
      alpha <- params$alpha; effect <- params$effect_threshold
      if(is.null(alpha) || is.null(effect) || length(alpha)!=1 || alpha<=0 || alpha>1 || length(effect)!=1 || effect<0) stop('Declare alpha and nonnegative effect_threshold explicitly.')
      d$.class <- ifelse(d$padj<=alpha & d$log2fc>=effect,'Up',ifelse(d$padj<=alpha & d$log2fc<=-effect,'Down','NS'))
      is_ma <- variant %in% c('ma','ma_density')
      if(is_ma && any(d$base_mean<=0)) stop('MA log abundance requires positive base_mean; no offset was invented.')
      d$.x <- if(is_ma) log10(d$base_mean) else d$log2fc
      d$.y <- if(is_ma) d$log2fc else pp_recipe_logp(d$padj,params)
      q <- ggplot2::ggplot(d,ggplot2::aes(.x,.y,colour=.class)) + ggplot2::geom_point(size=pp_point_size('dense'),alpha=.55) +
        ggplot2::scale_colour_manual(values=c(Up='#C95A4E',Down='#4E79A7',NS='#B8B8B2'))
      if(is_ma) q <- q + ggplot2::geom_hline(yintercept=c(-effect,effect),linetype='dashed') else
        q <- q + ggplot2::geom_vline(xintercept=c(-effect,effect),linetype='dashed') + ggplot2::geom_hline(yintercept=-log10(alpha),linetype='dashed')
      if(variant=='ma_density') q <- q + ggplot2::geom_density_2d(colour='#555555',linewidth=.2)
      if(variant=='facet') q <- q + ggplot2::facet_wrap(~group)
      if(variant=='labels') q <- pp_recipe_labels(q,d,'label')
      q + ggplot2::labs(x=if(is_ma) 'log10 abundance' else 'log2 fold change',y=if(is_ma) 'log2 fold change' else '-log10 adjusted p-value',colour='Class')
    },
    enrichment = {
      if(!is.null(params$top_n)) d <- d[order(d$qvalue),,drop=FALSE][seq_len(min(nrow(d),params$top_n)),,drop=FALSE]
      d$term <- factor(d$term,levels=rev(unique(d$term)))
      q <- ggplot2::ggplot(d,ggplot2::aes(ratio,term))
      if(variant=='lollipop') q <- q + ggplot2::geom_segment(ggplot2::aes(x=0,xend=ratio,yend=term),colour='#AAAAAA')
      if(variant=='bar_dot') q <- q + ggplot2::geom_col(ggplot2::aes(fill=qvalue),width=.6,alpha=.3,orientation='y')
      q <- q + ggplot2::geom_point(ggplot2::aes(size=count,colour=qvalue)) + ggplot2::scale_colour_gradientn(colours=rev(pp_gradient_palette()))
      if(nlevels(d$group)>1 || nlevels(d$category)>1) q <- q + ggplot2::facet_wrap(~group+category,scales='free_y')
      q + ggplot2::labs(x='Gene ratio',y=NULL,colour='q-value',size='Count')
    },
    gsea = {
      pp_assert_unique(d,c('rank','pathway'),'running score observations')
      d <- d[order(d$rank),,drop=FALSE]
      q <- ggplot2::ggplot(d,ggplot2::aes(rank,running_score))+ggplot2::geom_hline(yintercept=0,colour='#BBBBBB')+ggplot2::geom_line(colour='#4E79A7')
      if('pathway'%in%names(d)) q <- q + ggplot2::facet_wrap(~pathway)
      if('hit'%in%names(d)) q <- q + ggplot2::geom_rug(data=d[as.logical(d$hit),,drop=FALSE],sides='b')
      q
    },
    forest = {
      key <- interaction(d[intersect(c('metric','subgroup'),names(d))],drop=TRUE,lex.order=TRUE)
      d$.row <- factor(as.character(key),levels=rev(unique(as.character(key))))
      dodge <- ggplot2::position_dodge(width=.55)
      ggplot2::ggplot(d,ggplot2::aes(estimate,.row,colour=group)) +
        ggplot2::geom_vline(xintercept=params$reference %||% 0,linetype='dashed',colour='#AAAAAA')+
        ggplot2::geom_errorbar(ggplot2::aes(xmin=lower,xmax=upper),orientation='y',position=dodge,width=.12)+
        ggplot2::geom_point(position=dodge,size=pp_point_size('emphasis'))+
        ggplot2::labs(x=params$interval_label %||% 'Estimate and supplied interval',y=NULL,colour=NULL)
    },
    rank = {
      order <- params$order %||% unique(as.character(d$category[order(d$value)]))
      if(!setequal(order,as.character(d$category))) stop('Rank order must include all categories.')
      d$category <- factor(d$category,levels=order)
      q <- ggplot2::ggplot(d,ggplot2::aes(value,category,colour=group))+
        ggplot2::geom_segment(ggplot2::aes(x=0,xend=value,yend=category),linewidth=.3)+ggplot2::geom_point(size=pp_point_size('normal'))
      if(variant=='grouped') q <- q + ggplot2::facet_wrap(~group)
      if(variant=='labels') q <- pp_recipe_labels(q,d)
      q
    },
    dumbbell = {
      lev <- levels(droplevels(d$group)); a <- d[d$group==lev[1],,drop=FALSE]; b <- d[d$group==lev[2],,drop=FALSE]
      b <- b[match(a$category,b$category),,drop=FALSE]; a$.end <- b$value; a$.delta <- b$value-a$value
      q <- ggplot2::ggplot(a,ggplot2::aes(value,category))+
        ggplot2::geom_segment(ggplot2::aes(xend=.end,yend=category),colour='#AAAAAA')+
        ggplot2::geom_point(data=d,ggplot2::aes(colour=group),size=pp_point_size('emphasis'))
      if(variant=='delta') q <- q + ggplot2::geom_text(ggplot2::aes(x=(value+.end)/2,label=signif(.delta,3)),vjust=-.8,size=pp_text_size('minimum'))
      q
    },
    genome = pp_recipe_genome(d,params,variant),
    model = pp_recipe_model(d,params,variant),
    layout = {
      pp_require_backend('patchwork')
      main <- ggplot2::ggplot(d,ggplot2::aes(x,y,colour=group))+ggplot2::geom_point(size=pp_point_size('normal'))+pp_theme()
      if(variant=='inset') {
        bounds <- params$inset_bounds
        if(is.null(bounds)||length(bounds)!=4) stop('Inset requires inset_bounds=c(xmin,xmax,ymin,ymax).')
        small <- main + ggplot2::coord_cartesian(xlim=bounds[1:2],ylim=bounds[3:4])+ggplot2::theme(legend.position='none')
        main + patchwork::inset_element(small,.6,.6,.98,.98)
      } else {
        parts <- split(d,d$metric)
        plots <- lapply(parts,function(z) ggplot2::ggplot(z,ggplot2::aes(x,y,colour=group))+ggplot2::geom_point()+
          ggplot2::scale_colour_manual(values=pp_group_colors(d$group),limits=levels(d$group),drop=FALSE)+pp_theme()+ggplot2::labs(title=as.character(z$metric[1])))
        patchwork::wrap_plots(plots,guides='collect')
      }
    },
    stop('No core handler: ',h))
  if(!inherits(p,'patchwork')) {
    for(aesthetic in c('colour','fill')) {
      mapped <- c(list(p$mapping[[aesthetic]]),lapply(p$layers,function(l) l$mapping[[aesthetic]]))
      fields <- unique(vapply(Filter(Negate(is.null),mapped),rlang::as_label,character(1)))
      if(length(fields)==1 && fields%in%c('group','category') && fields%in%names(d) && !p$scales$has_scale(aesthetic)) {
        colors<-pp_group_colors(d[[fields]])
        p<-p+if(aesthetic=='colour') ggplot2::scale_colour_manual(values=colors) else ggplot2::scale_fill_manual(values=colors)
      }
    }
  }
  if(inherits(p,'patchwork')) p <- p & pp_theme() else p <- p + pp_theme()
  if(!is.null(params$x_label)) p <- p + ggplot2::labs(x=params$x_label)
  if(!is.null(params$y_label)) p <- p + ggplot2::labs(y=params$y_label)
  p
}

pp_recipe_genome <- function(d,params,variant) {
  if(variant=='track') return(ggplot2::ggplot(d,ggplot2::aes(x=start,xend=end,y=track,yend=track,colour=chr))+
    ggplot2::geom_segment(linewidth=1)+ggplot2::facet_wrap(~chr,scales='free_x')+ggplot2::labs(x='Genomic position (bp)',y=NULL))
  if(variant=='synteny') {
    required <- c('target_chr','target_start','target_end')
    if(length(setdiff(required,names(d)))) stop('Synteny requires target_chr, target_start, target_end; source intervals cannot stand in for target coordinates.')
    z <- do.call(rbind,lapply(seq_len(nrow(d)),function(i) {
      source <- c(d$start[i],d$end[i]);target<-c(d$target_start[i],d$target_end[i])
      if('strand'%in%names(d) && d$strand[i]=='-') source<-rev(source)
      if('target_strand'%in%names(d) && d$target_strand[i]=='-') target<-rev(target)
      data.frame(link=i,x=c(source,rev(target)),y=c(1,1,0,0),chr=d$chr[i],target_chr=d$target_chr[i])
    }))
    return(ggplot2::ggplot(z,ggplot2::aes(x,y,group=link,fill=chr))+ggplot2::geom_polygon(alpha=.5)+ggplot2::facet_grid(chr~target_chr,scales='free_x')+ggplot2::labs(x='Genomic position (bp)',y='Source / target'))
  }
  if(is.null(params$threshold) || params$threshold<=0 || params$threshold>1) stop('Declare a valid association threshold; no genome-wide default is inferred.')
  d <- d[order(d$chr,d$position),,drop=FALSE]; d$.logp <- pp_recipe_logp(d$pvalue,params)
  chromosomes <- levels(droplevels(d$chr)); lengths <- params$chromosome_lengths
  if(is.null(lengths)) lengths <- tapply(d$position,d$chr,max)
  if(is.null(names(lengths)) || !all(chromosomes %in% names(lengths))) stop('chromosome_lengths must be named for all chromosomes.')
  if(any(d$position>lengths[as.character(d$chr)])) stop('Position exceeds supplied chromosome length.')
  offsets <- stats::setNames(c(0,head(cumsum(lengths[chromosomes]),-1)),chromosomes)
  d$.position <- d$position + offsets[as.character(d$chr)]
  q <- ggplot2::ggplot(d,ggplot2::aes(if(variant=='manhattan') .position else position,.logp,colour=chr))+
    ggplot2::geom_point(size=pp_point_size('dense'))+ggplot2::geom_hline(yintercept=-log10(params$threshold),linetype='dashed')+
    ggplot2::labs(x='Genomic position (bp)',y='-log10 p-value')
  if(variant=='manhattan') q <- q + ggplot2::scale_x_continuous(breaks=offsets+lengths[chromosomes]/2,labels=chromosomes)
  if(variant=='facet') q <- q + ggplot2::facet_wrap(~chr,scales='free_x')
  if(variant=='regional') {
    if(length(unique(d$chr))!=1L) stop('Select one chromosome for regional association.')
    if(!is.null(params$window)) q <- q + ggplot2::coord_cartesian(xlim=params$window)
  }
  attr(q,'pp_coordinate_policy') <- list(lengths=lengths,source=if(is.null(params$chromosome_lengths)) 'observed maxima' else 'supplied chromosome lengths')
  q
}

pp_recipe_model <- function(d,params,variant) {
  if(variant=='calibration') {
    if(!'bin'%in%names(d)) stop('Calibration requires explicit bins or upstream binned summaries.')
    if(is.null(params$data_kind)) stop('Calibration requires data_kind=raw or summary.')
    if(params$data_kind=='raw') {
      if(is.null(params$unit_id)) stop('Raw calibration requires independent unit_id.')
      pp_assert_unique(d,c('group',params$unit_id))
      d <- stats::aggregate(cbind(observed,predicted)~bin+group,d,mean)
    } else pp_assert_unique(d,c('bin','group'))
    return(ggplot2::ggplot(d,ggplot2::aes(predicted,observed,colour=group))+ggplot2::geom_abline(slope=1,intercept=0,linetype='dashed')+ggplot2::geom_line()+ggplot2::geom_point()+ggplot2::coord_equal())
  }
  residual <- ggplot2::ggplot(d,ggplot2::aes(predicted,residual,colour=group))+ggplot2::geom_hline(yintercept=0,linetype='dashed')+ggplot2::geom_point()
  if(variant=='residual') return(residual)
  pp_require_backend('patchwork')
  association <- ggplot2::ggplot(d,ggplot2::aes(observed,predicted,colour=group))+ggplot2::geom_abline(slope=1,intercept=0,linetype='dashed')+ggplot2::geom_point()
  if(is.null(params$performance) || !is.data.frame(params$performance) || length(setdiff(c('group','metric','value'),names(params$performance)))) stop('Model composite requires an upstream performance table; scores are never synthesized from mean response.')
  metrics <- ggplot2::ggplot(params$performance,ggplot2::aes(group,value,colour=group))+ggplot2::geom_point()+ggplot2::facet_wrap(~metric,scales='free_y')
  patchwork::wrap_plots(list(association,residual,metrics),ncol=3)
}
