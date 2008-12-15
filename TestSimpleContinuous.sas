/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\TestSimpleContinuous.sas
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

/*
*/
filename crn_macs  FTP     "CRN_VDW_MACROS.sas"
                   HOST  = "centerforhealthstudies.org"
                   CD    = "/CRNSAS"
                   PASS  = "%1thunder#dog"
                   USER  = "CRNReader" ;


* filename crn_macs  "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\CRN_VDW_MACROS.sas" ;
%include crn_macs ;


%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\SimpleContinuous.sas" ;

%macro GetTestSample(N = 2000, Letter = Q, OutSet = TestPeople) ;
   proc sql outobs = &n nowarn ;
      create table &OutSet as
      select mrn
      from vdw.demog
      where substr(mrn, 3, 1) = "&Letter"
      ;
   quit ;
%mend GetTestSample ;

%GetTestSample(Letter = V) ;

* was 282 when daystol was 30 ;

%SimpleContinuous(People    = TestPeople           /* A dataset of MRNs whose enrollment we are considering. */
                  , StartDt = 01jan2006            /* A date literal identifying the start of the period of interest. */
                  , EndDt   = 31dec2006            /* A date literal identifying the end of the period of interest. */
                  , DaysTol = 90                   /* The # of days gap between otherwise contiguous periods of enrollment that is tolerable. */
                  , OutSet  = TestPeopleEnroll     /* Name of the desired output dset */
                  ) ;

proc freq data = TestPeopleEnroll ;
   tables CoveredDays * ContinuouslyEnrolled / list missing format = comma20. ;
run ;
