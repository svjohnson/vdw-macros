/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\debug_enrollment_macros.sas
*
* Kay Theis found discrepancies between %SimpleContinuous and %GetFollowUpTime.
* This program helped me to find and fix them.
*
* This program should be run as a check any time either macro is altered.
*
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

libname s '\\ctrhs-sas\sasuser\pardre1\debug_enrollment' ;

data main ;
  set s.roy(keep = mrn) ;
run ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

run ;

%**let my_start_date = 01Oct2006 ;
%let my_start_date = 01jan2007 ;
%let my_end_date = 31Dec2008 ;

** try 01jan2007 as an index/start ;

options mprint mlogic ;

%SimpleContinuous(
                 People=main
                , StartDt = &my_start_date
                , Enddt = &my_end_date
                , DaysTol = 90
                , outset = s.enrollment
                );
run;

%GetFollowUpTime(People       = main
               , IndexDate    = "&my_start_date"d
               , EndDate      = "&my_end_date"d
               , GapTolerance = 90
               , CallEndDateVar = disenroll_date
               , OutSet       = s.disenrollment
               , DebugOut     = work
                 ) ;
run;


proc freq data = s.enrollment ;
  tables continuouslyenrolled / missing ;
run ;

proc freq data = s.disenrollment ;
  tables disenroll_date / missing ;
run ;

proc sql ;
  create table s.discreps as
  select mrn, 'passed gfut, but not sc' as reason
  from s.disenrollment
  where disenroll_date = "&my_end_date"d AND mrn not in (select mrn from s.enrollment where continuouslyenrolled = 1)
  ;

  insert into s.discreps
  select e.mrn, 'passed sc, but not gfut' as reason
  from s.enrollment as e
  where e.continuouslyenrolled = 1 and mrn not in (select mrn from s.disenrollment where disenroll_date = "&my_end_date"d) ;

  create table s.raw_enroll as
  select e.mrn, enr_start, enr_end
  from vdw.enroll2 as e INNER JOIN
      s.discreps as m
  on    e.mrn = m.mrn
  order by e.mrn, enr_start, enr_end
  ;

quit ;

/*
gfut is more liberal than sc--it lets in 2 more people.

These people were both

proc sql ;
  delete from main
  where mrn not in (select mrn from s.discreps)
  ;
quit ;

%SimpleContinuous(
                 People=main
                , StartDt= 01Oct2006
                , Enddt= 31Dec2008
                , DaysTol = 90
                , outset = s.discrep_enrollment
                );

proc freq data = s.discrep_enrollment ;
  tables continuouslyenrolled / missing ;
run ;
*/


/*
  Now we have a problem w/GFUT--its too generous.
    not enrolled on index & gap from index to first enrollment is too long.

*/