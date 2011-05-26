/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\make_five_percent_vdw.sas
*
* Creates a 5-percent subset VDW for use in testing.
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

libname five '\\ctrhs-sas\Warehouse\Sasdata\CRN_VDW\5percent_subset' ;

%macro move_it ;

  %** This leaves out non-MRN files like everndc and provider specialty.  But those are ;
  %** small enough that we can just use the real ones. ;
  %let tabs = %lowcase("&_vdw_rx")
            , %lowcase("&_vdw_utilization")
            , %lowcase("&_vdw_dx")
            , %lowcase("&_vdw_px")
            , %lowcase("&_vdw_lab")
            , %lowcase("&_vdw_vitalsigns")
            , %lowcase("&_vdw_tumor")
            , %lowcase("&_vdw_enroll")
            , %lowcase("&_vdw_demographic")
            , %lowcase("&_vdw_census")
            , %lowcase("&_vdw_death")
            , %lowcase("&_vdw_cause_of_death")
  ;

  proc sql noprint ;
    select lowcase(compress(trim(libname || '.' || memname))) as nom, 'five.' || lowcase(memname)
    into :ds1-:ds9, :out1-:out9
    from dictionary.tables
    where  lowcase(compress(trim(libname || '.' || memname))) in (&tabs)
    ;
    %let num = &sqlobs ;
  quit ;

  %do i = 1 %to &num ;
    %let in = &&ds&i ;
    %let out = &&out&i ;
    %put copying &in to &out ;

    data &out ;
      set &in ;
      where substr(mrn, 1, 1) in ('5', 'P') ;
    run ;
  %end ;

%mend move_it ;

options mprint ;
options obs = 1000 ;

%move_it ;

