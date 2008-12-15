/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\TestPullContinuous2.sas
*
* Tests the %PullContinuous2() macro in the CRN standard macro
* library.
*
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%*include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

*include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\CRN_VDW_MACROS.sas" ;
filename crn_macs  FTP     "CRN_VDW_MACROS.sas"
                   HOST  = "centerforhealthstudies.org"
                   CD    = "/CRNSAS"
                   PASS  = "$blue33volcano#"
                   USER  = "CRNReader" ;

%include crn_macs ;


libname s "c:\deleteme\" ;

/*
   The test call is:
      Index Date:                01-June-2003
      Pre-index enrollment:      12 months
      Pre-index gap tolerance:   1 month
      Post-index enrollment:     16 months
      Post-index gap tolerance:  2 months

      So period of interest runs from June 2002 through Jan 2005.

*/

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

proc sql ;
   alter table test_people add primary key (MRN) ;
   alter table test_enroll add primary key (MRN, enr_year, enr_month) ;
   alter table test_enroll add foreign key (MRN) references test_people ;
quit ;

%PullContinuous2(InSet                   = test_people
               , OutSet                  = survivors
               , IndexDate               = '01Jun2003'd
               , PreIndexEnrolledMonths  = 12
               , PreIndexGapTolerance    = 1
               , PostIndexEnrolledMonths = 16
               , PostIndexGapTolerance   = 2
               , EnrollDset              = test_enroll
               , DebugOut                = s.testy
               ) ;

proc sql ;

   create table killed as
   select *
   from test_people
   except
   select *
   from survivors ;

   title "Killed" ;
   select * from killed ;

   title "Survivors" ;
   select * from survivors ;

   create table failures as
   select *, 'Bogus survivor' as problem from survivors where should_live = 'NO'
   union all
   select *, 'Unjustly killed' from killed where should_live = 'Yes'
   ;
   title "Test Failures" ;
   select * from failures ;
quit ;

