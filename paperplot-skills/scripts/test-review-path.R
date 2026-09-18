#!/usr/bin/env Rscript
# Actual public observations exercise review mechanics. This automated reviewer
# is deliberately identified and never counts as actual human approval.
source('paperplot-skills/scripts/paperplot_helpers.R')
if(!pp_check_environment(TRUE)$production_available) stop('Formal runtime required.')
out<-Sys.getenv('PAPERPLOT_REVIEW_TEST_OUTPUT',tempfile('pp-review-path-'))
dir.create(out,recursive=TRUE,showWarnings=FALSE)
p<-ggplot2::ggplot(mtcars,ggplot2::aes(wt,mpg))+ggplot2::geom_point()+ggplot2::labs(x='Weight (1000 lb)',y='Fuel economy (mpg)')
stem<-file.path(out,'public-state-fixture')
files<-pp_save_all_with_qa_loop(p,stem,render_spec=pp_render_spec(ocr='off'),max_iterations=0)
pending<-attr(files,'qa_contract')
if(pending$status!='warn') stop('Unreviewed real data must remain candidate.')
resolved<-pp_review_export(stem,'pass',reviewer='AUTOMATED REVIEW MECHANISM FIXTURE - NOT HUMAN APPROVAL',checks=unlist(pending$reviewable),reason='Test-fixture assertion only; verify bound review state transitions on real mtcars measurements. Not scientific/publication approval.')
if(resolved$status!='pass') stop('The complete review state is not reachable: ',pp_to_json(resolved$checks))
# Preserve source/output/provenance, but audit the same real files against a
# deliberately wrong physical declaration. Human success may not override it.
report<-jsonlite::fromJSON(paste0(stem,'_production_qa.json'),simplifyVector=FALSE)
bad_spec<-attr(files,'qa_render_spec');bad_spec$width_mm<-100
bad<-pp_run_export_audit(files,bad_spec,file.path(out,'intentional-size-error'))
if(bad$checks$svg_page_mm!='fail') stop('Actual size error was missed.')
report$final$raw_checks$export_svg_page_mm<-'fail'
report$final$checks$export_svg_page_mm<-'fail'
report$final$evidence_hash<-pp_content_hash(list(intentional_size_failure=TRUE,original=report$final$evidence_hash))
ppp_json(report,paste0(stem,'_production_qa.json'))
failed<-pp_review_export(stem,'pass',reviewer='AUTOMATED NEGATIVE FIXTURE',checks=unlist(pending$reviewable),reason='Deliberately attempt to approve an exact size failure; it must stay fail.')
if(failed$status!='fail') stop('A reviewer bypassed an exact failure.')
cat('Actual-file review reachability and non-waivable failure passed; these are not human review records.\n')
