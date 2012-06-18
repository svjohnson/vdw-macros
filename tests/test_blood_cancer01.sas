/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_blood_cancer01.sas
*
* Tests out the blood cancer definition macro.
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

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\BloodCancerDefinition01.sas" ;

%BloodCancerDefinition01(outds = leuks, startdt = 01jan2007, enddt = 31dec2007) ;

proc freq data = leuks order = freq ;
  tables icdosite * dxdate / missing format = comma10.0 ;
  format dxdate year4. ;
run ;

run ;
