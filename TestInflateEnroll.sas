/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\TestInflateEnroll.sas
*
* Tests the InflateEnroll macro.
*
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

* Simulate the enroll environment ;

/*
* Create an enroll v2 file ;
%let BHPGroups       = 29, 44, 45, 46, 66 ;

proc sql ;
   * reset inobs = 1000 nowarn ;
   create table vdw.enroll2 as
   select
        chsid        as MRN
      , startdt      as enr_start format = mmddyy10.
      , enddt        as enr_end   format = mmddyy10.
      , Location     as Location
      , PrimryDr     as PrimryDr
      , PrmCrCln     as PrmCrCln
      , case Medicare       when 1 then 'Y' else ' ' end as INS_Medicare
      , case Medicaid       when 1 then 'Y' else ' ' end as INS_Medicaid
      , case CommercialFlag when 1 then 'Y' else ' ' end as INS_Commercial
      , case PrivatepayFlag when 1 then 'Y' else ' ' end as INS_Privatepay
      , case OtherFlag      when 1 then 'Y' else ' ' end as INS_Other
      , case  when MedMkGrp in (&BHPGroups)  then 'Y' else ' ' end as INS_BasicHealth
   from vdw.enrlseed
   order by mrn, enr_start, enr_end
   ;
   * alter table vdw.enroll2 add constraint enroll2_pk primary key (MRN, enr_start, enr_end) ;
   create index enroll2_ix on vdw.enroll2 (MRN, enr_start) ;
quit ;
*/

%let _EnrollLib = \\ctrhs-sas\Warehouse\Sasdata\CRN_VDW ;
%let _EnrollData = enroll2 ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\InflateEnroll.sas" ;

* Grab a dset of test ppl ;

libname s "\\ctrhs-sas\sasuser\pardre1" ;

%macro MakeTestSample(OutSet, N, Letter) ;

   proc sql outobs = &N nowarn ;
      create table &OutSet as
      select mrn
      from vdw.demog
      where substr(MRN, 3, 1) = '&Letter'
      ;
   quit ;

%mend MakeTestSample ;

%*MakeTestSample(OutSet = s.test_ie, N = 200, Letter = Q) ;

options mprint mlogic ;

%let st = 01Jan2003 ;
%let en = 31Jul2005 ;

%macro MakeDSets ;

%GetInflatedEnroll(InSet      = s.test_ie    /* Name of the dset containing the CHSIDs of the ppl whose ENROLL recs you want. */
               , StartDt      = &st  /* The start of the period over which you want ENROLL recs, e.g., 01Jan1991 */
               , EndDt        = &en /* The end of the period over which you want ENROLL recs, e.g., 30Jun2003 */
               , OutSet       = s.out_ie  /* The name of the output dataset. */
               , MinVars      =  %str('Location', 'PrimryDr', 'PrmCrCln')
               ) ;

* Now pull the corresponding recs from old enroll to see if they are the same. ;
proc sql ;
   create table s.compare_ie as
   select e.*
   from vdw.enroll as e INNER JOIN
         s.test_ie as t
   on    e.MRN = t.MRN
   where mdy(e.enr_month, 1, e.enr_year) between "&st"d and "&en"d ;
quit ;
%mend MakeDSets ;

%makedsets ;

/*

definite difference for the first person: 00Q099DJTQ

first:
where 01jan2003 between s and e OR
      31Jul2005 between s and e


second:
where s between 01jan2003 and 31jul2005 OR
      e between 01jan2003 and 31jul2005

Starts      Stops       first second
07/01/2001	02/28/2003  yes   yes
03/01/2003	07/31/2003  no    yes
08/01/2003	08/31/2004  no    yes
09/01/2004	03/31/2005  no    yes
04/01/2005	08/31/2006  yes   yes


*/

/*

   Another difference for person 00Q7UCL76X.

Starts      Stops       second
06/01/1997	12/31/1997  no
01/01/1998	03/31/1998  no
04/01/1998	04/30/1999  no
06/01/1999	07/31/2000  no
08/01/2000	08/31/2000  no
09/01/2000	09/30/2000  no
10/01/2000	08/31/2005  no
09/01/2005	12/31/2005
01/01/2006	08/31/2006


*/

proc sql noexec ;
   create table s.enr2_raw as
   select *
   from vdw.enroll2
   where MRN = '00Q7UCL76X'
   order by enr_start, enr_end
   ;
quit ;

* proc compare base = s.out_ie compare = s.compare_ie(drop = mainnet) ;


run ;