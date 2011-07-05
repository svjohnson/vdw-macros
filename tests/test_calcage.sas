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

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

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

%**include "\\groups\data\ctrhs\crn\s d r c\vdw\Macros\standard_macros.sas" ;

%include "c:\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

data dates ;
  do i = 0 to 100 by 10 ;
    birth_date = intnx('year', "&sysdate9"d, -i, 'sameday') ;
    age = %calcage(refdate = "&sysdate9"d) ;
    output ;
  end ;
  format birth_date mmddyy10. ;
run ;

proc print ;
run ;

proc sql ;
  select %calcage(refdate = "&sysdate9"d) as age
  from dates
  ;
quit ;