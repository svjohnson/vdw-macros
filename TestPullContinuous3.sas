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
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

libname s '\\ctrhs-sas\sasuser\pardre1' ;
* libname s 's:\' ;

%macro MakeV2TestData ;
   data test_people ;
   input MRN $ 1-10 expected_outcome $ 12-70 should_live $ 71-74 ;
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

   * Everybody starts out w/a full complement of data. ;
   data test_enroll ;
      set test_people ;
      do enr_year = 2001 to 2006 ;
         do enr_month = 1 to 12 ;
            enr_date = mdy(enr_month, 1, enr_year) ;
            output ;
         end ;
      end ;
      keep mrn enr_year enr_month enr_date ;
      format enr_date mmddyy10. ;
   run ;

   * Now we surgically remove some data to make gaps. ;
   proc sql ;

      * Bobby      No gaps at all.                                   ;

      * Johnny     One acceptable pre-index gap.                     ;
      delete from test_enroll
      where MRN = 'Johnny' and
            enr_date in ('01Aug2002'd)
      ;
      * Joey       Several acceptable post-index gaps.               ;
      delete from test_enroll
      where MRN = 'Joey' and
            enr_date in ('01Aug2003'd, '01Sep2003'd,
                         '01Dec2003'd, '01Jan2004'd,
                         '01Mar2004'd, '01Apr2004'd)
      ;
      * Dee-dee    One UNACCEPTABLE pre-index gap. ;
      delete from test_enroll
      where MRN = 'Dee-dee' and
            enr_date in ('01Aug2002'd, '01Sep2002'd)
      ;
      * PJ         One acceptable post-index gap.                    ;
      delete from test_enroll
      where MRN = 'PJ' and
            enr_date in ('01May2004'd, '01Jun2004'd)
      ;
      * Jean       One acceptable big gap straddling the index date. ;
      delete from test_enroll
      where MRN = 'Jean' and
            enr_date between '01May2003'd and '01Aug2003'd
      ;

      * Mark       All enrollment prior to period of interest UNACCEPTABLE. ;
      delete from test_enroll
      where MRN = 'Mark' and
            enr_date ge '01Jun2002'd
      ;

      * Jane       All enrollment after period of interest UNACCEPTABLE.   ;
      delete from test_enroll
      where MRN = 'Jane' and
            enr_date le '01Jan2005'd
      ;
      * Jose       One UNACCEPTABLE post-index gap.                        ;
      delete from test_enroll
      where MRN = 'Jose' and
            enr_date in ('01Apr2004'd, '01May2004'd,
                         '01Jun2004'd)
      ;
      * Ann        A single record falling at the start of the pd          ;
      delete from test_enroll
      where MRN = 'Ann' and
            enr_date ne '01Jun1993'd
      ;
      * Don        One straddle-gap too big pre-index  ;
      delete from test_enroll
      where MRN = 'Don' and
            enr_date between '01Apr2003'd and '01Aug2003'd
      ;
      * Terry      One straddle-gap too big post-index ;
      delete from test_enroll
      where MRN = 'Terry' and
            enr_date between '01May2003'd and '01Sep2003'd
      ;
      * Roy        No enrollment after index + 1 month ;
      delete from test_enroll
      where MRN = 'Roy' and
            enr_date gt '01Jul2003'd
      ;
   quit ;

   data s.test_enroll ;
      set test_enroll ;
   run ;
   * Collapse the v2 data down into something w/start/stops. ;

   %include "\\home\pardre1\Reference\CollapsePeriods.sas" ;

   data gnu ;
      set s.test_enroll ;
      start_date = enr_date ;
      end_date = intnx('MONTH', start_date, 0, 'E') ;
      drop enr_: ;
   run ;

   options mprint ;

   %CollapsePeriods(Lib     = work  /* Name of the library containing the dset you want collapsed */
                  , DSet    = gnu  /* Name of the dset you want collapsed. */
                  , RecStart= start_date     /* Name of the var that contains the period start dates. */
                  , RecEnd  = end_date     /* Name of the var that contains the period end dates. */
                  , DaysTol = 2  /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  , Debug   = 0  /* 0/1 flag indicating whether you want the PUT statements to run (PRODUCES A LOT OF OUTPUT!). */
                  ) ;

   data s.test_start_stop ;
      set gnu ;
   run ;

%mend MakeV2TestData ;

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
Jean        09/01/2003   12/31/2006
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

filename crn_macs  "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\CRN_VDW_MACROS.sas" ;

%include crn_macs ;

%*include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\PullContinuous3.sas" ;
/*
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

%PullContinuous3(InSet                   = test_people
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
*/

* Grab a test set of people ;

%macro MakeTestPeople(OutSet, Letter, SizeLim) ;
   proc sql outobs = &SizeLim NOWARN ;
      create table &OutSet as
      select mrn
      from vdw.demog
      where substr(mrn, 8, 1) = "&Letter"
      ;
   quit ;
%mend MakeTestPeople ;

%*include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\PullContinuous3.sas" ;


%MakeTestPeople(OutSet = s.test_pc_people, Letter = L, SizeLim = 2000) ;

* Grab out their enroll records ;
proc sql ;
   create table s.new_enroll as
   select e.*
   from vdw.enroll2 as e INNER JOIN
         s.test_pc_people as p
   on    e.mrn =  p.mrn
   ;
quit ;

* Create an exploded version of enroll for use w/the old macro. ;
%include "\\groups\data\CTRHS\CHS\pardre1\GetV1VDWEnrollData.sas" ;

%GetV1VDWEnrollData(InSet      = s.test_pc_people
                  , OutSet     = s.old_enroll
                  , EnrollData = s.new_enroll
                  ) ;
* 12 months prior to 01-june-2003 (01-june-2002) to 16 months post (31-oct-2004) ;

* This one ran in: real time  = 1:32.72   cpu time = 1.73 seconds ;

data gnu ;
   set s.test_pc_people ;
   idat = '01Jun2003'd ;
run ;

proc sql ;
   create table drop_me as
   select *, '30jun2003'd as idat
   from gnu(obs = 10 drop = idat)
   ;

   insert into gnu
   select * from drop_me
   ;

   drop table drop_me
   ;

quit ;

%PullContinuous(InSet                    = gnu
               , OutSet                  = s.pc3_survivors
               , IndexDate               = idat
               , PreIndexEnrolledMonths  = 12
               , PreIndexGapTolerance    = 1
               , PostIndexEnrolledMonths = 16
               , PostIndexGapTolerance   = 2
               , EnrollDset              = s.new_enroll
               ) ;


* This one ran in real time           1:35.33      cpu time            1.54 seconds ;
%PullContinuous2(InSet                   = gnu
               , OutSet                  = s.pc2_survivors
               , IndexDate               = idat
               , PreIndexEnrolledMonths  = 12
               , PreIndexGapTolerance    = 1
               , PostIndexEnrolledMonths = 16
               , PostIndexGapTolerance   = 2
               , EnrollDset              = s.old_enroll
               ) ;

proc sql ;
   create table s.survived_2_butnot_3 as
   select s2.mrn
   from s.pc2_survivors as s2 LEFT JOIN
         s.pc3_survivors as s3
   on    s2.mrn = s3.mrn
   where s3.mrn IS NULL
   ;

   create table s.survived_3_butnot_2 as
   select s3.mrn
   from s.pc2_survivors as s2 RIGHT JOIN
         s.pc3_survivors as s3
   on    s2.mrn = s3.mrn
   where s2.mrn IS NULL
   ;

   create table s.survived_2_butnot_3_enroll3 as
   select e.*
   from  s.new_enroll as e INNER JOIN
         s.survived_2_butnot_3 as p
   on    e.mrn = p.mrn
   order by e.mrn, e.enr_start
   ;
   create table s.survived_2_butnot_3_enroll2 as
   select e.*
   from  s.old_enroll as e INNER JOIN
         s.survived_2_butnot_3 as p
   on    e.mrn = p.mrn
   order by e.mrn, e.enr_year, e.enr_month
   ;
quit ;

*PullContinuous8(InSet                   = s.survived_2_butnot_3
               , OutSet                  = s.drop_me
               , IndexDate               = '01Jun2003'd
               , PreIndexEnrolledMonths  = 12
               , PreIndexGapTolerance    = 1
               , PostIndexEnrolledMonths = 16
               , PostIndexGapTolerance   = 2
               , EnrollDset              = s.survived_2_butnot_3_enroll3
               , DebugOut                = s
               ) ;

