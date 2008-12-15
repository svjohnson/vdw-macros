/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\NewPullContinuous.sas
*
* A %pullcontinuous() for the start/stop version of ENROLL.
*********************************************/

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
   %GetVarList( Dset = &Dset
              , RecStart = &RecStart
              , RecEnd = &RecEnd) ;

   %put VarList is &VarList ;

   %let LastVar = %LastWord(&VarList) ;

   proc sort nodupkey data = &Dset ;
      by &VarList &RecStart &RecEnd ;
   run ;

   data &Dset ;
      retain PeriodStart PeriodEnd ;
      format PeriodStart PeriodEnd mmddyy10. ;
      set &Dset(rename = (&RecStart = _&RecStart
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
   data &Dset ;
      set &Dset(rename = (PeriodStart = &RecStart
                          PeriodEnd   = &RecEnd)) ;
      * if PeriodStart le PeriodEnd ;
      drop _&RecStart _&RecEnd ;
   run ;
%mend CollapsePeriods ;

%macro ExplodeEnrollData(InSet
                        , OutSet
                        , StartDate = "01jan1900"d
                        , EndDate   = "31dec9999"d) ;
   data &OutSet ;
      set &InSet ;
      period_start = max(enr_start, &StartDate) ;
      period_end   = min(enr_end, &EndDate) ;
      do i = 0 to intck('MONTH', period_start, period_end) ;
         enr_date = intnx('MONTH', period_start, i, 'MIDDLE') ;
         enr_month = month(enr_date) ;
         enr_year = year(enr_date) ;
         output ;
      end ;
      format enr_date mmddyy10. ;
      drop i period_start period_end ;
   run ;

%mend ExplodeEnrollData ;

%macro PullContinuous4(InSet                     /* The name of the input dataset of MRNs of the ppl whose enrollment you want to check. */
                     , OutSet                    /* The name of the output dataset of only the continuously enrolled people. */
                     , IndexDate                 /* Either the name of a date variable in InSet, or, a complete date literal (e.g., "01Jan2005"d) */
                     , PreIndexEnrolledMonths    /* The # of months of enrollment required prior to the index date. */
                     , PreIndexGapTolerance      /* The length of enrollment gaps you consider to be ignorable for pre-index date enrollment. */
                     , PostIndexEnrolledMonths   /* The # of months of enrollment required post index date. */
                     , PostIndexGapTolerance     /* The length of enrollment gaps you consider to be ignorable for post-index date enrollment.*/
                     , DebugOut = work           /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
                     , EnrollDset = __enroll.&_EnrollData /* For testing. */
                     ) ;

   /*

      Divide and conquer.

      First, ID the set of people w/no more than max(:GapTolerance) gaps between the period between
         (IndexDate - PreIndexEnrolledMonths) and (IndexDate + PostIndexEnrolledMonths).
      Those folks definitely go in OutSet.

      For the remaining, explode the enroll data into pm/pm structure & pass
      it to PullContinuous2.


   */

   libname __enroll "&_EnrollLib" access = readonly ;

   proc sql ;
      create table __ids as
      select distinct mrn
         , intnx('MONTH', &IndexDate, -&PreIndexEnrolledMonths, 'BEGINNING')  as earliest format = mmddyy10.
         , intnx('MONTH', &IndexDate,  &PostIndexEnrolledMonths, 'END')       as latest   format = mmddyy10.
         , (CALCULATED latest - CALCULATED earliest) + 1 as total_days_desired
      from &InSet
      ;

      * Make sure we only have one record per MRN. ;
      create table __drop_me as
      select mrn, count(*) as appears_num_times
      from __ids
      group by mrn
      having count(*) > 1 ;

      %if &sqlobs > 0 %then %do ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ERROR: &SQLOBS MRNs appear more than once in the input datset! ;
         %PUT ERROR: &SQLOBS MRNs appear more than once in the input datset! ;
         %PUT ERROR: &SQLOBS MRNs appear more than once in the input datset! ;
         %PUT ;
         %PUT See the .lst file for a list of duplicated MRNs ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         select * from __drop_me ;
         %abort return ;
      %end ;

      drop table __drop_me ;

      * Grab out the enroll records that could possibly contribute to the period of interest. ;
      create table __enroll as
      select i.mrn, i.earliest, i.latest, i.total_days_desired, e.enr_start, e.enr_end
      from  __ids as i INNER JOIN
            &EnrollDset as e
      on    i.MRN = e.MRN
      where i.earliest le e.enr_end AND
            i.latest   ge e.enr_start
      ;
   quit ;

   * The tolerances given in this macro are in months--convert those to days for the call to CollapsePeriods. ;
   * Lets be conservative at this stage--all months are 29 days long. ;

   %let days_per_month = 29 ;

   %if &PreIndexGapTolerance > &PostIndexGapTolerance %then %do ;
      %let tolerance_in_days = %eval(&days_per_month * &PreIndexGapTolerance) ;
   %end ;
   %else %do ;
      %let tolerance_in_days = %eval(&days_per_month * &PostIndexGapTolerance) ;
   %end ;

   %CollapsePeriods(Lib       = work      /* Name of the library containing the dset you want collapsed */
                  , DSet      = __enroll  /* Name of the dset you want collapsed. */
                  , RecStart  = enr_start   /* Name of the var that contains the period start dates. */
                  , RecEnd    = enr_end     /* Name of the var that contains the period end dates. */
                  , DaysTol   = &tolerance_in_days    /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  ) ;

   * Now that we have spackled over any minimal gaps, compare the # of days enrolled per period ;
   proc sql ;

      create table __enroll_with_covered_days as
      select   *
            , (min(latest, enr_end) - max(earliest, enr_start)) + 1 as CoveredDays
            , (CALCULATED CoveredDays = total_days_desired) as ContinuouslyEnrolled
      from __enroll
      ;

      * select * from gnu ;

      create table __continuously_enrolled as
      select MRN
      from &InSet
      where MRN in (select MRN from __enroll_with_covered_days where ContinuouslyEnrolled = 1)
      ;

      delete from __enroll
      where MRN in (select MRN from __enroll_with_covered_days where ContinuouslyEnrolled = 1)
      ;

      drop table __enroll_with_covered_days ;

   quit ;

   %ExplodeEnrollData(InSet = __enroll
                   , OutSet = __exploded
                   , StartDate = earliest
                   , EndDate = latest
                   ) ;


   proc sql ;
      drop table __enroll ;
   quit ;

   * Now we feed the exploded dataset to the old version of pullcontinuous. ;
   %PullContinuous2(   InSet                   = &InSet                    /* The name of the input dataset of MRNs of the ppl whose enrollment you want to check. */
                     , OutSet                  = __pc2_out                   /* The name of the output dataset of only the continuously enrolled people. */
                     , IndexDate               = &IndexDate                /* Either the name of a date variable in InSet, or, a complete date literal (e.g., "01Jan2005"d) */
                     , PreIndexEnrolledMonths  = &PreIndexEnrolledMonths   /* The # of months of enrollment required prior to the index date. */
                     , PreIndexGapTolerance    = &PreIndexGapTolerance     /* The length of enrollment gaps you consider to be ignorable for pre-index date enrollment. */
                     , PostIndexEnrolledMonths = &PostIndexEnrolledMonths  /* The # of months of enrollment required post index date. */
                     , PostIndexGapTolerance   = &PostIndexGapTolerance    /* The length of enrollment gaps you consider to be ignorable for post-index date enrollment.*/
                     , DebugOut                = &DebugOut          /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
                     , EnrollDset              = __exploded /* For testing. */
                     ) ;

   proc sql ;
      drop table __exploded ;

      insert into __continuously_enrolled (mrn)
      select mrn
      from __pc2_out ;

      drop table __pc2_out ;

      create table &OutSet as
      select *
      from &InSet
      where mrn in (select mrn from __continuously_enrolled) ;

      drop table __continuously_enrolled ;

   quit ;

%mend PullContinuous4 ;

%macro PullContinuous8(InSet                     /* The name of the input dataset of MRNs of the ppl whose enrollment you want to check. */
                     , OutSet                    /* The name of the output dataset of only the continuously enrolled people. */
                     , IndexDate                 /* Either the name of a date variable in InSet, or, a complete date literal (e.g., "01Jan2005"d) */
                     , PreIndexEnrolledMonths    /* The # of months of enrollment required prior to the index date. */
                     , PreIndexGapTolerance      /* The length of enrollment gaps you consider to be ignorable for pre-index date enrollment. */
                     , PostIndexEnrolledMonths   /* The # of months of enrollment required post index date. */
                     , PostIndexGapTolerance     /* The length of enrollment gaps you consider to be ignorable for post-index date enrollment.*/
                     , DebugOut = work           /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
                     , EnrollDset = __enroll.&_EnrollData /* For testing. */
                     ) ;

   %* Validate the arguments. ;
   %if &PreIndexGapTolerance > &PreIndexEnrolledMonths %then %do ;
      %put WARNING: Pre-index gap tolerance cannot be greater than the number;
      %put WARNING: of months of desired pre-index enrollment.;

      %let PreIndexGapTolerance = %eval(&PreIndexEnrolledMonths - 1) ;
      %put Setting the pre-index gap tolerance to &PreIndexGapTolerance ;
   %end ;

   %if &PostIndexGapTolerance > &PostIndexEnrolledMonths %then %do ;
      %put WARNING: Post-index gap tolerance cannot be greater than the number;
      %put WARNING: of months of desired Post-index enrollment.;

      %let PostIndexGapTolerance = %eval(&PostIndexEnrolledMonths - 1) ;
      %put Setting the Post-index gap tolerance to &PostIndexGapTolerance ;
   %end ;


   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro PullContinuous: ;
   %put ;
   %put Creating a dataset "&OutSet", which will look exactly like            ;
   %put dataset "&InSet", except that anyone not enrolled for                 ;
   %put &PreIndexEnrolledMonths months prior to &IndexDate (disregarding gaps ;
   %put of up to &PreIndexGapTolerance month(s)) AND &PostIndexEnrolledMonths ;
   %put months after &IndexDate (disregarding gaps of up to                   ;
   %put &PostIndexGapTolerance month(s)) will be eliminated.                  ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;

   libname __enroll "&_EnrollLib" access = readonly ;

   proc sql ;
      * Table of unique MRNs and the dates setting out the period of interest (earliest & latest). ;
      create table __ids as
      select distinct mrn
         , &IndexDate                                                         as idate    format = mmddyy10.
         , intnx('MONTH', &IndexDate, -&PreIndexEnrolledMonths, 'BEGINNING')  as earliest format = mmddyy10.
         , intnx('MONTH', &IndexDate,  &PostIndexEnrolledMonths, 'END')       as latest   format = mmddyy10.
      from &InSet
      ;

      * Make sure we only have one record per MRN. ;
      create table __drop_me as
      select mrn, count(* ) as appears_num_times
      from __ids
      group by mrn
      having count(*) > 1 ;

      %if &sqlobs > 0 %then %do ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ERROR: &SQLOBS MRNs appear more than once in the input datset with different index dates! ;
         %PUT ERROR: &SQLOBS MRNs appear more than once in the input datset with different index dates! ;
         %PUT ERROR: &SQLOBS MRNs appear more than once in the input datset with different index dates! ;
         %PUT ;
         %PUT See the .lst file for a list of duplicated MRNs ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         %PUT ;
         reset outobs = 20 nowarn ;
         select * from __drop_me ;
         %abort return ;
      %end ;

      reset outobs = max ;

      drop table __drop_me ;

      * Grab out the enroll records that could possibly contribute to the period of interest. ;
      create table __enroll as
      select i.mrn, i.earliest, i.latest, i.idate, e.enr_start, e.enr_end
      from  __ids as i INNER JOIN
            &EnrollDset as e
      on    i.MRN = e.MRN
      where i.earliest le e.enr_end AND
            i.latest   ge e.enr_start
      order by mrn, enr_start
      ;

      * Anybody w/no recs in __enroll could not possibly have been sufficiently enrolled. ;
      create table __not_enrolled as
      select i.mrn
      from __ids as i LEFT JOIN
            __enroll as e
      on    i.mrn = e.mrn
      where e.mrn IS NULL ;
   quit ;

   * Now we loop through the enroll records looking for gaps. ;
   * There are 3 places where gaps can occur--before the start of enrollment, ;
   * in the middle of enrollment (inter-record), and past the end of enrollment. ;
   * First records for a person can only have before-enrollment gaps.  Middle records ;
   * can only have an inter-record gap.  But Last records can have either or ;
   * both an inter and a post-enrollment gap. ;
   data &debugout..__insufficiently_enrolled ;
      retain _last_end . ;
      length reason $ 4 pre_gap_length post_gap_length 4 ;
      set __enroll ;
      by mrn ;
      num_possible_gaps = 1 ;
      if first.mrn then do ;
         * Earliest period for this person--there may be a gap between earliest & enr_start. ;
         possible_gap_start1 = earliest ;
         possible_gap_end1   = enr_start ;
      end ;
      else do ;
         * Middle or last rec--maybe an inter-record gap. ;
         possible_gap_start1 = _last_end ;
         possible_gap_end1   = enr_start ;
      end ;
      if last.mrn then do ;
         * Last period--may be a gap between end and latest. ;
         possible_gap_start2 = enr_end ;
         possible_gap_end2 = latest ;
         num_possible_gaps = 2 ;
      end ;

      array starts{2} possible_gap_start: ;
      array ends{2}   possible_gap_end: ;
      * Loop through the 2 possible gaps, outputting anybody w/an out of tolerance gap. ;
      do i = 1 to num_possible_gaps ;
         * We knock 1 off the number of months b/c we expect at least one month gap between contiguous periods. ;
         * No we dont. ;
         this_gap = intck('MONTH', starts{i}, ends{i}) ;

         if this_gap > 0 then do ;
            /*
               We have an actual gap.  There are 3 possibilities.
                  - The whole gap falls before the index date (possible_gap_end lt idate).
                  - The whole gap falls after the index date (possible_gap_start gt idate).
                  - The gap straddles the index date.
            */
            if ends{i} lt idate then do ;
               pre_gap_length = this_gap ;
               post_gap_length = 0 ;
            end ;
            else if starts{i} gt idate then do ;
               pre_gap_length = 0 ;
               post_gap_length = this_gap ;
            end ;
            else do ;   * Straddle gap--idate falls between gap start & gap end. ;
               pre_gap_length  = intck('MONTH', starts{i}, idate) ;
               post_gap_length = intck('MONTH', idate, ends{i})   ;
            end ;

         end ;

         if (pre_gap_length > &PreIndexGapTolerance) then do ;
            reason = 'pre' ;
            output ;
         end ;
         else if (post_gap_length > &PostIndexGapTolerance) then do ;
            reason = 'post' ;
            output ;
         end ;

      end ;
      * if mrn = '00LLKURRP7' then output ;
      _last_end = enr_end + 1 ;
      format _last_end possible_gap_start: possible_gap_end: mmddyy10. ;
   run ;

   proc sql ;
      create table &OutSet as
      select * from &InSet
      where mrn not in (select mrn from &debugout..__insufficiently_enrolled
                        UNION ALL
                        select mrn from __not_enrolled) ;
      drop table __enroll ;
      drop table __not_enrolled ;
   quit ;

%mend PullContinuous8 ;

%macro didnt_work(InSet                     /* The name of the input dataset of MRNs of the ppl whose enrollment you want to check. */
                     , OutSet                    /* The name of the output dataset of only the continuously enrolled people. */
                     , IndexDate                 /* Either the name of a date variable in InSet, or, a complete date literal (e.g., "01Jan2005"d) */
                     , PreIndexEnrolledMonths    /* The # of months of enrollment required prior to the index date. */
                     , PreIndexGapTolerance      /* The length of enrollment gaps you consider to be ignorable for pre-index date enrollment. */
                     , PostIndexEnrolledMonths   /* The # of months of enrollment required post index date. */
                     , PostIndexGapTolerance     /* The length of enrollment gaps you consider to be ignorable for post-index date enrollment.*/
                     , DebugOut = work           /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
                     , EnrollDset = __enroll.&_EnrollData /* For testing. */
                     ) ;


/*
   All we really need is mrn, index date, startdate & enddate.
   Call %collapseperiods w/just those vars?

   For each person
      early_date = index_date - (PreIndexEnrolledMonths - PreIndexGapTolerance)
      late_date = index_date + (PostIndexEnrolledMonths - PostIndexGapTolerance)

   Lots of ppl will have a single record that covers the whole period--they are an easy case.

   where (early_date between enr_start and enr_end) AND
         (late_date between enr_start and enr_end)

   For other records, we total up the gap months:
      The difference between early_date and enr_start (if > 0).
      The difference between enr_end and late_date (if > 0).

   To pull &EnrollDset records that could possibly contribute to the period of interest:

   where early_date between enr_start and enr_end or
         late_date  between enr_start and enr_end

   This doesnt work b/c it ignores the inter-record gaps.  The call to %collapsperiods()
   closes up 1-day gaps, but there may well still be longer inter-record gaps that
   are still w/in tolerance.  I could bump the tolerance figures in the call to %collapseperiods
   for that, but if I am going to allow for different tolerances before and after the
   index date, I would have to treat the before and after index periods differently--somehow
   partition the enroll records (breaking on index date) and call %cp twice, once for each
   period w/each tolerance.

   Test for a positive inter-record gap (enr_start - _LastEnd).  The gap is the period between _LastEnd and enr_start.
   3 scenarios:
      1) Completely pre-index (enr_start lt index_dt)
      2) Completely post-index ( index_dt lt _LastEnd) (This cant actually happen, can it?)
      3) Straddle (index_dt between _LastEnd and enr_start).



*/

   %* Validate the arguments. ;
   %if &PreIndexGapTolerance > &PreIndexEnrolledMonths %then %do ;
      %put WARNING: Pre-index gap tolerance cannot be greater than the number of months of desired pre-index enrollment. ;
      %let PreIndexGapTolerance = %eval(&PreIndexEnrolledMonths - 1) ;
      %put Setting the pre-index gap tolerance to &PreIndexGapTolerance ;
   %end ;

   %if &PostIndexGapTolerance > &PostIndexEnrolledMonths %then %do ;
      %put WARNING: Post-index gap tolerance cannot be greater than the number of months of desired Post-index enrollment. ;
      %let PostIndexGapTolerance = %eval(&PostIndexEnrolledMonths - 1) ;
      %put Setting the Post-index gap tolerance to &PostIndexGapTolerance ;
   %end ;


   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro PullContinuous3: ;
   %put ;
   %put Creating a dataset "&OutSet", which will look exactly like  ;
   %put dataset "&InSet", except that anyone not enrolled for &PreIndexEnrolledMonths ;
   %put months prior to &IndexDate (disregarding gaps of up to &PreIndexGapTolerance month(s)) AND ;
   %put &PostIndexEnrolledMonths months after &IndexDate (disregarding gaps of up to &PostIndexGapTolerance month(s)) will;
   %put be eliminated.;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;

   %* We only need our peoples enroll recs over the period from (IndexDate - (PreIndexEnrolledMonths + PreIndexGapTolerance))
   %* to                                                        (IndexDate + (PostIndexEnrolledMonths + PostIndexGapTolerance). ;
   %* These vars simplify the expressions a bit... ;
   %let PreMonthCount  = %eval(&PreIndexEnrolledMonths  + &PreIndexGapTolerance)  ;
   %let PostMonthCount = %eval(&PostIndexEnrolledMonths + &PostIndexGapTolerance) ;

   libname __enroll "&_EnrollLib" access = readonly ;

   proc sql ;
      create table &DebugOut..__thisenrl as
      select distinct i.MRN
            , e.enr_start                                               format = mmddyy10.
            , e.enr_end                                                 format = mmddyy10.
            , &IndexDate                                  as IDate      format = mmddyy10.
            , intnx("MONTH", &IndexDate, -&PreMonthCount) as early_date format = mmddyy10.
            , intnx("MONTH", &IndexDate, &PostMonthCount) as late_date  format = mmddyy10.
      from  &InSet as i LEFT JOIN
            &EnrollDset as e
      on    i.MRN = e.MRN
      WHERE calculated early_date between enr_start and enr_end OR
            calculated late_date  between enr_start and enr_end
      order by i.MRN, e.enr_start
      ;
   quit ;

   * In order to properly count gaps, I have to be able to assume that the records are absolutely contiguous. ;
   %CollapsePeriods(DSet    = &DebugOut..__thisenrl     /* Name of the dset you want collapsed. */
                  , RecStart= enr_start     /* Name of the var that contains the period start dates. */
                  , RecEnd  = enr_end     /* Name of the var that contains the period end dates. */
                  ) ;

   data &DebugOut..__gapstats ;
      length num_pre_gaps num_post_gaps dur_pre_gaps dur_post_gaps 4 ;
      set &DebugOut..__thisenrl ;
      by mrn ;
      if first.mrn then do ;
         num_pre_gaps  = 0 ;
         num_post_gaps = 0 ;
         dur_pre_gaps  = 0 ;
         dur_post_gaps = 0 ;
      end ;
      * Test for gaps.  Count number and aggregate durations (months). ;
      * Pre-index ;
      if early_date lt enr_start then do ;
         num_pre_gaps + 1 ;
         * Is this right?  I think it will consider a duration of 1 day = 1 month if they fall in different months. ;
         dur_pre_gaps + intck("MONTH", early_date, enr_start) ;
      end ;
      * Post-index ;
      if enr_end lt late_date then do ;
         num_post_gaps + 1 ;
         dur_post_gaps + intck("MONTH", enr_end, late_date) ;
      end ;
      if last.mrn then output ;
   run ;

   proc sql ;
      create table &DebugOut..__nogoodniks as
      select mrn
      from &DebugOut..__gapstats
      where dur_post_gaps gt &PostIndexGapTolerance OR
            dur_pre_gaps  gt &PreIndexGapTolerance
      ;
      create table &OutSet as
      select *
      from &InSet
      where MRN not in (select MRN from &DebugOut..__nogoodniks) ;
   quit ;

   libname __enroll clear ;

%mend didnt_work ;
