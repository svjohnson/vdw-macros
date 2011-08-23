/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\collapse_periods.sas
*
* <<purpose>>
*********************************************/

%macro CollapsePeriods(Lib          /* Name of the library containing the dset you want collapsed */
                     , DSet         /* Name of the dset you want collapsed. */
                     , RecStart     /* Name of the var that contains the period start dates. */
                     , RecEnd       /* Name of the var that contains the period end dates. */
                     , PersonID  = MRN   /* Name of the var that contains a unique person identifier. */
                     , OutSet = &lib..&dset /* In case you dont want this to overwrite your input dataset, specify another. */
                     , DaysTol = 1  /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                     , Debug   = 0  /* 0/1 flag indicating whether you want the PUT statements to run (PRODUCES A LOT OF OUTPUT!). */
                     ) ;

   %** Takes an input mbhist dataset and collapses contiguous time periods where the variables ;
   %** other than the ones defining period start/stop dates dont change. ;

   %** Adapted from Mark Terjesons code posted to sas-l: http://www.listserv.uga.edu/cgi-bin/wa?A2=ind0003d&L=sas-l&D=0&P=18578 ;

  %** preparing to go to a single inset param. ;
  %local inset ;
  %let inset = &Lib..&Dset ;

   %** This defines VarList ;
   %GetVarList( Dset = &inset
              , RecStart = &RecStart
              , RecEnd = &RecEnd
              , PersonID = &PersonID) ;

   %put VarList is &VarList ;

   %put Length of varlist is %length(&varlist) ;

  %local LastVar ;

   %if %length(&varlist) = 0 %then %do ;
      %let LastVar = &PersonID ;
   %end ;
   %else %do ;
      %let LastVar = %LastWord(&VarList) ;
   %end ;

   proc sort nodupkey data = &inset ;
      by &PersonID &RecStart &VarList &RecEnd ;
   run ;

   data &outset ;
      retain PeriodStart PeriodEnd ;
      format PeriodStart PeriodEnd mmddyy10. ;
      set &inset(rename = (&RecStart = _&RecStart
                                &RecEnd   = _&RecEnd)) ;

      by &PersonID &VarList NOTSORTED ;

      if first.&LastVar then do ;
         ** Start of a new period--initialize. ;
         PeriodStart = _&RecStart ;
         PeriodEnd   = _&RecEnd ;
         %if &Debug = 1 %then %do ;
            put "First &LastVar:          " _N_ = PeriodStart =  _&RecStart =  PeriodEnd =  _&RecEnd = ;
         %end ;
      end ;
       /*
          Checking "contiguousity":
          If this records start date falls w/in (or butts up against) the
          current period (plus tolerance), then extend the current period out to this
          records end date.
       */
       ** if (PeriodStart <= _&RecStart <= PeriodEnd + 1) then do ;
       ** RP20100504: fixing a bug when using a tolerance of zero days. ;
       ** RP20101210: fixing a bug that fails to collapse gaps of exactly &daystol length. ;
       if (PeriodStart <= _&RecStart <= (PeriodEnd +(&DaysTol + 1))) then do ;
          ** Extend the period end out to whichever is longer--the period or the record. ;
          PeriodEnd = max(_&RecEnd, PeriodEnd) ;
          %if &Debug = 1 %then %do ;
             put "Extending period end:   " _N_ = PeriodStart =  _&RecStart =  PeriodEnd =  _&RecEnd = ;
          %end ;
       end ;
       else do ;
          * We are in a new period--output the last rec & reinitialize. ;
          output ;
          PeriodStart = _&RecStart ;
          PeriodEnd   = _&RecEnd ;
       end ;
      /*
         Likewise, if this is our last value of the last var on our BY list, we are about to start a new period.
         Spit out the record--the new period vars get initialized above in the "if first.&LastVar..."
         block.
      */
      if last.&LastVar then do ;
         %if &Debug = 1 %then %do ;
            put "Last &LastVar:           " _N_ = PeriodStart =  _&RecStart =  PeriodEnd =  _&RecEnd = ;
         %end ;
         output ;
      end ;
   run ;
  ** Now we have the actual start/stop dates in PeriodStart & PeriodEnd--rename those to ;
  ** the original record start/stop variable names, and strip out any wacky recs where start comes after end ;
  data &outset ;
    length &RecStart &RecEnd 4 ;
    set &outset(rename = (PeriodStart = &RecStart
                          PeriodEnd   = &RecEnd)) ;
    ** if PeriodStart le PeriodEnd ;
    drop _&RecStart _&RecEnd ;
  run ;
  %** This is obscure, but seems like good hygeine.  Tyler called cp twice, the second time with a dset that had nothing but mrn, start and stop. ;
  %** Looks like the second call did not overwrite the value in varlist, and he got errors about named vars not being present. ;
  %** So now we null out the var to keep that from happening. ;
  %let VarList = ;
%mend CollapsePeriods ;
