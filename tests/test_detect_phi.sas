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


** ====================== BEGIN EDIT SECTION ============================ ;
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

%** A regular expression giving the pattern that your MRN values follow. Used to check character vars for possibly holding MRNs. ;
%let mrn_regex = (\d{7,8}|[A-Z0-9]{10}) ;

%** A pipe-delimited list of variable names that should trigger a warning in the ouput of the macro detect_phi. ;
%** Not case-sensitive. ;
%let locally_forbidden_varnames = consumno|hrn ;

%** Where you put the detect_phi program file. ;
%include "c:\Documents and Settings\pardre1\My Documents\vdw\macros\detect_phi.sas" ;

** Please replace this w/the proper path to your stdvars file. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
** ====================== END EDIT SECTION ============================ ;

%include vdw_macs ;

libname t 'c:\deleteme\phi_macro_testing' ;
** libname t '\\ctrhs-sas\SASUser\pardre1\vdw\macro_testing' ;
** libname t '\\ctrhs-sas\SASUser\pardre1\vdw\voc_ute\general_qa\to_send' ;
** libname t '\\ctrhs-sas\SASUser\pardre1\vdw\voc_ute\general_qa\to_stay' ;
options orientation = landscape ;

** ods graphics / height = 6in width = 10in ;

%let out_folder = c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;

**libname vdw '\\ctrhs-sas\Warehouse\Sasdata\CRN_VDW\5percent_subset' ;
libname cd '\\ctrhs-sas\Warehouse\Sasdata\Consumer Demographics' ;

ods html path = "&out_folder" (URL=NONE)
         body = "test_detect_phi.html"
         (title = "test_detect_phi output")
          ;

  options nofmterr ;
  %detect_phi(transfer_lib = cd, obs_lim = 200, eldest_age = 50) ;

run ;

ods _all_ close ;

run ;
