#!/usr/bin/env Rscript
# Explicit environment setup only; plotting never installs packages.
args <- commandArgs(TRUE)
script_arg <- sub('^--file=','',commandArgs(FALSE)[grepl('^--file=',commandArgs(FALSE))])
lockfile <- file.path(dirname(normalizePath(script_arg[[1]],mustWork=TRUE)),'..','renv.lock')
if(length(args)!=1L) stop('Usage: bootstrap-environment.R <isolated-runtime-prefix>')
prefix <- normalizePath(args[[1]],mustWork=TRUE)
if(any(as.integer(charToRaw(prefix))>127L) || grepl(' ',prefix,fixed=TRUE)) stop('Choose an ASCII, space-free runtime prefix (e.g. ~/.local/share/paperplot/runtime-0.7.0); pkg-config cannot reliably compile under escaped paths.')
if(getRversion()!=numeric_version('4.6.0')) stop('The locked runtime requires R 4.6.0.')
library_path <- file.path(prefix,'r-library')
dir.create(library_path,recursive=TRUE,showWarnings=FALSE)
.libPaths(c(library_path,.Library))
Sys.setenv(RENV_PATHS_CACHE=file.path(prefix,'renv-cache'),RENV_PATHS_LIBRARY=library_path,
           RENV_CONFIG_PAK_ENABLED='FALSE',RENV_CONFIG_AUTOLOADER_ENABLED='FALSE')
options(repos=c(CRAN='https://cloud.r-project.org'),Ncpus=2,timeout=600)
Sys.setenv(PKG_CONFIG_PATH=paste(file.path(prefix,'lib','pkgconfig'),file.path(prefix,'share','pkgconfig'),sep=.Platform$path.sep))
# Conda's R build may retain an older Fortran subdirectory. Resolve the actual
# installed compiler, in this environment only; never modify user Makevars.
gcc_dirs <- list.dirs(file.path(prefix,'lib','gcc'),recursive=TRUE,full.names=TRUE)
gcc_dirs <- gcc_dirs[file.exists(file.path(gcc_dirs,'libgfortran.a'))]
if(length(gcc_dirs)) {
  makevars <- file.path(prefix,'Makevars.paperplot')
  writeLines(paste0('FLIBS = -L',shQuote(tail(gcc_dirs,1)),' -lgfortran -lquadmath -lm'),makevars)
  Sys.setenv(R_MAKEVARS_USER=makevars)
}
if(!requireNamespace('renv',quietly=TRUE)) install.packages('renv',lib=library_path)
project <- file.path(prefix,'renv-project'); dir.create(project,showWarnings=FALSE)
renv::init(project=project,bare=TRUE,restart=FALSE)
renv::settings$bioconductor.version('3.23',project=project)
if(file.exists(lockfile)) {
  renv::restore(project=project,lockfile=lockfile,prompt=FALSE)
  writeLines(renv::paths$library(project=project),file.path(prefix,'r-library-path.txt'))
  cat('PaperPlot locked R environment restored:',prefix,'\n')
  quit(status=0)
}
if(!identical(Sys.getenv('PAPERPLOT_BOOTSTRAP_UNLOCKED'),'1')) stop('No tested renv.lock found. Unlocked bootstrap is a maintainer-only operation.')
cran <- c('ggplot2','patchwork','ggrepel','ragg','svglite','systemfonts','jsonlite','ggridges',
          'ggbeeswarm','circlize','gridGraphics','ape','igraph','ggraph','ggalluvial','sf','ComplexUpset')
renv::install(cran,project=project,prompt=FALSE)
renv::install(c('bioc::ComplexHeatmap','bioc::treeio','bioc::ggtree'),project=project,prompt=FALSE)
renv::snapshot(project=project,type='all',prompt=FALSE)
writeLines(renv::paths$library(project=project),file.path(prefix,'r-library-path.txt'))
cat('PaperPlot R environment ready:',prefix,'\n')
