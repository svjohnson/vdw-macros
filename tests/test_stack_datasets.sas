/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_stack_datasets.sas
*
* Tests the stack_datasets macro.
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

** For inspecting SQL sent to a server. ;
** options sastrace = ',,,d' sastraceloc = saslog nostsuffix ;

libname _all_ clear ;

libname z '\\ghrisas\SASUser\pardre1\test\stack_datasets' ;
libname s '\\ghrisas\SASUser\pardre1\test\' ;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\stack_datasets.sas" ;
%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
%**include vdw_macs ;

options mlogic ;

%stack_datasets(inlib = z, nom = ghct, outlib = s) ;
