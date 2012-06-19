/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_charlson.sas
*
* <<purpose>>
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

%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include '\\home\pardre1\SAS\SCRIPTS\sasntlogon.sas';
%include "//ghrisas/warehouse/sasdata/crn_vdw/lib/StdVars_Teradata.sas";
%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\Charlson.sas" ;

%macro get_test_ppl(outset) ;
  ** Current reported bug is that the below icd-9 px code does not get taken into account. ;
  proc sql outobs = 400 nowarn ;
    create table &outset as
    select distinct mrn, (adate + 100) as index_date format = mmddyy10.
    from &_vdw_px
    where px = "38.48"
    ;
  quit ;

%mend get_test_ppl ;

%macro get_novisits(appendto = s.charlson_ppl, dat = 30jun2007) ;
  proc sql outobs = 100 nowarn ;
    create table gnu as
    select distinct d.mrn, "&dat"d as index_date format = mmddyy10.
    from &_vdw_demographic as d LEFT JOIN
         &_vdw_dx as i
    on    d.mrn = i.mrn AND
          i.adate between ("&dat"d - 365) and "&dat"d
    where i.mrn IS NULL
    ;

    insert into &appendto (mrn, index_date)
    select mrn, index_date
    from gnu
    ;
  quit ;

%mend get_novisits ;

%macro get_randoms(appendto = s.charlson_ppl, dat = 30jun2007) ;
  proc sql outobs = 100 nowarn ;
    create table gnu as
    select mrn, "&dat"d as index_date format = mmddyy10.
    from &_vdw_demographic
    where substr(mrn, 3, 1) = 'F'
    ;
    insert into &appendto (mrn, index_date)
    select mrn, index_date
    from gnu
    ;
  quit ;

%mend get_randoms ;

%**get_test_ppl(outset = s.charlson_ppl) ;

%**get_novisits ;
%**get_randoms ;
%charlson(inputds = s.charlson_ppl
          , IndexDateVarName = index_date
          , outputds = s.charlson_test
          , IndexVarName = charlson
          , inpatonly=A
          , malig=N
          );
run ;
