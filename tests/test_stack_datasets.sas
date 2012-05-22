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

** For inspecting SQL sent to a server. ;
** options sastrace = ',,,d' sastraceloc = saslog nostsuffix ;

libname z '\\groups\data\CTRHS\Crn\Pharmacovigilance\programming\data\chartval\submitted' ;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\stack_datasets.sas" ;

%stack_datasets(inlib = z, nom = lvef_events, outlib = s) ;