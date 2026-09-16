#!/usr/bin/env Rscript
source('paperplot-skills/scripts/paperplot_helpers.R')
check <- function(x,label) if(!isTRUE(x)) stop(label,call.=FALSE)
fails <- function(x,label) check(inherits(tryCatch(force(x),error=identity),'error'),label)
good <- list(data_integrity='pass',physical_export='pass',visual_layout='pass')
check(pp_final_qa(list(),'pass')$status=='warn','Empty checks must remain incomplete')
check(pp_final_qa(good,'pending')$status=='warn','Human approval required')
check(pp_final_qa(good,'pass')$status=='pass','A complete approved case is reachable')
pending <- good; pending$visual_layout <- 'unverified'
review <- list(visual_layout=list(decision='pass',reviewer='test fixture',reason='Fixture verifies review mechanics, not manuscript approval',evidence_hash='abc'))
check(pp_final_qa(pending,'pass',reviews=review,reviewable='visual_layout',evidence_hash='abc')$status=='pass','Bound item review closes its uncertainty')
check(pp_final_qa(pending,'pass',reviews=review,reviewable='visual_layout',evidence_hash='other')$status=='warn','Old review cannot apply to new evidence')
pending$visual_layout <- 'fail'
check(pp_final_qa(pending,'pass',reviews=review,reviewable='visual_layout',evidence_hash='abc')$status=='fail','Exact failure cannot be waived')

d <- data.frame(x=1:2,y=1:2,group=c('control','treated'))
p <- ggplot2::ggplot(d,ggplot2::aes(x,y,colour=group))+ggplot2::geom_point()+ggplot2::scale_colour_manual(values=c(control='blue',treated='red'))
q <- ggplot2::ggplot(d,ggplot2::aes(x,y,colour=group))+ggplot2::geom_point()+ggplot2::scale_colour_manual(values=c(control='red',treated='blue'))
fails(pp_assert_data_unchanged(pp_plot_evidence(p),pp_plot_evidence(q)),'Reversed group colours need explicit scientific/display review')
q <- p + ggplot2::labs(x='different unit')
fails(pp_assert_data_unchanged(pp_plot_evidence(p),pp_plot_evidence(q)),'Changing units cannot masquerade as styling')
q <- p+ggplot2::coord_cartesian(xlim=c(1,1.4))
fails(pp_assert_data_unchanged(pp_plot_evidence(p),pp_plot_evidence(q)),'Cropping observations out of the coordinate window cannot masquerade as styling')

local({
  # Isolate filesystem freshness to exercise the actual approval transition.
  env <- new.env(parent=globalenv())
  env$ppp_fresh <- function(x,root,id) list(fresh=TRUE)
  env$ppp_assembly_artifacts <- function(a,root) list(valid=TRUE)
  status <- ppp_assembly_status; environment(status) <- env
  x <- list(current_assembly='r1',layout_version='l1',layout_confirmed='l1',
    panels=list(a=list(current='r1',review=list(revision='r1',decision='fail'))),
    assemblies=list(r1=list(layout_version='l1',incomplete=list(),panels=list(a=list(revision='r1')),qa=list(status='warn',evidence_hash='hash'))),
    assembly_review=list(revision='r1',evidence_hash='hash',result=list(status='pass')))
  check(status(x,tempdir())$status=='fail','A later panel rejection invalidates approved assembly')
})

root <- tempfile('pp-migration-'); dir.create(root)
state <- list(schema_version=1L,panels=list(),assemblies=list(),current_assembly=NULL,
              figure_id='legacy',message='Legacy test',layout=list(order=list()),events=list())
ppp_json(state,file.path(root,'project.json'))
original <- tools::md5sum(file.path(root,'project.json'))
plan <- pp_project_migrate(root)
check(plan$to==2L && identical(original,tools::md5sum(file.path(root,'project.json'))),'Migration dry-run is read-only')
pp_project_migrate(root,dry_run=FALSE)
check(ppp_read(root)$schema_version==2L,'Schema migration complete')
check(length(list.files(root,pattern='project-schema1-'))==1L,'Migration backup retained')
check(!dir.exists(file.path(root,'.project-lock')),'Migration lock released')
cat('Final QA, scientific encoding and state regressions passed.\n')
