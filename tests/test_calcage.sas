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
  dsoptions="note2err" NOSQLREMERGE
;
/*   sastrace = ',,,d'
  sastraceloc = saslog nostsuffix
 */
%**include "\\groups\data\ctrhs\crn\s d r c\vdw\Macros\standard_macros.sas" ;

%include "c:\users\pardre1\Documents\vdw\macros\standard_macros.sas" ;

%let test_date = 29-feb-2004 ;

data dates ;
  do i = 0 to 100 by 10 ;
    birth_date = intnx('year', "&test_date"d, -i, 'sameday') ;
    age = %calcage(birth_date, "&test_date"d) ;
    if mod(i, 2) = 0 then PapResDt = '25dec1966'd ;
    PapCollDt = '01jan1977'd ;
    output ;
  end ;
  format birth_date pap: mmddyy10. ;
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