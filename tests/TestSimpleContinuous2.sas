/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\TestSimpleContinuous2.sas
*
* Investigate a problem w/%sc reported by Sharon Fuller, and hopefully
* serve as a solid test suite going forward.
*
* Period of interest is all of 2003 and 2004, we will allow 90 days gaps.
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%**let macfile = \\ctrhs-sas\Warehouse\Sasdata\CRN_VDW\lib\standard_macros.sas ;  ** <-- Non-updated version. ;
%let macfile = \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas ;  ** <-- Working copy. ;

%include "&macfile" ;

data fake_people ;
  infile datalines truncover ;
  input
    @1  mrn         $char10.
    @11 ce_expected 1.0
    @13 description $char100.
  ;
datalines ;
roy       1 More than continuously enrolled across 2 recs.
sharon    1 Exactly continuously enrolled across 2 recs.
bill      1 More than continuously enrolled in a single rec.
david     1 Enrolled enough, but with an extra pre-POI record w/negative CoveredDays.
bob       0 Not enrolled at all.
virginia  0 One too-long gap.
gene      0 Not enrolled enough on a single rec.
marge     1 Tolerable gaps at the beginning and end of the POI.
jerry     1 Tolerable pre/post gaps + one tolerable middle gap.
;
run ;
data fake_enroll ;
  input
    @1    mrn         $char10.
    @11   enr_start   date9.
    @23   enr_end     date9.
  ;
  format
    enr_: mmddyy10.
  ;
datalines ;
roy       01jan2001   31jan2002
roy       01feb2002   31dec2005
sharon    01jan2003   31jan2003
sharon    01feb2003   31dec2004
virginia  01jan2003   31jan2003
virginia  15may2003   31dec2005
bill      01may2000   31dec2005
gene      01may2000   30sep2004
david     01jan2000   31oct2002
david     01feb2003   31dec2004
marge     01feb2003   30nov2004
jerry     01feb2003   30nov2003
jerry     01feb2004   30nov2004
;
run ;

options mprint ;

%SimpleContinuous(People    = fake_people  /* A dataset of MRNs whose enrollment we are considering. */
                 , StartDt  = 01jan2003    /* A date literal identifying the start of the period of interest. */
                 , EndDt    = 31dec2004    /* A date literal identifying the end of the period of interest. */
                 , DaysTol  = 90    /* The # of days gap between otherwise contiguous periods of enrollment that is tolerable. */
                 , OutSet   = fake_out    /* Name of the desired output dset */
                 , EnrollDset = fake_enroll /* For testing. */
                 ) ;

ods html path = "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\" (URL=NONE)
         body = "TestSimpleContinuous2.html"
         (title = "TestSimpleContinuous2 output")
          ;

  title1 "Using &macfile" ;

  proc sql ;

    create table results as
    select p.mrn, ce_expected, continuouslyenrolled, covereddays, description
    from fake_people as p LEFT JOIN
          fake_out as o
    on    p.mrn = o.mrn
    ;

    title2 "FAILED TESTS!!!" ;
    select *
    from results
    where ce_expected ne continuouslyenrolled
    order by ce_expected, mrn
    ;
    title2 "Passed tests." ;
    select *
    from results
    where ce_expected eq continuouslyenrolled
    order by ce_expected, mrn
    ;

  quit ;

ods html close ;

