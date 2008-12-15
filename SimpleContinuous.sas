/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\SimpleContinuous.sas
*
* A simple macro to evaluate whether a group of people were
* continuously enrolled over a period of interest.
* Motivated by a desire for a simpler macro than VDWs
* PullContinuous().
*********************************************/

%macro SimpleContinuous(People      /* A dataset of MRNs whose enrollment we are considering. */
                     , StartDt      /* A date literal identifying the start of the period of interest. */
                     , EndDt        /* A date literal identifying the end of the period of interest. */
                     , DaysTol      /* The # of days gap between otherwise contiguous periods of enrollment that is tolerable. */
                     , OutSet       /* Name of the desired output dset */
                     , EnrollDset = __enroll.&_EnrollData /* For testing. */
                     ) ;

   libname __enroll "&_EnrollLib" access = readonly ;

/*
   Produces a dset detailing the enrollment of the MRNs in &People, including a flag
   signifying whether the person was continuously enrolled between &StartDt and &EndDt.
*/

   proc sql noprint ;
      * How many days long is the period of interest? ;
      create table dual (x char(1)) ;
      insert into dual(x) values ('x') ;
      select ("&EndDt"d - "&StartDt"d + 1) as TotDays
               into :TotDays
      from  dual ;
   quit ;

   %put ;
   %put ;
   %put ContinuousEnroll macro--pulling continuous enrollment information for the MRNs in &People ;
   %put between &StartDt and &EndDt (&TotDays days total).;
   %put ;
   %put ;

   proc sql ;
      * Uniquify the list of MRNs, just in case ;
      create table _ids as
      select distinct MRN
      from &People ;

      * Gather start/end dates from enrlseed that could possibly cover the period of interest. ;
      create table _periods as
      select e.MRN
           , e.enr_start
           , e.enr_end
      from &EnrollDset as e INNER JOIN
          _ids as i
      on    e.MRN = i.MRN
      where "&StartDt"d le e.enr_end AND
            "&EndDt"d   ge e.enr_start
            ;

   * Collapse any contiguous periods of enrollment. ;
   %CollapsePeriods(Lib       = work      /* Name of the library containing the dset you want collapsed */
                  , DSet      = _periods  /* Name of the dset you want collapsed. */
                  , RecStart  = enr_start   /* Name of the var that contains the period start dates. */
                  , RecEnd    = enr_end     /* Name of the var that contains the period end dates. */
                  , DaysTol   = &DaysTol  /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  , Debug     = 0         /* 0/1 flag indicating whether you want the PUT statements to run (PRODUCES A LOT OF OUTPUT!). */
                  ) ;

   * Calculate # of days between start & end date. ;
   proc sql ;
      create table _period_days as
      select MRN
            , (min("&EndDt"d, enr_end) - max("&StartDt"d, enr_start) + 1) as Days
      from _periods
      ;

      create table &OutSet(label = "Enrollment information for the MRNs in &People") as
      select mrn
            , sum(days) as CoveredDays label = "Number of enrolled days between &StartDt and &EndDt"
            , (sum(days) = &TotDays) as ContinuouslyEnrolled                 label = "0/1 flag answering question--was this persion continuously enrolled from &StartDt to &EndDt. (disregarding gaps up to &DaysTol days)?"
      from _period_days
      group by mrn
      ;
      insert into &OutSet (MRN, CoveredDays, ContinuouslyEnrolled)
      select MRN, 0, 0
      from _ids
      where mrn not in (select mrn from _periods)
      ;

      select * from _periods     where mrn in (select mrn from _periods group by mrn having count(*) > 1) ;
      select * from _period_days where mrn in (select mrn from _periods group by mrn having count(*) > 1) ;
      select * from &OutSet      where mrn in (select mrn from _periods group by mrn having count(*) > 1) ;

   quit ;

   libname __enroll CLEAR ;

%mend SimpleContinuous ;
