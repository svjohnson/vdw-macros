/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_rxrisk.sas
*
* Does a very minimal testing of the rxrisk macro.
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%macro make_test_people(n = 200) ;
  proc sql outobs = &n nowarn ;
    create table s.test_people as
    select mrn, '30jun2003'd as index_date
    from vdw.demog
    where substr(mrn, 3, 1) = 'M'
    ;
  quit ;
%mend ;

%**make_test_people ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

%GetRxRiskForPeople(InFile = s.test_people, OutFile = s.rxrisk, IndexDt = index_date) ;
