/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\test_vitals_demog_switchover.sas
*
*
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ; ** dsoptions="note2err" NOSQLREMERGE ;

/*
Getting ready to switch over to v3 on demog & vitals.  What macros need to be touched?

macros touching demog:
  GetRxRiskForPeople      *
  cleanvitals             *
  GetKidBMIPercentiles    *
  make_inclusion_table    *
  GetAdultBMI             *
  BMI_adult_macro         * (called by GetAdultBMI).

macros touching vitals:
  cleanvitals

  GetVitalSignsForPeople
  GetKidBMIPercentiles


*/

%macro get_test_kids(n = 300, outset = s.test_kids) ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from vdw.demog
    where birth_date gt '13jan1994'd and
          substr(mrn, 4, 1) = 'K'
    ;
  quit ;
%mend get_test_kids ;

%macro get_test_cohort(n = 300, outset = s.test_cohort) ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from vdw.demog
    where substr(mrn, 4, 1) = 'A'
    ;
  quit ;
%mend get_test_cohort ;

/*
%get_test_kids ;
%get_test_cohort ;
*/

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\StdVars.sas" ;
%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

%macro no_changes_needed ;
  data cohort ;
    set s.test_cohort s.test_kids ;
    idate = '20jun2007'd ;
    format idate mmddyy10. ;
  run ;


  %GetRxRiskForPeople(InFile = cohort, OutFile = s.test_rxriskforpeople_v3, IndexDt = idate) ;


  options dsoptions="zaa?" ;
  %GetKidBMIPercentiles(Inset = s.test_kids /* Dset of MRNs on whom you want kid BMI recs */
                          , OutSet = s.test_kid_bmis
                          , StartDt = 01jan2009
                          , EndDt = &sysdate9
                          ) ;

  ** While no changes were **necessary** here, I did take the opportunity to change from a "select *" to a ;
  ** specific list of relevant variables to grab out of the vitals table. ;
  %GetAdultBMI(people = s.test_cohort, outset = s.test_adult_bmi, StartDt = '01jan2006'd, EndDt = '30jun2007'd) ;

  %CleanVitals(OutLib = mac, Clean=Y, Dirty=Y, Report=Y, Limits=Y);

%mend no_changes_needed ;


%macro needed_changes ;
  ods html path = "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\" (URL=NONE)
           body = "test_make_inclusion_table.html"
           (title = "test_make_inclusion_table output")
            ;


  options mprint ;

  %make_inclusion_table(cohort = vdw.demog) ;

  run ;
  ods html close ;
%mend needed_changes ;

libname mac '\\ctrhs-sas\SASUser\pardre1\vdw\macro_testing' ;


%**needed_changes ;

%macro not_yet_tested ;





%mend not_yet_tested ;
