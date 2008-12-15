%macro LastWord(WordList) ;
   %* This is a helper macro for CollapsePeriods--it just returns the last word (variable name) in a string (var list). ;
   %let i = 0 ;
   %do %until(&ThisWord = ) ;
      %let i = %eval(&i + 1) ;
      %let ThisWord = %scan(&WordList, &i) ;
   %end ;
   %let i = %eval(&i - 1) ;
   %* Note the lack of a semicolon on the next line--thats on purpose! ;
   %scan(&WordList, &i)
%mend LastWord ;

%macro GetVarList(DSet         /* Name of the dset you want collapsed. */
                , RecStart     /* Name of the var that contains the period start dates. */
                , RecEnd       /* Name of the var that contains the period end dates. */
                ) ;

   %* This is also a helper macro for CollapsePeriods--it creates a global macro var ;
   %* containing a list of all vars in the input named dset *other than* the ones that ;
   %* define the start/end of each record. ;

   %* I dont know a good way of passing a return value out of a macro--so this is made global. ;
   %global VarList ;

   /*

   Dictionary.Columns is a dynamically-created dataset, consisting of one row per
   variable per dataset, in all of the currently defined libraries.

   My understanding is that sas will only create this 'table' if you issue
   a query against it.

   There can be ersatz errors caused by the creation of this table when there
   are sql views contained in a defined libname whose source tables
   are not resolvable.

   Dictionary.columns looks like this:

   create table DICTIONARY.COLUMNS
  (
   libname  char(8)     label='Library Name',
   memname  char(32)    label='Member Name',
   memtype  char(8)     label='Member Type',
   name     char(32)    label='Column Name',
   type     char(4)     label='Column Type',
   length   num         label='Column Length',
   npos     num         label='Column Position',
   varnum   num         label='Column Number in Table',
   label    char(256)   label='Column Label',
   format   char(16)    label='Column Format',
   informat char(16)    label='Column Informat',
   idxusage char(9)     label='Column Index Type'
  );

   */

   %* If we got just a one-part dset name for a WORK dataset, add the WORK libname explicitly. ;

   %if %index(&Dset, .) = 0 %then %do ;
      %let Dset = work.&Dset ;
   %end ;

   %*put Dset is &Dset ; ;

   proc sql noprint ;
      * describe table dictionary.columns ;
      select name
      into :VarList separated by ' '
      from dictionary.columns
      where upcase(compress(libname || '.' || memname)) = %upcase("&Dset") AND
            upcase(name) not in (%upcase("&RecStart"), %upcase("&RecEnd")) ;
   quit ;

%mend GetVarList ;

%macro CollapsePeriods(Lib          /* Name of the library containing the dset you want collapsed */
                     , DSet         /* Name of the dset you want collapsed. */
                     , RecStart     /* Name of the var that contains the period start dates. */
                     , RecEnd       /* Name of the var that contains the period end dates. */
                     , DaysTol = 1  /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                     , Debug   = 0  /* 0/1 flag indicating whether you want the PUT statements to run (PRODUCES A LOT OF OUTPUT!). */
                     ) ;

   %* Takes an input mbhist dataset and collapses contiguous time periods where the variables ;
   %* other than the ones defining period start/stop dates dont change. ;

   %* Adapted from Mark Terjesons code posted to sas-l: http://www.listserv.uga.edu/cgi-bin/wa?A2=ind0003d&L=sas-l&D=0&P=18578 ;

   %* This defines VarList ;
   %GetVarList( Dset = &Lib..&Dset
              , RecStart = &RecStart
              , RecEnd = &RecEnd) ;

   %put VarList is &VarList ;

   %let LastVar = %LastWord(&VarList) ;

   proc sort nodupkey data = &Lib..&Dset ;
      by &VarList &RecStart &RecEnd ;
   run ;

   data &Lib..&Dset ;
      retain PeriodStart PeriodEnd ;
      format PeriodStart PeriodEnd mmddyy10. ;
      set &Lib..&Dset(rename = (&RecStart = _&RecStart
                          &RecEnd   = _&RecEnd)) ;
      by &VarList ;

      if first.&LastVar then do ;
         * Start of a new period--initialize. ;
         PeriodStart = _&RecStart ;
         PeriodEnd   = _&RecEnd ;
         %if &Debug = 1 %then %do ;
            put "First &LastVar:          " _N_ = PeriodStart =  _&RecStart =  PeriodEnd =  _&RecEnd = ;
         %end ;
      end ;
      * else do ;
         /*
            Checking "contiguousity":
            If this records start date falls w/in (or butts up against) the
            current period (plus tolerance), then extend the current period out to this
            records end date.
         */
         * if (PeriodStart <= _&RecStart <= PeriodEnd + 1) then do ;
         if (PeriodStart <= _&RecStart <= (PeriodEnd + &DaysTol)) then do ;
            * Extend the period end out to whichever is longer--the period or the record. ;
            PeriodEnd = max(_&RecEnd, PeriodEnd) ;
            %if &Debug = 1 %then %do ;
               put "Extending period end:    " _N_ = PeriodStart =  _&RecStart =  PeriodEnd =  _&RecEnd = ;
            %end ;
         end ;
         else do ;
            * We are in a new period--output the last rec & reinitialize. ;
            output ;
            PeriodStart = _&RecStart ;
            PeriodEnd   = _&RecEnd ;
         end ;
      * end ;
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
   * Now we have the actual start/stop dates in PeriodStart & PeriodEnd--rename those to ;
   * the original record start/stop variable names, and strip out any wacky recs where start comes after end ;
   data &Lib..&Dset ;
      set &Lib..&Dset(rename = (PeriodStart = &RecStart
                          PeriodEnd   = &RecEnd)) ;
      * if PeriodStart le PeriodEnd ;
      drop _&RecStart _&RecEnd ;
   run ;
%mend CollapsePeriods ;


%macro GetFollowUpTime(People    /* Dset of MRNs */
               , IndexDate       /* Name of a date var in &People, or else a
                                    date literal, marking the start of the
                                    follow-up period. */
               , EndDate         /* Name of a date var in &People, or else a
                                    complete date literal, marking the end of
                                    the period of interest. */
               , GapTolerance    /* Number of days disenrollment to ignore in
                                    deciding the disenrollment date. */
               , CallEndDateVar  /* What name should we give the date var that
                                    will hold the end of the f/up period? */
               , OutSet          /* The name of the output dataset. */
               , DebugOut = work           /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
               , EnrollDset = __enroll.&_EnrollData /* Supply your own enroll data if you like. */
                 ) ;

   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro GetFollowUpTime V0.90: ;
   %put ;
   %put Creating a dset "&OutSet", which will look just like "&People" except ;
   %put that it will have an additional variable "&CallEndDateVar", which will ;
   %put hold the earliest of date-of-last-enrollment, or &EndDate (or, if the ;
   %put person was not enrolled at all a missing value). ;
   %put ;
   %put THIS IS BETA SOFTWARE-PLEASE SCRUTINIZE THE RESULTS AND REPORT PROBLEMS;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;


   libname __enroll "&_EnrollLib" access = readonly ;

   proc sql ;
    %* Grab ENROLL recs for our ppl of interest where the periods overlap the period between &IndexDate and EndDate ;
      create table &DebugOut..__enroll as
      select p.mrn
            , e.enr_start
            , e.enr_end
            , &IndexDate as idate format = mmddyy10.
            , &EndDate   as edate format = mmddyy10.
      from  &People as p INNER JOIN
            &EnrollDset as e
      on    p.MRN = e.MRN
      where &IndexDate le e.enr_end AND
            &EndDate   ge e.enr_start
      order by mrn, enr_start
      ;
   quit ;

   * Collapse contiguous periods down. ;
   %CollapsePeriods(Lib      = &DebugOut          /* Name of the library containing the dset you want collapsed */
                  , DSet     = __enroll      /* Name of the dset you want collapsed. */
                  , RecStart = enr_start     /* Name of the var that contains the period start dates. */
                  , RecEnd   = enr_end       /* Name of the var that contains the period end dates. */
                  , DaysTol  = &GapTolerance /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  ) ;

   * The end of contiguous enrollment is enr_end on the rec w/the earliest enr_start ;
   proc sort data = &DebugOut..__enroll out = &DebugOut..__collapsed_enroll ;
      by mrn enr_start ;
   run ;

   proc sort nodupkey data = &DebugOut..__collapsed_enroll out = &DebugOut..__first_periods ;
      by mrn ;
   run ;

   proc sql ;
      create table &OutSet as
      select p.* , min(e.edate, e.enr_end) as &CallEndDateVar format = mmddyy10.
      from  &People as p LEFT JOIN
            &DebugOut..__first_periods as e
      on    p.mrn = e.mrn
      ;
   quit ;

%mend GetFollowUpTime ;

%macro OldVersion(People    /* Dset of MRNs */
               , IndexDate       /* Name of a date var in &People, or else a
                                    date literal, marking the start of the
                                    follow-up period. */
               , EndDate         /* Name of a date var in &People, or else a
                                    complete date literal, marking the end of
                                    the period of interest. */
               , GapTolerance    /* Number of months disenrollment to ignore in
                                    deciding the disenrollment date. */
               , CallEndDateVar  /* What name should we give the date var that
                                    will hold the end of the f/up period? */
               , OutSet          /* The name of the output dataset. */
                 ) ;


   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro GetFollowUpTime V0.80: ;
   %put ;
   %put Creating a dset "&OutSet", which will look just like "&People" except ;
   %put that it will have an additional variable "&CallEndDateVar", which will ;
   %put hold the earliest of date-of-last-enrollment, or &EndDate (or, if the ;
   %put person was not enrolled at all a missing value). ;
   %put ;
   %put THIS IS BETA SOFTWARE-PLEASE SCRUTINIZE THE RESULTS AND REPORT PROBLEMS;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;


   %* Use this to save interim dsets for later inspection. ;
   %*let debuglib = owt. ;
   %let debuglib = ;

   libname __enroll "&_EnrollLib" access = readonly ;

   proc sql ;

    %* Grab ENROLL recs for our ppl of interest, between &IndexDate and EndDate;
    %* This semi-redundant WHERE clause is b/c I want to use an index on;
    %* enr_year if there is one.;
    %* The intnx() makes up for the month-level precision of the EnrollDate;
      create table &debuglib._grist as
      select distinct e.MRN
            , &IndexDate                  as idate       format = mmddyy10.
            , &EndDate                    as edate       format = mmddyy10.
            , mdy(enr_month, 1, enr_year) as EnrollDate  format = mmddyy10.
      from __enroll.&_EnrollData as e INNER JOIN
            &People as p
      on    e.MRN = p.MRN
      where e.enr_year between year(&IndexDate) and year(&EndDate) AND
           CALCULATED EnrollDate between intnx('MONTH',&IndexDate,0,'BEGINNING')
                                     and intnx('MONTH',&EndDate  ,0,'END') ;
   quit ;

   * Who has a gap longer than the tolerance? ;
   proc sort data = &debuglib._grist ;
      by MRN EnrollDate ;
   run ;

   data &debuglib._gap_ends ;
      retain _LastDate . ;
      set &debuglib._grist ;
      by MRN EnrollDate ;

      format _LastDate mmddyy10. ;

      * For *most* recs we want to eval the difference between this recs;
      *   EnrollDate, and the one on the last rec. ;
      * We always expect a 1-month gap, so we subtract out the expected gap. ;
      ThisGap = intck("MONTH", _LastDate, EnrollDate) - 1 ;
      EndGap = 0 ;

      * But two rec types are special--firsts and lasts w/in an MRN group. ;
      select ;
         * For first MRN recs, the gap we need to eval is the one from the ;
         * start of the period of interest to the current EnrollDate
         *   --so redefine ThisGap. ;
         when (first.MRN) ThisGap = intck("MONTH", IDate, EnrollDate) ;
         * For last MRN recs, we have an additional gap to consider;
         *  --the one between ;
         * EnrollDate and the end of the period of interest. So redefine EndGap;
         when (last.MRN)  EndGap = intck("MONTH", EnrollDate, EDate) ;
         otherwise ; * Do nothing! ;
      end ;

      if max(ThisGap, EndGap) gt (&GapTolerance) then do ;
         * Weve got an intolerable gap somewhere. ;
         /*
            There are 3 types of gaps:
               - Leading (gaps between index and first EnrollDate).
               - Interim (gaps entirely embraced by Index and End).
               - Trailing (gaps between EnrollDate and End).

            For a Leading gap, the f/up time should be 0.
            For an Interim gap, the f/up time runs from Index to the last
               EnrollDate prior to the gap.
            For a Trailing gap, the f/up time should run from Index to
               the last EnrollDate.

            In the next step, we remove records from _grist w/enrolldates on or
            after the one on the earliest gap.

            So-since ppl w/Trailing gaps are enrolled on this EnrollDate we will
            bump their enrolldate by one month, so they get credit for being
            enrolled during this month.

         */

         select ;
            when (first.MRN) do ;
               * Its a leading gap--meaning no relevant enrollment hx. ;
               EnrollDate = idate ;
            end ;
            when (last.MRN) do ;
               * Could be either an interim or a trailing gap, or both. ;
               * If *just* a trailing, we need to bump EnrollDate by a month. ;
               if ThisGap le (&GapTolerance)
                 then EnrollDate = intnx('MONTH', EnrollDate, 1) ;
            end ;
            otherwise ; * Do nothing! ;
         end ;
         output ;
      end ;

      _LastDate = EnrollDate ;
   run ;


   proc sql ;
      * Dset _gap_ends contains MRN/EDate combos for the *ends* of all ;
      *   impermissible gaps.  Find each persons first such gap. ;
      create table &debuglib._first_gaps as
      select MRN, min(EnrollDate) as EndFirstGap format = mmddyy10.
      from &debuglib._gap_ends
      group by MRN
      ;

      * Remove any recs from grist that are on or after each persons ;
      *   first impermissible gap. ;
      create table &debuglib._clean_grist as
      select g.MRN, g.EnrollDate
      from  &debuglib._grist as g LEFT JOIN
            &debuglib._first_gaps as f
      on    g.MRN = f.MRN
      where f.MRN IS NULL OR
            g.EnrollDate lt f.EndFirstGap
      ;

      %if %length(&debuglib) = 0 %then drop table &debuglib._grist ; ;
      %if %length(&debuglib) = 0 %then drop table &debuglib._gap_ends ; ;

     * Now find each persons last enrollment date. ;
     * Right now these are firsts-of-the-month.  ;
     *   Should we bump them to lasts? Yes. ;
      create table &debuglib._last_enroll_dates as
      select MRN
           , intnx('MONTH', max(EnrollDate), 0, 'END')
               as LastEnrollDate format = mmddyy10.
      from &debuglib._clean_grist
      group by MRN
      ;

      %if %length(&debuglib) = 0 %then drop table &debuglib._clean_grist ; ;

      %* Finally, write the new var to &People. ;
      create table &OutSet as
      select p.*
           ,  case
                  when l.MRN IS NULL then .
                  else min(&EndDate, LastEnrollDate)
              end as &CallEndDateVar format = mmddyy10.
      from &People as p LEFT JOIN
            &debuglib._last_enroll_dates as l
      on    p.MRN = l.MRN
      ;

      %if %length(&debuglib) = 0 %then drop table &debuglib._first_gaps ; ;
   quit ;

   libname __enroll clear ;
%mend OldVersion ;
