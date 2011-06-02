/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\test_enroll_switchover.sas
*
* We are ready to switch enrollment over--do the standard macros all work?
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

/*
  Macros that touch the enrollment file:
    WORKS:      PullContinuous
    NOT TESTED: OldGetFollowUpTime (deprecated--will not test)
    WORKS:      GetFollowUpTime
    WORKS:      GetRxRiskForPeople
    WORKS:      CleanEnroll
    WORKS:      SimpleContinuous
*/

filename mac "\\mlt1q0\c$\documents and settings\pardre1\my documents\vdw\macros\" ;

%macro make_test(out = s.test_enroll) ;
  proc sql ;
    create table gnu as
    select distinct MRN, adate
    from vdw.px
    where px in ('86671', '87102', '87103')
    ;

    create table gnu_grouped as
    select mrn, min(adate) as index_date format = mmddyy10.
    from gnu
    group by mrn
    ;

    reset outobs = 300 nowarn ;

    create table &out as
    select o.*, deathdt as DOD format = mmddyy10., min(deathdt, intnx('year', index_date, 2, 'sameday')) as end_date format = mmddyy10.
    from  gnu_grouped as o LEFT JOIN
          vdw.death as d
    on    o.mrn = d.mrn
    ;
  quit ;
%mend make_test ;

%**make_test ;

%**let _vdw_enroll = &_vdw_enroll_m6 ;

%macro these_work ;
  %PullContinuous(InSet = s.test_enroll
                , OutSet = s.out_continuous
                , IndexDate = index_date
                , PreIndexEnrolledMonths = 12
                , PreIndexGapTolerance = 2
                , PostIndexEnrolledMonths = 6
                , PostIndexGapTolerance = 1
                ) ;


  %GetFollowUpTime(People          = s.test_enroll   /* Dset of MRNs */
                 , IndexDate       = index_date            /* Name of a date var in &People, or else a complete date literal, marking the start of the follow-up period. */
                 , EndDate         = end_date       /* Name of a date var in &People, or else a complete date literal, marking the end of the period of interest. */
                 , GapTolerance    = 90                  /* Number of daysdisenrollment to ignore in deciding the disenrollment date. */
                 , CallEndDateVar  = end_of_fup         /* What name should we give the date var that will hold the end of the f/up period? */
                 , OutSet          = s.test_fup        /* The name of the output dataset */
                   ) ;

  %SimpleContinuous(People    = s.test_enroll  /* A dataset of MRNs whose enrollment we are considering. */
                   , StartDt  = 01jan2003    /* A date literal identifying the start of the period of interest. */
                   , EndDt    = 31dec2004    /* A date literal identifying the end of the period of interest. */
                   , DaysTol  = 90    /* The # of days gap between otherwise contiguous periods of enrollment that is tolerable. */
                   , OutSet   = s.test_simpcont    /* Name of the desired output dset */
                   ) ;

  %GetRxRiskForPeople(InFile = s.test_enroll, OutFile = s.test_rxriskforpeople, IndexDt = index_date) ;

%mend these_work ;

options mprint ;


** options obs = 1000 ;

%include mac(standard_macros.sas) ;

libname ce '\\ctrhs-sas\SASUser\pardre1\vdw\macro_testing' ;

%CleanEnroll(outlib = ce, clean = Y, dirty = Y, report = Y) ;

