/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* TestPullContinuous3.sas
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

libname s '\\ctrhs-sas\sasuser\pardre1' ;

/*
   These data are of course derived from the V2 test data.
   Correct results are:
      Survivors
         Bobby
         Johnny
         PJ
         Jean
      Non-survivors
         Dee-dee
         Mark
         Jane
         Jose
         Ann
         Don
         Terry
         Roy
*/
data test_enroll ;
input MRN $ @13 enr_start mmddyy10. @26 enr_end mmddyy10. ;
format enr_start enr_end mmddyy10. ;
datalines ;
Bobby       01/01/2001   12/31/2006
Dee-dee     01/01/2001   07/31/2002
Dee-dee     10/01/2002   12/31/2006
Don         01/01/2001   03/31/2003
Don         09/01/2003   12/31/2006
Jane        02/01/2005   12/31/2006
Jean        01/01/2001   04/30/2003
Jean        08/01/2003   12/31/2006
Joey        01/01/2001   07/31/2003
Joey        10/01/2003   11/30/2003
Joey        02/01/2004   02/29/2004
Joey        05/01/2004   12/31/2006
Johnny      01/01/2001   07/31/2002
Johnny      09/01/2002   12/31/2006
Jose        01/01/2001   03/31/2004
Jose        07/01/2004   12/31/2006
Mark        01/01/2001   05/31/2002
PJ          01/01/2001   04/30/2004
PJ          07/01/2004   12/31/2006
Roy         01/01/2001   07/31/2003
Terry       01/01/2001   04/30/2003
Terry       10/01/2003   12/31/2006
Ann         06/01/2003   06/30/2003
;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%**include vdw_macs ;

options mprint ;

data test_people ;
input MRN $ 1-8 expected_outcome $ 12-70 should_live $ 71-74 ;
datalines ;
Bobby      No gaps at all.                                            Yes
Johnny     One acceptable pre-index gap.                              Yes
Joey       Several acceptable post-index gaps.                        Yes
Dee-dee    One UNACCEPTABLE pre-index gap.                            NO
PJ         One acceptable post-index gap.                             Yes
Jean       One acceptable big gap straddling the index date.          Yes
Mark       All enrollment prior to period of interest UNACCEPTABLE.   NO
Jane       All enrollment after period of interest UNACCEPTABLE.      NO
Jose       One UNACCEPTABLE post-index gap.                           NO
Ann        A single record falling at the start of the pd             NO
Don        One straddle-gap too big pre-index                         NO
Terry      One straddle-gap too big post-index                        NO
Roy        No enrollment after index + 1 month                        NO
;
run ;

proc sql ;
   title "Unaccounted for!" ;
   select p.*
   from test_people as p left join
         test_enroll as e
   on    p.mrn = e.mrn
   where e.mrn is null ;
quit ;

options source2 ;

options mlogic mprint ;

%PullContinuous(InSet                   = test_people
               , OutSet                  = s.survivors
               , IndexDate               = '01Jun2003'd
               , PreIndexEnrolledMonths  = 12
               , PreIndexGapTolerance    = 1
               , PostIndexEnrolledMonths = 16
               , PostIndexGapTolerance   = 2
               , EnrollDset              = test_enroll
               , DebugOut                = s
               ) ;


proc sql ;
   title "Survivors" ;
   select * from s.survivors ;

   title "Non-survivors" ;
   select * from test_people where MRN not in (select MRN from s.survivors) ;

quit ;
