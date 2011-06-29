/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\test_vdw_formats.sas
*
* Tests the vdw_formats macro.
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  formchar  = '|-++++++++++=|-/|<>*'
  linesize  = 150
  msglevel  = i
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

** Please replace w/a reference to your local StdVars. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include vdw_macs ;

data gnu ;
  input
    @1    drg
  ;
datalines ;
4
5
6
run ;

proc print ;
run ;

options mprint ;
%vdw_formats ;

proc print data = gnu ;
  format drg drga. ;
run ;
