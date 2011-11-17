/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\make_patient_periods.sas
*
* At the mid-year meeting in Minneapolis we discussed the need to have
* data documenting the periods over which non-member patients seem to
* be affiliated with the vdw-implementing-sites providers.  The most
* appealing approach is to infer periods from contacts documented in vdw
* files, and append these to vdw.enroll w/a to-be-decided new value of the
* enrollment_basis variable.
*
* This program is intended to be a sketch of an approach to creating such a
* file from ute encounters and rx fills.  The goal is to have something we
* can all run.
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas.connected.new" ;

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
%**include vdw_macs ;
%include '\\mlt1q0\C$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas' ;

%macro make_patient_periods(days_tolerance = 30, outset = patient_periods, enroll_start = 01jan1988) ;

  %local wh ;
  %if %symexist(_vdw_enroll) %then %do ;
    %put Enrollment file detected--removing any contacts happening during an enrollment period. ;
    %let wh = %str(where = (pat_start ge "&enroll_start"d)) ;
  %end ;
  %else %do ;
    %put Looks like your site does not have an enrollment file--just using patient contacts. ;
    %let wh = %str(where = (pat_start IS NOT NULL)) ;
  %end ;

  data all_contacts ;
    length pat_end pat_start 4 ;
    ** TODO: Add other datasets?  I would expect vitals to be redundant w/ute.  Maybe not lab though? ;
    set
      &_vdw_utilization (keep = mrn adate  rename = (adate  = pat_start) &wh)
      &_vdw_rx          (keep = mrn rxdate rename = (rxdate = pat_start) &wh)
    ;
    ** TODO: ? Make this figure dependant on age/sex of the person. ? ;
    ** If yes--probably want to nodupkey this guy before joining to demog. ;
    pat_end = pat_start + &days_tolerance ;
  run ;

  ** Dump dupes here, on the theory that we will reduce i/o and boost perf. ;
  proc sort nodupkey data = all_contacts ;
    by mrn pat_start ;
  run ;

  %if %symexist(_vdw_enroll) %then %do ;
    proc sql ;
      %** TODO: ? use a tolerance period around enr_start/end? ;
      create table patient_contacts as
      select a.*
      from all_contacts as a LEFT JOIN
           &_vdw_enroll as e
      on    a.mrn = e.mrn AND
            pat_start between enr_start and enr_end
      where e.mrn IS NULL
      ;
      drop table all_contacts ;
    quit ;
  %end ;
  %else %do ;
    proc datasets nolist library = work ;
      change all_contacts = patient_contacts ;
    quit ;
  %end ;

  ** Lot of magic in this macro--it does handle overlapping periods, and merges ;
  ** within-tolerance periods together. ;
  %CollapsePeriods(lib        = work
                  , dset      = patient_contacts
                  , recstart  = pat_start
                  , recend    = pat_end
                  , daystol   = &days_tolerance
                  , outset    = &outset
                  ) ;

%mend make_patient_periods ;

** options obs = 1000 ;

options mprint ;

/*

%make_patient_periods(days_tolerance = 90, outset = s.patient_periods) ;

  221,233,015 raw contact recs
  129,917,584 after nodupkey
    3,879,401 happening outside an enrollment period
    1,020,311 period records after collapsing. (compare, 3,049,266 in enroll).
    Median & Mode durations = days_tolerance.




*/
data gnu ;
  set s.patient_periods ;
  duration = pat_end - pat_start ;
  label duration = "No. days in the period." ;
run ;

options orientation = landscape ;

ods graphics / height = 6in width = 10in ;

%let out_folder = \\home\pardre1\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "make_patient_periods.html"
         (title = "make_patient_periods output")
          ;

  proc univariate plot ;
    var duration ;
    id mrn ;
  run ;

  proc sgplot data = gnu ;
    vbox duration ;
  run ;

run ;

ods _all_ close ;
