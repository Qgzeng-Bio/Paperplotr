# PaperPlot recipe entrypoint: manifest-directed dispatch, mandatory real input.
# Simulation is reachable only through the explicitly named demo constructor.
for (.module in c("recipe-contract.R", "recipe-handlers.R", "recipe-specialized.R")) {
  source(file.path(pp_helper_script_dir, "lib", .module), local = FALSE)
}

pp_recipe_family_kind <- function(recipe_id) pp_recipe_entry(recipe_id)$handler
pp_recipe_base <- function() pp_theme()

pp_recipe_plot <- function(recipe_id, df, params = list(), mode = Sys.getenv("PAPERPLOT_MODE", "production")) {
  if (missing(df)) stop("df is required; use pp_recipe_mock_data() only for an explicit demo.")
  mode <- match.arg(mode, c("production","preview","demo"))
  if (isTRUE(attr(df, "pp_demo")) && mode != "demo") stop("Simulated input cannot enter production/preview as real evidence.")
  if (mode == "demo") params <- utils::modifyList(attr(df,"pp_demo_params") %||% list(), params)
  original <- df
  entry <- pp_recipe_entry(recipe_id)
  df <- pp_validate_recipe_input(recipe_id,df,params,mode)
  spec <- params$render_spec %||% pp_render_spec(width_mm=entry$default_width_cm*10,
    height_mm=entry$default_height_cm*10,mode=mode)
  if (entry$handler %in% c("complex_heatmap","sets","network","flow","circos","spatial","tree")) {
    plot <- pp_recipe_specialized(entry,df,params,spec)
  } else plot <- pp_recipe_core(entry,df,params)
  if (!inherits(plot,"ggplot") && !grid::is.grob(plot)) stop("Recipe must return a vector drawing object.")
  attr(plot,"pp_render_spec") <- spec
  attr(plot,"pp_recipe_evidence") <- list(recipe_id=recipe_id,source=original,
    validated=df,policy=attr(df,"pp_input_policy"),params=params,backend=entry$backend,mode=mode)
  if(!is.null(params$statistics)) {
    statistics <- do.call(pp_statistical_test,c(list(df=df),params$statistics))
    statistics$model <- NULL
    attr(plot,'pp_statistics') <- statistics
    attr(plot,'pp_recipe_evidence')$statistics <- statistics
  }
  if (grid::is.grob(plot)) {
    attr(plot,"pp_backend_spec") <- spec
    attr(plot,"pp_vector_builder") <- local({
      e <- entry; data <- df; settings <- params
      function(render_spec) pp_recipe_specialized(e,data,settings,render_spec)
    })
  }
  if (mode=="demo" && inherits(plot,"ggplot")) plot <- plot + ggplot2::labs(caption="DEMO / simulated test data")
  plot
}

pp_recipe_mock_data <- function(recipe_id, seed = 20260606) {
  old_seed <- if(exists(".Random.seed",.GlobalEnv,inherits=FALSE)) get(".Random.seed",.GlobalEnv) else NULL
  on.exit(if(!is.null(old_seed)) assign(".Random.seed",old_seed,.GlobalEnv) else if(exists(".Random.seed",.GlobalEnv,inherits=FALSE)) rm(".Random.seed",envir=.GlobalEnv))
  set.seed(seed)
  e <- pp_recipe_entry(recipe_id); h <- e$handler
  n <- 36
  d <- data.frame(sample=paste0("s",seq_len(n)),group=factor(rep(c("A","B","C"),each=12)),
    category=factor(rep(c("a","b","c"),12)),metric=factor(rep(c("m1","m2"),18)),
    value=seq_len(n)/10+sin(seq_len(n)),x=seq_len(n)/10,y=seq_len(n)/9+sin(seq_len(n)),
    label=ifelse(seq_len(n)<=3,paste0("label",seq_len(n)),""),count=seq_len(n),facet=rep(c("f1","f2"),each=18))
  d$pc1 <- d$x; d$pc2 <- d$y
  params <- list(data_kind="raw",summary="mean",unit_id="sample",error_type="se",alpha=.05,
    effect_threshold=1,threshold=5e-8,p_display_floor=1e-12,fit="lm",binwidth=.5,
    ellipse_level=.95,stress=.42,permanova_p=.023,variance_percent=c(32,16),
    input_scale="counts",distance="euclidean",linkage="complete",directed=TRUE,
    variant="chord",crs=4326,inset_bounds=c(1,2,1,3))
  if(h=="bar" && e$variant=="horizontal") { params$data_kind <- "summary"; d <- d[1:6,]; d$category <- factor(paste0("c",1:6)); d$error <- .2 }
  if(h=="composition") {d <- expand.grid(group=c("A","B"),category=c("a","b","c")); d$value <- 1:6}
  if(h=="composition" && e$variant=="diverging") {d$value[c(1,3,5)] <- -d$value[c(1,3,5)];params$input_scale <- "signed"}
  if(h %in% c("paired","dumbbell")) {
    d <- expand.grid(sample=paste0("s",1:8),group=c("A","B"))
    d$value <- seq_len(nrow(d))/3; d$category <- d$sample; d$metric <- "m1"
  }
  if(h %in% c("matrix","complex_heatmap")) {
    d <- expand.grid(metric=paste0("m",1:5),category=paste0("m",1:5))
    d$value <- sin(seq_len(nrow(d))); d$count <- seq_len(nrow(d)); d$group <- "All"
  }
  if(h=="timeseries") { d <- expand.grid(time=1:10,group=c("A","B")); d$value <- sin(d$time)+as.numeric(factor(d$group));d$error <- .1; params$data_kind <- "summary" }
  if(h=="differential") {d$feature <- paste0("g",seq_len(nrow(d)));d$log2fc <- seq(-3,3,length.out=nrow(d));d$padj <- seq(.001,.4,length.out=nrow(d));d$base_mean <- seq_len(nrow(d))*10}
  if(h=="enrichment") {d <- data.frame(term=paste0("path",1:8),ratio=seq(.1,.8,length.out=8),qvalue=seq(.001,.1,length.out=8),count=1:8)}
  if(h=="gsea") {d <- data.frame(rank=1:50,running_score=sin((1:50)/10),hit=rep(c(TRUE,FALSE),25))}
  if(h=="forest") {d <- expand.grid(metric=c("m1","m2"),group=c("A","B"));d$estimate <- 1:4;d$lower <- d$estimate-.5;d$upper <- d$estimate+.5;d$subgroup <- "All"}
  if(h=="rank") {d <- data.frame(category=factor(letters[1:8]),group=rep(c("A","B"),4),value=1:8,label=letters[1:8])}
  if(h=="genome") {
    d <- data.frame(chr=factor(rep(c("Chr1","Chr2"),each=20)),position=rep(seq(100,2000,100),2),pvalue=10^(-seq(1,10,length.out=40)))
    d$start <- d$position; d$end <- d$start+50;d$track <- "track1";d$feature <- paste0("v",1:40)
    d$target_chr <- d$chr;d$target_start <- d$start+10;d$target_end <- d$end+10;d$target <- d$target_chr
    if(e$variant=="regional") d <- d[d$chr=="Chr1",]
  }
  if(h=="model") {
    d$observed <- d$x; d$predicted <- d$y;d$residual <- d$observed-d$predicted;d$bin <- factor(rep(1:4,9))
    if(e$variant=="calibration") {d$observed <- plogis(d$observed-2);d$predicted <- plogis(d$predicted-2);params$data_kind <- "raw"}
    params$performance <- data.frame(group=c("A","B","C"),metric="RMSE",value=c(.2,.3,.4))
  }
  if(h=="sets") {d <- expand.grid(item=paste0("i",1:12),set=c("A","B","C"));d$present <- as.integer(seq_len(nrow(d))%%3!=0 | seq_len(nrow(d))%%4==0)}
  if(h %in% c("network","flow")) {d <- data.frame(source=c("A","A","B","C"),target=c("B","C","D","D"),weight=c(3,2,2,3));d$value <- d$weight}
  if(h=="circos") {d <- data.frame(chr=rep(c("Chr1","Chr2"),each=5),start=rep(seq(0,800,200),2),end=rep(seq(100,900,200),2),value=1:10);params$chromosome_lengths <- c(Chr1=1000,Chr2=1000)}
  if(h=="tree") {d <- data.frame(node=c("root","inner","a","b","c"),parent=c(NA,"root","inner","inner","root"),group=c("x","x","A","B","A"),value=1:5,branch_length=c(0,.2,.3,.4,.5))}
  if(h=="spatial") {
    d <- data.frame(longitude=c(0,1,2),latitude=c(0,1,0),value=c(1,2,3),region=c("a","b","c"))
    if(e$variant=="polygon") {
      pp_require_backend("sf")
      geometry <- sf::st_sfc(lapply(0:2,function(i) sf::st_polygon(list(matrix(c(i,0,i+1,0,i+1,1,i,1,i,0),ncol=2,byrow=TRUE)))),crs=4326)
      params$geometry <- sf::st_sf(region=d$region,geometry=geometry)
    }
  }
  if(h=="layout") d$metric <- rep(c("m1","m2"),each=18)
  attr(d,"pp_demo") <- TRUE; attr(d,"pp_demo_params") <- params
  d
}
