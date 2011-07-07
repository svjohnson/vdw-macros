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
    age = %calcage(birth_date, "&sysdate9"d) ;
    if mod(i, 2) = 0 then PapResDt = '25dec1966'd ;
    PapCollDt = '01jan1977'd ;
    output ;
  end ;
  format birth_date mmddyy10. ;
run ;

proc print ;
run ;

proc sql ;
  select %calcage(bdtvar = birth_date, refdate = "&sysdate9"d) as age
  from dates
  ;

  create table gnu as
  select * from dates
  where floor((intck('month', birth_date, coalesce(PapResDt, PapCollDt)) - (day(coalesce(PapResDt, PapCollDt)) < day(birth_date))) / 12) between 21 and 65
  ;
  create table gnu as
  select * from dates
  where %CalcAge(birth_date, coalesce(PapResDt, PapCollDt)) between 21 and 65
  ;
quit ;


** Tyler reports error w/this call: ;

** where %CalcAge(b.birth_date, coalesce(a.PapResDt, a.PapCollDt)) between 21 and 65 ;