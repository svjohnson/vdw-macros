/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_rxriskforpeople.sas
*
* A thin wrapper program that calls rxriskforpeople just to try and provoke syntax errors.
*
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%macro get_test_cohort(outobs = s.test_vitals, n = 50) ;
  proc sql outobs = &n nowarn ;
    create table &outobs as
    select mrn
    from &_vdw_demographic
    where substr(mrn, 3, 1) = 'Z'
    ;
  quit ;
%mend ;

%GetRxRiskForPeople(InFile = s.test_cohort, OutFile = test_rxriskforpeople, IndexDt = '20jun2007'd) ;
