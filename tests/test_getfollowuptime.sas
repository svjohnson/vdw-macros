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


* %get_test_people ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
%include vdw_macs ;

* %include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

options mprint ;

%GetFollowUpTime(People = s.test_ppl
               , IndexDate    = rxstrtdt
               , EndDate      = '31mar2010'd
               , GapTolerance  = 0
               , CallEndDateVar = enroll_enddt
               , OutSet       = s.gfut_output
               , debugout = s
                 ) ;

