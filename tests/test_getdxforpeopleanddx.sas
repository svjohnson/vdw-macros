/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_getdxforpeopleanddx.sas
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\CRN_VDW_MACROS.sas" ;

libname asc "\\ctrhs-sas\sasuser\pardre1\asc" ;

proc sql outobs = 20 nowarn ;
  create table ppl as
  select mrn
  from vdw.demog
  where substr(mrn, 4, 1) = 'X'
  ;
quit ;


  %GetDxForPeopleAndDx(People = ppl
                , DxLst = asc.dx_codes
                , StartDt = 01jun2004
                , EndDt = 31oct2004
                , Outset = ad_diags4
                ) ;


run ;
