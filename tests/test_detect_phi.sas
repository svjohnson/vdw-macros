/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_detect_phi.sas
*
* <<purpose>>
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  dsoptions="note2err" NOSQLREMERGE
  mprint
  nofmterr
;

%include "c:\Documents and Settings\pardre1\My Documents\vdw\macros\detect_phi.sas" ;

** Please replace this w/the proper path to your stdvars file. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** The macro requires one of the standard macros. ;
%include vdw_macs ;

** libname t 'c:\deleteme\phi_macro_testing' ;
** libname t '\\ctrhs-sas\SASUser\pardre1\vdw\macro_testing' ;
** libname t '\\ctrhs-sas\SASUser\pardre1\vdw\voc_ute\general_qa\to_send' ;
libname t '\\ctrhs-sas\SASUser\pardre1\vdw\voc_ute\general_qa\to_stay' ;
options orientation = landscape ;

** ods graphics / height = 6in width = 10in ;

%let mrn_regex = (\d{7,8}|\w{10}) ;
%**let mrn_regex = (\d{3}) ;
%let locally_forbidden_varnames = consumno ;

%let out_folder = c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "test_detect_phi.html"
         (title = "test_detect_phi output")
          ;

  options nofmterr ;
  %detect_phi(transfer_lib = t) ;

run ;

ods _all_ close ;

run ;
