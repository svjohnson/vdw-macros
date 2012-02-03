/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_ute_switchover.sas
*
* We are switching utilization over at the end of Sep 2011.  Time to see which
* macros barf and which ones dont.
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

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;


libname t '\\ctrhs-sas\SASUser\pardre1\vdw\macro_testing' ;

/*
  Macros that hit one or more of the ute files or provider specialty:
    GetUtilizationForPeople     *
    GetPxForPeople              *
    GetDxForPeople              *
    GetDxForDx                  *
    GetPxForPx                  *
    GetDxForPeopleAndDx
    GetPxForPeopleAndPx
    charlson                    *
    get_preg_events
    vdwcountsandrates1
*/


** Make the v3 stuff the current. ;
%**let _vdw_utilization        = &_vdw_utilization_m2        ;
%**let _vdw_dx                 = &_vdw_dx_m2                 ;
%**let _vdw_px                 = &_vdw_px_m2                 ;
%**let _vdw_provider_specialty = &_vdw_provider_specialty_m5 ;

%macro get_test_cohort(n = 300, outset = s.test_cohort) ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from vdw.demog
    where substr(mrn, 4, 1) = 'A'
    ;
  quit ;
%mend get_test_cohort ;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

%**get_test_cohort(outset = t.people) ;


%macro no_changes_needed ;
  %GetUtilizationForPeople(people = t.people, startdt = 01jan2005, enddt = 30jun2010, outset = t.out_get_ute_for_people) ;
  %GetPxForPeople(people = t.people, startdt = 01jan2009, enddt = 30jun2010, outset = t.out_get_px_for_people) ;
  %GetDxForPeople(people = t.people, startdt = 01jan2009, enddt = 30jun2010, outset = t.out_get_dx_for_people) ;

  %GetDxForDx(DxLst   = pv.outcome_diagnosis_codes
          , DxVarName = code
          , StartDt   = 01jan2009
          , EndDt     = 30jun2010
          , Outset    = t.out_get_dx_for_dx
          ) ;
libname pv '\\ctrhs-sas\SASUser\pardre1\pharmacovigilance' ;

  %GetPxForPx(PxLst   = pv.outcome_procedure_codes
          , PxVarName = px
          , PxCodeTypeVarName = codetype
          , StartDt   = 01jan2009
          , EndDt     = 30jun2010
          , Outset    = t.out_get_px_for_px
          ) ;

%mend no_changes_needed ;

%macro changes_complete ;
  libname pvg '\\ctrhs-sas\SASUser\pardre1\pharmacovigilance' ;

  data gnu ;
    set pvg.cohort(keep = mrn dx_date charlson_score) ;
  run ;
  options mprint errors = 4 ;
  %charlson(InputDS = gnu, IndexDateVarName = dx_date, OutputDS = s.charlson_out, IndexVarName = charlie, InpatOnly = A, Malig = N) ;

%mend changes_complete ;

%changes_complete ;
