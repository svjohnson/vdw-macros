/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_make_denoms.sas
*
* Tests the make_denoms macro.
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;


%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\make_denoms.sas" ;

%make_denoms(start_year = 2009, end_year = 2011, outset = s.test_denoms) ;
