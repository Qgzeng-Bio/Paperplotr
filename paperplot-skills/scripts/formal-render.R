#!/usr/bin/env Rscript
# Full engineering acceptance. Human/private-science release gates stay separate.
source('paperplot-skills/scripts/paperplot_helpers.R')
doctor <- pp_check_environment(TRUE)
if(!doctor$production_available) stop('Formal rendering requires every backend, Python QA, Poppler and licensed Arial; no skip permitted.')
lock <- jsonlite::fromJSON('paperplot-skills/renv.lock',simplifyVector=FALSE)
if(as.character(getRversion())!='4.6.0' || lock$Bioconductor$Version!='3.23') stop('Wrong R/Bioconductor runtime.')
wrong <- names(Filter(function(p) !requireNamespace(p$Package,quietly=TRUE)||utils::packageVersion(p$Package)!=numeric_version(p$Version),lock$Packages))
if(length(wrong)) stop('R packages differ from lock: ',paste(wrong,collapse=', '))
python <- pp_resolve_qa_python()
if(system2(python,c('-c',shQuote('import sys,PIL,pypdf; assert sys.version_info[:2]==(3,13); assert PIL.__version__=="12.3.0"; assert pypdf.__version__=="6.19.0"')))!=0) stop('Python differs from requirements.lock.')
out<-Sys.getenv('PAPERPLOT_FORMAL_OUTPUT',file.path('visual-checks',paste0('formal-',format(Sys.time(),'%Y%m%d-%H%M%S'))))
dir.create(out,recursive=TRUE,showWarnings=FALSE);out<-normalizePath(out)
Sys.setenv(PAPERPLOT_TEST_OUTPUT=file.path(out,'physical'),PAPERPLOT_PROJECT_TEST_OUTPUT=file.path(out,'project'),PAPERPLOT_HETEROGENEOUS_OUTPUT=file.path(out,'heterogeneous'),PAPERPLOT_REVIEW_TEST_OUTPUT=file.path(out,'review-mechanics'),PAPERPLOT_NESTED_TEST_OUTPUT=file.path(out,'nested-project'))
jobs <- list(
  structure=c('validate-skill.R'), catalog=c('catalog.py','--check'),
  input_contract=c('test-recipe-contract.R'),specialized=c('test-specialized-contract.R'),
  recipes=c('test-recipe-exports.R',file.path(out,'recipes')),
  templates=c('smoke-test-templates.R'),project=c('test-figure-project.R'),heterogeneous=c('test-heterogeneous.R'),nested_project=c('test-nested-project.R'),
  physical=c('test-production-contract.R','--require-production'),review_mechanics=c('test-review-path.R'),
  installation=c('test-skill-install.py'),public_sources=c('fetch-public-cases.py'),
  public_cases=c('test-public-cases.R',file.path(out,'public-cases')))
runner<-normalizePath('paperplot-skills/scripts/paperplot-run')
result<-list()
for(id in names(jobs)) {
  job<-jobs[[id]];args<-c(file.path('paperplot-skills/scripts',job[1]),job[-1])
  log<-file.path(out,paste0(id,'.log'));cat('Formal check:',id,'\n');flush.console()
  code<-system2(runner,shQuote(args),stdout=log,stderr=log)
  result[[id]]<-list(status=if(code==0) 'pass' else 'fail',exit_code=code,log=log,log_md5=unname(tools::md5sum(log)))
  if(code!=0) cat(paste(tail(readLines(log,warn=FALSE),12),collapse='\n'),'\n')
}
passed<-all(vapply(result,function(x)x$status=='pass',logical(1)))
source_files<-c(list.files('paperplot-skills/scripts',recursive=TRUE,full.names=TRUE,pattern='\\.(R|py)$'),list.files('paperplot-skills/recipes',full.names=TRUE),list.files('paperplot-skills',full.names=TRUE,pattern='lock$'))
source_files<-source_files[!dir.exists(source_files)]
report<-list(version=pp_helper_version,engineering=if(passed)'pass' else 'fail',skipped=0L,
  manuscript_acceptance='pending actual human review and original private IGS/main-figure inputs',release_ready=FALSE,
  environment=doctor,source_hashes=as.list(tools::md5sum(source_files)),checks=result)
writeLines(pp_to_json(report),file.path(out,'formal-render.json'))
cat('Engineering:',report$engineering,'; skipped: 0; manuscript/private acceptance: pending.\nEvidence:',out,'\n')
if(!passed) stop('Formal engineering checks failed; see retained logs.')
