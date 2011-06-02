/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* <<program name>>
*
* <<purpose>>
*********************************************/

libname owt    "\\groups\DATA\CTRHS\Crn\S D R C\Diffusion\AntiEstrogen\Programming\Data" ;

options mprint nofmterr ;

data gnu ;
   set owt.breasttumors (obs = 100) ;
   EndDate = min(of DOD, "31Dec2004"d) ;
   format EndDate mmddyy10. ;
   keep mrn enddate dxdate ;
run ;

%GetFollowUpTime(People          = gnu   /* Dset of MRNs */
               , IndexDate       = DxDate             /* Name of a date var in &People, or else a complete date literal, marking the start of the follow-up period. */
               , EndDate         = EndDate       /* Name of a date var in &People, or else a complete date literal, marking the end of the period of interest. */
               , GapTolerance    = 90                  /* Number of daysdisenrollment to ignore in deciding the disenrollment date. */
               , CallEndDateVar  = end_of_fup         /* What name should we give the date var that will hold the end of the f/up period? */
               , OutSet          = owt.drop_me        /* The name of the output dataset */
               , DebugOut        = owt
                 ) ;

/*
data out.drop_me ;
   set out.drop_me ;
   other_end_date = min(end_of_fup, dod) ;
   fup_mos = intck("MONTH", DxDate, other_end_date) ;
   format other_end_date mmddyy10. ;
run ;

proc format ;
   * The tumor marker and stage vars get recoded to numerics below--here
   * are what should be valid formats for the recoded vars. ;
   value ERM
      1, 3    = "Positive"
      2, 8-10 = "Negative or Unknown"
      /*
      3 = "Borderline"
      other = "Unexpected value!"
      8 = "Ordered, results unknown"
      9 = "Unknown/no information"
      10 = "Not done"
      */
   ;
/*
quit ;

goptions device = activex ;

proc sql ;
   create table gnu as
   select fup_mos, put(ermarker, erm.) as er, stageaj
   from out.drop_me
   order by stageaj ;
quit ;


ods html path = "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\" (URL=NONE)
         body = "test_fup_time.html" ;
   proc boxplot data = gnu ;
      plot fup_mos * stageaj ;

run ;
ods html close ;


run ;
*/