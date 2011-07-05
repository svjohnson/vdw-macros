/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\ctrhs\crn\s d r c\vdw\Macros\tests\test_calcage.sas
*
* Tests the calcage macro. ;
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  sastrace = ',,,d'
  sastraceloc = saslog nostsuffix
  dsoptions="note2err" NOSQLREMERGE
;

%include "\\groups\data\ctrhs\crn\s d r c\vdw\Macros\standard_macros.sas" ;

data dates ;
  do i = 0 to 100 by 10 ;
    dob = intnx('year', "&sysdate9"d, -i, 'sameday') ;
    age = %calcage(BDTVar = dob, refdate = "&sysdate9"d) ;
    output ;
  end ;
  format dob mmddyy10. ;
run ;

proc print ;
run ;
