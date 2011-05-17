/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\populations.sas
*
* Enumerates and counts the populations found in the VDW for a given period of time.
*********************************************/

** ====================== BEGIN EDIT SECTION ======================= ;
** Please comment-out or remove this line if Roy forgets to.  Thanks/sorry! ;
%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" mprint ; ** nosqlremerge ;

** Mostly just testing to make sure I am not relying on libs set elsewhere, but consider leaving this in ;
** as it will make the query to dictionary.tables more efficient and less prone to ersatz errors.. ;
libname _all_ clear ;

** Please replace with a reference to your local StdVars file. ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

** The date limits over which we want to report.  Please set this to the most recent ;
** full calendar year over which you have VDW data. ;

%let period_start = 01jan2010 ;
%let period_end   = 31dec2010 ;

** A folder spec where a dataset and the HTML output can be written--please make sure you leave a
** trailing folder separator character (e.g., a backslash) here--ODS is very picayune about that... ;
%let out_folder = \\ctrhs-sas\SASUser\pardre1\ ;
** ======================= END EDIT SECTION ======================== ;

libname out "&out_folder" ;

%macro get_people(inset, datevar, outset) ;
  ** Assumption here is that PS will perform at least as well as SQL. ;
  proc sort nodupkey data = &inset (where = (&datevar between "&period_start"d and "&period_end"d) keep = mrn &datevar) out = &outset (keep = mrn) ;
    by mrn ;
  run ;
%mend get_people ;

%macro make_stats_dset(outset) ;

  %** Creates an output dataset of counts of people in the various VDW files named in the &tabs ;
  %** macro var below (plus enroll and demog).  Each combination of in and not-in those files that ;
  %** any MRN can take will be represented with a row. ;


  /*
    This is perhaps a bit too clever.  The goal is to have this run without error even
    at sites that dont have a lab or vitals dataset.  At those sites I am assuming that
    they will have the requisite macro vars defined, but they will be empty (or not refer
    to a dset).  If that is so, the query on dictionary.tables will just return the
    names of the VDW dsets they *do* have, and the rest should run just on that.

    If so, the process for adding a new dset should be pretty easy--just add it to the tabs
    var here, and elaborate the macro array stuff.
  */
  %local tabs ;
  %let tabs = %lowcase("&_vdw_rx")
            , %lowcase("&_vdw_utilization")
            , %lowcase("&_vdw_lab")
            , %lowcase("&_vdw_vitalsigns")
            , %lowcase("&_vdw_tumor")
  ;

  proc sql noprint ;
    select lowcase(compress(trim(libname || '.' || memname))) as nom
    into :ds1-:ds9
    from dictionary.tables
    where  lowcase(compress(trim(libname || '.' || memname))) in (&tabs)
    ;
    %let num = &sqlobs ;
  quit ;

  %** Load up a couple of arrays w/the names of the dsets we are interested in, and the relevant date vars. ;
  %do i = 1 %to &num ;
    %let this_ds = &&ds&i ;
          %if &this_ds = %lowcase(&_vdw_rx)           %then %do ; %let dv&i = rxdate ;       %let os&i = rx       ; %end ;
    %else %if &this_ds = %lowcase(&_vdw_lab)          %then %do ; %let dv&i = lab_dt ;       %let os&i = lab      ; %end ;
    %else %if &this_ds = %lowcase(&_vdw_utilization)  %then %do ; %let dv&i = adate ;        %let os&i = ute      ; %end ;
    %else %if &this_ds = %lowcase(&_vdw_vitalsigns)   %then %do ; %let dv&i = measure_date ; %let os&i = vitals   ; %end ;
    %else %if &this_ds = %lowcase(&_vdw_tumor)        %then %do ; %let dv&i = dxdate       ; %let os&i = tumor    ; %end ;
    %else                                                   %do ; %let dv&i = zah ;          %let os&i = zah      ; %end ;

    %get_people(inset = &this_ds, datevar = &&dv&i, outset = &&os&i) ;

  %end ;

  proc sql ;
    ** Enrollment is special-assume everybodys got that. ;
    create table in_enroll as
    select distinct mrn
    from &_vdw_enroll
    where enr_start lt "&period_end"d and enr_end gt "&period_start"d
    ;
  quit ;

  options obs = max ;

  data in_any ;
    merge
      in_enroll (in = enroll)
      %do i = 1 %to &num ;
        &&os&i (in = &&os&i)
      %end ;
    ;
    by mrn ;
    in_enroll = enroll ;
    %do i = 1 %to &num ;
      in_&&os&i = &&os&i ;
    %end ;

    label
      in_enroll = "Enrolled at least one day between &period_start and &period_end.?"
      %do i = 1 %to &num ;
        in_&&os&i = "Found in &&os&i between &period_start and &period_end.?"
      %end ;
    ;
  run ;

  proc sql ;
    ** Add an in-demog flag (this one is over all time). ;
    create table everybody as
    select e.*, (not d.mrn is null) as in_demog label = "Found in Demographics file?"
    from  in_any as e LEFT JOIN
          &_vdw_demographic as d
    on    e.mrn = d.mrn
    ;

    ** Weve only got one rec per MRN, right? ;
    create unique index mrn on everybody (mrn) ;

    %let vlist = in_demog, in_enroll ;
    %do i = 1 %to &num ;
      %let vlist = &vlist., in_&&os&i ;
    %end ;

    create table vdw_populations as
    select &vlist, count(*) as n format = comma14.0
    from everybody
    group by &vlist
    ;

    create table &outset as
    select "&_siteabbr" as site
            , "&period_start"d  as period_start format = mmddyy10.
            , "&period_end"d    as period_end   format = mmddyy10.
            , *
    from vdw_populations
    ;
  quit ;
%mend make_stats_dset  ;

** options obs = 1000 ;
%make_stats_dset(outset = out.&_SiteAbbr._pop_counts) ;

proc format ;
  value enr
    0 = 'Not enrolled'
    1 = 'Enrolled'
  ;
  value oth
    0 = 'No'
    1 = 'Yes'
  ;
quit ;

ods html path = "&out_folder" (URL=NONE)
         body = "populations.html"
         (title = "VDW Populations")
          ;

  proc sql ;
    create table gnu as
    select in_enroll, (sum(in_ute, in_rx) = 2) as in_uterx label = "In both utilization and rx?", n
    from  out.&_SiteAbbr._pop_counts
    ;
  quit ;

  proc freq data = gnu ;
    weight n ;
    tables in_enroll * in_uterx / missing format = comma9.0 ;
    format in_enroll enr. in_uterx oth. ;
  run ;

  proc freq data =  out.&_SiteAbbr._pop_counts ;
    weight n ;
    tables in_enroll * (in_rx in_ute /* in_lab in_vitals */) / missing format = comma8.0 ;
    tables in_rx * in_ute / missing format = comma8.0 ;
    format in_: oth. in_enroll enr. ;
  run ;

ods _all_ close ;

