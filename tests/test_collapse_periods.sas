/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_collapse_periods.sas
*
* <<purpose>>
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  sastrace = ',,,d'
  sastraceloc = saslog nostsuffix
  dsoptions="note2err" NOSQLREMERGE
;

%include "c:\Documents and Settings\pardre1\My Documents\vdw\macros\collapse_periods.sas" ;

data gnu ;
   input
      @1    consumno    $char8.
      @10   mbheffdt    date9.
      @22   mbhtrmdt    date9.
      @34   pccplus     $char1.
   ;
   format
      mbh: mmddyy10. ;
   ;
datalines ;
roy      01jan2000   31aug2000   A
roy      01sep2000   30sep2000   B
roy      01oct2000   31dec2000   A
roy      01jan2001   30jun2007   A
;
run ;

proc print data = gnu ;
title "Original dset" ;
run ;

%CollapsePeriods(Lib      = work    /* Name of the library containing the dset you want collapsed */
               , DSet     = gnu    /* Name of the dset you want collapsed. */
               , RecStart = mbheffdt    /* Name of the var that contains the period start dates. */
               , RecEnd   = mbhtrmdt     /* Name of the var that contains the period end dates. */
               , PersonID = consumno
               , DaysTol  = 32  /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
               , Debug    = 1  /* 0/1 flag indicating whether you want the PUT statements to run (PRODUCES A LOT OF OUTPUT!). */
               ) ;

proc print data = gnu ;
   title "Collapsed" ;
run ;

proc contents data = gnu ;
run ;

/*
proc print data = gnu ;
title "Original dset" ;
run ;

proc contents data = gnu ;
run ;
*/
