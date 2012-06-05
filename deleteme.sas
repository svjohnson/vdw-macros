/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\deleteme.sas
*
* <<purpose>>
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  errors    = 5
  nocenter
  noovp
  nosqlremerge
;

libname submit 'C:\deleteme\counts_rates\submitted' ;

data submit.sop_test_counts ;
  set submit.nsp_test_counts ;
  array n num_recs num_ppl num_enrolled_ppl rate_enrolled_ppl ;
  do i = 1 to dim(n) ;
    n{i} = max(n{i}, 0) * 10 * uniform(0) ;
  end ;

  drop i ;

run ;