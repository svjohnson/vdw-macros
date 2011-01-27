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

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%macro get_people(inset, datevar, outset) ;
  ** Assumption here is that PS will perform at least as well as SQL. ;
  proc sort nodupkey data = &inset (where = (&datevar between "&period_start"d and "&period_end"d) keep = mrn &datevar) out = &outset (keep = mrn) ;
    by mrn ;
  run ;
%mend get_people ;

%macro make_stats_dset(period_start, period_end, outset) ;

  %get_people(inset = &_vdw_rx          , datevar = rxdate        , outset = in_rx      ) ;
  %get_people(inset = &_vdw_utilization , datevar = adate         , outset = in_ute     ) ;
  %get_people(inset = &_vdw_lab         , datevar = lab_dt        , outset = in_lab     ) ;
  %get_people(inset = &_vdw_vitalsigns  , datevar = measure_date  , outset = in_vitals  ) ;


  ** Enrollment is special. ;
  proc sql ;
    create table in_enroll as
    select distinct mrn
    from &_vdw_enroll
    where enr_start lt "&period_end"d and enr_end gt "&period_start"d
    ;
  quit ;

  options obs = max ;

  data in_any ;
    merge
      in_rx     (in = rx)
      in_ute    (in = ute)
      in_lab    (in = lab)
      in_vitals (in = vitals)
      in_enroll (in = enroll)
    ;
    by mrn ;
    in_rx     = rx ;
    in_ute    = ute ;
    in_lab    = lab ;
    in_vitals = vitals ;
    in_enroll = enroll ;
    label
      in_rx     = "Found in Rx between &period_start and &period_end.?"
      in_ute    = "Found in Utilization between &period_start and &period_end.?"
      in_lab    = "Found in Lab results between &period_start and &period_end.?"
      in_vitals = "Found in Vital Signs between &period_start and &period_end.?"
      in_enroll = "Enrolled at least one day between &period_start and &period_end.?"
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

    %let vlist = in_demog, in_enroll, in_rx, in_ute, in_lab, in_vitals ;

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

%**make_stats_dset(period_start = 01jan2009, period_end   = 31dec2009, outset = s.vdw_population_counts) ;

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


%let out_folder = \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "populations.html"
         (title = "populations output")
          ;

ods rtf file = "&out_folder.populations.rtf" ;

  proc sql ;
    create table gnu as
    select in_enroll, (sum(in_ute, in_rx) = 2) as in_uterx, n
    from s.vdw_population_counts
    ;
  quit ;

  proc freq data = gnu ;
    weight n ;
    tables in_enroll * in_uterx / missing format = comma9.0 ;
    format in_enroll enr. in_uterx oth. ;
  run ;

  proc freq data = s.vdw_population_counts ;
    weight n ;
    tables in_enroll * (in_rx in_ute in_lab in_vitals) / missing format = comma8.0 ;
    tables in_rx * in_ute / missing format = comma8.0 ;
    format in_enroll enr. in_rx in_ute in_lab in_vitals oth. ;
  run ;

ods _all_ close ;

