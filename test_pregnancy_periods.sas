/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\ctrhs\crn\s d r c\vdw\macros\test_pregnancy_periods.sas
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
  dsoptions="note2err" NOSQLREMERGE
;

%include "\\groups\data\ctrhs\crn\s d r c\vdw\macros\pregnancy_periods.sas" ;

options mprint ;

data test_cohort ;
  input
    @1    mrn         $char11.
  ;
datalines ;
MKDD29D32S
666GTQ2EX2
JJURCC3EV2
;
run ;

** libname _all_ clear ;
libname t '\\ctrhs-sas\SASUser\pardre1' ;
libname pvg '\\ctrhs-sas\SASUser\pardre1\pharmacovigilance' ;
%**pregnancy_periods(inset = pvg.cohort
                  , out_periods = t.pvg_preg_periods
                  , out_events  = t.pvg_preg_events) ;

%**make_preg_periods(inevents = t.pvg_preg_events
                , out_periods = t.pvg_preg_periods
                , max_pregnancy_length = 270) ;

/*

%get_preg_events(inset = pvg.cohort
                  , start_date = 01jan2001
                  , end_date = 31dec2002
                  , out_events = s.pregnancy_events) ;
*/

proc freq data = t.pvg_preg_periods order = freq ;
  tables outcome_category / missing ;
run ;

proc freq data = t.pvg_preg_periods order = freq ;
  tables first_sign_code / missing ;
  where outcome_category = 'unknown' ;
run ;
