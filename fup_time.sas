%macro GetFollowUpTime(People    /* Dset of MRNs */
               , IndexDate       /* Name of a date var in &People, or else a date literal, marking the start of the follow-up period. */
               , EndDate         /* Name of a date var in &People, or else a complete date literal, marking the end of the period of interest. */
               , GapTolerance    /* Number of months disenrollment to ignore in deciding the disenrollment date. */
               , CallEndDateVar  /* What name should we give the date var that will hold the end of the f/up period? */
               , OutSet          /* The name of the output dataset. */
                 ) ;


   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro GetFollowUpTime V0.80: ;
   %put ;
   %put Creating a dset "&OutSet", which will look just like "&People" except that ;
   %put it will have an additional variable "&CallEndDateVar", which will hold the earliest of ;
   %put date-of-last-enrollment, or &EndDate (or, if the person was not enrolled at all ;
   %put a missing value). ;
   %put ;
   %put THIS IS BETA SOFTWARE--PLEASE SCRUTINIZE THE RESULTS AND REPORT ANY PROBLEMS! ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;


   %* Use this to save interim dsets for later inspection. ;
   %let debuglib = owt. ;
   %*let debuglib = ;

   libname __enroll "&_EnrollLib" access = readonly ;

   proc sql feedback ;

      %* Grab ENROLL recs for our ppl of interest, between &IndexDate and EndDate. ;
      %* This semi-redundant WHERE clause is b/c I want to be able to use an index on ;
      %* enr_year if there is one. ;
      %* The intnx() stuff is to make up for the month-level precision of the EnrollDate. ;
      create table &debuglib._grist as
      select distinct e.MRN
            , &IndexDate                  as idate       format = mmddyy10.
            , &EndDate                    as edate       format = mmddyy10.
            , mdy(enr_month, 1, enr_year) as EnrollDate  format = mmddyy10.
      from __enroll.&_EnrollData as e INNER JOIN
            &People as p
      on    e.MRN = p.MRN
      where e.enr_year between year(&IndexDate) and year(&EndDate) AND
            CALCULATED EnrollDate between intnx('MONTH', &IndexDate, 0, 'BEGINNING')
                                      and intnx('MONTH', &EndDate  , 0, 'END') ;
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

      * For *most* recs we want to eval the difference between this recs EnrollDate, and the one on the last rec. ;
      * We always expect a 1-month gap, so we subtract out the expected gap. ;
      ThisGap = intck("MONTH", _LastDate, EnrollDate) - 1 ;
      EndGap = 0 ;

      * But two rec types are special--firsts and lasts w/in an MRN group. ;
      select ;
         * For first MRN recs, the gap we need to eval is the one from the ;
         * start of the period of interest to the current EnrollDate--so redefine ThisGap. ;
         when (first.MRN) ThisGap = intck("MONTH", IDate, EnrollDate) ;
         * For last MRN recs, we have an additional gap to consider--the one between ;
         * EnrollDate and the end of the period of interest.  So redefine EndGap. ;
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
            For an Interim gap, the f/up time runs from Index to the last EnrollDate prior to the gap.
            For a Trailing gap, the f/up time should run from Index to the last EnrollDate.

            In the next step, we remove records from _grist w/enrolldates on or after
            the one on the earliest gap.

            So--since ppl w/Trailing gaps are actually enrolled on this EnrollDate
            we will bump their enrolldate by one month, so they get credit for being
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
               if ThisGap le (&GapTolerance) then EnrollDate = intnx('MONTH', EnrollDate, 1) ;
            end ;
            otherwise ; * Do nothing! ;
         end ;
         output ;
      end ;

      _LastDate = EnrollDate ;
   run ;


   proc sql ;
      * Dset _gap_ends contains MRN/EDate combos for the *ends* of all impermissible gaps.  Find each persons first such gap. ;
      create table &debuglib._first_gaps as
      select MRN, min(EnrollDate) as EndFirstGap format = mmddyy10.
      from &debuglib._gap_ends
      group by MRN
      ;

      * Remove any recs from grist that are on or after each persons first impermissible gap. ;
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
     * Right now these are firsts-of-the-month.  Should we bump them to lasts? Yes. ;
      create table &debuglib._last_enroll_dates as
      select MRN, intnx('MONTH', max(EnrollDate), 0, 'END') as LastEnrollDate format = mmddyy10.
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
%mend GetFollowUpTime ;
