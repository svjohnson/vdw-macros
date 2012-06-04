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

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

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

%let outt = \\ghrisas\SASUser\pardre1\ ;
%let outpath = &outt ;
libname s "&outt" ;

%let __out = s.ghc_test_counts ;

%let out_folder = \\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "test_counts_and_rates.html"
         (title = "test_counts_and_rates output")
          ;
	proc print data = &__out (obs=200) ;
		title1 "Here is a sample of what you are sending out" ;
		title2 "Please inspect the full dataset in &outpath.&__out..sas7bdat before sending." ;
    id data_type category ;
		var code descrip num_recs num_ppl num_enrolled_ppl rate_enrolled_ppl ;
		sum num_ppl num_enrolled_ppl rate_enrolled_ppl ;
    by data_type category ;
  run ;

ods _all_ close ;
run ;
