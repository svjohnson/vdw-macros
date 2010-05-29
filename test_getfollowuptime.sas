/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_getfollowuptime.sas
*
* Stand-alone tests for %gfut--created 20100503 in response to Jane Graftons bug report.
*
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

/*

Janes call was:

  %getfollowuptime(cohort,rxstrtdt,'31mar2010'd,0,enroll_enddt,enroll_enddts)

She reported not getting any end dates > july 2009.
*/

%macro get_test_people(obs = 100, out = s.test_ppl) ;
  proc sql outobs = &obs nowarn ;
    create table &out as
    select distinct mrn, ('25dec2008'd + round(uniform(0) * 50)) as rxstrtdt format = mmddyy10.
    from vdw.enroll2
    where '01feb2010'd between enr_start and enr_end
    ;
  quit ;
%mend ;

/*

%get_test_people ;

options mprint ;


proc sql ;
  create table s.drop_me as
  select *
  from vdw.enroll2
  where mrn = '0001BP10MP'
  order by enr_start, enr_end
  ;
quit ;

*/

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

options mprint ;

data test_ppl ;
  set s.test_ppl ;
  where mrn = '0001BP10MP' ;
run ;

%GetFollowUpTime(People = test_ppl
               , IndexDate    = rxstrtdt
               , EndDate      = '31mar2010'd
               , GapTolerance  = 0
               , CallEndDateVar = enroll_enddt
               , OutSet       = s.gfut_output
               , debugout = s
                 ) ;

** Bug looks to be in %collapseperiods! ;

data grist ;
  set s.__pre_collapse_enroll ;
run ;

   %CollapsePeriods(Lib      = work     /* Name of the library containing the dset you want collapsed */
                  , DSet     = grist      /* Name of the dset you want collapsed. */
                  , RecStart = enr_start     /* Name of the var that contains the period start dates. */
                  , RecEnd   = enr_end       /* Name of the var that contains the period end dates. */
                  , PersonID = MRN
                  , DaysTol  = 0 /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  ) ;

data s.grist ;
  set grist ;
run ;
