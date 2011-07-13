/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\make_five_percent_vdw.sas
*
* Generates ghetto SAS DDL for the VDW files.
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

%macro gen_it ;

  %** This leaves out non-MRN files like everndc and provider specialty.  But those are ;
  %** small enough that we can just use the real ones. ;
  %let tabs = %lowcase("&_vdw_rx")
            , %lowcase("&_vdw_utilization_m2")
            , %lowcase("&_vdw_dx_m2")
            , %lowcase("&_vdw_px_m2")
            , %lowcase("&_vdw_lab")
            , %lowcase("&_vdw_vitalsigns")
            , %lowcase("&_vdw_tumor")
            , %lowcase("&_vdw_enroll")
            , %lowcase("&_vdw_demographic")
            , %lowcase("&_vdw_census")
            , %lowcase("&_vdw_death")
            , %lowcase("&_vdw_cause_of_death")
            , %lowcase("&_vdw_provider_specialty_m5")
            , %lowcase("&_vdw_everndc")
  ;

  proc sql number ;
    select lowcase(compress(trim(libname || '.' || memname))) as nom
    into :ds1-:ds99
    from dictionary.tables
    where  lowcase(compress(trim(libname || '.' || memname))) in (&tabs)
    ;
    %let num = &sqlobs ;

    %do i = 1 %to &num ;
      %let this = &&ds&i ;
      describe table &this ;
    %end ;
  quit ;

%mend gen_it ;

** options mprint ;
** options obs = 1000 ;

%gen_it ;

