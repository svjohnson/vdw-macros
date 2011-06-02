/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_bp_flag.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\BP_FLAG.sas" ;
%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%macro get_test_cohort(outobs = s.test_bp, lett = S, n = 5000) ;
  proc sql outobs = &n nowarn ;
    create table &outobs as
    select *
    from &_vdw_vitalsigns
    where substr(mrn, 3, 1) = "&lett"
    ;
  quit ;
%mend ;

%**get_test_cohort ;

%bp_flag(dsin    = s.test_bp,
         dsout   = test_bp_out) ;

run ;

