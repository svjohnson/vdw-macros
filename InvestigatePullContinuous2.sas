/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\InvestigatePullContinuous2.sas
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

libname s "\\CTRHS-SAS\SASUser\pardre1" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\CRN_VDW_MACROS.sas" ;

/*

   These 2 calls do not currently give the same results, and they should.

%PullContinuous2(InSet                   = possibles
               , OutSet                  = test.enrolled
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 0
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;

%PullContinuous2(InSet                   = possibles
               , OutSet                  = test.enrolled
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 1000
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;

*/




/*
%PullContinuous2(InSet                   = s.possibles
               , OutSet                  = s.new_pc2_results
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 0
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;


The last version of the code returned 399,997 people.
This new version returns              407,282 people.

Everyone who made through the old version is also in the new version.

So drill-down on the newbies--do they deserve to be here?

NO--looks like these are all ppl w/periods prior to index date,
which periods end exactly one month after the index date.

So--add a test case to TestPullContinuous2.sas & see if I can
get it to fail.  Done--fails.  Fixed--and no new failures.  So run
on the whole group again.

Done--and now we get the same 399,997 people from both runs.
*/

proc sql ;
   create table s.unique_to_new as
   select n.mrn
   from  s.new_pc2_results as n LEFT JOIN
         s.old_pc2_results as o
   on    n.mrn = o.mrn
   where o.mrn IS NULL ;

   create table s.unique_to_old as
   select o.MRN
   from s.old_pc2_results as o LEFT JOIN
         s.new_pc2_results as n
   on    o.mrn = n.mrn
   where n.mrn IS NULL ;
quit ;

/*
proc sql outobs = 10 nowarn ;
   create table testies as
   select mrn
   from s.unique_to_new
   order by uniform(123) ;

   reset outobs = max ;

   create table s.raw_enroll as
   select e.mrn
         , mdy(enr_month, 1, enr_year) as enrdate format = mmddyy10.
         , '01Jul2003'd as IndexDate format = mmddyy10.
         , intck('MONTH', calculated IndexDate, calculated EnrDate) as MonthNum
   from vdw.enroll as e INNER JOIN
         testies as t
   on    e.mrn = t.mrn
   where e.enr_year between 2003 and 2005
   order by mrn, enr_year, enr_month
   ;

quit ;

*/


/*
proc sql ;
   create table s.possibles as
   select distinct MRN
   from vdw.enroll
   where enr_year ge 2003
   ;
quit ;
%PullContinuous2(InSet                   = s.possibles
               , OutSet                  = s.normal
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 0
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;

%PullContinuous2(InSet                   = s.possibles
               , OutSet                  = s.weird
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 1000
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;

proc sql ;
   create table s.in_normal_but_not_weird as
   select n.*
   from  s.normal as n LEFT JOIN
         s.weird as w
   on    n.MRN = w.MRN
   where w.MRN IS NULL
   ;

   reset exec ;

   create table s.in_weird_but_not_normal as
   select w.*
   from  s.normal as n RIGHT JOIN
         s.weird as w
   on    n.MRN = w.MRN
   where n.MRN IS NULL
   ;
quit ;

/*

   The pregap = 1000 run gives 456,600 people
   The pregap = 0    run gives 407,763 people
   There are 50,724 people in 1000 that don't also appear in 0.
   There are 1,887  people in 0    that don't also appear in 1000.


* Step 1--look at the smaller group. ;
proc sql ;

   reset noexec ;

   delete from s.in_normal_but_not_weird
   where MRN not in (select MRN from s.normal_rejects)
   ;

   create table s.nnw_raw as
   select e.MRN
         , mdy(enr_month, 1, enr_year) as EnrDate format = mmddyy10.
         , '01Jul2003'd as IndexDate format = mmddyy10.
         , intck('MONTH', calculated IndexDate, calculated EnrDate) as MonthNum
   from  s.in_normal_but_not_weird as t INNER JOIN
         vdw.enroll as e
   on    e.MRN = t.MRN
   where calculated enrdate ge calculated indexdate AND
         calculated MonthNum le 24
   order by e.MRN, e.enr_year, e.enr_month
   ;

   * reset exec ;

   create table s.nnw_counts as
   select mrn, count(*) as num_months
   from s.nnw_raw
   group by mrn
   order by 2 desc
   ;

   select num_months, count(*) as freq
   from s.nnw_counts
   group by num_months ;

*/

   /*

      This gives:

      num_months      freq
      --------------------
              24       687
              23       810
              22       113
              21        49
              20        10


   */


/*
   create table s.drop_me as
   select r.*
   from s.nnw_raw as r INNER JOIN
         s.nnw_counts as c
   on    r.mrn = c.mrn
   where c.num_months le 21
   order by r.mrn, r.enrdate
   ;

quit ;

data s.drop_me ;
   retain _lastdate . ;
   set s.drop_me ;
   by mrn enrdate ;

   if first.mrn then do ;
      gap = 0 ;
   end ;
   else do ;
      gap = intck("MONTH", _LastDate, enrdate) ;
   end ;

   _lastdate = enrdate ;
   format _lastdate mmddyy10. ;
run ;

/*
   Theory: There is an order effect happening, whereby depending on where a persons data lie
   in the input dset (or in ENROLL) allows some of the data to be missed.

   DISPROVED!  All the same MRNs come through a second time.

   New Theory: the problem is particular to recs where there is only a single record during the period of interest.

   Yes--thats it.  I test for first.mrn and last.mrn in a SELECT block, the nature of which is to execute the first branch
   that tests true, and *only* that branch.  For these recs first.mrn is true, and so the ThisGap var is the gap between
   this rec and the start of the period of interest.  But the last.mrn branch is never traveled, and so EndGap is
   not getting set properly.

data gnu ;
   set s.nnw_counts ;
   * where num_months = 1 ;
   keep mrn ;
run ;

%PullContinuous2(InSet                   = gnu
               , OutSet                  = s.normal_rejects
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 0
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;

run ;
*/

/*


*Step 2: Look at the larger group. ;
proc sql noexec ;

   reset outobs = 10 nowarn ;

   create table test as
   select mrn, uniform(0)
   from   s.in_weird_but_not_normal
   ;

   reset outobs = max ;

   create table s.wnn_raw as
   select e.MRN
         , mdy(enr_month, 1, enr_year) as EnrDate format = mmddyy10.
         , '01Jul2003'd as IndexDate format = mmddyy10.
         , intck('MONTH', calculated IndexDate, calculated EnrDate) as MonthNum
   from  test as t INNER JOIN
         vdw.enroll as e
   on    e.MRN = t.MRN
   order by e.MRN, e.enr_year, e.enr_month
   ;

*/
/*

   Okay, the pattern seems to be that people w/large pre-index
   gaps and *no* post-index enrollment are getting in.  Lets re-run
   on a small group and see what the log looks like.

   And the operative problem is that gaps that cross the index are evaluated as pre-index
   gaps.  "This is just an arbitrary decision", say the comments in the program.

   The quick fix is to validate the macro parameter values to disallow gap tolerances
   greater than the desired number of enrolled months.  That will almost surely fix this
   problem.


   Okay--tried that--it does indeed fix the problem.  But do we want to elaborate the macro
   so that it evals the pre- and post- parts of the gap independantly?  That would probably
   be more in line w/user expectations.

   reset exec ;

   create table test as
   select distinct mrn
   from s.wnn_raw
   ;

quit ;

%PullContinuous2(InSet                   = test
               , OutSet                  = s.weird_rejects
               , IndexDate               = '01Jul2003'd
               , PreIndexEnrolledMonths  = 0
               , PreIndexGapTolerance    = 1000
               , PostIndexEnrolledMonths = 24
               , PostIndexGapTolerance   = 2
               ) ;

*/
