/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
*
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\fuzz_dates.sas" ;

/*
libname tf 'c:\deleteme\test_fuzz_dates' ;
libname orig 'C:\DeleteMe\test_fuzz_dates\unfuzzed' ;


data orig.people ;
  input
    @1    mrn         $char8.
    @9    birth_date  date9.
    @19   sex         $char1.
    @21   christmas   date9.
  ;
  format
    birth_date christmas mmddyy10.
  ;
  label
    birth_date = "Date this person was born"
    christmas = "Merry Christmas!"
  ;
datalines ;
roy     30jun1966 m 25dec1975
laurel  05apr1970 f 25dec1975
bill    09dec1942 m 25dec1975
anne    12dec1939 f 25dec1975
;
run ;


data orig.fills ;
  input
    @1    mrn         $char8.
    @9    fill_date   date9.
    @19   drug        $char20.
  ;
  format
    fill_date mmddyy10.
  ;
  label
    fill_date = "Date the indicated prescription was filled"
  ;
datalines ;
roy     30jun1986 crack
roy     29jun1980 aspirin
roy     27jun1981 profollica
roy     25jun1982 aspartame
roy     23jun1983 mailman
roy     21jun1984 johnny walker
roy     19jun1985 johnny walker
roy     17jun1986 schlitz
roy     15jun1987 yellow
roy     13jun1988 tylenol
roy     11jun1989 the purple pill
roy     09jun1990 something
roy     07jun1991 something
mary    05apr2008 crack
tim     09dec1942 crack
tim     12dec1939 crack
;
run ;

data orig.diagnoses ;
  input
    @1    mrn         $char8.
    @9    dx_date     date9.
    @19   diagnosis   $char20.
  ;
  format
    dx_date mmddyy10.
  ;
datalines ;
roy     30jun1966 baldness
roy     29jun1980 baldness
roy     27jun1981 baldness
roy     25jun1982 baldness
roy     23jun1983 baldness
roy     21jun1984 baldness
roy     19jun1985 baldness
bob     17jun1986 athletes foot
bob     15jun1987 athletes foot
bob     13jun1988 athletes foot
bob     11jun1989 athletes foot
roy     09jun1990 still baldness
roy     07jun1991 still baldness
mary    05apr2008 crotchetiness
tim     09dec1942 toenail fungus
tim     12dec1939 toenail fungus
;
run ;

proc sql ;
  describe table dictionary.columns ;
quit ;
*/

data people ;
  set vdw.demog ;
  where substr(mrn, 3, 1) = 'F' ;
  if _n_ le 1000 ;
run ;

options mprint ;

%fuzz_dates(
      inlib       = work      /* libname where your to-be-fuzzed dsets live*/
    , outlib      = s        /* name of the libname where you want the fuzzed dsets */
    , dsets       = people /* a space-delimited list of the dataset(s) whose dates you want fuzzed */
    , XWalk       = xwalk     /* name you want for the xwalk dataset */
    , IdVar       = mrn       /* the id variable in common among the input datasets (which gets removed & replaced by a study_id */
    , datevars    = dx_date birth_date fill_date /* a space-delimited list of the date variables you want fuzzed. Not all date vars are found in all datasets */
    , FuzzDays    = 30       /* minimum number of days to add */
      ) ;

proc freq data = s.xwalk ;
  tables fuzz_days ;
run ;
