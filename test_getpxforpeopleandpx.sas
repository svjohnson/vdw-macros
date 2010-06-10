/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_getpxforpeopleandpx.sas
*
* Sharon Fuller reports getting a "ERROR 22-322: Syntax error, expecting one of the following: a quoted string"
* error running GetPxForPeopleAndPx.  Trying to repro.
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%macro get_test_people ;
  proc sql outobs = 40 ;
    create table with as
    select distinct mrn
    from vdw.px
    where px in (select px from s.cocapxcodelist)
    ;

    create table s.test_ppl as
    select *
    from with
    ;
  quit ;
%mend ;

%**get_test_people ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

/*

GetPxForPeopleAndPx (
                     People
                     , PxLst
                     , StartDt
                     , EndDt
                     , Outset
                     ) ;

*/


options source source2 mprint ;

%GetPxForPeopleAndPx (
           people = s.test_ppl
         , pxlst = s.CocaPxCodeList
         , startdt = 01Jul2008
         , enddt = 31May2010
         , outset = s.cocapx
         )
;


