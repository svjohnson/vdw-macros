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

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  dsoptions="note2err" NOSQLREMERGE
;

** Please replace w/a reference to your local StdVars. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include vdw_macs ;

data gnu ;
  input
    @1    px         $char6.
  ;
datalines ;
31199
19329
10010
run ;

proc print ;

run ;
options mprint ;
%vdw_formats ;
run ;

proc print data = gnu ;
  format px $cptn. ;
run ;
