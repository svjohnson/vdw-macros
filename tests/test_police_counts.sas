/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_police_counts.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  sastrace = ',,,d'
  sastraceloc = saslog nostsuffix
  nofmterr
;
  ** dsoptions="note2err" NOSQLREMERGE
;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\police_counts.sas" ;

/*
proc freq noprint data = sashelp.class ;
  tables age / out = age_freqs ;
run ;

%police_counts(transfer_lib = work, lowest_count = 3, check_or_recode = R) ;

title1 "Redacted data" ;
proc print data = age_freqs ;
run ;

title1 "Original data" ;
proc print data = age_freqs_orig ;
run ;
*/

libname l '\\ctrhs-sas\sasuser\pardre1\vdw\voc_lab\v3_qa_results' ;
libname u '\\ctrhs-sas\SASUser\pardre1\vdw\voc_ute\general_qa\to_send' ;
%police_counts(transfer_lib = l, check_or_recode = c, lowest_count = 5) ;
run ;
