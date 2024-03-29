/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas
*
* Contains standard VDW macros for use against VDW data.
*
* These macros are documented here:
* https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/vdw-standard-macros
*
* Anything documented on that page is supported--please report bugs to pardee.r@ghc.org.
*
* You will find other macros in this file--most are helpers for the documented macros.  There may
* also be a vestigial macro or two (there are none when I write this comment, but who knows what
* the future may bring?).  Any such macros are unsupported.
*
*********************************************/

** Utility macro for fairly precisely calculating age. ;
%macro CalcAge(BDtVar, RefDate) ;
  floor ((intck('month',&BDTVar,&RefDate) - (day(&RefDate) < min (day(&BDTVar),
  day (intnx ('month',&RefDate, 1) - 1) ) ) ) /12 )
%mend CalcAge ;

%macro GetRxForPeople(
         People   /* The name of a dataset containing the MRNs of people
                     whose fills you want. */
       , StartDt  /* The date on which you want to start collecting fills. */
       , EndDt    /* The date on which you want to stop collecting fills. */
       , Outset   /* The name of the output dataset containing the fills. */
       ) ;

   /*
      Gets the pharmacy fills for a specified set of people (identified by MRNs)
      which ocurred between the dates specified in StartDt and EndDt.
   */


   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;
      proc sql ;
         create table &OutSet as
         select r.*
         from &_vdw_rx as r INNER JOIN
               &People as p
         on    r.MRN = p.MRN
         where r.RxDate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;
   %end ;

%mend GetRxForPeople ;
/*********************************************************;
* Testing GetRxForPeople (tested Ok 20041230 gh);
* ;
%include '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas';

data PeopleIn;
  infile '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\testchs100.txt';
  input mrn $char10.;
run;

%GetRxForPeople(PeopleIn,01Jan2002,31Dec2002,RxOut) ;
**********************************************************/;


%macro GetRxForDrugs(
            DrugLst  /* The name of a dataset containing the NDCs of the drugs
                         whose fills you want. */
          , StartDt  /* The date on which you want to start collecting fills.*/
          , EndDt    /* The date on which you want to stop collecting fills. */
          , Outset   /* The name of the output dataset containing the fills. */
          ) ;

   /*
      Gets the pharmacy fills for a specified set of drugs (identified by NDCs)
      which ocurred between the dates specified in StartDt and EndDt.
   */

   %if &DrugLst = &Outset %then %do ;
     %put PROBLEM: Drug List dataset must be different from the OutSet dataset.;
     %put PROBLEM: Both parameters are set to "&DrugLst". ;
     %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;

      proc sql ;
         create table &OutSet as
         select r.*
         from &_vdw_rx as r INNER JOIN
               &DrugLst as p
         on    r.NDC = p.NDC
         where r.RxDate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;

   %end ;
%mend GetRxForDrugs ;

%macro GetRxForPeopleAndDrugs(
           People   /* The name of a dataset containing the people
                       whose fills you want. */
         , DrugLst  /* The NDC codes of interest */
         , StartDt  /* The date on which you want to start collecting fills.*/
         , EndDt    /* The date on which you want to stop collecting fills. */
         , Outset   /* The name of the output dataset containing the fills. */
         ) ;

   /*
      Gets the pharmacy fills for a specified set of people (identified by MRNs)
      which occurred between the dates specified in StartDt and EndDt.
   */

   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;

      proc sql ;
  	    create table &OutSet as
	  			select r.*
   				from  &_vdw_rx as r
   				INNER JOIN &People as p
   				on    r.MRN = p.MRN
   				where r.RxDate BETWEEN "&StartDt"d AND "&EndDt"d AND
         				r.NDC in (select _x.NDC from &DrugLst as _x) ;
      quit ;

   %end ;
%mend GetRxForPeopleAndDrugs ;

%macro GetDxForPeopleAndDx (
           People  /* The name of a dataset containing the people whose
                      fills you want. */
         , DxLst   /* The ICD9 codes of interest */
         , StartDt /* The date on which you want to start collecting fills.*/
         , EndDt   /* The date on which you want to stop collecting fills. */
         , Outset  /* The name of the output dataset containing the fills. */
         ) ;


   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;

   %else %do ;
      proc sql ;
        create table &outset as
			  select d.*
   			from  &_vdw_dx as d
   			INNER JOIN &People as p
   			on    d.MRN = p.MRN
   			where d.ADate BETWEEN "&StartDt"d AND "&EndDt"d AND
   						d.dx in (select _x.dx from &DxLst as _x)
        ;
      quit ;
   %end ;


%mend GetDxForPeopleAndDx;

%macro CountFills(DrugList) ;
   /*
      Counts the number of fills for each of the NDC codes specified in
      the input dataset.
   */



   proc sql ;
      title2 "Extent of pharmacy data." ;
      select count(*) as NumFills label = "Total rx records"
            , min(RxDate) as FirstFill
                format = mmddyy10. label = "Earliest recorded fill"
            , max(RxDate) as LastFill
                format = mmddyy10. label = "Most recent recorded fill"
      from &_vdw_rx ;

      title2 "Number of fills for the list of NDCs in &DrugList" ;
      select d.generic
            , d.NDC
            , count(r.NDC) as NumFills label = "Number of Fills"
            , min(r.RxDate) as FirstFill
                format = mmddyy10. label = "Date of first fill"
            , max(r.RxDate) as LastFill
                format = mmddyy10. label = "Date of most recent fill"
      from  &DrugList as d LEFT JOIN
            &_vdw_rx as r
      on    d.NDC = r.NDC
      group by d.generic, d.NDC ;
   quit ;


%mend CountFills ;

%macro BreastCancerDefinition01(StartDt = 01Jan1997
                              , EndDt = 31Dec2003
                              , OutSet = brca) ;
   /*
      Pulls the set of "incident" (that is, first-ocurring during the
      specified date range) breast cancers, both invasive and in-situ
      (but excluding LCIS).

      These criteria are based on the ones used for the Early Screening study.
      See: https://www.kpchr.org/CRN2/apps/storage/docs/
                            20000823whmesprogramming_case_criteria.doc.
   */



   proc sql number ;
      create table _AllBreastTumors as
      select mrn
            , DxDate
            , DtMrk1 as ERMarker
            , StageGen
            , StageAJ
      from  &_vdw_tumor
      where DxDate between "&StartDt"d and "&EndDt"d  AND
            ICDOSite between 'C500' and 'C509'        AND
            Gender = '2'                              AND
            Morph NOT between '9590' and '9979'       AND
            ( (behav in ('3', '6', '9')) OR
              (behav = '2' AND MORPH ne '8520')) ;

      create table _FirstBTs as
      select DISTINCT b.*
      from  _AllBreastTumors as b
        INNER JOIN
            (select MRN, min(DxDate) as FirstBTDate
              from _AllBreastTumors group by MRN) as b2
      on    b.MRN = b2.MRN AND
            b.DxDate = b2.FirstBTDate
      order by mrn, ERMarker ;

      drop table _AllBreastTumors ;

      title "These people had >1 tumor dxd on the same day, ";
      title2 "each with different receptor statuses or stages." ;
      select *
      from  _FirstBTs
      where MRN in (select _FirstBTs.MRN from _FirstBTs group by _FirstBTs.MRN having count(*) > 1);
      title ;

      * Some women will have > 1 breast tumor dxd on the same day, each with ;
      * different stages and/or receptor statuses.  We want to call the ;
      * receptor status positive if any tumor is positive, and we want to ;
      * take the greatest stage. ;

      create table &OutSet as
      select mrn
            , dxdate
            , min(case ERMarker
                     when '0' then 10
                     else input(ERMarker, 2.0)
                  end) as ERMarker format = ERM.
            , max(case lowcase(StageGen)
                     when '9' then -1
                     when 'b' then -2
                     else input(StageGen, 2.0)
                  end) as StageGen format = StageGen.
            , max(case lowcase(StageAJ)
                     when '' then -1
                     when 'unk' then -1
                     when '2a' then 2
                     when '2b' then 2.5
                     when '3a' then 3
                     when '3b' then 3.5
                     else input(StageAJ, 2.0)
                  end) as StageAJ format = StageAJ.
      from _FirstBTs
      group by mrn, dxdate ;
   quit ;



%mend BreastCancerDefinition01 ;

%macro BreastCancerDefinition02(StartDt = 01Jan1997
                              , EndDt = 31Dec2003
                              , OutSet = brca
                              , OutMultFirsts =
                              ) ;
   /*
    Adapted from 01, for Pharmacovigilance.  Differences:
      01 includes DCIS (but not LCIS).  This is invasive tumors only.
      Returns a dataset of *tumors*, not *women*.  There are frequently > 1 tumor discovered as a
      "first tumor" so applications will have to reduce that to women if necessary.
      Not so much printing (but optional output dset).
      More warnings.

      TODO: Try and nail down a more HMO-site-general list of morphology codes
            to exclude.  These have just had scrutiny from the Group Health
            staff and on the Group Health data.
   */

  %local female ;
  %let   female = 2 ;

  %local collab_stage_year ;
  %let collab_stage_year = 2003 ;

  %local behav_primary ;
  %local behav_metastatic ;
  %local behav_unknown_prim_meta ;

  %let behav_primary = 3 ;
  %let behav_metastatic = 6 ;
  %let behav_unknown_prim_meta = 9 ;

  %* These appeared in some GH breast tumor data--they are undesirable. ;
  %local non_small_cell ;
  %local neuroendicrine ;
  %local fibrosarcoma ;

  %let non_small_cell = 8046 ;
  %let neuroendicrine = 8246 ;
  %let fibrosarcoma = 8810 ;

  %local in_situ ;
  %let in_situ = 0 ;

  proc sql number ;
    * We take these over all time since the file is small and we want to be ;
    * able to call the resulting cases "incident" insofar as we can ;
    create table _AllBreastTumors as
    select *
    from  &_vdw_tumor
    where DxDate le "&EndDt"d                  AND
          Gender = "&female"                   AND
          ICDOSite between 'C500' and 'C509'   AND
          Morph NOT between '9590' and '9979'  AND
          Morph NOT in ("&non_small_cell", "&neuroendicrine", "&fibrosarcoma" ) AND
          behav in ("&behav_primary", "&behav_unknown_prim_meta") AND
          stagegen ^= "&in_situ"
    ;

    * Check desired date limits against observed, and warn as necessary. ;
    select  min(dxdate) as first_tumor   format = yymmddn8. label = "First observed breast tumor (over all time)"
          , max(dxdate) as last_tumor    format = yymmddn8. label = "Last observed breast tumor (over all time)"
          , "&StartDt"d as desired_first format = yymmddn8.
          , "&EndDt"d   as desired_last  format = yymmddn8.
    into :first_tumor, :last_tumor, :desired_first, :desired_last
    from _AllBreastTumors
    ;

    %if &desired_first < &first_tumor %then %do i = 1 %to 10 ;
      %put WARNING: NO BREAST TUMORS FOUND PRIOR TO &STARTDT (EARLIEST IS &FIRST_TUMOR)--EARLY TUMORS MAY NOT BE AS "INCIDENT" AS LATER ONES!!! ;
    %end ;

    %if &desired_last > &last_tumor %then %do i = 1 %to 10 ;
      %put WARNING: NO BREAST TUMORS FOUND AFTER &LAST_TUMOR.--THE &_TUMORDATA FILE IS NOT EXTENSIVE ENOUGH TO MEET THIS REQUEST!!! ;
    %end ;

    * Grab all tumors from each womans first dxdate. ;
    create table _FirstBTs as
    select DISTINCT b.*
    from  _AllBreastTumors as b
      INNER JOIN
          (select MRN, min(DxDate) as FirstBTDate
           from _AllBreastTumors
           group by MRN
           having min(DxDate) between "&StartDt"d and "&EndDt"d) as b2
    on    b.MRN = b2.MRN AND
          b.DxDate = b2.FirstBTDate
    order by mrn, dxdate;

    drop table _AllBreastTumors ;

    * Who had > 1 breast tumor discovered on the day of their first tumor? ;
    create table _multiple_firsts as
    select *
    from  _FirstBTs
    where MRN in (select _FirstBTs.MRN
                  from _FirstBTs
                  group by _FirstBTs.MRN
                  having count(*) > 1)
    ;

    %if &SQLOBS > 0 %then %do ;
      %do i = 1 %to 5 ;
        %PUT BCD2 NOTE: There is at least one, and may be as many as %eval(&SQLOBS/2) people with > 1 tumor dignosed on the same day, each with different receptor statuses or stages. ;
      %end ;
      %if %length(&OutMultFirsts) > 0 %then %do ;
        create table &OutMultFirsts as
        select *
        from _multiple_firsts
        ;
        %do i = 1 %to 5 ;
          %put BCD2 NOTE: The multiple-first-tumor records have been written out to &OutMultFirsts ;
        %end ;
      %end ;

    %end ;

    create table &OutSet as
    select *
    from _FirstBTs
    ;
  quit ;

%mend BreastCancerDefinition02 ;

%macro PullContinuous(InSet                     /* The name of the input dataset of MRNs of the ppl whose enrollment you want to check. */
                     , OutSet                    /* The name of the output dataset of only the continuously enrolled people. */
                     , IndexDate                 /* Either the name of a date variable in InSet, or, a complete date literal (e.g., "01Jan2005"d) */
                     , PreIndexEnrolledMonths    /* The # of months of enrollment required prior to the index date. */
                     , PreIndexGapTolerance      /* The length of enrollment gaps in months you consider to be ignorable for pre-index date enrollment. */
                     , PostIndexEnrolledMonths   /* The # of months of enrollment required post index date. */
                     , PostIndexGapTolerance     /* The length of enrollment gaps in months you consider to be ignorable for post-index date enrollment.*/
                     , DebugOut = work           /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
                     , EnrollDset = &_vdw_enroll /* For testing. */
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
         %*abort return ;
         %goto exit;
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
%exit:
%mend PullContinuous ;


%macro ndclookup(
         inds     /* An input dataset of strings to search for,
                       in a var named "drugname".  */
       , outds    /* The name of the output dset of NDCs,
                       which contain one of the input strings. */
       , EverNDC  /* The name of your local copy of the EverNDC file. */
       );

*******************************************************************************;
* look up NDC codes by drugnames or fragments of drugnames
* Check the results file to see that they are all drugs of interest
*
* Input:
*	inds is the name of the input SAS dataset with the list of character strings
*		to match contains the variable "drugname"
*		Both the Generic and Brand fields are searched for all input strings
*
*	outds is the name of the output SAS dataset
*       EverNDC is the SAS dataset name of the file of all NDCcodes
*
* EverNDC is the fully qualified name of your local copy of the EverNDC dataset
*
*    Example:
*Data StringsOfInterest;
*   input  drugname $char20.;
*   datalines;
*TAMOX
*Ralox
*NOLVADEX
*LETROZOLE
*EXEMESTANE
*ANASTROZOLE

*%ndclookup(StringsOfInterest, NDCs_of_Interest, mylib.EverNDC);
*******************************************************************************;

  proc sql noprint ;

    * Create a monster WHERE clause to apply to ever_ndc from the contents   ;
    * of InDs. The embedded single quotes can get a bit confusing--just      ;
    * remember that one single quote character escapes the following one.  So;
    * a string of 4 single-quote chars in a row defines a string containing  ;
    * one single quote--the two on the ends delimit the string, and the two  ;
    * in the middle resolve to one (the first one escaping the second).      ;
    * SQL written by Roy Pardee                                              ;

    select 'upcase(n.Generic) LIKE ''%' || trim(upcase(s.DrugName))|| '%''' ||
       ' OR upcase(n.Brand)   LIKE ''%' || trim(upcase(s.DrugName))|| '%'''
          as where_clause
    into :wh separated by ' OR '
    from &inds as s ;

    * First pull all of the NDCs that meet the WHERE clause above. ;
    create table _OfInterest as
    select distinct *
    from &everndc as n
    where &wh ;

    * Now pull drugs that *dont* match the WHERE clause, but share an NDC ;
    *   with one that does. ;
    create table _Suspicious as
    select distinct n.*
    from _OfInterest as a inner join &everndc as n
    on a.ndc = n.ndc
    where not (&wh)
    ;

    * Mash the two dsets together ;
    create table &outds as
    select *, 0 as Suspicious
      label = "Flag for whether Generic or Brand contained a string of interest"
    from _OfInterest
    UNION ALL
    select *, 1 as Suspicious
    from _Suspicious ;

    drop table _OfInterest ;
    drop table _Suspicious ;
  quit ;
%mend ndclookup;

%macro GetPxForPeople(
           People  /* The name of a dataset containing the people whose
                         procedures you want. */
         , StartDt /* The date on which you want to start collecting procs*/
         , EndDt   /* The date on which you want to stop collecting procedures*/
         , Outset  /* The name of the output dataset containing the procedures*/
         ) ;

   /*
      Gets the procedures for a specified set of people (identified by MRNs)
      which ocurred between the dates specified in StartDt and EndDt.
   */


   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;
      proc sql ;
         create table &OutSet as
         select r.*
         from &_vdw_px as r INNER JOIN
               &People as p
         on    r.MRN = p.MRN
         where r.ADate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;
   %end ;

%mend GetPxForPeople ;

%macro GetUtilizationForPeople(
          People  /* The name of a dataset containing the people whose
                       procedures you want*/
        , StartDt /* The date on which you want to start collecting procedures*/
        , EndDt   /* The date on which you want to stop collecting procedures*/
        , Outset  /* The name of the output dataset containing the procedures*/
        ) ;

   /*
      Gets the utilization records for a specified set of people (identified
      by MRNs) hich ocurred between the dates specified in StartDt and EndDt.
   */

   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;
      proc sql ;
         create table &OutSet as
         select r.*
         from &_vdw_utilization as r INNER JOIN
               &People as p
         on    r.MRN = p.MRN
         where r.ADate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;
   %end ;

%mend GetUtilizationForPeople ;

/*********************************************************;
* Testing GetPxForPeople (tested ok 20041230 gh);
* ;
%include '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas';

data PeopleIn;
  infile '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\testchs100.txt';
  input mrn $char10.;
run;

%GetPxForPeople(PeopleIn,01Jan2002,31Dec2002,PxOut) ;
**********************************************************/;

%macro GetDxForPeople(
          People  /* The name of a dataset containing the people whose
                       diagnoses you want. */
        , StartDt /* The date on which you want to start collecting diagnoses.*/
        , EndDt   /* The date on which you want to stop collecting diagnoses. */
        , Outset  /* The name of the output dataset containing the diagnoses. */
        ) ;

   /*
      Gets the diagnoses for a specified set of people (identified by MRNs)
      which ocurred between the dates specified in StartDt and EndDt.
   */

   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;
      proc sql ;
         create table &OutSet as
         select r.*
         from &_vdw_dx as r INNER JOIN
               &People as p
         on    r.MRN = p.MRN
         where r.ADate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;
   %end ;

%mend GetDxForPeople ;
/*********************************************************;
* Testing GetDxForPeople (tested ok 20041230 gh);
* ;
%include '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas';

data PeopleIn;
  infile '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\testchs100.txt';
  input mrn $char10.;
run;

%GetDxForPeople(PeopleIn,01Jan2002,31Dec2002,DxOut) ;
**********************************************************/;


%macro GetDxForDx(
          DxLst     /* The name of a dataset containing the diagnosis
                         list you want. */
        , DxVarName /* The name of the DX variable in DxLst  */
        , StartDt   /* The date on which you want to start collecting fills. */
        , EndDt     /* The date on which you want to stop collecting fills. */
        , Outset    /* The name of the output dataset containing the fills. */
        ) ;

   /*
     Gets the records for a specified set of diagnoses (identified by ICD9 code)
     which ocurred between the dates specified in StartDt and EndDt.
   */

   %if &DxLst = &Outset %then %do ;
    %put PROBLEM: The Diagnosis List dataset must be different from the;
    %put PROBLEM:   OutSet dataset;
    %put PROBLEM: Both parameters are set to "&DxLst". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;
      proc sql ;
         create table &OutSet as
         select DBig.*
         from  &_vdw_dx as DBig INNER JOIN
               &DxLst as DLittle
         on    DBIG.DX = Dlittle.&DxVarName.
         where Dbig.ADate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;
   %end ;

%mend GetDxForDx ;
/*********************************************************;
* Testing GetDxForDx (tested 20041230 gh);
* ;
%include '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas';

data DxOfInterest;
  input dx $char6.;
  cards;
V22   Normal pregnancy
V22.0       Supervision of normal first pregnancy
V22.1       Supervision of other normal pregnancy
V22.2       Pregnant state, incidental
run;

%GetDxForDx(DxOfInterest, dx,01Jan2002,31Dec2002,DxOut) ;
**********************************************************/;

%macro GetPxForPx(
          PxLst             /*The name of a dataset containing the procedure
                                list you want. */
        , PxVarName         /*The name of the Px variable in PxLst  */
        , PxCodeTypeVarName /*Px codetype variable name in PxLst  */
        , StartDt           /*The date when you want to start collecting data*/
        , EndDt             /*The date when you want to stop collecting data*/
        , Outset            /*Name of the output dataset containing the data*/
        ) ;

  /*
  Gets the records for a specified set of diagnoses (identified by ICD9 code)
  which ocurred between the dates specified in StartDt and EndDt.
  */

  %if &PxLst = &Outset %then %do ;
    %** Make sure we arent going to overwrite the pxlist dset. ;
    %put PROBLEM: The Px List dataset must be different from the OutSet dataset;
    %put PROBLEM: Both parameters are set to "&PxLst". ;
    %put PROBLEM: Doing nothing. ;
  %end ;
  %else %do ;
    ** Make sure input variables exist in the pxlist dset. ;
    proc contents noprint data = &PxLst out = __varlist ;

    proc sql noprint ;
      select count(*) as num_vars
      into :num_vars
      from __varlist
      where upcase(name) in (%upcase("&PxVarName"), %upcase("&PxCodeTypeVarName")) ;
      drop table __varlist ;
    quit ;
    %if (&num_vars < 2) %then %do ;
      %put ERROR: The Px List dataset you supplied does not have one or both of the variables you named in the input parameters!!! ;
      %put ERROR: Expected to find both variables "&PxVarName" and "&PxCodeTypeVarName" in dataset "&PxLst", but one or both are missing. ;
      %put ERROR: Doing nothing. ;
    %end ;
    %else %do ;
      proc sort nodupkey data = &pxlst dupout = in_dupes ;
        by &pxvarname &pxcodetypevarname ;
      run ;
      proc sql noprint ;

        select count(*) as frq
        into :num_dupes
        from in_dupes
        ;

        reset print ;

        %if &num_dupes > 0 %then %do ;
          %put WARNING: There were duplicated values in your &PxLst dataset--THEY HAVE BEEN REMOVED!  Please see output for a listing of the codes that were duplicated. ;
          select 'WARNING: These values were duplicated in your input dataset of procedure codes.' as msg, *
          from in_dupes
          ;
          drop table in_dupes ;
        %end ;
        create table &OutSet as
        select PBig.*
        from  &_vdw_px as PBig INNER JOIN
              &PxLst as PLittle
        on    PBig.PX = PLittle.&PxVarName.  and
              PBig.PX_CodeType = PLittle.&PxCodeTypeVarName.
        where Pbig.ADate BETWEEN "&StartDt"d AND "&EndDt"d ;
      quit ;
    %end ;
  %end ;
%mend GetPxForPx ;
*********************************************************;
* Testing GetPxForPx (tested 20041230 gh);
* ;
/*
%include '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas';

data PxOfInterest;
  input Px $char6. CodeType $char1.;
  cards;
59409 C VAGINAL DELIVERY ONLY
59410 C  VAGINAL DELIVERY INCL POSTPARTUM CARE
59510 C  ROUTINE OB CARE INCL ANTEPARTUM CAR, CESAREAN DELIVER, POSTPARTUM CARE
59514 C  CESAREAN DELIVERY ONLY
run;

%GetPxForPx(PxOfInterest, px, CodeType, 01Jan2002,31Dec2002,PxOut) ;
**********************************************************;
*/

/* *********************************************************
* Takes an input dataset bearing a specified ID code (e.g.,
* MRN) and replaces it with an arbitrary
* StudyID, creating a crosswalk dset that relates the
* original ID codes to the new StudyIDs.
*
* Sample call:
*
* %DeIDDset( InSet = phe.people    The input dataset.
*          , XWalkSet = phe.xwalk  Name of the crosswalk dset
*          , OldIDVar = CHSID      Name of the ID variable you want removed.
*          , NewIDVar = StudyID    Name for the new ID variable.
*          , NewIDLen = 8          The length of the new ID variable.
*          ) ;
********************************************************* */

%macro DeIDDset( InSet     /* Name of the dataset you want de-identified. */
               , XWalkSet  /* Name of the output ID-crosswalk dset. */
               , OldIDVar  /* Name of the ID variable you want removed. */
               , NewIDVar  /* Name for the new ID variable the macro creates. */
               , NewIDLen  /* The length of the new ID variable.*/
               , StartIDsAt = 0
               ) ;

   proc sql nowarn ;
      create table _UIDs as
      select distinct &OldIDVar
      from &InSet
      ;
   quit ;

   %if %length(%trim(&sqlobs)) > &NewIDLen %then %do ;
      %put ;
      %put PROBLEM: THE ID LENGTH SPECIFIED IS INSUFFICIENT!!! ;
      %put ;
      %put DOING NOTHING!!! ;
      %put ;
   %end ;
   %else %do ;

      data _UIDs ;
        set _UIDs ;
        randy = uniform(675555) ;
      run ;

      proc sort data = _UIDs ;
        by randy ;
      run ;

      data &XWalkSet(keep = &NewIDVar &OldIDVar) ;
         set _UIDs ;
         &NewIDVar = put((_N_ + &StartIDsAt), z&NewIDLen..0) ;
         drop randy ;
      run ;

      proc sql ;
         create table &InSet._DeIDed(drop = &OldIDVar) as
         select x.&NewIDVar
               , i.*
         from  &XWalkSet as x INNER JOIN
               &InSet as i
         on    x.&OldIDVar = i.&OldIDVar ;
      quit ;

      data &InSet ;
         set &InSet._DeIDed ;
      run ;

      proc sql ;
         drop table &InSet._DeIDed ;
      quit ;

   %end ;

%mend DeIDDset ;

%macro charlson(inputds
              , IndexDateVarName
              , outputds
              , IndexVarName
              , inpatonly=I
              , malig=N
              , NoEncounterGetsMissing = N
              );
/*********************************************

* Charlson comorbidity macro.sas
*
* Computes the Deyo version of the Charleson
*
*
*  Programmer
*     Hassan Fouayzi
*
*
* Input data required:
*
*     VDW Utilization files
*     Input SAS dataset INPUTDS
*        contains the variables MRN, STUDYID, and INDEXDT
*        INPATONLY flag - defauts to Inpatient only (I).  Valid values are
*                           I-inpatient or B-Both inpatient and outpatient
*                           or A-All encounter types
*        MALIG flag - Defaults to no(N).  If MALIG is yes (Y) then the weights
*                         of Metastasis and Malignancy are set to zero.
*                     This may be useful in a study of cancer.
*
*        NoEncounterGetsMissing - Defaults to (N).  Controls whether people for
*                                 whom no dx/px data is found get a charlson score
*                                 of 0 (default) or a missing value.  For cohorts whose
*                                 year-pre-index-date data capture is assured (usually via
*                                 enrollment data), having no encounters should legitimately
*                                 indicate a lack of any comorbidities & therefore a legit
*                                 score of 0.  Cohorts *not* previously vetted in this way may
*                                 not support that inference, and users should specify a Y
*                                 for this parameter to prevent unwarranted interpretation
*                                 of the Charlson score.
*
* Outputs:
*     Dataset &outputsd with on record per studyid
*     Variables
*       MI            = "Myocardial Infarction: "
*       CHD           = "Congestive heart disease: "
*       PVD           = "Peripheral vascular disorder: "
*       CVD           = "Cerebrovascular disease: "
*       DEM           = "Dementia: "
*       CPD           = "Chronic pulmonary disease: "
*       RHD           = "Rheumatologic disease: "
*       PUD           = "Peptic ulcer disease: "
*       MLIVD         = "Mild liver disease: "
*       DIAB          = "Diabetes: "
*       DIABC         = "Diabetes with chronic complications: "
*       PLEGIA        = "Hemiplegia or paraplegia: "
*       REN           = "Renal Disease: "
*       MALIGN        = "Malignancy, including leukemia and lymphoma: "
*       SLIVD         = "Moderate or severe liver disease: "
*       MST           = "Metastatic solid tumor: "
*       AIDS          = "AIDS: "
*       &IndexVarName = "Charlson score: "
*
*
* Dependencies:
*
*     StdVars.sas--the site-customized list of standard macro variables.
*     The DX and PROC files to which stdvars.sas refer
*
*
* Example of use:
*     %charlson(testing,oot, Charles, inpatonly=B)
*
* Notes:
*   You will often need to remove certain disease format categories for your
*   project. For instance, the Ovarian Ca EOL study removed Metastatic Solid
*   Tumor since all were in end stages. It would be inappopriate not to exclude
*   this category in this instance. Please use this macro wisely.
*
*   There are several places that need to be modified.
*     1.  Comment the diagnosis category in the format.
*     2.  Remove that diagnosis category in 2 arrays.
*     3.  Select the time period for the source data and a reference point.
*     4.  Data selection.  All diagnoses and procedures?  Inpt only?  The user
*         may want to remove certain types of data to make the sources from all
*         sites consistent.
*
* Version History
*
*     Written by Hassan Fouayzi starting with source from Rick Krajenta
*     Modified into a SAS Macro format           Gene Hart         2005/04/20
*     Malig flag implemented                     Gene Hart         2005/05/04
*     Add flag to mark thos with no visits       Gene Hart         2005/05/09
*     Add additional codes to disease            Tyler Ross        2006/03/31
*     Changed EncType for IP visits to new ut
*       specs and allowed all visit types option Tyler Ross       2006/09/15
*     Removed "456" from Moderate/Severe Liver   Hassan Fouayzi    2006/12/21
*
*     Should the coalesce function be on studyid or mrn?  1 MRN with 2 STUDYIDs
*       could happen
*
*     move then proc codes to a format
*
* Source publication
*     From: Fouayzi, Hassan [mailto:hfouayzi@meyersprimary.org]
*     Sent: Wednesday, May 04, 2005 9:07 AM
*     Subject: RE: VDW Charlson macro
...
*     Deyo RA, Cherkin DC, Ciol MA. Adapting a clinical comorbidity Index for
*     use with ICD-9-CM administrative databases.
*       J Clin Epidemiol 1992; 45: 613-619.
*     We added CPT codes and a couple of procedures for Peripheral
*       vascular disorder.
*
*********************************************/

/**********************************************/
/*Define and format diagnosis codes*/
/**********************************************/

** TODO:  Come up with an ICD-10 version of this format!!! ;
** TODO: character formats w/ranges make me nervous--this should be vetted against a lookup dataset. ;
PROC FORMAT;
   VALUE $ICD9CF
/* Myocardial infraction */
	"410   "-"410.92",
	"412   " = "MI"
/* Congestive heart disease */
	"428   "-"428.9 " = "CHD"
/* Peripheral vascular disorder */
	"440.20"-"440.24",
	"440.31"-"440.32",
	"440.8 ",
	"440.9 ",
	"443.9 ",
	"441   "-"441.9 ",
	"785.4 ",
	"V43.4 ",
	"v43.4 " = "PVD"
/* Cerebrovascular disease */
    "430   "-"438.9 " = "CVD"
/* Dementia */
	"290   "-"290.9 " = "DEM"
/* Chronic pulmonary disease */
	"490   "-"496   ",
	"500   "-"505   ",
	"506.4 " =  "CPD"
/* Rheumatologic disease */
	"710.0 ",
  "710.1 ",
 	"710.4 ",
  "714.0 "-"714.2 ",
  "714.81",
  "725   " = "RHD"
/* Peptic ulcer disease */
	"531   "-"534.91" = "PUD"
/* Mild liver disease */
	"571.2 ",
	"571.5 ",
	"571.6 ",
	"571.4 "-"571.49" = "MLIVD"
/* Diabetes */
	"250   "-"250.33",
	"250.7 "-"250.73" = "DIAB"
/* Diabetes with chronic complications */
	"250.4 "-"250.63" = "DIABC"
/* Hemiplegia or paraplegia */
	"344.1 ",
	"342   "-"342.92" = "PLEGIA"
/* Renal Disease */
	"582   "-"582.9 ",
	"583   "-"583.7 ",
	"585   "-"586   ",
	"588   "-"588.9 " = "REN"
/*Malignancy, including leukemia and lymphoma */
	"140   "-"172.9 ",
	"174   "-"195.8 ",
	"200   "-"208.91" = "MALIGN"
/* Moderate or severe liver disease */
	"572.2 "-"572.8 ",
	"456.0 "-"456.21" = "SLIVD"
/* Metastatic solid tumor */
	"196   "-"199.1 " = "MST"
/* AIDS */
	"042   "-"044.9 " = "AIDS"
/* Other */
   other   = "other"
;
run;

** For debugging. ;
%local sqlopts ;
%let sqlopts = feedback sortmsg stimer ;
%**let sqlopts = ;

*******************************************************************************;
** subset to the utilization data of interest (add the people with no visits  *;
**    back at the end                                                         *;
*******************************************************************************;


***********************************************;
** implement the Inpatient and Outpatient Flags;
*********************************************** ;
%if &inpatonly =I %then %let inpatout= AND EncType in ('IP');
%else %if &inpatonly =B %then %let inpatout= AND EncType in ('IP','AV');
%else %if &inpatonly =A %then %let inpatout=;
%else %do;
  %Put ERROR in Inpatonly flag.;
  %Put Valid values are I for Inpatient and B for both Inpatient and Outpatient;
%end;

proc sql &sqlopts ;

   create table _ppl as
   select MRN, Min(&IndexDateVarName) as &IndexDateVarName format = mmddyy10.
   from &inputds
   group by MRN ;

  %local TotPeople ;
   %let TotPeople = &SQLOBS ;

  alter table _ppl add primary key (MRN) ;

  create table  _DxSubset as
  select sample.mrn, &IndexDateVarName, adate, case dx_codetype when '09' then put(dx, $icd9cf.) else '???' end as CodedDx
  from &_vdw_dx as d INNER JOIN _ppl as sample
  ON    d.mrn = sample.mrn
  where  adate between sample.&IndexDateVarName-1
                  and sample.&IndexDateVarName-365
            &inpatout.
  ;

   select count(distinct MRN) as DxPeople format = comma.
     label = "No. people having any Dxs w/in a year prior to &IndexDateVarName"
         , (CALCULATED DxPeople / &TotPeople) as PercentWithDx
            format = percent6.2 label = "Percent of total"
   from _DxSubset ;

  create table _PxSubset as
  select p.*
  from &_vdw_px as p, _ppl as sample
  where p.mrn = sample.mrn
        and px_codetype in ('C4', 'H4', '09')
        and adate between sample.&IndexDateVarName-1
                      and sample.&IndexDateVarName-365
        &inpatout.
  ;

   select count(distinct MRN) as PxPeople format = comma.
     label = "No. people who had any Pxs w/in a year prior to &IndexDateVarName"
         , (CALCULATED PxPeople / &TotPeople) as PercentWithPx
             format = percent6.2 label = "Percent of total sample"
   from _PxSubset ;

quit ;

proc sort data = _DxSubset ;
   by MRN ;
run ;

proc sort data = _PxSubset ;
   by MRN ;
run ;

/**********************************************/
/*** Assing DX based flagsts                ***/
/***                                        ***/
/***                                        ***/
/**********************************************/

%local var_list ;
%let var_list = MI CHD PVD CVD DEM CPD RHD PUD MLIVD DIAB
                DIABC PLEGIA REN MALIGN SLIVD MST AIDS ;

data _DxAssign ;
  length &var_list 3 ;
  retain           &var_list ;
  set _DxSubset;
  by mrn;
  array COMORB (*) &var_list ;
  if first.mrn then do;
     do I=1 to dim(COMORB);
        COMORB(I) = 0 ;
     end;
  end;
  select (CodedDx);
     when ('MI')    MI     = 1;
     when ('CHD')   CHD    = 1;
     when ('PVD')   PVD    = 1;
     when ('CVD')   CVD    = 1;
     when ('DEM')   DEM    = 1;
     when ('CPD')   CPD    = 1;
     when ('RHD')   RHD    = 1;
     when ('PUD')   PUD    = 1;
     when ('MLIVD') MLIVD  = 1;
     when ('DIAB')  DIAB   = 1;
     when ('DIABC') DIABC  = 1;
     when ('PLEGIA')PLEGIA = 1;
     when ('REN')   REN    = 1;
     when ('MALIGN')MALIGN = 1;
     when ('SLIVD') SLIVD  = 1;
     when ('MST')   MST    = 1;
     when ('AIDS')  AIDS   = 1;
     otherwise ;
  end;
  if last.mrn then output;
  keep   mrn  &var_list ;
run;

/** Procedures: Peripheral vascular disorder **/
data _PxAssign;
   set _PxSubset;
   by mrn;
   retain PVD ; ** [RP] Added 5-jul-2007, at Hassan Fouyazis suggestion. ;
   keep mrn PVD;
   if first.mrn then PVD = 0;
   if    PX= "38.48" or
         PX ="93668" or
         PX in ("34201","34203","35454","35456","35459","35470") or
                "35355" <= PX <= "35381" or
         PX in ("35473","35474","35482","35483","35485","35492","35493",
                "35495","75962","75992") or
         PX in ("35521","35533","35541","35546","35548","35549","35551",
                "35556","35558","35563","35565","35566","35571","35582",
                "35583","35584","35585","35586","35587","35621","35623",
                "35641","35646","35647","35651","35654","35656","35661",
                "35663","35665","35666","35671")
         then PVD=1;
   if last.mrn then output;
run;

/** Connect DXs and PROCs together  **/
proc sql &sqlopts ;
  ** Adding a bunch of coalesces here in case there are ppl w/procs but no dxs. ;
  create table _DxPxAssign as
   select  coalesce(D.MRN, P.MRN) as MRN
         , coalesce(D.MI    , 0)  as MI
         , coalesce(D.CHD   , 0)  as CHD
         , coalesce(D.CVD   , 0)  as CVD
         , coalesce(D.DEM   , 0)  as DEM
         , coalesce(D.CPD   , 0)  as CPD
         , coalesce(D.RHD   , 0)  as RHD
         , coalesce(D.PUD   , 0)  as PUD
         , coalesce(D.MLIVD , 0)  as MLIVD
         , coalesce(D.DIAB  , 0)  as DIAB
         , coalesce(D.DIABC , 0)  as DIABC
         , coalesce(D.PLEGIA, 0)  as PLEGIA
         , coalesce(D.REN   , 0)  as REN
         , coalesce(D.MALIGN, 0)  as MALIGN
         , coalesce(D.SLIVD , 0)  as SLIVD
         , coalesce(D.MST   , 0)  as MST
         , coalesce(D.AIDS  , 0)  as AIDS
         , max(D.PVD, P.PVD)      as PVD
   from  WORK._DXASSIGN as D full outer join
         WORK._PXASSIGN P
   on    D.MRN = P.MRN
   ;
quit ;

*****************************************************;
* Assign the weights and compute the index
*****************************************************;

Data _WithCharlson;
  set _DxPxAssign;
  M1=1;M2=1;M3=1;

** implement the MALIG flag;
   %if &malig =N %then %do; O1=1;O2=1; %end;
   %else %if &malig =Y %then  %do; O1=0; O2=0; %end;
   %else %do;
     %Put ERROR in MALIG flag.  Valid values are Y (Cancer study. Zero weight;
     %Put ERROR the cancer vars)  and N (treat cancer normally);
   %end;

  if SLIVD = 1 then M1=0;
  if DIABC = 1 then M2=0;
  if MST   = 1 then M3=0;


&IndexVarName =   sum(MI , CHD , PVD , CVD , DEM , CPD , RHD ,
                  PUD , M1*MLIVD , M2*DIAB , 2*DIABC , 2*PLEGIA , 2*REN ,
                  O1*2*M3*MALIGN , 3*SLIVD , O2*6*MST , 6*AIDS) ;

Label
  MI            = "Myocardial Infarction: "
  CHD           = "Congestive heart disease: "
  PVD           = "Peripheral vascular disorder: "
  CVD           = "Cerebrovascular disease: "
  DEM           = "Dementia: "
  CPD           = "Chronic pulmonary disease: "
  RHD           = "Rheumatologic disease: "
  PUD           = "Peptic ulcer disease: "
  MLIVD         = "Mild liver disease: "
  DIAB          = "Diabetes: "
  DIABC         = "Diabetes with chronic complications: "
  PLEGIA        = "Hemiplegia or paraplegia: "
  REN           = "Renal Disease: "
  MALIGN        = "Malignancy, including leukemia and lymphoma: "
  SLIVD         = "Moderate or severe liver disease: "
  MST           = "Metastatic solid tumor: "
  AIDS          = "AIDS: "
  &IndexVarName = "Charlson score: "
;

keep MRN &var_list &IndexVarName ;

run;

/* add the people with no visits back in, and create the final dataset */
/* people with no visits or no comorbidity DXs have all vars set to zero */

proc sql &sqlopts ;
  create table &outputds as
  select distinct i.MRN
      , i.&IndexDateVarName
      , coalesce(w.MI           , 0) as  MI
                   label = "Myocardial Infarction: "
      , coalesce(w.CHD          , 0) as  CHD
                   label = "Congestive heart disease: "
      , coalesce(w.PVD          , 0) as  PVD
                   label = "Peripheral vascular disorder: "
      , coalesce(w.CVD          , 0) as  CVD
                   label = "Cerebrovascular disease: "
      , coalesce(w.DEM          , 0) as  DEM
                   label = "Dementia: "
      , coalesce(w.CPD          , 0) as  CPD
                   label = "Chronic pulmonary disease: "
      , coalesce(w.RHD          , 0) as  RHD
                   label = "Rheumatologic disease: "
      , coalesce(w.PUD          , 0) as  PUD
                   label = "Peptic ulcer disease: "
      , coalesce(w.MLIVD        , 0) as  MLIVD
                   label = "Mild liver disease: "
      , coalesce(w.DIAB         , 0) as  DIAB
                   label = "Diabetes: "
      , coalesce(w.DIABC        , 0) as  DIABC
                   label = "Diabetes with chronic complications: "
      , coalesce(w.PLEGIA       , 0) as  PLEGIA
                   label = "Hemiplegia or paraplegia: "
      , coalesce(w.REN          , 0) as  REN
                   label = "Renal Disease: "
      , coalesce(w.MALIGN       , 0) as  MALIGN
                   label = "Malignancy, including leukemia and lymphoma: "
      , coalesce(w.SLIVD        , 0) as  SLIVD
                   label = "Moderate or severe liver disease: "
      , coalesce(w.MST          , 0) as  MST
                   label = "Metastatic solid tumor: "
      , coalesce(w.AIDS         , 0) as  AIDS
                   label = "AIDS: "
      %if %upcase(&NoEncounterGetsMissing) = Y %then %do ;
        , w.&IndexVarName
      %end ;
      %else %do ;
        , coalesce(w.&IndexVarName, 0) as &IndexVarName
      %end ;
       label = "Charlson score: "
      , (w.MRN is null)              as  NoVisitFlag
                   label = "No diagnoses or procedures found in the year prior to &IndexDateVarName for this person"
  from _ppl as i left join _WithCharlson as w
  on i.MRN = w.MRN
  ;

/* clean up work sas datasets */
proc datasets nolist ;
 delete _DxSubset
        _PxSubset
        _DxAssign
        _PxAssign
        _DxPxAssign
        _WithCharlson
        _NoVisit
        _ppl
        ;
%mend charlson;


%macro LastWord(WordList) ;
   %** This is a helper macro for CollapsePeriods--it just returns the last word (variable name) in a string (var list). ;
   %local i ;
   %local ThisWord ;
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
               , PersonID  = MRN   /* Name of the var that contains a unique person identifier. */
                ) ;

   %** This is also a helper macro for CollapsePeriods--it creates a global macro var ;
   %** containing a list of all vars in the input named dset *other than* the ones that ;
   %** define the start/end of each record. ;

   %** I dont know a good way of passing a return value out of a macro--so this is made global. ;
   %global VarList ;

   %** If we got just a one-part dset name for a WORK dataset, add the WORK libname explicitly. ;

   %if %index(&Dset, .) = 0 %then %do ;
      %let Dset = work.&Dset ;
   %end ;

   %**put Dset is &Dset ; ;

  %** This used to use a query to dictionary.columns to grab this info--huge. pain. in. the. ass. ;
  %** Dont use d.c--SAS is not a good citizen when you have libnames defined against RDBMSs. ;
  proc contents noprint data = &dset out = __varlist ;
  run ;

  proc sql noprint ;
    ** describe table dictionary.columns ;
    select name
    into :VarList separated by ' '
    from __varlist
    where upcase(name) not in (%upcase("&RecStart"), %upcase("&RecEnd"), %upcase("&PersonID")) ;

    drop table __varlist ;
  quit ;

%mend GetVarList ;

%macro CollapsePeriods(Lib          /* Name of the library containing the dset you want collapsed */
                     , DSet         /* Name of the dset you want collapsed. */
                     , RecStart     /* Name of the var that contains the period start dates. */
                     , RecEnd       /* Name of the var that contains the period end dates. */
                     , PersonID   = MRN /* Name of the var that contains a unique person identifier. */
                     , OutSet     = &lib..&dset /* In case you dont want this to overwrite your input dataset, specify another. */
                     , DaysTol    = 1   /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                     , Debug      = 0   /* 0/1 flag indicating whether you want the PUT statements to run (PRODUCES A LOT OF OUTPUT!). */
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
      length PeriodStart PeriodEnd 4 ;
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
               , DebugOut = work /* Libname to save interim dsets to for debugging--leave set to work to discard these. */
               , EnrollDset = &_vdw_enroll /* Supply your own enroll data if you like. */
               , Reverse = 0     /* **(JW 30DEC2009) Look backwards from IndexDate? 1=Reverse */
                 ) ;

   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro GetFollowUpTime V0.91 (REVISED for Reverse look by JW):  ;
   %put ;
   %put Creating a dset "&OutSet", which will look just like "&People" except  ;
   %put that it will have an additional variable "&CallEndDateVar", which will ;
   %put hold the earliest of date-of-last-enrollment, or &EndDate (or, if the  ;
   %put person was not enrolled at all a missing value). ;
   %put ;
   %put THIS IS BETA SOFTWARE-PLEASE SCRUTINIZE THE RESULTS AND REPORT PROBLEMS;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;




   proc sql noprint ;


      %** Grab ENROLL recs for our ppl of interest where the periods overlap the period between &IndexDate and EndDate ;
      create table &DebugOut..__enroll as
      select p.mrn
            , e.enr_start
            , e.enr_end
            , &IndexDate as idate format = mmddyy10.
            , &EndDate   as edate format = mmddyy10.
      from  &People as p INNER JOIN
            &EnrollDset as e
      on    p.MRN = e.MRN

      %IF &Reverse.=1 %THEN %DO;
      %**(JCW 18FEB2010);
          where intnx('day', &EndDate.  , -&GapTolerance, 'sameday') <= e.enr_end
            and intnx('day', &IndexDate.,  &GapTolerance, 'sameday') >= e.enr_start
      %END;
      %ELSE %DO;
          where intnx('day', &IndexDate., -&GapTolerance, 'sameday') <= e.enr_end
            AND intnx('day', &EndDate.  ,  &GapTolerance, 'sameday') >= e.enr_start
      %END;

      order by mrn,

      %IF &Reverse.=1 %THEN %DO;
      %**(JCW 30DEC2009);
          enr_end DESC
      %END;
      %ELSE %DO;
          enr_start
      %END;

      ;
   quit ;

  data &debugout..__pre_collapse_enroll ;
    set &debugout..__enroll ;
  run ;

   *** Collapse contiguous periods down. ;
   %CollapsePeriods(Lib      = &DebugOut     /* Name of the library containing the dset you want collapsed */
                  , DSet     = __enroll      /* Name of the dset you want collapsed. */
                  , RecStart = enr_start     /* Name of the var that contains the period start dates. */
                  , RecEnd   = enr_end       /* Name of the var that contains the period end dates. */
                  , PersonID = MRN
                  , DaysTol  = &GapTolerance /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  ) ;

  ** Handle the (I would hope rare) case where someone is not enrolled on their index ;
  ** date, and the start of their enrollment is more than &GapTolerance days away. ;
  proc sql ;
    delete from &DebugOut..__enroll
    %IF &Reverse.=1 %THEN %DO;
      where (idate-enr_end) gt &GapTolerance
    %END;
    %ELSE %DO;
      where (enr_start - idate) gt &GapTolerance
    %END;
    ;
  quit ;


   ** The end of contiguous enrollment is enr_end on the rec w/the earliest enr_start ;
   proc sort data = &DebugOut..__enroll out = &DebugOut..__collapsed_enroll ;
      by mrn enr_start ;
   run ;

   proc sort nodupkey data = &DebugOut..__collapsed_enroll out = &DebugOut..__first_periods ;
      by mrn ;
   run ;

   proc sql ;
      create table &OutSet as
      select p.* ,

      %IF &Reverse.=1 %THEN %DO;
      %**(JCW 30DEC2009);
        max(e.edate, e.enr_start)
      %END;
      %ELSE %DO;
        min(e.edate, e.enr_end)
      %END;
      as &CallEndDateVar format = mmddyy10.

      from  &People as p LEFT JOIN
            &DebugOut..__first_periods as e
      on    p.mrn = e.mrn
      ;
   quit ;

%mend GetFollowUpTime;

%macro GetRxRiskForPeople(InFile, OutFile, IndexDt);
/*************************************************
* Tyler Ross
* Center for Health Studies
* 206-287-2927
* ross.t@ghc.org
*
* GetRxRiskForPeople.sas
*
* Purpose:
*	Calculates RxRisk comorbidity for a list of MRN. Indicates diseases based on
*   Rx fills.
*
* Notes:
*	This code was based heavily on Jim Savarino's RxRisk macro program
*	written for use at CHS.
*	If enrollment data is not available for the day before IndexDt, the enrollee
*   is assumed to not be on Medicaid nor Medicare.  This is partly because the
*		CRN specs do not distinguish between non-Medicare and missing.
*	Weights are callibrated separately for adults and children. Disease categories
*   in many cases are applicable to only one of these two models. The lable of
*   each disease starts with A if adults only, P if pediatrics only, and AP if
*   both apply.
*
*   Be aware that this macro may take a while depending on the size of your
*     cohort and the size of your data structures.
*
* Dependencies:
*	A series of SAS data files that accompany this program and a libref assigned
*		to the directory they are stored in in StdVars.sas
*   (%let _RxRiskLib="\\DIRECTORY";).
*	StdVars.sas--the site-customized list of standard macro variables.
*	The following variables from the following data structures
*			Demographics: MRN, Birth_Date, Gender  (All required)
*			Enrollment: MRN, Ins_Medicare, Ins_Medicaid (Not required)
*			Pharmacy: MRN, RxDate, NDC (Required)
*
*			****************************************************
*			***IMPORTANT***IMPORTANT***IMPORTANT***IMPORTANT****
*
*			The Pharmacy file must have all fills one year prior
*			to the index date for each enrollee for the results
*			to be accurate!
*
*			***IMPORTANT***IMPORTANT***IMPORTANT***IMPORTANT****
*			****************************************************
*
* Inputs:
*	A file with variables MRN and &IndexDt to calculate RxRisk.
*
* Output:
*	A file with 52 variables:
*		MRN
*		RxRisk = The RxRisk estimate of MRN's expenditures for the year
*					starting on IndexDt
*		Model = The model used to calculate RxRisk
*					A = Adult
*					P = Pediatric
*		49 Diseases = Series of disease dummies based on Rx fills
*
* Parameters:
*	&InFile  = The name of a file with distinct MRN
*	&OutFile = The name of the file that will be outputted
*	&IndexDt = The variable that holds the first day of the year's expenditures
*              that you want to estimate for each individual (i.e. the date on
*			         which to calculate the comorbidity.
*
* Version History
*
*	Created:	01/17/2006
*	Modified:	03/28/2006
*		- Added disease-specific sub-categories for adults & children.
* Modified: 10/20/2006
*   - Adjusted enrollment merge to match new enrollment specs
* Modified 3/24/2009 [RP]
*   - Fixed some of the joins so that this will run on sas 9.2.
*   - Prettied up some of the code
*   - Made the CondCodes{i} comparison literals text so this will run w/dsoptions="note2err".
*
* Users of RxRisk should cite these two papers, on which the work is based:
*
* Paul A. Fishman, Michael Goodman, Mark Hornbrook, Richard Meenan, Don Bachman,
*   Maureen OKeefe Rossetti, "Risk Adjustment Using Automated Pharmacy Data:
*   the RxRisk Model," Medical Care 2003;41:84-99
*
* Paul Fishman and David Shay,
* "A Pediatric Chronic Disease Score from Automated Pharmacy Data",
*    Medical Care, 1999,37(9) pp 872-880.
*
*************************************************/
  %local adultage ;
  %local MaxDisease ;

	%LET adultage=18;
	/*This limits the maximum number of different diseases a person can have*/
	%LET MaxDisease=20;

	libname risk "&_RxRiskLib.";

	/*Get the Cases file ready*/
	proc sql;
	/*Add on gender and age from demographics*/
	create table GrabDem as
	select 	distinct i.mrn
			, &IndexDt.
			, coalesce(ifn(upcase(d.gender)="M", 0, .),
			           ifn(upcase(d.gender)="F", 1, .)) as gender
			, floor((intck('month',d.Birth_Date,&IndexDt.)
				- (day(&IndexDt.) < day(d.Birth_Date))) / 12) as age
	from &infile. as i
		LEFT JOIN
		&_vdw_demographic as d
	on i.MRN = d.MRN
	;

	/*Add on Medicare and Medicaid from enrollment*/
	create table Cases as
	select 	  g.*
			, ifn(upcase(e.Ins_Medicare)="Y", 1, 0, 0) as Medicare
			, ifn(upcase(e.Ins_Medicaid)="Y", 1, 0, 0) as Medicaid
	from GrabDem as g
		INNER JOIN
		 &_vdw_enroll as e
	on g.MRN = e.MRN
	where &IndexDt. between e.Enr_Start and e.Enr_End
	;

	/*Get the drug file ready*/
	create table drugs as
	select    distinct i.mrn
			, i.&IndexDt.
			, r.RxDate
			, r.NDC
	from &infile as i
			LEFT JOIN
		 &_vdw_rx as r
    on    i.MRN = r.MRN
    where r.RxDate BETWEEN (&IndexDt.-366) AND (&IndexDt.-1) ;

	/* Attach a cost for age, adult model  */
  create table adult_cost_age_lookup as
  select a.code
      , c.cost
      , a.ageinclusive as age_lowbound
      , a.ageexclusive - 1 as age_highbound
      , a.female as gender
  from  risk.adultageclassification as a INNER JOIN
        risk.adultcostcoefficient as c
  on    a.code = c.code
  where age_lowbound ge &adultage
  ;

  create table adultcost as
  select  c.*
        , l.code
        , l.cost
        , 'A' as model
  from cases as c INNER JOIN
       adult_cost_age_lookup as l
  on   c.gender = l.gender
  WHERE c.age BETWEEN l.age_lowbound and l.age_highbound
  ORDER BY c.mrn
  ;

  drop table adult_cost_age_lookup ;

  /*
	create table adultcost as
	select    T1.*
    			, T2.code
    			, T3.cost
    			,'A' as Model
	from  risk.adultcostcoefficient as T3
		, Cases as T1 inner join risk.adultageclassification as T2
	on t3.code=t2.code
	where T1.age >= &adultage and T2.female=T1.gender and
		 (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
	order by MRN;
  */

	/* Attach a cost for age, pediatric model  */
  create table child_cost_age_lookup as
  select a.code
      , c.cost
      , a.ageinclusive as age_lowbound
      , a.ageexclusive - 1 as age_highbound
      , a.female as gender
  from  risk.childageclassification as a INNER JOIN
        risk.childcostcoefficient as c
  on    a.code = c.code
  where age_lowbound lt &adultage
  ;

  create table pedcost as
  select  c.*
        , l.code
        , l.cost
        , 'P' as model
  from cases as c INNER JOIN
       child_cost_age_lookup as l
  on   c.gender = l.gender
  WHERE c.age BETWEEN l.age_lowbound and l.age_highbound
  ORDER BY c.mrn
  ;

  drop table child_cost_age_lookup ;

  /*
	create table pedcost as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'P' as Model
	from risk.childcostcoefficient as T3
		, Cases as T1 inner join risk.childageclassification as T2
	on t3.code=t2.code
	where T1.age < &adultage and T2.female=T1.gender and
		(T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
	order by MRN
	;
  */


	/* For adult model , compute a cost factor for Medicare  */
	create table adult_medicare_lookup as
  select a.code
      , c.cost
      , a.ageinclusive as age_lowbound
      , a.ageexclusive - 1 as age_highbound
  from  risk.medicareclassification as a INNER JOIN
        risk.adultcostcoefficient as c
  on    a.code = c.code
  ;

  create table carecost as
  select  c.*
        , l.code
        , l.cost
        , 'A' as model
  from cases as c INNER JOIN
       adult_medicare_lookup as l
  on    c.medicare = 1 AND
        c.age ge &adultage AND
        c.age BETWEEN l.age_lowbound and l.age_highbound
  ORDER BY c.mrn
  ;

  drop table adult_medicare_lookup ;

  /*
	create table carecost as
	select 	  T1.*
			, T2.code
			, T3.cost
			,'A' as Model
	from risk.adultcostcoefficient as T3
		, Cases as T1 inner join risk.medicareclassification as T2
	on t3.code=t2.code
	where (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
		and (T1.age >= &adultage ) and (T1.medicare=1)
	order by MRN
	;
  */

	/* For adult, compute a cost factor for Medicaid when present  */
	create table medicaid_lookup as
  select a.code
      , c.cost
      , a.ageinclusive as age_lowbound
      , a.ageexclusive - 1 as age_highbound
  from  risk.medicaidclassification as a INNER JOIN
        risk.adultcostcoefficient as c
  on    a.code = c.code
  ;

  create table caidcost as
  select  c.*
        , l.code
        , l.cost
        , 'A' as model
  from cases as c INNER JOIN
       medicaid_lookup as l
  on    c.medicaid = 1 AND
        c.age ge &adultage AND
        c.age BETWEEN l.age_lowbound and l.age_highbound
  ORDER BY c.mrn
  ;

  /*
	create table caidcost as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'A' as Model
	from risk.adultcostcoefficient T3,
		Cases as T1 inner join risk.medicaidclassification as T2
	on t3.code=t2.code
	where (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
		and (T1.age >= &adultage ) and (T1.medicaid=1)
	order by MRN;

  */

	/* For pediatric model, compute a cost factor for Medicaid when present  */

  create table caidchld as
  select  c.*
        , l.code
        , l.cost
        , 'A' as model
  from  cases as c INNER JOIN
        medicaid_lookup as l
  on    c.medicaid = 1 AND
        c.age lt &adultage AND
        c.age BETWEEN l.age_lowbound and l.age_highbound
  ORDER BY c.mrn
  ;

  drop table medicaid_lookup ;

	/* Rebuild case information with age cost factor and medicare cost added */
	data caseinfo;
  		set adultcost pedcost;
  		by mrn;
	run;

	/* Drop working tables to free disk space */
	proc sql;
		drop table adultcost;
		drop table pedcost;

	/* Screen out any medications not within time window  */
	create table workmeds as
	select 	  T1.*
			, T2.age
	from drugs as T1 INNER JOIN caseinfo as T2
	on T2.MRN=T1.MRN
	where ( (T2.&IndexDt.-T1.RxDate) > 0 ) AND ( (T2.&IndexDt.-T1.RxDate) <= 365 )
	;

	/* Attach a cost coefficient to each medication, adult model  */
	create table work1 as
	select	  T1.*
			, T2.code
			, T3.cost
			, 'A' as Model
	from risk.adultcostcoefficient as T3
		, workmeds as T1 inner join risk.adultdrugclassification as T2
	on t2.ndccode=t1.ndc
	where t3.code=t2.code AND T1.age >= &adultage
	;

	/* Attach a cost coefficient to each medication, pediatric model */
	create table work2 as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'P' as Model
	from risk.childcostcoefficient as T3
		, workmeds as T1 inner join risk.childdrugclassification as T2
	on t2.ndccode=t1.ndc
	where t3.code=t2.code AND T1.age < &adultage
	;

	proc sql;  drop table workmeds; quit;

	/* Now remove duplicate cost classifications at case id level
  	   for adults. Sorting separately to reduce cost of sort...
	*/
	%local byvars ;
	%let byvars=mrn code;
	proc sort data=work1 nodupkey; by &byvars; run;

	/* Now remove duplicate cost classifications at case id level for children*/
	proc sort data=work2 nodupkey; by &byvars; run;

  %local keepvars ;
	/* Now produce file with rxrisk outcome */
	%let keepvars=MRN Model cost;
	data work3(keep=MRN model cost);
   		set work1(keep=&keepvars)
          work2(keep=&keepvars)
			caseinfo(keep=&keepvars)
			carecost(keep=&keepvars)
			caidcost(keep=&keepvars)
			caidchld(keep=&keepvars);
	run;

	proc sql;
		drop table work1;
		drop table work2;
		drop table carecost;
		drop table caidcost;
		drop table caidchld;

	/*Create Rx Variable*/
	create table work4 as
	select 	  MRN
			, sum(cost) as rxrisk
			, model
	from work3
	group by MRN, model
	;
	drop table work3;

	/*****************************************************
	* Modification to add disease indicators starts here *
	*****************************************************/

	/*Add codes for children*/
	create table DiseaseKids as
	select a.mrn, B.code, c.age
	from drugs as a, risk.childdrugclassification as B, GrabDem as c
	where a.ndc=B.ndccode AND a.mrn=c.mrn AND (0<=c.age<&adultage.)
	;
	/*Add codes for adults*/
	create table DiseaseAll as
	select a.mrn, B.code, c.age
	from drugs as a, risk.adultdrugclassification as B, GrabDem as c
	where a.ndc=B.ndccode AND a.mrn=c.mrn AND c.age>=&adultage.
	;
	quit;
	/*Combine kids and adults*/
	proc append base=DiseaseAll data=DiseaseKids; run;

	/*Keep first instance of each disease*/
	proc sort data=DiseaseAll nodupkey; by mrn code; run;

  proc sort data=DiseaseAll; by mrn age; run;

	proc transpose data=DiseaseAll out=DiseaseAll prefix=CondCode;
		var code;
		by mrn age;
	run;

  %local flag_names ;
  %let flag_names = Acne Allerg Alpha Amino Anxiety Asthma ADD Bipolar CAD
                		CLS CAH PRV CF Dep Dm2 Eczema Epi ESRD GAD Glaucoma Gout
                		GHD HD Hemophilia HIV Hyperlip HTN Immunod Iron IBS Lead
                		Liver Malabs Malig Ostomy Pain Inflame Parkin Pituitary
                		Psych Renal RDS RA Sickle	Steroid Thyroid Trache
                		Transplant TB ;

	/*Assign diseases*/
	data DiseaseAll (keep=mrn Acne--TB) ;
		set DiseaseAll;
		length &flag_names 3 ;

		array Conds{*} &flag_names ;

		do i = 1 to dim(Conds);
   			Conds{i} = 0;
		end;

		array CondCodes{*} CondCode1-CondCode&MaxDisease.;

		do i = 1 to dim(CondCodes);
			if CondCodes{i} 	   = '1' & age<&adultage.   then Acne       =1 ;
			else if CondCodes{i} = '2' & age<&adultage. 	then Allerg     =1 ;
			else if CondCodes{i} = '3' & age<&adultage. 	then Alpha      =1 ;
			else if CondCodes{i} = '4' & age<&adultage. 	then Amino      =1 ;
   		else if CondCodes{i} = '5'  					        then Anxiety    =1 ;
   		else if CondCodes{i} = '6'  					        then Asthma     =1 ;
			else if CondCodes{i} = '7' & age<&adultage. 	then ADD        =1 ;
   		else if CondCodes{i} = '8'  					        then Bipolar    =1 ;
   	  else if CondCodes{i} = '9'  					        then CAD        =1 ;
			else if CondCodes{i} = '10' & age<&adultage. 	then CLS        =1 ;
			else if CondCodes{i} = '11' & age<&adultage.	then CAH        =1 ;
			else if CondCodes{i} = '12' & age>=&adultage.	then PRV        =1 ;
			else if CondCodes{i} = '13' 					        then CF         =1 ;
			else if CondCodes{i} = '14' 					        then Dep        =1 ;
			else if CondCodes{i} = '15' 					        then Dm2        =1 ;
			else if CondCodes{i} = '16' & age<&adultage.	then Eczema     =1 ;
			else if CondCodes{i} = '17' 					        then Epi        =1 ;
			else if CondCodes{i} = '18' & age>=&adultage.	then ESRD       =1 ;
			else if CondCodes{i} = '19' 					        then GAD        =1 ;
			else if CondCodes{i} = '20' & age>=&adultage.	then Glaucoma   =1 ;
			else if CondCodes{i} = '21' & age>=&adultage.	then Gout       =1 ;
			else if CondCodes{i} = '22' & age<&adultage.	then GHD        =1 ;
			else if CondCodes{i} = '23' & age>=&adultage.	then HD         =1 ;
			else if CondCodes{i} = '24' & age<&adultage.	then Hemophilia =1 ;
			else if CondCodes{i} = '25' 					        then HIV        =1 ;
			else if CondCodes{i} = '26' 					        then Hyperlip   =1 ;
			else if CondCodes{i} = '27' & age>=&adultage.	then HTN        =1 ;
			else if CondCodes{i} = '28' & age<&adultage.	then Immunod    =1 ;
			else if CondCodes{i} = '29' & age<&adultage.	then Iron       =1 ;
			else if CondCodes{i} = '30' 					        then IBS        =1 ;
			else if CondCodes{i} = '31' & age<&adultage.	then Lead       =1 ;
			else if CondCodes{i} = '32' 					        then Liver      =1 ;
			else if CondCodes{i} = '33' & age<&adultage.	then Malabs     =1 ;
			else if CondCodes{i} = '34' 					        then Malig      =1 ;
			else if CondCodes{i} = '35' & age<&adultage.	then Ostomy     =1 ;
			else if CondCodes{i} = '36' & age<&adultage.	then Pain       =1 ;
			else if CondCodes{i} = '37' & age<&adultage.	then Inflame    =1 ;
			else if CondCodes{i} = '38' & age>=&adultage.	then Parkin     =1 ;
			else if CondCodes{i} = '39' & age<&adultage.	then Pituitary  =1 ;
			else if CondCodes{i} = '40' 					        then Psych      =1 ;
			else if CondCodes{i} = '41' 					        then Renal      =1 ;
			else if CondCodes{i} = '42' & age<&adultage.	then RDS        =1 ;
   		else if CondCodes{i} = '43' 					        then RA         =1 ;
			else if CondCodes{i} = '44' & age<&adultage.	then Sickle     =1 ;
			else if CondCodes{i} = '45' & age<&adultage.	then Steroid    =1 ;
			else if CondCodes{i} = '46' 					        then Thyroid    =1 ;
			else if CondCodes{i} = '47' & age<&adultage.	then Trache     =1 ;
			else if CondCodes{i} = '48' 					        then Transplant =1 ;
   		else if CondCodes{i} = '49' 					        then TB         =1 ;
		end;
	run;

   proc sql;
   /*Create Output File*/
   create table &outfile as
   select a.MRN
         , a.rxrisk                                   label ='RxRisk Comorbidity'
         , a.model                                    label ='Adult vs Pediatric Model'
         , coalesce(b.Acne        , 0) as Acne        label ='P1 Acne'                            length=3
         , coalesce(b.Allerg      , 0) as Allerg      label ='P2 Allergic Rhinitis'               length=3
         , coalesce(b.Alpha       , 0) as Alpha       label ='P3 Alpha'                           length=3
         , coalesce(b.Amino       , 0) as Amino       label ='P4 Amino Acid Disorders'            length=3
         , coalesce(b.Anxiety     , 0) as Anxiety     label ='AP5 Anxiety and Tension'            length=3
         , coalesce(b.Asthma      , 0) as Asthma      label ='AP6 Asthma'                         length=3
         , coalesce(b.ADD         , 0) as ADD         label ='P7 Attention Deficit Disorder'      length=3
         , coalesce(b.Bipolar     , 0) as Bipolar     label ='AP8 Bipolar Disorder'               length=3
         , coalesce(b.CAD         , 0) as CAD         label ='AP9 Cardiac Disease'                length=3
         , coalesce(b.CLS         , 0) as CLS         label ='P10 Central Line Supplies'          length=3
         , coalesce(b.CAH         , 0) as CAH         label ='P11 Congenital Adrenal Hypoplasia'  length=3
         , coalesce(b.PRV         , 0) as PRV         label ='A12 Coronary/Peripheral Vasc'       length=3
         , coalesce(b.CF          , 0) as CF          label ='AP13 Cystic Fibrosis'               length=3
         , coalesce(b.Dep         , 0) as Dep         label ='AP14 Depression'                    length=3
         , coalesce(b.Dm2         , 0) as Dm2         label ='AP15 Diabetes'                      length=3
         , coalesce(b.Eczema      , 0) as Eczema      label ='P16 Eczema'                         length=3
         , coalesce(b.Epi         , 0) as Epi         label ='AP17 Epilepsy'                      length=3
         , coalesce(b.ESRD        , 0) as ESRD        label ='A18 ESRD'                           length=3
         , coalesce(b.GAD         , 0) as GAD         label ='AP19 Gastric Acid Disorder'         length=3
         , coalesce(b.Glaucoma    , 0) as Glaucoma    label ='A20 Glaucoma'                       length=3
         , coalesce(b.Gout        , 0) as Gout        label ='A21 Gout'                           length=3
         , coalesce(b.GHD         , 0) as GHD         label ='P22 Growth Hormone Deficiency'      length=3
         , coalesce(b.HD          , 0) as HD          label ='A23 Heart Disease/Hypertension'     length=3
         , coalesce(b.Hemophilia  , 0) as Hemophilia  label ='P24 Hemophilia'                     length=3
         , coalesce(b.HIV         , 0) as HIV         label ='AP25 HIV'                           length=3
         , coalesce(b.Hyperlip    , 0) as Hyperlip    label ='AP26 Hyperlipidemia'                length=3
         , coalesce(b.HTN         , 0) as HTN         label ='A27 Hypertension'                   length=3
         , coalesce(b.Immunod     , 0) as Immunod     label ='P28 Immunodeficiency'               length=3
         , coalesce(b.Iron        , 0) as Iron        label ='P29 Iron Overload'                  length=3
         , coalesce(b.IBS         , 0) as IBS         label ='AP30 Irritable Bowel Syndrome'      length=3
         , coalesce(b.Lead        , 0) as Lead        label ='P31 Lead Poisoning'                 length=3
         , coalesce(b.Liver       , 0) as Liver       label ='AP32 Liver Disease'                 length=3
         , coalesce(b.Malabs      , 0) as Malabs      label ='P33 Malabsorbtion'                  length=3
         , coalesce(b.Malig       , 0) as Malig       label ='AP34 Malignancies'                  length=3
         , coalesce(b.Ostomy      , 0) as Ostomy      label ='P35 Ostomy'                         length=3
         , coalesce(b.Pain        , 0) as Pain        label ='P36 Pain'                           length=3
         , coalesce(b.Inflame     , 0) as Inflame     label ='P37 Pain and Inflammation'          length=3
         , coalesce(b.Parkin      , 0) as Parkin      label ='A38 Parkinsons Disease'             length=3
         , coalesce(b.Pituitary   , 0) as Pituitary   label ='P39 Pituitary Hormone'              length=3
         , coalesce(b.Psych       , 0) as Psych       label ='AP40 Psychotic Illness'             length=3
         , coalesce(b.Renal       , 0) as Renal       label ='AP41 Renal Disease'                 length=3
         , coalesce(b.RDS         , 0) as RDS         label ='P42 Respiratory Distriess Syndrome' length=3
         , coalesce(b.RA          , 0) as RA          label ='AP43 Rheumatoid Arthritis'          length=3
         , coalesce(b.Sickle      , 0) as Sickle      label ='P44 Sickle Cell Anemia'             length=3
         , coalesce(b.Steroid     , 0) as Steroid     label ='P45 Steroid Dependent Disease'      length=3
         , coalesce(b.Thyroid     , 0) as Thyroid     label ='AP46 Thyroid Disorder'              length=3
         , coalesce(b.Trache      , 0) as Trache      label ='P47 Tracheostomy'                   length=3
         , coalesce(b.Transplant  , 0) as Transplant  label ='AP48 Transplant'                    length=3
         , coalesce(b.TB          , 0) as TB          label ='AP49 Tuberculosis'                  length=3
   from work4 as a
      LEFT JOIN
       DiseaseAll as b
   on a.mrn=b.mrn
   ;

	drop table work4;
	quit;
%mend GetRxRiskForPeople;

%macro PrettyVar(VarName) ;
  %local __allups ;
  %local __4thups ;
  %local __delims ;
  %local __upprefixes ;

   %let __allups = %str('Po', 'Ne', 'Nw', 'Se', 'Sw', 'N.e.', 'N.w.', 'S.e.'
                      , 'S.w.', 'C/o', 'P.o.', 'P.o', 'Ii', 'Iii', 'Iv', 'Mlk', 'Us') ;
   %let __4thUps = %str('Maccoll', 'Maccubbin', 'Macdonald', 'Macdougall'
                      , 'Macgregor', 'Macintyre', 'Mackenzie', 'Macmenigall'
                      , 'Macneil', 'Macneill') ;
   %** These signify apartment numbers like #3A ;
   %let __upprefixes = %str('#', '1', '2', '3', '4'
                          , '5', '6', '7', '8', '9', '0') ;

   %let __delims = " -'." ;

   __i            = 0 ;
   __word         = '~' ;
   __pretty_var   = '' ;
   __propcased    = propcase(&VarName, &__delims) ;

   * We have had a lot of backticks & double-quotes in our address components at GHC. ;
   __propcased    = compress(__propcased, '`"') ;

   do while (__word ne '') ;
      * put __word = ;
      __i + 1 ;

      * This will eat any delimiters other than the space char. ;
      __word = scan(__propcased, __i, " ")  ;

      %* TODO: Apply address-word-regularizing format to __word here. ;

      if __word in(&__allups) then do ;
         __word = upcase(__word) ;
      end ;

      if __word in(&__4thUps) then do ;
         substr(__word, 4, 1) = upcase(substr(__word, 4, 1)) ;
      end ;

      * Try out upcasing the 3rd char for any word beginning with Mc ;
      if substr(__word, 1, 2) = 'Mc' then do ;
         substr(__word, 3, 1) = upcase(substr(__word, 3, 1)) ;
      end ;

      * Pound symbols signify apt. numbers--upcase those. ;
      /* if substr(__word, 1, 1) in (&__upprefixes)
          and reverse(substr(reverse(compress(__word)), 1, 2))
              not in (&__downsuffixes) then do ; */
      if substr(__word, 1, 1) in (&__upprefixes)  then do ;
         if prxmatch(__ordinal_regex, __word) > 0 then do ;
            * This is a 22nd, 34th type thing--leave it alone ;
         end ;
         else do ;
            * This is most likely an apartment number--upcase it. ;
            __word = upcase(__word) ;
         end ;
      end ;

      __pretty_var = compbl(__pretty_var || __word || ' ') ;

   end ;

   &VarName = left(__pretty_var) ;

%mend PrettyVar ;

%macro PrettyCase(InSet = , OutSet = , VarList = , MaxLength = 500) ;
   data &OutSet ;
      length __word __propcased __pretty_var $ &MaxLength ;
      retain __ordinal_regex ;
      set &InSet ;
      if _n_ = 1 then do ;
         %* This matches things like 21st, 5th, etc. ;
         __ordinal_regex = prxparse("/\d+(st|nd|rd|th)/i") ;
      end ;
      %local i ;
      %local ThisVar ;
      %let i = 0 ;
      %let ThisVar = ~ ;
      %do %until(%length(&ThisVar) = 0) ;
         %let i = %eval(&i + 1) ;
         %let ThisVar = %scan(&VarList, &i) ;
         %put Working on &ThisVar %length(&ThisVar) ;
         %if %length(&ThisVar) gt 0 %then %do ;
            %PrettyVar(VarName = &ThisVar) ;
         %end ;
      %end ;

      drop __: ;
   run ;
%mend PrettyCase ;

%macro GetCensusForPeople(InSet  , OutSet  ) ;
 /*Removed the year parameter so that vdw_census will always point
at the standard vars reference. DLK 08-19-2010 */
   proc sql ;
      create table &OutSet (drop = _mrn) as
      select *
      from  &InSet as i LEFT JOIN
            &_vdw_census (rename = (mrn = _mrn)) as c
      on    i.mrn = c._mrn
      ;
   quit ;

%mend GetCensusForPeople ;

%macro CleanRx(OutLib, Clean=N, Dirty=N, Report=Y);
/***************************************************************************
* Parameters:
*   OutLib  = The library name you've already declared where you want output
*             you elect to save (Clean="Y", Dirty="Y") to go.
*   Clean   = "Y" will output a table (in OutLib) with Rx fills deemed clean.
*             Any other value will not output this table.
*   Dirty   = "Y" will output a table (in Outlib) with Rx fills deemed dirty.
*             along with DirtyReason, a text variable explaining why the record
*             is dirty.  Any other value will not output this file.
*   Report  = "Y" will do a freq tabulation on the dirty data by DirtyReason,
*             report misspecified variable lengths, and perform freq tables on
*             the clean data.
*             Any other value will suppress this calculation.
*
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:
*   Created August 1, 2006
**************************************************************************/

  /*Catch Errors*/
  %if &Clean ^= Y AND &Dirty ^= Y AND &Report ^= Y %then %do;
    %put ERROR: YOU MUST SPECIFY AT LEAST ONE TABLE TO OUTPUT OR TO PRODUCE;
    %put ERROR: A REPORT. SET <<CLEAN>>, <<DIRTY>>, AND/OR <<REPORT>> TO "Y";
  %end;
  %else %do;
    %local DataStatement ;
    %local DirtyReturn ;
    %local CleanReturn ;
    /*This mess is so that we save a little IO time depending on whether
      programmer wants the datasets saved.*/
    %if &Report ^= Y AND &Clean ^= Y %then %do;
      %let DataStatement = &OutLib..Dirty;
      %let DirtyReturn   = output &Outlib..dirty;
      %let CleanReturn   = ;
    %end;
    %else %if &Report ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &OutLib..Clean (drop=DirtyReason);
      %let DirtyReturn = ;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output clean;
    %end;
    %else %if &Report = Y AND &Clean = Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &Outlib..Clean (drop=DirtyReason) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty = Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output clean;
    %end;
    %else %do; /*They want both clean and dirty, regardless of report*/
      %let DataStatement = &Outlib..Clean (drop=DirtyReason) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;

    /*Clean the data*/

    proc sort data=&_vdw_rx out=ToClean;
      by mrn rxdate ndc;
    run;

    data &DataStatement;
      set ToClean;
      by mrn rxdate ndc;
      length DirtyReason $30;

      if MISSING(MRN)=1 then do;
        DirtyReason = "Missing MRN";
        &DirtyReturn;
      end;
      else if MISSING(RxDate)=1 then do;
        DirtyReason = "Missing RxDate";
        &DirtyReturn;
      end;
      else if MISSING(NDC)=1 then do;
        DirtyReason = "Missing NDC";
        &DirtyReturn;
      end;
      else if rxdate > "&Sysdate."d then do;
        DirtyReason = "Dispense date in the future";
        &DirtyReturn;
      end;
      else if length(NDC) ^= 11 then do;
        DirtyReason = "NDC is improper length";
        &DirtyReturn;
      end;
      else if length(compress(NDC,'1234567890', 'k')) ^= 11 then do;
        DirtyReason = "NDC has non numeric values";
        &DirtyReturn;
      end;
      else if (MISSING(RxSup)=0 AND RxSup <= 0) then do;
        DirtyReason = "RxSup is non-positive";
        &DirtyReturn;
      end;
      else if (MISSING(RxAmt)=0 AND RxAmt <= 0) then do;
        DirtyReason = "RxAmt is non-positive";
        &DirtyReturn;
      end;
      else if (first.MRN=0 AND first.RxDate=0 AND first.NDC=0) then do;
        DirtyReason = "Duplicate MRN, RxDate, NDC";
        &DirtyReturn;
      end;
      else do;
        &CleanReturn;
      end;
    run;
    %if &Report = Y %then %do;
      proc format;
       	value RXSUPf
       	  low -  0 = 'Less than zero'
       	  0 <-< 28 = '1 to 27'
       	  28 - 32  = '28 to 32'
       	  32 <-< 58 = '33 to 57'
          58 - 63 = '58 to 63'
       	  63 <-< 88 = '64 to 87'
       	  88 - 95   = '88 to 95'
       	  95 <- high = 'More than 95'
       	;
        value RXAMTf
       	  low - 0 = 'Less than zero'
       	  0 <- 20 = '1 to 20'
       	  20 <- 40 = '21 to 40'
          40 <- 60 = '41 to 60'
       	  60 <- 80 = '61 to 80'
       	  80 <- 100 = '81 to 100'
       	  100 <- 200 = '101 to 200'
       	  200 <- high = 'More than 200'
       	;
      run;
      proc freq data= %if(&Clean=Y) %then &Outlib..Clean; %else Clean;;
        title "Frequency Distributions of Obs That Are Clean";
        format RxDate Year. RXSUP RXSUPf. RXAMT RXAMTf.;
        table RxDate RXSUP RXAMT /missing;
      run;
      proc freq data= %if(&Dirty=Y) %then &Outlib..Dirty noprint;
                      %else Dirty noprint;;
        table DirtyReason / out=DirtyReport;
      run;
      proc contents data=&_vdw_rx out=RxContents noprint; run;
      data WrongLength (keep=vname YourLength SpecLength);
        set RxContents;
        length vname $32. YourLength 8 SpecLength 8;
        vname = upcase(compress(name));
        if vname='MRN' then do;
          call symput('TotalRecords', compress(nobs));
          return;
        end;
        else if vname="RXDATE" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else if vname="NDC" AND length^=11 then do;
          YourLength=length;
          SpecLength=11;
          output;
        end;
        else if vname="RXSUP" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else if vname="RXAMT" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else return;
      run;
      *This should not error nor print if WrongLength is empty;
      proc print data=WrongLength;
        title "Table of Variables Having the Wrong Length";
      run;
      title "Frequency of Observations Not up to Specs by Reason";
      proc sql;
        select DirtyReason
             , COUNT as Frequency
             , COUNT/&TotalRecords. *100 as PercentOfAllRx
             , Percent as PercentOfDirtyRx
        from DirtyReport
        ;
      quit;
    %end;
  %end;
%mend CleanRx;

%macro GetVitalSignsForPeople (
              People  /* The name of a dataset containing the people whose
                           vitals you want*/
            , StartDt /* The date on which you want to start collecting vitals*/
            , EndDt   /* The date on which you want to stop collecting vitals */
            , Outset  /* The name of the output dataset containing the vitals */
            ) ;
   *Author: Tyler Ross, ross.t@ghc.org , 206-287-2927;


   /*Catch and Throw*/
   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %if %sysfunc(abs("&StartDt"d > "&EndDt"d))=1 %then %do ;
     %put PROBLEM: The start date you entered occurrs after the end date ;
     %put PROBLEM: Start date is "&StartDt." and end date is "&EndDt." ;
     %put PROBLEM: Doing nothing. ;
   %end ;
   %else %if %sysfunc(exist(&People))=0 %then %do;
     %put PROBLEM: The People dataset (&People.) does not exist. ;
     %put PROBLEM: Doing nothing. ;
   %end;
   %else %do;
   /*Get Vitals*/
     proc sql;
       create table &OutSet. as
         select v.*
         from &People as p
           INNER JOIN
              &_vdw_vitalsigns as v
         on p.mrn = v.mrn
         where v.Measure_Date BETWEEN "&StartDt"d AND "&EndDt"d
       ;
     quit;
   %end;
%mend GetVitalSignsForPeople;

/********************************************************************
* TESTING GetVitalSignsForPeople;
*
* *GRAB TEST PEOPLE;
* proc sql;
*   create table Afew as select distinct mrn from vdw.&_VitalData
*     where Measure_Date between '01May2005'd AND '15May2005'd;
* quit;
* *Problem 1;
* %*GetVitalSignsForPeople(afew,   05May2005, 10May2005, afew);
* *Problem 2;
* %*GetVitalSignsForPeople(afew,   05May2005, 01Jan1999, myout);
* *Problem 3;
* %*GetVitalSignsForPeople(nodata, 05May2005, 10May2005, myout);
* *No problems;
* %*GetVitalSignsForPeople(afew,   05May2005, 10May2005, myout);
*
**********************************************************************/


%macro Diabetes_Charlson(outfile, startdate, enddate, EncType = A);
/***************************************************************************
****************************************************************************
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:  Created September 15, 2006
*
* Purpose:
*   For the diabetes dx as defined by Charlson, this macro creates
*    - A dataset called Diabetes_Charlson with the dx and descriptions
*    - A format called Diabetes_Charlson with the dx
*    - A dataset called &outfile with all people having diabetes
*
* Parameters:
*   Outfile = the file that will contain the list of MRN of those with diabetes
*   StartDate = Date from which you want to start looking for diabetes dx
*   EndDate   = Date from which you want to stop looking for diabetes dx
*   EncType   = Value of A will search All encounters (default),
*               Value of I will search only Inpatient encounters
*               Value of B will search Both IP and OP for dx (but not others)
*
* Dependencies:
*   The Dx file (with the EncType variable as the char(2) version if you use
*                EncType = I or B options)
*   A call to input standard vars before running the macro
*
***************************************************************************
**************************************************************************/

**Catch and Throw;
%let EncType = %upcase(&EncType.);
%if (&EncType.^= A AND &EncType. ^= I AND &EncType. ^= B) %then %do;
  %put PROBLEM: The parameter 'Inpatient' must be among 'A', 'I', or 'B';
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%else %if %sysfunc(abs("&StartDate"d > "&EndDate"d))=1 %then %do;
  %put PROBLEM: The Startdate must be on or before the EndDate;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;

/**************************************
*From the Charlson Macro
***Diabetess;
     "250   "-"250.33",
	   "250.7 "-"250.73" = "DIAB"
***Diabetes with chronic complications
	   "250.4 "-"250.63" = "DIABC"
**************************************/



* TODO: Break this out into a separate macro that just defines the format, which we can share with the charlson macro--keep it DRY. ;
proc format;
  value $Diabetes_Charlson
     "250   "-"250.33",
	   "250.7 "-"250.73",
	   "250.4 "-"250.63"  = "DIABC"
  ;
run;

data Diabetes_Charlson;
*Note - Datalines are not allowed in macros;
  length diabetes_dx $6 description $50;

diabetes_dx="250"   ; description="DIABETES MELLITUS"          ; output;
*Just in case lets throw one in with the decimal;
diabetes_dx="250."  ; description="DIABETES MELLITUS"          ; output;
diabetes_dx="250.22"; description="DM2/NOS W HYPEROSMOL UNC"   ; output;
diabetes_dx="250.50"; description="DM2/NOS W EYE MANIF NSU"    ; output;
diabetes_dx="250.0" ; description="DIABETES MELLITUS UNCOMP"   ; output;
diabetes_dx="250.23"; description="DM1 HYPEROSMOLARITY UNC"    ; output;
diabetes_dx="250.51"; description="DM1 W EYE MANIFEST NSU"     ; output;
diabetes_dx="250.00"; description="DM2/NOS UNCOMP NSU"         ; output;
diabetes_dx="250.29"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.52"; description="DM2/NOS W EYE MANIF UNC"    ; output;
diabetes_dx="250.01"; description="DM1 UNCOMP NSU"             ; output;
diabetes_dx="250.3" ; description="DIABETES W COMA NEC"        ; output;
diabetes_dx="250.53"; description="DM1 W EYE MANIFEST UNC"     ; output;
diabetes_dx="250.02"; description="DM2/NOS UNCOMP UNC"         ; output;
diabetes_dx="250.30"; description="DM2/NOS W COMA NEC NSU"     ; output;
diabetes_dx="250.59"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.03"; description="DM1 UNCOMP UNC"             ; output;
diabetes_dx="250.31"; description="DM1 W COMA NEC NSU"         ; output;
diabetes_dx="250.6" ; description="DM2 NEUROLOGIC MANIFEST"    ; output;
diabetes_dx="250.09"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="503.2" ; description="DM2/NOS W COMA NEC UNC"     ; output;
diabetes_dx="250.60"; description="DM2/NOS W NEUR MANIF NSU"   ; output;
diabetes_dx="250.1" ; description="DIABETES W KETOACIDOSIS"    ; output;
diabetes_dx="250.33"; description="DM1 W COMA NEC UNC"         ; output;
diabetes_dx="250.61"; description="DM1 W NEURO MANIFEST NSU"   ; output;
diabetes_dx="250.10"; description="DM2/NOS W KETOACID NSU"     ; output;
diabetes_dx="250.4" ; description="DM W RENAL MANIFESTATION"   ; output;
diabetes_dx="250.62"; description="DM2/NOS W NEUR MANIF UNC"   ; output;
diabetes_dx="250.11"; description="DM1 W KETOACIDOSIS NSU"     ; output;
diabetes_dx="250.40"; description="DM2/NOS W REN MANIF NSU"    ; output;
diabetes_dx="250.63"; description="DM1 W NEURO MANIFEST UNC"   ; output;
diabetes_dx="250.12"; description="DM2/NOS W KETOACID UNC"     ; output;
diabetes_dx="250.41"; description="DM1 W RENAL MANIFEST NSU"   ; output;
diabetes_dx="250.7" ; description="DM W CIRC DISORDER"         ; output;
diabetes_dx="250.13"; description="DM1 W KETOACIDOSIS UNC"     ; output;
diabetes_dx="250.42"; description="DM2/NOS W REN MANIF UNC"    ; output;
diabetes_dx="250.70"; description="DM2/NOS W CIRC DIS NSU"     ; output;
diabetes_dx="250.19"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.43"; description="DM1 W RENAL MANIFEST UNC"   ; output;
diabetes_dx="250.71"; description="DM1 W CIRC DISORD NSU"      ; output;
diabetes_dx="250.2" ; description="DM W HYPEROSMOLARITY"       ; output;
diabetes_dx="250.49"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.72"; description="DM2/NOS W CIRC DIS UNC"     ; output;
diabetes_dx="250.20"; description="DM2/NOS W HYPEROSMOL NSU"   ; output;
diabetes_dx="250.5" ; description="DM W OPHTHALMIC MANIFEST"   ; output;
diabetes_dx="250.73"; description="DM1 W CIRC DISORD UNC"      ; output;
diabetes_dx="250.21"; description="DM1 HYPEROSMOLARITY NSU";   ; output;
run;

proc sql noprint;
  create table &outfile as
    select distinct mrn
    from &_vdw_dx
    where dx in(select diabetes_dx from diabetes_charlson)
      AND adate between "&startdate"d AND "&EndDate"d
%if       %upcase(&EncType.) = I %then AND EncType = "IP";
%else %if %upcase(&EncType.) = B %then AND EncType in("AV", "IP");
  ;
quit;

%exit: %mend Diabetes_Charlson;

/*TEST SECTION;
*Problem 1;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = Z);
*Problem 2;
%Diabetes_Charlson(outfile=MyTest, startdate=15May2004, enddate=01Mar2002
                 , EncType = A);
*Success 1;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = A);
*Success 2;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = I);
*Success 3;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = B);
*/



%macro GetDateRange(path, filename, print=1);
/***************************************************************************
****************************************************************************
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:
*   Created Sept 18, 2006
*
* Purpose:
*   For every variable in path.filename that has a date format, this macro
*     creates two global macro variables in date9 format with the names
*     TheDateVar_Min and TheDateVar_Max
*   You may optionally print the results to the lst file
*
* Parameters:
*   Path = The path name to the data file (which will get called as a libname)
*   Filename = The name of the data set
*   Print = Set to 0 will supress the date ranges printed to screen
*           Set to 1 (default) will show all date vars min and max values
*
* Examples:
*   %GetDateRange(&_TumorLib., &_TumorData.);
*   ...will create the global variables
*     DOD_Max, DOD_Min, BDate_Max, BDate_Min, DxDate_Max, DxDate_Min,
*     DT_Surg_Max, DT_Surg_Min and so forth where...
*   &DOD_MAX = 09Sep2006
*   &DOD_Min = 01Feb1982
*   and so forth
*
***************************************************************************
**************************************************************************/
  libname __PATH "&path.";

  %if %sysfunc(exist(__Path.&filename.)) = 0 %then %do;
    %put PROBLEM: The file &filename. does not exist in the path you specified;
    %put PROBLEM: Path = &path.;
    %put PROBLEM: DOING NOTHING;
    %goto exit;
  %end;
  %else %if (&print. ^=0 AND &print. ^=1) %then %do;
    %put PROBLEM: The print parameter must be equal to zero (0) or one (1);
    %put PROBLEM: DOING NOTHING;
    %goto exit;
  %end;

  *Go through the select twice -once for the globals that will be made;
  *  Once for the locals for the summary proc;
  proc sql noprint;
      select compress(name) || "_Max " || compress(name) || "_Min"
             into: ForGlobals separated by " "
      from dictionary.columns
      where upcase(compress(type))    = "NUM"
        AND upcase(compress(libname)) = "__PATH"
        AND upcase(compress(MemName)) = upcase("&filename")
        AND (
             index(upcase(format), "DATE") > 0
            OR
             index(upcase(format), "YY") > 0
            OR
             index(upcase(format), "JULIAN") > 0
            )
    ;
    select name into: DateVars_&filename. separated by " "
      from dictionary.columns
      where upcase(compress(type))    = "NUM"
        AND upcase(compress(libname)) = "__PATH"
        AND upcase(compress(MemName)) = upcase("&filename")
        AND (
             index(upcase(format), "DATE") > 0
            OR
             index(upcase(format), "YY") > 0
            OR
             index(upcase(format), "JULIAN") > 0
            )
    ;
  quit;

  *Verify that the macro variable exists (that there is at least one date var);
  %if %symexist(DateVars_&filename.) %then %do;

    %put The date variables in &filename. are &&DateVars_&filename;
    *Get the min and max of the date vars;
    proc summary data= __Path.&filename. noprint min max;
      var &&DateVars_&filename;
      output out=Ranges;
    run;
    *Make MAX come before MIN;
    proc sort data=Ranges; by _STAT_; run;

    *Allow user to see the results in the .lst file;
    %if &print. = 1 %then %do;
     proc print data=Ranges;
     title "The minimum and maximum values of the date variables in &filename.";
       where upcase(compress(_STAT_)) in("MIN", "MAX");
     run;
    %end;

    *Declare the variables as global - call symput will default to local o.w.;
    %global &ForGlobals;
    *Create local variables holding the min and max values;
    data _NULL_;
      set Ranges (where=(upcase(compress(_STAT_)) in("MIN", "MAX")));

      array datevars {*} _NUMERIC_ ;
      if _n_ = 1 then do;
        do i=1 to dim(datevars);
          if vname(datevars{i}) NOT IN("_TYPE_", "_FREQ_", "_STAT_") then
            call symput(vname(datevars{i}) || "_Max", put(datevars{i}, date9.));
        end;
      end;
      else do;
        do i=1 to dim(datevars);
          if vname(datevars{i}) NOT IN("_TYPE_", "_FREQ_", "_STAT_") then
            call symput(vname(datevars{i}) || "_Min", put(datevars{i}, date9.));
        end;
      end;
    run;

    *Clean up;
    proc sql;
      drop table Ranges;
    quit;
  %end;
  %else %do;
    %put PROBLEM: Sorry, but no date variables were found in &filename;
    %put PROBLEM: Verify that &filename. has at least one numeric variable;
    %put PROBLEM: formatted as a date variable;
    %goto exit;
  %end;

%exit: %mend GetDateRange;

*TEST SECTION;
/*******************
* Raise exceptions *
*******************/
*Print var out of range;
%*GetDateRange(&_RxLib. , &_RxData., print=2);
*Data that doesnt exist;
%*GetDateRange(&_RxLib. , NotReal);
*A file with no date variables;
%*GetDateRange(&_RxLib. , &_EverNDCData);

*NOW FOR SUCCESSFUL RUNS;
%*GetDateRange(&_UtilizationLib. , &_DXDATA.   , print=0);
%*GetDateRange(&_TumorLib.       , &_TUMORDATA., print=1);
%*GetDateRange(&_RxLib.          , &_RxData.   , print=1);
%*GetDateRange(&_VitalLib.       , &_VitalData          );

%*put _user_;


%macro Hypertension_BP(outfile, startdate, enddate,
                       Diastolic_Min = 90, Systolic_Min = 140,
                       Strict_Equality = 0, Either = 1);

/***************************************************************************
****************************************************************************
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History: Created September 27, 2006

* Purpose:
*   Pulls all people with a systolic and-or diastolic BP reading above
*     specified threasholds over specified dates along with their highest
*     systolic and diastolic readings in that period. Can be used to defined
*     hypertension.
*
* Parameters:
*   Outfile = The name of the file that will be output
*   StartDate = The date from which you want to start looking for BP
*   EndDate   = The date to which you want to end looking for BP
*   Diastolic_Min = The minimum diastolic value that will be allowed in output
*   Systolic_Min  = The minimum systolic  value that will be allowed in output
*   Strict_Equality = 0 allows BP readings of min values and above
*                     1 only allows BP readings above the min values
*   Either = 0 requires a systolic AND a diastolic reading above the min
*            1 allows either a systolic OR a diastolic reading above the min
*
* Notes:
*   Systolic and diastolic readings above mins are not required to be on
*   the same day when Either = 0 is specified.
*
***************************************************************************
**************************************************************************/

%if %sysfunc(abs("&StartDate"d > "&EndDate"d))=1 %then %do;
  %put PROBLEM: The StartDate must be on or before the EndDate;
  %put StartDate is &StartDate., EndDate is &EndDate.;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%if (&Diastolic_Min < 0 OR &Systolic_Min < 0) %then %do;
  %put PROBLEM: The min values for BP must be non-negative;
  %put Diastolic_Min = &Diastolic_Min. , Systolic_Min = &Systolic_Min.;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%if (&Strict_Equality. ^= 0 AND &Strict_Equality. ^= 1) %then %do;
  %put PROBLEM: The Strict_Equality variable must be 0 or 1;
  %put Strict_Equality = &Strict_Equality;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%if (&Either. ^= 0 AND &Either. ^= 1) %then %do;
  %put PROBLEM: The Either variable must be 0 or 1;
  %put Either = &Either;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;

*Create conditional;
%local conditional ;
%if (&Strict_Equality. = 0 AND &Either. = 1) %then %do;
  %let Conditional= max(Diastolic) >= &Diastolic_Min.
                 OR max(Systolic)  >= &Systolic_Min.;
%end;
%else %if (&Strict_Equality. = 1 AND &Either. = 1) %then %do;
  %let Conditional= max(Diastolic) > &Diastolic_Min.
                 OR max(Systolic)  > &Systolic_Min.;
%end;
%else %if (&Strict_Equality. = 0 AND &Either. = 0) %then %do;
  %let Conditional= max(Diastolic) >= &Diastolic_Min.
                AND max(Systolic)  >= &Systolic_Min.;
%end;
%else %if (&Strict_Equality. = 1 AND &Either. = 0) %then %do;
  %let Conditional= max(Diastolic) > &Diastolic_Min.
                AND max(Systolic)  > &Systolic_Min.;
%end;



proc sql;
 create table &outfile. as
   select mrn
        , max(Diastolic) as Max_Diastolic
 label = "Person's highest diastolic reading between &StartDate. and &EndDate."
        , max(Systolic)  as Max_Systolic
 label = "Person's highest systolic reading between &StartDate. and &EndDate."
   from &_vdw_vitalsigns (where=(Measure_Date between "&StartDate"d
                                                 AND "&EndDate"d  ))
   group by mrn
   having &Conditional.
 ;
quit;

%exit: %mend Hypertension_BP;

/*TEST SECTION;
proc format;
  value sysf
    low  -  0    = "Non-positive"
    0   <-< 130  = "<130"
    130  -< 140  = "130 to 139"
    140          = "140"
    140 <-< 160  = "140 to 159"
    160  -< 180  = "160 to 179"
    180  -  high = "180+"
  ;
  value diaf
    low  -  0    = "Non-positive"
    0   <-< 80   = "<80"
    80   -< 90   = "80 to 89"
    90           = "90"
    90  <-< 100  = "90 to 99"
    100  -< 110  = "100 to 110"
    110  -  high = "110+"
  ;
quit;
*Problem 1;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2002);
*Problem 2;
%Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Diastolic_Min=-5, Systolic_Min=10);
*Problem 3;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Strict_Equality=Y);
*Problem 4;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Either=2);


*Success 1;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006);
proc freq data=testing;
  title "Success 1";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
proc sort data=testing NODUPKEY; by mrn; run;
*Success 2;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Diastolic_Min=85, Systolic_Min=135);
proc freq data=testing;
  title "Success 2";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 3;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Strict_Equality=1, Either=1);
proc freq data=testing;
  title "Success 3";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 4;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Strict_Equality=0, Either=0);
proc freq data=testing;
  title "Success 4";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 5;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Strict_Equality=1, Either=0);
proc freq data=testing;
  title "Success 5";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 6;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
               Diastolic_Min=90, Systolic_Min=150, Strict_Equality=1, Either=0);
proc freq data=testing;
  title "Success 6";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*/

%macro CleanEnroll(OutLib, Clean=N, Dirty=N, Report=Y, EnrollDset = &_vdw_enroll);
/***************************************************************************
* Parameters:
*   OutLib  = The library name you've already declared where you want output
*             you elect to save (Clean="Y", Dirty="Y") to go.
*   Clean   = "Y" outputs a table (in OutLib) with enroll records deemed clean.
*             Any other value will not output this table.
*   Dirty   = "Y" outputs a table (in Outlib) with enroll records deemed dirty.
*             along with DirtyReason, a text variable explaining why the record
*             is dirty.  Any other value will not output this file.
*   Report  = "Y" will do a freq tabulation on the dirty data by DirtyReason,
*             report misspecified variable lengths, and perform freq tables on
*             the clean data.
*             Any other value will suppress this calculation.
*
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* Modified by:
*   David Tabano
*   Institute for Health Research, Kaiser Permanente Colorado
*   (303)614-1348
*   david.c.tabano@kp.org
*
* History:
*   Created October 13, 2006
*   Modified August 23, 2011
**************************************************************************/

  /*Catch Errors*/
  %if &Clean ^= Y AND &Dirty ^= Y AND &Report ^= Y %then %do;
    %put ERROR: YOU MUST SPECIFY AT LEAST ONE TABLE TO OUTPUT OR TO PRODUCE;
    %put ERROR: A REPORT. SET <<CLEAN>>, <<DIRTY>>, AND/OR <<REPORT>> TO "Y";
  %end;
  %else %do;
    /*This mess is so that we save a little IO time depending on whether
      programmer wants the datasets saved.*/
    %local DataStatement ;
    %local DirtyReturn ;
    %local CleanReturn ;
    %if &Report ^= Y AND &Clean ^= Y %then %do;
      %let DataStatement = &OutLib..Dirty;
      %let DirtyReturn   = output &Outlib..dirty;
      %let CleanReturn   = ;
    %end;
    %else %if &Report ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &OutLib..Clean (drop=DirtyReason LastEnd);
      %let DirtyReturn = ;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason LastEnd) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output clean;
    %end;
    %else %if &Report = Y AND &Clean = Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &Outlib..Clean (drop=DirtyReason LastEnd) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty = Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason LastEnd) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output clean;
    %end;
    %else %do; /*They want both clean and dirty, regardless of report*/
  %let DataStatement = &Outlib..Clean (drop=DirtyReason LastEnd) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;


    %** helper macro ;
    %macro checkflag(var, flag_vals = %str('Y', 'N', 'U')) ;
      else if &var NOT IN(&flag_vals) then do;
        DirtyReason = "Invalid value for &var";
        &DirtyReturn;
      end;
    %mend checkflag ;

    /*Clean the data*/

    proc sort data=&_vdw_enroll out=ToClean;
      by mrn enr_start;
    run;

    data &DataStatement;
      set &_vdw_enroll end = last ;
      by mrn enr_start;
      length DirtyReason $40 LastEnd 4 DaysEnrolled 8;

      DaysEnrolled = Enr_End - Enr_Start + 1;

      if MISSING(MRN)=1 then do;
        DirtyReason = "Missing MRN";
        &DirtyReturn;
      end;
      else if MISSING(enr_start)=1 then do;
        DirtyReason = "Missing ENR_Start";
        &DirtyReturn;
      end;
      else if MISSING(enr_end)=1 then do;
        DirtyReason = "Missing ENR_End";
        &DirtyReturn;
      end;
      else if enr_end < enr_start then do;
        DirtyReason = "Enr_end is BEFORE enr_start";
        &DirtyReturn;
      end;
      else if first.MRN = 0 AND LastEND > enr_start then do;
        DirtyReason = "Enroll period overlaps with other obs";
        &DirtyReturn;
      end;

      %checkflag(var = ins_medicare)
      %checkflag(var = ins_medicare_a)
      %checkflag(var = ins_medicare_b)
      %checkflag(var = ins_medicare_c)
      %checkflag(var = ins_medicare_d)
      %checkflag(var = ins_medicaid)
      %checkflag(var = ins_commercial)
      %checkflag(var = ins_privatepay)
      %checkflag(var = ins_selffunded)
      %checkflag(var = ins_statesubsidized)
      %checkflag(var = ins_highdeductible)
      %checkflag(var = ins_other)

      %checkflag(var = enrollment_basis, flag_vals = %str('G', 'I', 'B'))

      %checkflag(var = plan_hmo)
      %checkflag(var = plan_ppo)
      %checkflag(var = plan_pos)
      %checkflag(var = plan_indemnity)

      %checkflag(var = outside_utilization)

      %checkflag(var = drugcov)
      else do;
        &CleanReturn;
      end;
      LastEnd = enr_end;
      retain LastEnd;
      ** Putting this here b/c proc contents spits out a missing for obs when run against a view. ;
      if last then do ;
        call symput('TotalRecords', put(_n_, best.)) ;
      end ;
      format LastEnd mmddyy10. ;
    run;

    %if &Report = Y %then %do;
      proc format;
        value DEnrollf
          1           = "1 Day"
          2    - 27   = "2 to 27 days"
          28   - 31   = "28 to 31 days"
          32   - 93   = "32 to 93 days"
          94   - 186  = "94 to 186 days"
          187  - 363  = "187 to 363 days"
          364  - 366  = "364 to 366 days"
          367  - 1096 = "367 to 1096 days (3 years)"
          1096 - high = "More than 1096 days"
          other       = "Other?!"
        ;
      run;
      proc freq data= %if(&Clean=Y) %then &Outlib..Clean; %else Clean;;
        title "Frequency Distributions of Obs That Are Clean";
        format Enr_Start MMYY. Enr_End MMYY. DaysEnrolled DEnrollf.;
        table Enr_Start Enr_End DaysEnrolled Ins_Medicare Ins_Medicaid
              Ins_Commercial Ins_PrivatePay Ins_Other DRUGCOV;
      run;
      proc freq data= %if(&Dirty=Y) %then &Outlib..Dirty noprint;
                      %else Dirty noprint;;
        table DirtyReason / out=DirtyReport;
      run;
      proc contents data=&_vdw_enroll out=EnrollContents noprint;
      run;

      data WrongLength (keep=vname YourLength SpecLength);
        set EnrollContents;
        length vname $32. YourLength 8 SpecLength 8;

        vname = upcase(compress(name));

        select (vname) ;
          when ('MRN') do ;
            ** Doing this is the dsetp above b/c the below does not work if _vdw_enroll points to a view. ;
            ** call symput('TotalRecords', put(nobs, best.));
            return;
          end ;
          when ('INS_MEDICARE'
                , 'INS_MEDICAID'
                , 'INS_COMMERCIAL'
                , 'INS_PRIVATEPAY'
                , 'INS_OTHER'
                , 'DRUGCOV'
                , "INS_STATESUBSIDIZED"
                , "INS_SELFFUNDED"
                , "INS_HIGHDEDUCTIBLE"
                , "INS_MEDICARE_A"
                , "INS_MEDICARE_B"
                , "INS_MEDICARE_C"
                , "INS_MEDICARE_D"
                , "PLAN_HMO"
                , "PLAN_POS"
                , "PLAN_PPO"
                , "PLAN_INDEMNITY"
                , "OUTSIDE_UTILIZATION"
                , "ENROLLMENT_BASIS"
                ) do ;
            YourLength = length ;
            SpecLength = 1 ;
          end ;
          ** Dropping the PCC PCP length checks b/c the spec allows those to vary. ;
          otherwise do ;
            ** put "Got " vname= "--doing nothing." ;
          end ;
        end ;
        if YourLength ne SpecLength then output ;
      run ;

      **This should not error nor print if WrongLength is empty;
      proc print data=WrongLength;
        title "Table of Variables Having the Wrong Length";
      run;
      title "Frequency of Observations Not up to Specs by Reason";
      proc sql;

        select DirtyReason
             , COUNT as Frequency
             , (COUNT / &TotalRecords ) * 100 as PercentOfAllEnroll
             , Percent as PercentOfDirtyEnroll
          from DirtyReport
        ;
      quit;
    %end;
  %end;
%mend CleanEnroll;
%macro CleanVitals(OutLib, Clean=N, Dirty=N, Report=Y, Limits=N);
/***************************************************************************
* Parameters:
*   OutLib  = The library name you've already declared where you want output
*             you elect to save (Clean="Y", Dirty="Y") to go.
*   Clean   = "Y" outputs a table (in OutLib) with records deemed clean.
*             Any other value will not output this table.
*   Dirty   = "Y" outputs a table (in Outlib) with records deemed dirty.
*             along with DirtyReason, a text variable explaining why the record
*             is dirty.  Any other value will not output this file.
*   Report  = "Y" will do a freq tabulation on the dirty data by DirtyReason,
*             report misspecified variable lengths, and perform freq tables on
*             the clean data.
*             Any other value will suppress this calculation.
*   Limits  = "Y outputs a table called LIMITS (in Outlib) with only those
*             values in the vitals sign dataset that values compatible with life
*
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:
*   Created January 8, 2007
**************************************************************************/

  /*Catch Errors*/
  %if &Clean ^= Y AND &Dirty ^= Y AND &Report ^= Y %then %do;
    %put ERROR: YOU MUST SPECIFY AT LEAST ONE TABLE TO OUTPUT OR TO PRODUCE;
    %put ERROR: A REPORT. SET <<CLEAN>>, <<DIRTY>>, AND/OR <<REPORT>> TO "Y";
  %end;
  %else %do;
    /*This mess is so that we save a little IO time depending on whether
      programmer wants the datasets saved.*/

    %local DataStatement ;
    %local DirtyReturn   ;
    %local CleanReturn   ;

    %if &Report ^= Y AND &Clean ^= Y %then %do;
      %let DataStatement = &OutLib..Dirty;
      %let DirtyReturn   = output &Outlib..dirty;
      %let CleanReturn   = output clean;
    %end;
    %else %if &Report ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &OutLib..Clean (drop=DirtyReason);
      %let DirtyReturn = ;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output clean;
    %end;
    %else %if &Report = Y AND &Clean = Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &Outlib..Clean (drop=DirtyReason) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty = Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason ) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output clean;
    %end;
    %else %do; /*They want both clean and dirty, regardless of report*/
  %let DataStatement = &Outlib..Clean (drop=DirtyReason) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;

    /*Clean the data*/


    **IMPUTE BMI FROM SCRATCH;
    %local verybig ;
    %LET verybig = 10000000000000000;
    data NumberOff;
      set &_vdw_vitalsigns;
      length id 8;
      id=_n_;
    run;
    proc sort data=NumberOff out=Forwards;  by MRN            Measure_Date; run;
    proc sort data=NumberOff out=Backwards; by MRN Descending Measure_Date; run;

    data forwardBMI (keep=id CDays_Diff CBMI absdiff);
      set forwards (keep=MRN HT WT Measure_Date id Days_Diff BMI);
      length
        oldht      8
    	  CDays_Diff 4
    	  olddt      4
    	  absdiff    4
    	  CBMI       8
      ;

      by mrn;

      *Calculate BMI, take old HT when HT is missing;
      if WT = . then do; CBMI = .; CDays_Diff=.; absdiff=&verybig; end;
      else do;
        if (HT^=.)  then do;
          CBMI = round((WT*0.454)/(HT*0.0254 * HT*0.0254), 0.1);
    	    CDays_Diff=0;
    	    absdiff=.;
          oldht = HT;
          olddt=Measure_Date;
        end;
        else if(oldht=.) then do; CBMI=.; CDays_Diff=.; absdiff=&verybig; end;
        else do;
          CBMI = round((WT*0.454)/(oldht*0.0254 * oldht*0.0254), 0.1);
          CDays_Diff = (olddt - Measure_Date) ;
    	    absdiff = abs(CDays_Diff);
        end;
      end;

      if last.mrn=1 then do; oldht = .; olddt=.; end;
      retain oldht olddt;
    run;

    data backwardBMI (keep=id CDays_Diff CBMI absdiff);
      set backwards (keep=MRN HT WT Measure_Date id Days_Diff BMI);
      length
        oldht      8
    	  CDays_Diff 4
    	  olddt      4
    	  absdiff    4
    	  CBMI       8
      ;

      by mrn;

      *Calculate BMI, take old HT when HT is missing;
      if WT = . then do; CBMI = .; CDays_Diff=.; absdiff=&verybig; end;
      else do;
        if (HT^=.)  then do;
          CBMI = round((WT*0.454)/(HT*0.0254 * HT*0.0254), 0.1);
    	    CDays_Diff=0;
    	    absdiff=0;
          oldht = HT;
          olddt=Measure_Date;
        end;
        else if(oldht=.) then do; CBMI=.; CDays_Diff=.; absdiff=&verybig; end;
        else do;
          CBMI = round((WT*0.454)/(oldht*0.0254 * oldht*0.0254), 0.1);
    	  /*VERY TRICKY - This line stays the same despite the backward run*/
          CDays_Diff = (olddt - Measure_Date);
    	    absdiff = abs(CDays_Diff);
        end;
      end;

      if last.mrn=1 then do; oldht = .; olddt=.; end;
      retain oldht olddt;
    run;
    /*Keep the version with the smaller date difference*/
    proc append base=backwardBMI  data=forwardBMI; run;
    proc sort   data=backwardBMI; by id absdiff; run;
    proc sort   data=backwardBMI NODUPKEY; by id; run;

    *APPEND CBMI to dataset;
    data &DataStatement;
      merge NumberOff
            BackwardBMI;
      by id;

      length DirtyReason $40 ;

      if MISSING(MRN)=1 then do;
        DirtyReason = "Missing MRN";
        &DirtyReturn;
      end;
      else if MISSING(Measure_Date)=1 then do;
        DirtyReason = "Missing Measure_Date";
        &DirtyReturn;
      end;
      else if HT < 0 AND MISSING(HT)=0 then do;
        DirtyReason = "HT is less than zero";
        &DirtyReturn;
      end;
      else if WT < 0 AND MISSING(WT)=0 then do;
        DirtyReason = "WT is less than zero";
        &DirtyReturn;
      end;
      else if Diastolic < 0 AND MISSING(Diastolic)=0 then do;
        DirtyReason = "Diastolic is less than zero";
        &DirtyReturn;
      end;
      else if Systolic < 0 AND MISSING(Systolic)=0 then do;
        DirtyReason = "Systolic is less than zero";
        &DirtyReturn;
      end;
      else if BMI < 0 AND MISSING(BMI)=0 then do;
        DirtyReason = "BMI is less than zero";
        &DirtyReturn;
      end;
      else if POSITION NOT IN("1", "2", "3", "") then do;
        DirtyReason = "Invalid value for Position";
        &DirtyReturn;
      end;
      else if round(BMI, 0.1) ^= round(CBMI, 0.1) then do;
        DirtyReason = "BMI value is imputed incorrectly";
        &DirtyReturn;
      end;
      else if Days_Diff ^= CDays_Diff then do;
        if (Days_Diff = CDays_Diff *-1 AND Days_Diff ^= 0)
          then DirtyReason = "Days_Diff is of the opposite sign";
          else DirtyReason = "Days_Diff is not correct";
        &DirtyReturn;
      end;
      else do;
        &CleanReturn;
      end;
    run;

    *MANUFACTURE REPORT;
    %if &Report = Y %then %do;
      proc format;
        value HTf
          0          = 'Exactly zero'
          0  <-  12  = '0 to 1 foot'
          12 <-  24  = '1 to 2 feet'
          24 <-  36  = '2 to 3 feet'
          36 <-  48  = '3 to 4 feet'
          48 <-  60  = '4 to 5 feet'
          60 <-  72  = '5 to 6 feet'
          72 <-  84  = '6 to 7 feet'
          84 <-  96  = '7 to 8 feet'
          96 <-  108 = '8 to 9 feet'
          108 <- 120 = '9 to 10 feet'
          120 <- high = 'Over 10 feet'
          .          = 'Missing'
          other      = 'Less than zero?!'
        ;
        value WTf
          0          = 'Zero exactly'
          0   <-  40 = '0 to 40 pounds'
          40  <-  80 = '40 to 80 pounds'
          80  <- 120 = '80 to 120 pounds'
          120 <- 160 = '120 to 160 pounds'
          160 <- 200 = '160 to 200 pounds'
          200 <- 240 = '200 to 240 pounds'
          240 <- 280 = '240 to 280 pounds'
          280 <- 320 = '280 to 320 pounds'
          320 <- 400 = '320 to 400 pounds'
          400 <- 500 = '400 to 500 pounds'
          500 <- 600 = '500 to 600 pounds'
          600 - high = 'More than 600 pounds'
          .          = 'Missing'
          other      = 'Less than zero?!'
        ;
        value datediff
         -10000 -< -5000  = '-10000 to -5000'
          -5000 -< -2500  = '-5000 to -2500'
          -2500 -< -365   = '-2500 to -365'
          -365  -< -180   = '-365 to -180'
          -180  -< -30    = '-180 to -30'
          -30   -< 0      = '-30 to 0'
          0               = '0 exactly'
          0     <-< 30    = '0 to 30'
          30     -< 180   = '30 to 180'
          180    -< 365   = '180 to 365'
          365    -< 2500  = '365 to 2500'
          2500   -< 5000  = '2500 to 5000'
          5000   -< 10000 = '5000 to 10000'
          .               = 'Missing'
          other           = 'Other'
        ;
        value systolicf
          0            = "Exactly zero"
          0   <-< 110  = "<110"
          110  -< 120  = "110 to 119"
          120  -< 130  = "120 to 129"
          130  -< 140  = "130 to 139"
          140          = "140"
          140 <-< 150  = "140 to 149"
          150  -< 160  = "150 to 159"
          160  -< 170  = "160 to 169"
          170  -< 180  = "170 to 179"
          180  -  high = "180+"
          .            = "Missing"
          other        = "Less than zero?!"
        ;
        value diastolicf
          0            = "Exactly zero"
          0   <-< 60   = "<60"
          60   -< 70   = "60 to 69"
          70   -< 80   = "70 to 79"
          80   -< 90   = "80 to 89"
          90           = "90"
          90  <-< 100  = "90 to 99"
          100  -< 110  = "100 to 109"
          110  -< 120  = "110 to 119"
          120  -< 130  = "120 to 129"
          130  -  high = "130+"
          .            = "Missing"
          other        = "Less than zero?!"
        ;
        value BMIf
  	      0             = 'Zero'
	        0    <-< 18.5 = 'Adult Underweight'
	        18.5  -< 25   = 'Adult Normal'
          25    -< 30   = 'Adult Overweight'
	        30    - 50    = 'Adult Obese to 50'
	        50   <- high  = 'Greater than 50'
	        .             = 'Missing'
	        other         = "Other?!"
        ;
        value $ positionf
          "1" = "Sitting"
          "2" = "Standing"
          "3" = "Supine"
          " "  = "Unkown"
          other = "Unexpected Value!?"
        ;
      run;
      proc freq data= %if(&Clean=Y) %then &Outlib..Clean; %else Clean;;
        title "Frequency Distributions of Obs That Are Clean";
        format HT HTf. WT WTf. Days_Diff datediff. Measure_Date year. BMI BMIf.
               systolic systolicf. diastolic diastolicf. position $positionf.;
        table HT WT BMI Days_Diff Measure_Date
              Systolic Diastolic position/missing;
      run;
      proc freq data= %if(&Dirty=Y) %then &Outlib..Dirty noprint;
                      %else Dirty noprint;;
        table DirtyReason / out=DirtyReport;
      run;
      proc contents data=&_vdw_vitalsigns out=VitalContents noprint;
      run;

      data WrongLength (keep=vname YourLength SpecLength);
        set VitalContents;
        length vname $32. YourLength 8 SpecLength 8;
        vname = upcase(compress(name));
        if vname='MRN' then do;
          call symput('TotalRecords', compress(nobs));
          return;
        end;
        else if vname="Measure_Date" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else if vname="HT" AND length^=8 then do;
          YourLength=length;
          SpecLength=8;
          output;
        end;
        else if vname="WT" AND length^=8 then do;
          YourLength=length;
          SpecLength=8;
          output;
        end;
        else if vname="BMI" AND length^=8 then do;
          YourLength=length;
          SpecLength=8;
          output;
        end;
        else if vname="DAYS_DIFF" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else if vname="DIASTOLIC" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else if vname="SYSTOLIC" AND length^=4 then do;
          YourLength=length;
          SpecLength=4;
          output;
        end;
        else if vname="POSITION" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else return;
      run;

      *This should not error nor print if WrongLength is empty;
      proc print data=WrongLength;
        title "Table of Variables Having the Wrong Length";
      run;
      title "Frequency of Observations Not up to Specs by Reason";
      proc sql;
        select DirtyReason
             , COUNT as Frequency
             , COUNT/&TotalRecords. * 100 as PercentOfAllVitalData
             , Percent as PercentOfDirtyVitalData
          from DirtyReport
        ;
      quit;
    %end;
  %end;
  %if &Limits=Y %then %do;
  %local cleaner ;
    %if &Clean=Y %then %let cleaner=&Outlib..clean;
      %else %let cleaner=clean;
    proc sql;
      create table &Outlib..LIMITS (drop=_age) as
        select a.*
             , %CalcAge(b.Birth_Date, a.Measure_Date) as _age
        from &cleaner. as a
          INNER JOIN &_vdw_demographic as b
          on a.mrn=b.mrn
        where
         (    (calculated _age = 0               AND a.HT between 3 and 41)
           OR (calculated _age between 1  and 5  AND a.HT between 12 and 60)
           OR (calculated _age between 6  and 12 AND a.HT between 20 and 84)
           OR (calculated _age between 13 and 17 AND a.HT between 30 and 108)
           OR (calculated _age >= 18             AND a.HT between 36 and 108)
           OR MISSING(a.HT)=1
         )
         AND
         (    (calculated _age = 0               AND a.WT between 0 and  80)
           OR (calculated _age between 1  and 5  AND a.WT between 9 and 200)
           OR (calculated _age between 6  and 12 AND a.WT between 20 and 350)
           OR (calculated _age between 13 and 17 AND a.WT between 25 and 650)
           OR (calculated _age >= 18             AND a.WT between 50 and 1000)
           OR MISSING(a.WT)=1
         )
         AND (a.BMI between 8 and 200        OR MISSING(a.BMI)=1)
         AND (a.Systolic between 50 and 300  OR MISSING(a.Systolic)=1)
         AND (a.Diastolic between 20 and 160 OR MISSING(a.Diastolic)=1)
      ;
    quit;
  %end;
%mend CleanVitals;

%macro SimpleContinuous(People      /* A dataset of MRNs whose enrollment we are considering. */
                     , StartDt      /* A date literal identifying the start of the period of interest. */
                     , EndDt        /* A date literal identifying the end of the period of interest. */
                     , DaysTol      /* The # of days gap between otherwise contiguous periods of enrollment that is tolerable. */
                     , OutSet       /* Name of the desired output dset */
                     , EnrollDset = &_vdw_enroll /* For testing. */
                     ) ;

/*

   A simple macro to evaluate whether a group of people were
   continuously enrolled over a period of interest.
   Motivated by a desire for a simpler macro than VDWs
   PullContinuous().

   Produces a dset detailing the enrollment of the MRNs in &People, including a flag
   signifying whether the person was continuously enrolled between &StartDt and &EndDt.
*/

   proc sql noprint ;
      ** How many days long is the period of interest? ;
      create table dual (x char(1)) ;
      insert into dual(x) values ('x') ;
      select ("&EndDt"d - "&StartDt"d + 1) as TotDays
               into :TotDays
      from  dual ;
   quit ;

   %put ;
   %put ;
   %put SimpleContinuous macro--pulling continuous enrollment information for the MRNs in &People ;
   %put between &StartDt and &EndDt (&TotDays days total).;
   %put ;
   %put ;


   proc sql ;
      ** Uniquify the list of MRNs, just in case ;
      create table _ids as
      select distinct MRN
      from &People ;

      ** Gather start/end dates from enroll that could possibly cover the period of interest. ;
      ** We no longer look out past the POI--now we just manually correct gaps at the beginning and end of the POI. ;
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

      /* where "&EarliestStart"d le e.enr_end AND
            "&LatestEnd"d     ge e.enr_start
      */


   ** Collapse any contiguous periods of enrollment. ;
   %CollapsePeriods(Lib       = work      /* Name of the library containing the dset you want collapsed */
                  , DSet      = _periods  /* Name of the dset you want collapsed. */
                  , RecStart  = enr_start   /* Name of the var that contains the period start dates. */
                  , RecEnd    = enr_end     /* Name of the var that contains the period end dates. */
                  , PersonID  = MRN
                  , DaysTol   = &DaysTol  /* The number of days gap to tolerate in evaluating whether one period is contiguous w/another. */
                  ) ;

  **  Now we worry about pre- and post-POI gaps. ;
  proc sort data = _periods ;
    by mrn enr_start ;
  run ;

  data _periods ;
    set _periods ;
    by mrn enr_start ;
    if first.mrn then do ;
      ** If enr_start is within &daystol days after &StartDt, we move enr_start to &StartDt (thereby closing the gap). ;
      x = (enr_start - "&StartDt"d) ;
      if 1 le (enr_start - "&StartDt"d) le &DaysTol then do ;
         ** put 'Correcting enr_start for ' mrn= ;
         enr_start = "&StartDt"d ;
       end ;
       else do ;
        ** put 'No need to correct enr_start for ' mrn= enr_start= 'diff is ' x ;
       end ;
    end ;
    if last.mrn then do ;
      ** If enr_end is within &daystol days before &EndDt, we move enr_end to &EndDt ;
      if 1 le ("&EndDt"d - enr_end) le &DaysTol then do ;
        ** put 'Correcting enr_end for ' mrn= ;
        enr_end = "&EndDt"d ;
      end ;
    end ;
    drop x ;
  run ;

   ** Calculate # of days between start & end date. ;
   proc sql ;
      create table _period_days as
      select MRN
            , (min("&EndDt"d, enr_end) - max("&StartDt"d, enr_start) + 1) as Days
      from _periods
      ;

      create table &OutSet(label = "Enrollment information for the MRNs in &People") as
      select mrn
            , sum(days) as CoveredDays label = "Number of enrolled days between &StartDt and &EndDt"
            , (sum(days) ge &TotDays) as ContinuouslyEnrolled label = "0/1 flag answering was this person continuously enrolled from &StartDt to &EndDt. (disregarding gaps up to &DaysTol days)?"
      from _period_days
      group by mrn
      ;
      insert into &OutSet (MRN, CoveredDays, ContinuouslyEnrolled)
      select MRN, 0, 0
      from _ids
      where mrn not in (select mrn from _period_days)
      ;
   quit ;

%mend SimpleContinuous ;

%macro GetPxForPeopleAndPx (
                           People  /* The name of a dataset containing the people whose fills you want. */
                           , PxLst   /* The PROC codes of interest */
                           , StartDt /* The date on which you want to start collecting fills.*/
                           , EndDt   /* The date on which you want to stop collecting fills. */
                           , Outset  /* The name of the output dataset containing the fills. */
                           ) ;

   %if &People = &Outset %then %do ;
      %put PROBLEM: The People dataset must be different from the OutSet dataset. ;
      %put PROBLEM: Both parameters are set to "&People". ;
      %put PROBLEM: Doing nothing. ;
   %end ;
   %else %do ;

      proc sql ;
      create table &OutSet as
      			  select d.*
      			from  &_vdw_px as d
      			INNER JOIN &People as p
      			on    d.MRN = p.MRN
      			where d.ADate BETWEEN "&StartDt"d AND "&EndDt"d AND
      						d.px in (select pl.px from &PxLst as pl)
      ;
      quit ;
   %end ;

%mend GetPxForPeopleAndPx ;

%macro RemoveDset(dset = ) ;
   %if %sysfunc(exist(&dset)) %then %do ;
      proc sql ;
         drop table &dset ;
      quit ;
   %end ;
%mend RemoveDset ;

%macro GetKidBMIPercentiles(Inset  /* Dset of MRNs on whom you want kid BMI recs */
                        , OutSet
                        , StartDt = 01jan1960
                        , EndDt = &sysdate9
                        ) ;


   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro GetKidBMIPercentiles: ;
   %put ;
   %put Creating a dataset "&OutSet", which will contain all BMI measures  ;
   %put on record for the people whose MRNs are contained in "&InSet" which ;
   %put were taken while the people were between the ages of 2 and 17 and ;
   %put taken between "&StartDt" and "&EndDt". ;
   %put  ;
   %put The output dataset will contain a variable calculated by the CDCs ;
   %put normative sample percentile score program found here: ;
   %put http://www.cdc.gov/nccdphp/dnpao/growthcharts/resources/sas.htm ;
   %put ;
   %put From this variable (called BMIPCT) you can categorize the children ;
   %put into normal/overweight/obese brackets with the following format: ;
   %put  ;
   %put proc format ;                                                ;
   %put    value bmipct                                              ;
   %put       low -< 5    = 'Underweight < 5th percentile'           ;
   %put       5   -< 85   = 'Normal weight 5th to 84.9th percentile' ;
   %put       85  -< 95   = 'Overweight 85th to 94.9th percentile'   ;
   %put       95  -  high = 'Obese >=95th percentile'                ;
   %put    ;                                                         ;
   %put quit ;                                                       ;
   %put                                                             ;
   %put ============================================================== ;
   %put ;
   %put ;





   proc sql ;
      ** Gather the demog data for our input dset. ;
      create table __demog as
      select i.mrn
            , case d.gender when 'M' then 1 when 'F' then 2 else . end as sex label = '1 = Male; 2 = Female'
            , d.birth_date
      from  &InSet as i LEFT JOIN
           &_vdw_demographic as d
      on    i.mrn = d.mrn
      ;

      ** Now gather any ht/wt measures that occurred prior to the 18th birthday. ;
      create table _indata as
      select d.mrn
            , d.sex
            , d.birth_date
            , measure_date
            , ht*2.54         as height label = 'Height in centimeters'
            , wt*0.45359237   as weight label = 'Weight in kilograms'
            , bmi             as original_bmi label = 'BMI as originally calculated'
            , ((measure_date - birth_date)/365.25 * 12) as agemos label = 'Age at measure in months'
            , days_diff
            , %CalcAge(bdtvar = birth_date, refdate = measure_date) as age_at_measure
            , . as recumbnt   label = 'Recumbent flag (not implemented in VDW)'
            , . as headcir    label = 'Head circumference (not implemented in VDW)'
      from  __demog as d INNER JOIN
            &_vdw_vitalsigns as v
      on    d.mrn = v.mrn
      where calculated age_at_measure between 2 and 17 AND
            ht IS NOT NULL AND
            wt IS NOT NULL AND
            days_diff = 0 AND
            measure_date between "&StartDt"d and "&EndDt"d
      ;
   quit ;

   ** ROY--CHANGE THIS BACK TO PULLING FROM THE FTP SERVER!!! ;
  filename kid_bmi   FTP     "gc-calculate-BIV.sas"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/Alfresco/Sites/vdwcode/documentLibrary"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader"
                     PASSIVE
                     ;


   ** filename kid_bmi "\\groups\data\CTRHS\Crn\S D R C\VDW\VitalSigns\gc-calculate-BIV.sas" ;

   data _indata ;
      set _indata ;

   %include kid_bmi ;

   run ;

   data &OutSet ;
      set _indata ;

      label
         HTPCT    = 'percentile for length-for-age or stature-for-age'
         HAZ      = 'z-score for length-for-age or stature-for-age'
         WTPCT    = 'percentile for weight-for-age'
         WAZ      = 'z-score for weight-for-age'
         WHPCT    = 'percentile for weight-for-length or weight-for-stature'
         WHZ      = 'z-score for weight-for-length or weight-for-stature'
         BMIPCT   = 'percentile for body mass index-for-age'
         BMIZ     = 'z-score for body mass index-for-age'
         BMI      = 'calculated body mass index value [weight(kg)/height(m)2 ]'
         HCPCT    = 'percentile for head circumference-for-age'
         HCZ      = 'z-score for head circumference-for-age'
         _BIVHT   = 'outlier variable for height-for-age (0  acceptable normal range; 1  too low; 2  too high)'
         _BIVWT   = 'outlier variable for weight-for-age (0  acceptable normal range; 1  too low; 2  too high)'
         _BIVWHT  = 'outlier variable for weight-for-height (0  acceptable normal range; 1  too low; 2  too high)'
         _BIVBMI  = 'outlier variable for body mass index-for-age (0  acceptable normal range; 1  too low; 2  too high)'
      ;
      %* Note--these are dropped only b/c I dont know what they are--could not find ;
      %* documentation on them on the CDC website. ;
      drop
         _SDLGZLO
         _SDLGZHI
         _FLAGLG
         _SDSTZLO
         _SDSTZHI
         _FLAGST
         _SDWAZLO
         _SDWAZHI
         _FLAGWT
         _SDBMILO
         _SDBMIHI
         _FLAGBMI
         _SDHCZLO
         _SDHCZHI
         _FLAGHC
         _BIVHC
         _FLAGWLG
         _FLAGWST
      ;

   run ;

%mend GetKidBMIPercentiles ;

%macro GetLabForPeopleAndLab(
							People
						, LabLst
						, StartDt
						, EndDt
						, Outset
						) ;

  *****************************************************************************
  Gets the Lab results for a specified set of people (identified by MRNs)
  which occurred between the dates specified in StartDt and EndDt.
  *****************************************************************************;

  %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
    %end ;
  %else %do ;


    proc sql ;
      create table __ids as
      select distinct mrn
      from &people
      ;
      create table &OutSet as
    			select l.*
  			from &_vdw_lab as l INNER JOIN
  			      __ids as p
  			on    l.MRN = p.MRN
  			where l.Lab_dt BETWEEN "&StartDt"d AND "&EndDt"d AND
  						l.Test_Type in (select &LabLst..test_type from &LabLst) ;
    quit ;

  %end;
%mend GetLabForPeopleAndLab ;

%macro make_inclusion_table(cohort = ) ;

  %local demog ;
  %let demog = &_vdw_demographic ;

  proc format ;
    value $Hispani
      'Y' = '1 Hispanic or Latino'
      'N' = '2 Not Hispanic or Latino'
      'U'
      , ' '
      , ''
      , Missing = '3 Unknown (Individuals not reporting ethnicity)'
    ;
    value $Gender
      'M' = 'Males'
      'F' = 'Females'
      Other = 'Unknown or Not Reported'
    ;

    /*
    I would love it if someone could check my geography here--I am especially
    unsure of the Native Hawaiian or Other Pac Islander category.
    */
    value $Race
      'IN' = '1 American Indian/Alaska Native'
      'AS' = '2 Asian'
      'HP' = '3 Native Hawaiian or Other Pacific Islander'
      'BA' = '4 Black or African American'
      'WH' = '5 White'
      'MU' = '6 More than one race'

      '01' = '5 White'
      '02' = '4 Black or African American'
      '03' = '1 American Indian/Alaska Native'
      '04'
      , '05'
      , '06'
      , '08'
      , '09'
      , '10'
      , '11'
      , '12'
      , '13'
      , '14'
      , '96' = '2 Asian'
        '07'
      , '20'
      , '21'
      , '22'
      , '25'
      , '26'
      , '27'
      , '28'
      , '30'
      , '31'
      , '32'
      , '97' = '3 Native Hawaiian or Other Pacific Islander'
        '-1' = '6 More than one race'


      Other = '7 Unknown or Not Reported'
    ;
  quit ;

  ** TODO: the macro should check for the presence of gender, race1 and hispanic, and only pull them if necessary. ;
  proc sql ;
    create table _reportable as
    select d.mrn, d.race1 as race label = "Racial Category"
          , d.hispanic label = "Ethnic Category"
          , d.gender label = "Sex/Gender"
    from &demog as d INNER JOIN
         &cohort as c
    on    d.mrn = c.mrn
    ;

    create table genders (gender char(1)) ;
    insert into genders(gender) values ('F') ;
    insert into genders(gender) values ('M') ;
    insert into genders(gender) values ('U') ;

    create table races(race char(2)) ;
    insert into races(race) values ('IN') ;
    insert into races(race) values ('AS') ;
    insert into races(race) values ('HP') ;
    insert into races(race) values ('BA') ;
    insert into races(race) values ('WH') ;
    insert into races(race) values ('MU') ;

    insert into races(race) values ('01') ;
    insert into races(race) values ('02') ;
    insert into races(race) values ('03') ;
    insert into races(race) values ('04') ;
    insert into races(race) values ('  ') ;
    insert into races(race) values ('97') ;
    insert into races(race) values ('-1') ;

    create table ethnicities(hispanic char(1)) ;
    insert into ethnicities(hispanic) values('Y') ;
    insert into ethnicities(hispanic) values('N') ;
    insert into ethnicities(hispanic) values('U') ;
    insert into ethnicities(hispanic) values(' ') ;

    create table class_levels as
    select gender, race, hispanic
    from genders CROSS JOIN races CROSS JOIN ethnicities ;

  quit ;

  title1 "Inclusion Enrollment Report" ;

  title2 "PART A TOTAL ENROLLMENT REPORT" ;
  proc tabulate data = _reportable missing format = comma15.0 order = formatted classdata = class_levels ;
    class hispanic race gender ;
    keylabel N = ' ' ;
    tables hispanic all='Total of all subjects:', gender all = 'Total' / printmiss misstext = '0' box = 'Ethnic Category' ;
    tables race     all='Total of all subjects:', gender all = 'Total' / printmiss misstext = '0' box = 'Racial Categories' ;
    format race $race. hispanic $hispani. gender $gender. ;
  quit ;

  title2 "PART B HISPANIC ENROLLMENT REPORT" ;
  proc tabulate data = _reportable missing format = comma15.0 order = formatted  classdata = class_levels ;
    class hispanic race gender ;
    keylabel N = ' ' ;
    tables race all='Total of Hispanics or Latinos:', gender all = 'Total' / printmiss misstext = '0' box = 'Racial Categories' ;
    format race $race. hispanic $hispani. gender $gender. ;
    where put(hispanic, $hispani.) = '1 Hispanic or Latino' ;
  quit ;



%mend make_inclusion_table ;

************************************************************************;
** Program: BMI_adult_macro.sas                                        *;
**                                                                     *;
** Purpose: Calculate BMI for adults and include a flag for reason     *;
**          that a BMI was not calculated. This flag can have values   *;
**          of:  MISSING AGE                                           *;
**               UNDER AGE 18                                          *;
**               NO WT                                                 *;
**               NO HT                                                 *;
**               NO HT OR WT                                           *;
**               WT OUT OF RANGE                                       *;
**               BMI OUT OF RANGE                                      *;
**                                                                     *;
**          The BMI algorithm and cut-off recommendations were         *;
**          reviewed by the Obesity special interest group.            *;
**          This is meant to flag only those extreme values or         *;
**          situations where there is reason to suspect a data entry   *;
**          error, and further review may be warranted.                *;
**                                                                     *;
**          The macro assumes that the program is placed into the      *;
**          middle of a program. It assumes that libnames have been    *;
**          defined prior to the macro call, and indicates that the    *;
**          macro parameters have be fully qualified dataset names.    *;
**                                                                     *;
**                                                                     *;
**         Three variables are created:                                *;
**                                                                     *;
**         VARIABLE       DECRIPTION                  FORMAT           *;
**         ---------------------------------------------------------   *;
**         BMI            BMI FOR ADULTS              Numeric          *;
**         HT_MEDIAN      MEDIAN HT FOR ADULTS        Numeric          *;
**         BMI_flag       BMI QC FLAG                 $16.             *;
**                                                                     *;
** Author: G. Craig Wood, Geisinger Health System                      *;
**         cwood@geisinger.edu                                         *;
**                                                                     *;
** Revisions: Intial Creation 6/7/2010                                 *;
**                                                                     *;
************************************************************************;
** Macro Parameters:                                                   *;
**                                                                     *;
** VITALS_IN: These needs to have the following variables:             *;
**        MRN, HT, WT, and measure_date.                               *;
**        Feed in fully qualified name, i.e. use libname and           *;
**        dataset name together if reading a permanent dataset.        *;
**        This macro program assumes that desired libraries have been  *;
**        defined previously in the program. StandardVars macro        *;
**        variables can be used.                                       *;
**                                                                     *;
** DEMO_IN: These needs to have the following variables:               *;
**        MRN, birth_date.                                             *;
**        Feed in fully qualified name, i.e. use libname and           *;
**        dataset name together if reading a permanent dataset.        *;
**        This macro program assumes that desired libraries have been  *;
**        defined previously in the program. StandardVars macro        *;
**        variables can be used.                                       *;
**                                                                     *;
** VITALS_OUT: Feed in fully qualified name, i.e. use libname and      *;
**        dataset name together if writing to a permanent dataset.     *;
**                                                                     *;
** KEEPVARS: Optional parameter indicating the values to keep in your  *;
**           quality checking dataset.  May be left blank to simply    *;
**           attach the two new variables to an existing dataset.      *;
************************************************************************;
** Examples of use:                                                    *;
**                                                                     *;
** %bp_flag(vitals_in=&_vdw_vitalsigns,                                *;
**          demo_in=&_vdw_demographic,                                 *;
**          vitals_out=BMI_qc,                                         *;
**          keepvars= mrn measure_date BMI BMIFLAG)                    *;
**                                                                     *;
** %bp_flag(vitals_in=cohort_vitals,                                   *;
**          demo_in=cohort_demo,                                       *;
**          vitals_out=BMI_qc,                                         *;
**          keepvars= mrn measure_date BMI BMIFLAG ht wt)              *;
**                                                                     *;
** %bp_flag(vitals_in=cohort_vitals,                                   *;
**          demo_in=&_vdw_demographic,                                 *;
**          vitals_out=lib_out.BMI_qc,                                 *;
**          keepvars= )                                                *;
**                                                                     *;
************************************************************************;


%MACRO BMI_adult_macro(vitals_in, demo_in, vitals_out, keepvars);


PROC SQL;
CREATE TABLE one AS SELECT A.*, B.birth_date, ((measure_date-birth_date)/365.25)AS AGE FROM &vitals_in A LEFT OUTER JOIN &demo_in  B
ON A.MRN = B.MRN;
QUIT;

proc means noprint nway data=one; class mrn; var ht; WHERE (ht>=48 AND ht<=84) AND AGE>=18; output out=outHT (drop=_type_ _freq_) median=HT_median; run;
proc sort; by mrn; run;

data &vitals_out; merge one outht; by mrn;
        %if &keepvars ne %then %do; keep &keepvars; %end;

        format BMIflag $16.;

        if age = . THEN BMIflag = 'MISSING AGE';
        if age<18 AND age NE . then BMIflag='UNDER AGE 18';
        if age<18 then HT_median=.;
        if BMIflag=' ' and HT_median=. and wt=. then BMIflag='NO HT OR WT';
        if BMIflag=' ' and HT_median=. then BMIflag='NO HT';
        if BMIflag=' ' and wt=. then BMIflag='NO WT';
        if BMIflag=' ' and wt ne . and (wt<50 or wt>700) then BMIflag='WT OUT OF RANGE';

        if BMIflag=' ' then BMI=round((703*wt/(HT_median*HT_median)),0.01);
        if BMIflag=' ' and BMI ne . and (BMI<15 or BMI>90) then do;
                BMIflag='BMI OUT OF RANGE';
                BMI=.;
                end;
        drop age birth_date;
        run;


PROC DATASETS NOLIST; DELETE one outht; QUIT;

%MEND BMI_adult_macro;

/*
  GetAdultBMI

  A little wrapper macro that lets users supply a cohort dset & an optional time period, for whom/over which they
  would like BMI data (as calculated by the vital signs WGs official code).

  Author: Roy Pardee
*/
%macro GetAdultBMI(people = , outset = , StartDt = "01jan1960"d, EndDt = "&sysdate"d) ;
  proc sql ;
    create table __in_demog as
    select distinct p.mrn, birth_date
    from  &people as p INNER JOIN
          &_vdw_demographic as d
    on    p.mrn = d.mrn
    ;
  quit ;


  ** Vars in v3 of vitals: ;
  ** enc_id, enctype, mrn, measure_date, ht_raw, wt_raw, ht, wt, bmi_raw, tobacco, tobacco_type, diastolic, systolic, diastolic_raw, systolic_raw, bp_type, position, measure_time, head_cir_raw, respir_raw, temp_raw, pulse_raw  ;

  proc sql ;
    create table __in_vitals as
    select p.*, measure_date, ht, wt
    from  &_vdw_vitalsigns as v INNER JOIN
          &people as p
    on    v.mrn = p.mrn
    where v.measure_date between &StartDt and &EndDt
    ;
  quit ;

  %BMI_adult_macro(vitals_in = __in_vitals, demo_in = __in_demog, vitals_out = &outset) ;

%mend GetAdultBMI ;

************************************************************************;
** Program: BP_FLAG.sas                                                 *;
**                                                                     *;
** Purpose: Create flags that can be used to determine quality of      *;
**          systolic and diastolic blood pressure fields.              *;
**          Cut-off recommendations reviewed by CVRN HTN Registry      *;
**          site PIs on 5/12/2010. This is meant to flag only those    *;
**          extreme values or situations where there is reason to      *;
**          suspect a data entry error, and further review may be      *;
**          warranted.                                                 *;
**                                                                     *;
**         Three variables are created:                                *;
**                                                                     *;
**         VARIABLE        VALUES                                      *;
**         ---------------------------------------------------------   *;
**         SYSTOLIC_QUAL   NULL, ABN_HIGH, ABN_LOW                     *;
**         DIASTOLIC_QUAL  NULL, ABN_HIGH                              *;
**         SYS_DIA_QUAL    SYSTOLIC <= DIASTOLIC, DIFFERENCE < 20,     *;
**                         DIFFERENCE > 100                            *;
**                                                                     *;
**         Note that NULL is only used when the other paired value for *;
**         the blood pressure is not null.                             *;
**                                                                     *;
** Author: Heather Tavel, KPCO                                         *;
**         Heather.M.Tavel@kp.org                                      *;
**                                                                     *;
** Revisions: Intial Creation 5/28/2010                                *;
**                                                                     *;
************************************************************************;
** Macro Parameters:                                                   *;
**                                                                     *;
** DSIN: Feed in fully qualified name, i.e. use libname and dataset    *;
**       name together if reading a permanent dataset. This macro      *;
**       program assumes that desired libraries have been defined      *;
**       previously in the program. StandardVars macro variables can   *;
**       be used.                                                      *;
**                                                                     *;
** DSOUT: Feed in fully qualified name, i.e. use libname and dataset   *;
**        name together if writing to a permanent dataset.             *;
**                                                                     *;
** KEEPVARS: Optional parameter indicating the values to keep in your  *;
**           quality checking dataset.  May be left blank to simply    *;
**           attach the three quality checking variables to an         *;
**           existing dataset.                                         *;
************************************************************************;
** Examples of use:                                                    *;
**                                                                     *;
** %bp_flag(dsin=&_vdw_vitalsigns,                                     *;
**          dsout=bp_qc,                                               *;
**          keepvars= mrn measure_date systolic diastolic)             *;
**                                                                     *;
** %bp_flag(dsin=cohort_vitals,                                        *;
**          dsout=cohort_vitals,                                       *;
**          keepvars=)                                                 *;
**                                                                     *;
** %bp_flag(dsin=&_vdw_vitalsigns,                                     *;
**          dsout=studylib.cohort_vitals,                              *;
**          keepvars=mrn measure_date systolic diastolic ht wt)        *;
**                                                                     *;
************************************************************************;
%macro bp_flag(dsin, dsout, keepvars);

data &dsout;
 set &dsin
     %if &keepvars ne %then %do; (keep=&keepvars)%end;
     ;

 ** Flag Systolic quality. Null values are suspect if diastolic exists ;

 if systolic gt 300          then SYSTOLIC_QUAL = 'ABN_HIGH';
  else if . < systolic < 50  then SYSTOLIC_QUAL = 'ABN_LOW';
  else if (systolic = . and
           diastolic ne .)   then SYSTOLIC_QUAL = 'NULL';

 ** Flag diastolic quality. Diastolic can go as low as 0, so there is no;
 ** lower limit.  Null values are OK in studies that may only care about;
 ** systolic.  This is just informative just in case it is needed.      ;
 ** DIA_ABN is set to 'NULL' only if a systolic value is entered on the ;
 ** same record.                                                        ;

 if diastolic gt 160          then DIASTOLIC_QUAL = 'ABN_HIGH';
  else if (systolic ne . and
           diastolic eq .)    then DIASTOLIC_QUAL = 'NULL';

 ** Now look at a comparative view between systolic and diastolic       ;
 ** systolic should always be greater than diastolic, and any difference;
 ** less than 20 or greater than 100 is suspect and should be reviewed  ;
 ** further.                                                            ;

 if systolic ne .
    and diastolic ne . then
    do;
	 if systolic < = diastolic
                            then SYS_DIA_QUAL = 'SYSTOLIC <= DIASTOLIC';
      else if systolic - diastolic < 20
                            then SYS_DIA_QUAL = 'DIFFERENCE < 20';
	  else if systolic-diastolic > 100
                            then SYS_DIA_QUAL = 'DIFFERENCE > 100';
	end;
run;

** Run a frequency on the results.  Can have more than one condition at ;
** a time;

proc freq data=&dsout;
 tables SYSTOLIC_QUAL
        DIASTOLIC_QUAL
        SYS_DIA_QUAL
        SYSTOLIC_QUAL*DIASTOLIC_QUAL
		SYSTOLIC_QUAL*SYS_DIA_QUAL
		DIASTOLIC_QUAL*SYS_DIA_QUAL/missing;
run;

%mend bp_flag;

%macro vdw_formats(lib = work, tweaked_descriptions = 0) ;
  filename vdw_fmt   FTP     "formats.xpt"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/Alfresco/Sites/vdwcode/documentLibrary"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader"
                     PASSIVE
                     DEBUG
                     /* rcmd  = 'binary' this makes the macro barf w/an access violation at Essentia--it is not necessary. */
                     ;

  libname  vdw_fmt xport ;

  *recode label to be of the form CODE(DESCRIPTION) if label only contains DESCRIPTION;
  data vdw_formats;
    set vdw_fmt.formats;
    %if &tweaked_descriptions = 1 %then %do ;
      if (not(label =: strip(start)) or index(label,'(')=0) and start = end then
        label = strip(start) || ' (' || strip(label) || ')' ; *prepend code to desc;
    %end ;
  run;

  proc format lib = &lib cntlin = vdw_formats ;
  run ;

  proc datasets nolist;  delete vdw_formats;  run; *Clean up workspace;

%mend vdw_formats ;

%macro get_preg_events(inset =
                      , start_date =
                      , end_date =
                      , out_events = pregnancy_events) ;

  %** This is a helper macro for pregnancy_periods below--you will almost always want to use that. ;

  %** I split this up in order to make testing easier. ;


  %** Obtain the list of pregnancy-related codes from the FTP server ;
  %** These lists are managed in: ;
  %** \\groups\data\ctrhs\crn\s d r c\vdw\macros\manage_pregnancy_codes.sas ;
  %** TODO: make it easy to swap this out for a local filename, for sites (KPNW) that cant do FTP. ;
  filename preg_ftp  FTP     "pregnancy_codes.xpt"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/Alfresco/Sites/vdwcode/documentLibrary"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader"
                     DEBUG
                     PASSIVE
                     /* rcmd  = 'binary' this makes the macro barf w/an access violation at Essentia--it is not necessary. */
                     ;
  libname preg_ftp xport ;

  proc copy in = preg_ftp out = work ;
  run ;

  libname preg_ftp clear ;

  %** Pull the events. ;
  proc sql ;
    create table dx as
    select d.mrn, adate, d.dx as event_code, descr as description, sigs as signifies
    from  &_vdw_dx as d INNER JOIN
          &inset as c
    on    d.mrn = c.mrn INNER JOIN
          preg_dx as p
    on    d.dx = p.dx
    where d.adate between "&start_date"d and "&end_date"d
    ;
    create table px as
    select p.mrn, adate, p.px as event_code, descr as description, sigs as signifies
    from  &_vdw_px as p INNER JOIN
          &inset as c
    on    p.mrn = c.mrn  INNER JOIN
          preg_px as pp
    on    p.px = pp.px AND
          p.px_codetype = pp.px_ct
    where p.adate between "&start_date"d and "&end_date"d
    ;

    create table &out_events as
    select *, 'dx' as source from dx
    UNION ALL
    select *, 'px' as source from px
    ;

    drop table dx ;
    drop table px ;

  quit ;

  proc sort nodupkey data = &out_events ;
    by mrn adate signifies event_code ;
  run ;

%mend get_preg_events ;

%macro make_preg_periods(inevents = pregnancy_events
                      , out_periods =
                      , max_pregnancy_length = 270) ;

  %** Make episodes out of the events. ;
  proc format ;
    %** The set of codes has a type G that signifies testing events--this version of the macro does not ;
    %** take those into account. ;
    value $evnt
      'P'   = 'pregnant'
      'D'   = 'delivered'
      'M'   = 'miscarried'
      'S'   = 'stillborn'
      'T'   = 'terminated'
      other = 'zah?'
    ;

    value $daysb
      'D'       = '270'
      'M'       = '98'
      'S', 'T'  = '112'
      other     = 'zah?'
    ;
  quit ;


  proc sort data = &inevents out = all_events ;
    by mrn adate ;
    where put(signifies, $evnt.) ne 'zah?' ;
  run ;

  proc sort data = all_events out = terminating_events ;
    by mrn adate signifies event_code ;
    where put(signifies, $evnt.) in ('delivered', 'miscarried', 'stillborn', 'terminated') ;
  run ;

  ** Reduce to one terminating event per person/date. ;
  ** Putting signifies in the above sort means that deliveries are favored over miscarriages, miscars are favored over ;
  ** stills, and stills over terminations. ;
  data terminating_events ;
    set terminating_events ;
    by mrn adate ;
    if first.adate ;
  run ;

  proc sql ;
    ** Remove all events happening on a termination date. ;
    create table events as
    select a.*
    from  all_events as a LEFT JOIN
          terminating_events as t
    on    a.mrn = t.mrn AND
          a.adate = t.adate
    where t.mrn IS NULL
    ;
  quit ;

  ** In GH data we frequently had multiple termination events w/in a few days of one another (e.g., missed abortion on day 1, followed by d and c on day 3);
  ** Reduce any such to a single termining event. ;
  data terminating_events ;
    retain _last_adate . ;
    set terminating_events ;
    by mrn adate ;
    if not first.mrn then do ;
      if (adate - _last_adate) le 2 then delete ;
    end ;
    _last_adate = adate ;
    drop _last_adate ;
  run ;

  ** Put those termination dates back in. ;
  proc append base = events data = terminating_events ;
  run ;

  ** Re-do the sort. ;
  proc sort data = events ;
    by mrn adate ;
  run ;


  ** ...and now the fun begins. ;
  data __outeps ;
    length
      outcome_category  $ 10
      outcome_code      $ 8
      first_sign_code   $ 8
    ;
    retain
      preg_episode      0
      first_sign_date   .
      first_sign_code   ''
      preg_code_count   0
      _last_event_date  .
    ;
    set events ;
    by mrn ;


    ** New episodes happen when: ;
      ** this is the first record for a new woman. ;
      ** the immediately prior record for this woman ended a pregnancy episode (in which case the _last_event_date will be set to missing.) ;
      ** the date on this record is too far away from the last date for it to be the same pregnancy . ;

    if first.mrn then do ;
      _last_event_date = . ;
      preg_episode = 0 ;
    end ;

    days_since = adate - coalesce(_last_event_date, adate) ;

    new_episode = (first.mrn or
                   (n(_last_event_date) = 0 ) or
                   (days_since gt &max_pregnancy_length)
                   ) ;

    if new_episode then do ;
      ** If we have exceeded max_pregnancy_length we need to output a record w/what we know thus far for the previous episode. ;
      if days_since gt &max_pregnancy_length then do ;
        outcome_category = 'unknown' ;
        outcome_date = _last_event_date ;
        outcome_code = '' ;
        output ;
      end ;

      preg_episode + 1 ;

      ** reset vars ;
      first_sign_date   = .  ;
      first_sign_code   = '' ;
      status            = '' ;
      _last_event_date  = .  ;
      preg_code_count   = 0  ;

      ** if this rec signifies a pregnancy, then it is the first sign. ;
      select(put(signifies, $evnt.)) ;
        when('pregnant') do ;
          first_sign_date = adate ;
          first_sign_code = event_code ;
        end ;
        otherwise do ;
          ** nothing ;
        end ;
      end ;
    end ;

    ** Regardless of where we are in an episode, these things need to be done. ;
    outcome_date = adate ;

    select(put(signifies, $evnt.)) ;
      when('pregnant') do ;
        preg_code_count + 1 ;
        _last_event_date = adate ;

        ** Special-case: if the record for this woman ends w/a pregnant event, spit out whatever we know by now. ;
        if last.mrn then do ;
          outcome_code = '' ;
          outcome_category = 'unknown' ;
          output ;
        end ;

      end ;
      when('delivered', 'miscarried', 'stillborn', 'terminated') do ;
        ** End this episode. ;
        outcome_code = event_code ;
        outcome_category = put(signifies, $evnt.) ;
        probable_onset = adate - input(put(signifies, $daysb.), best.) ;
        output ;
        ** reset _last_event_date so we start a new episode on the next record for this woman.. ;
        _last_event_date = . ;
      end ;
    end ;
  run ;

  proc sql ;
    create table &out_periods as
    select mrn
         , preg_episode      label = "Ordinal counter for the pregancy episode for the woman."
         , probable_onset    label = "Likely onset of the pregnancy.  Imputed from the type of outcome--be skeptical for outcomes other than 'delivered'." format = mmddyy10.
         , first_sign_date   label = "Date of the first 'prenatal' type event attributable to this pregnancy." format = mmddyy10.
         , first_sign_code   label = "The first-ocurring event code (dx/px) for a 'prenatal' type event during this pregnancy."
         , outcome_date      label = "The date the pregnancy episode ended (e.g., birth/termination/miscarriage if that is the outcome, or last sign of pregnacy if outcome unknown)" format = mmddyy10.
         , outcome_code      label = "The event code (dx/px) for the event that ended this pregnancy."
         , outcome_category  label = "Type of pregnancy outcome."
         , preg_code_count   label = "The number of 'prenatal' type events found during this pregnancy."
    from __outeps
    order by mrn, outcome_date, preg_episode
    ;
  quit ;
%mend make_preg_periods ;

%macro pregnancy_periods(inset                 =
                        , out_periods          =
                        , start_date           = 01jan1966
                        , end_date             = &sysdate9
                        , out_events           = pregnancy_events
                        , max_pregnancy_length = 270) ;

  %** Broke this macro into two in order to facilitate testing. ;
  %get_preg_events(inset = &inset
                  , start_date = &start_date
                  , end_date = &end_date
                  , out_events = &out_events) ;


  %make_preg_periods(inevents = &out_events
                  , out_periods = &out_periods
                  , max_pregnancy_length = &max_pregnancy_length) ;


%mend pregnancy_periods ;

%macro make_denoms(start_year, end_year, outset) ;
  %local round_to ;
  %let round_to = 0.0001 ;

  proc format ;
    ** 0-17, 18-64, 65+ ;
    value shrtage
      low -< 18 = '0 to 17'
      18  -< 65 = '18 to 64'
      65 - high = '65+'
    ;
    value agecat
      low -< 5 =  '00to04'
      5   -< 10 = '05to09'
      10  -< 15 = '10to14'
      15  -< 20 = '15to19'
      20  -< 30 = '20to29'
      30  -< 40 = '30to39'
      40  -< 50 = '40to49'
      50  -< 60 = '50to59'
      60  -< 65 = '60to64'
      65  -< 70 = '65to69'
      70  -< 75 = '70to74'
      75 - high = 'ge_75'
    ;
    ** For setting priority order to favor values of Y. ;
    value $dc
      'Y'   = 'A'
      'N'   = 'B'
      other = 'C'
    ;
    ** For translating back to permissible values of DrugCov ;
    value $cd
      'A' = 'Y'
      'B' = 'N'
      'C' = 'U'
    ;
    value $Race
      'WH' = 'White'
      'BA' = 'Black'
      'IN' = 'Native'
      'AS' = 'Asian'
      'HP' = 'Pac Isl'
      'MU' = 'Multiple'
      Other = 'Unknown'
    ;
    value $eb
      'I' = 'Insurance'
      'G' = 'Geography'
      'B' = 'Both Ins + Geog'
      'P' = 'Non-member patient'
    ;
  quit ;

  data all_years ;
    do year = &start_year to &end_year ;
      first_day = mdy(1, 1, year) ;
      last_day  = mdy(12, 31, year) ;
      ** Being extra anal-retentive here--we are probably going to hit a leap year or two. ;
      num_days  = last_day - first_day + 1 ;
      output ;
    end ;
    format first_day last_day mmddyy10. ;
  run ;

  proc sql ;
    /*
      Dig this funky join--its kind of a cartesian product, limited to
      enroll records that overlap the year from all_years.
      enrolled_proportion is the # of days between <<earliest of enr_end and last-day-of-year>>
      and <<latest of enr_start and first-day-of-year>> divided by the number of
      days in the year.

      Nice thing here is we can do calcs on all the years desired in a single
      statement.  I was concerned about perf, but this ran quite quickly--the
      whole program took about 4 minutes of wall clock time to do 1998 - 2007 @ GH.

    */
    create table gnu as
    select mrn
          , year
          , min(put(drugcov, $dc.)) as drugcov
          , min(put(outside_utilization, $dc.)) as outside_utilization
          , min(put(enrollment_basis, $eb.)) as enrollment_basis
          /* This depends on there being no overlapping periods to work! */
          , sum((min(enr_end, last_day) - max(enr_start, first_day) + 1) / num_days) as enrolled_proportion
    from  &_vdw_enroll as e INNER JOIN
          all_years as y
    on    e.enr_start le y.last_day AND
          e.enr_end   ge y.first_day
    group by mrn, year
    ;

    reset outobs = max warn ;

    create table with_agegroup as
    select g.mrn
        , year
        , put(%calcage(birth_date, refdate = mdy(1, 1, year)), agecat.) as agegroup label = "Age on 1-jan of [[year]]"
        , gender
        , put(race1, $race.) as race length = 10
        , put(drugcov, $cd.) as drugcov
        , put(outside_utilization, $cd.) as outside_utilization
        , enrollment_basis
        , enrolled_proportion
    from gnu as g LEFT JOIN
         &_vdw_demographic as d
    on   g.mrn = d.mrn
    ;

    create table &outset as
    select year
        , agegroup
        , drugcov label = "Drug coverage status (set to 'Y' if drugcov was 'Y' even once in [[year]])"
        , outside_utilization label = "Was there reason to suspect incomplete capture of ute or rx? (set to 'Y' if outside_ute was 'Y' even once in [[year]])"
        , enrollment_basis label = "What sort of relationship between person and HMO does this record document?"
        , race
        , gender
        , round(sum(enrolled_proportion), &round_to) as prorated_total format = comma20.2 label = "Pro-rated number of people enrolled in [[year]] (accounts for partial enrollments)"
        , count(mrn)               as total          format = comma20.0 label = "Number of people enrolled at least one day in [[year]]"
    from with_agegroup
    group by year, agegroup, drugcov, outside_utilization, enrollment_basis, race, gender
    order by year, agegroup, drugcov, outside_utilization, enrollment_basis, race, gender
    ;

    /*
    ** Create a dset of (masked) counts by race for submission to GH for collation. ;
    create table race_counts_&_SiteAbbr as
    select year, agegroup, race
          , case when sum(prorated_total) between .01 and 4 then .a else sum(prorated_total) end as prorated_total format = comma20.2
          , case when sum(total)          between 1   and 4 then .a else sum(total)          end as total          format = comma20.0
    from &outset
    group by year, agegroup, race
    ;
    */

  quit ;

%mend make_denoms ;
%macro vdwcountsandrates1(medcodes=,start_date=,end_date=,fileIN=,cohort=,outpath=,outname=);
/****************************************************************************************************/
/****************************************************************************************************/
/*	This macro collects counts and rates of supplied codes at a given site over a specified time period. 								  */
/*	Over this time period, and for each category in the study, counts are collected for 												  */
/*	(i) the total number of times a certain medcode (px, dx, ndc) was encountered														  */
/* (ii) the total number of people who were assigned this code																			  */
/*(iii) the total number of enrolled people who were assigned this code.																  */
/* (iv) A rate of incidence per 10,000 people is calculated over the enrolled people. 													  */
/*  																																	  */
/* An example of calling the macro in general (when there is no cohort file)is as follows (leave the cohort= argument blank): 			  */
/* %vdwcountsandrates1(px,'01jan09'd,'31dec09'd, fileIN=lib1.outds, COHORT=, 															  */
/*		outpath=\\groups\data\CTRHS\Crn\S D R C\VDW\Radiology\sasdata\InputData\Finalized Input Counts and Rates);						  */
/*																																		  */
/* When a cohort file exists, here is another way to call the macro: 																	  */
/* %vdwcountsandrates1(px,'01jan09'd,'31dec09'd, fileIN=path.outds, COHORT=lib2.cohorttest, 											  */
/*		outpath=\\groups\data\CTRHS\Crn\S D R C\VDW\Data\Counts and Rates\Data) 														  */
/******************************************************************************************************************************************/
options  mprint nocenter msglevel = i NOOVP dsoptions="note2err" ;
libname path "&outpath.";

/*The lack of symmetry in the table names requires a small twist*/
%let _vdw_px=&_vdw_px; %let _vdw_dx=&_vdw_dx; %let _vdw_ndc=&_vdw_rx;
%let ndcdate=rxdate;   %let pxdate=adate;     %let dxdate=adate;

/*Determine which medical codes are available in the supplied data*/
data combined_px combined_dx combined_ndc;
	set &fileIN.;
	if substr(upcase(medcode),1,2)="PX" then do;
		CodeType=substr(upcase(medcode),4,1);
		output combined_px;
	end;
	else if substr(upcase(medcode),1,2)="DX" then output combined_dx;
	else if substr(upcase(medcode),1,3)="NDC" then output combined_ndc;
run;

%if %upcase(&cohort.) eq %then %do;
/*We'll later use this step to calc rates - rates are count/enrPple *10k
Here and below, handling is required for the cohort yes or no instance*/
proc sql;
	select count(distinct mrn) as EnrPple into :EnrPple
	from &_vdw_enroll.
	where &start_date between enr_start and enr_end;
quit;
%end;

%else %if %upcase(&cohort.) ne %then %do;
/*We'll later use this next step to calc rates - rates are count/enrPple *10k*/
proc sql;
	select count(distinct mrn) as EnrPple into :EnrPple
	from &cohort. where mrn in (select mrn from &_vdw_enroll
	where &start_date between enr_start and enr_end);
quit;
%end;

/*Run for all specified medical code categories: 'px dx ndc' or a combo of the 3 - if they're not in &fileIn, skip to next*/
%local i cat;
  %do i=1 %to %sysfunc(countw(&medcodes));
		%let cat = %scan(%bquote(&medcodes),&i,' ');
   		proc sql; select count(*) into :numb from combined_&cat.; quit;
  			%if &numb=0 %then %do;
		%put **********************************************************;
		%put No %upcase(&cat) Codes in &FileIn.. Skipping.;
		%put **********************************************************;
			%end;
  		%if &numb=0 %then %goto skip;
		/*else, start processing the medcode*/
		%put NOTE: Commencing to Run &cat. codes.;


		/*Create tables- All People, Modify code if cohort is/is not available*/
		%if %upcase(&cohort.) ne %then %let addcohort = %str(AND mrn in (select mrn from &cohort.));
		%else %if %upcase(&cohort.) eq %then %let addcohort=;

		proc sql;
		/*Count all people with PX/DX/NDC of Interest*/
			create table allPple as
			select description, &cat., Category, count(&cat.) as &cat.count, count(distinct mrn) as allPeople
			from combined_&cat. as a
			left join &&&_vdw_&cat. as b
			on a.code = b.&cat.
			where &&&cat.date between &start_date. and &end_date. &addcohort.
			group by &cat., description, category;

		/*Create tables- All Enrolled People, modify code for cohort yes or no*/
		create table enrolledpple as
			select &cat.,description, count(distinct mrn) as allEnrolledPeople

			from
			(select mrn, &cat., description
			from combined_&cat. as a left join &&&_vdw_&cat. as b on a.code =b.&cat.
			where &&&cat.date between &start_date. and &end_date. &addcohort.)

			where mrn in
 			(select mrn from &_vdw_enroll where &start_date. between enr_start and enr_end)
		group by &cat., description;

		proc sql;
		/*Create table with distinct totals*/
			create table combined&cat. as
			select distinct a.description, a.&cat., Category, a.&cat.count label="%upcase(&cat.) Count",
			allPeople label="All People", allEnrolledPeople label="All Enrolled People"
			from allpple as a
			left join enrolledpple as b
			on a.&cat.=b.&cat.;

		/*There may be many categories in the study - account for each here*/
		select distinct category into :category separated by "/" from combined_&cat;
		select count(distinct category) as catgct into :catgct from combined_&cat;

		%do j=1 %to &catgct.;
			%let catg = %scan(&category., &j., '/');

			proc sql;
				select count(distinct mrn) as EnrPple&cat. into :EnrPple&cat.

				from
	 			(select distinct mrn, &cat.
 	  			from combined_&cat. as a left join &&&_vdw_&cat. as b on a.code =b.&cat.
	  			where compress(category)=%sysfunc(compress("&catg.")) and
				&&&cat.date between &start_date. and &end_date.)

 				where mrn in
  	 			(select mrn from &_vdw_enroll where &start_date between enr_start and enr_end &addcohort.);

			insert into combined&cat.
				(description, &cat., Category, &cat.count, allPeople, allEnrolledPeople)
				values("~TOTAL FOR %upcase(&catg.) %upcase(&cat.) CODES**","~Total","&catg.",.,.,&&EnrPple&cat.);
		%end;

		/*Create tables- Include the rates - one on all enrolled people*/
		create table combined2&cat. as
			select distinct description, a.&cat., Category, a.&cat.count label="%upcase(&cat.) Count",
			allPeople label="All People",
			allEnrolledPeople label="All Enrolled People",
			int((allEnrolledPeople/&EnrPple.)*10000) as RateAllEnr label="Rate/10K Over All Enrolled People"
			from combined&cat. as a order by &cat. ;
		/*the final stage- creating the end table*/
		create table catg&cat. as
			select distinct description, Category, Code as &cat. label="Medical Code"
			from combined_&cat. order by &cat. ;

		data final&cat.;
			merge catg&cat. (in=a) combined2&cat. (in=b);
			by &cat. ;
			if a or b;
		run;

		/*Clean up a little, add Site Code*/
		data final&cat.;
			set final&cat.;
			if  1 <= allPeople <=6 then allPeople=.a;
			if  1 <= pxcount <=6 then pxcount = .a;
			if  1 <= allEnrolledPeople<=6 then do;
               allEnrolledPeople=.a;
               rateallenr=.a;
      End;
			Sitecode="&_sitecode.";
		run;

		proc sort data=final&cat. out=path.final_&OutName._&cat._&_sitecode._&sysdate. /*nodupkey*/; by &cat.; run;

    proc format;
    	value LessSix
    	.a = '<6'
    	other=[9.0];
    run;

		proc print data=path.final_&OutName._&cat._&_sitecode._&sysdate. (obs=200);  /* fix this for final */
			title "Here is a sample of what you are sending out";
			format _numeric_ LessSix. ;
		run;
  %skip:
  %end;
%mend vdwcountsandrates1;

%macro titlefoots;
title "Some Codes Related to %upcase(&catg.)";
	title2 "Counts of All %upcase(&cat.) over period of interest by site within HMORN.";
	title3 "&titl3.";
	footnote1 "Preliminary: The above exhibit shows the incidence of selected codes at sites. The list is not exhaustive," ;
	footnote2 " and may need augumenting. The motive is to assess data quality across sites over selected codes." ;
	footnote3 "**Only Calculated on Enrolled so far";
	footnote4 "Prepared on &sysdate.";
%mend titlefoots;
/********************************************************************************************************************************/
/* This macro tabulates results from sites 4 ways: (i) procedure counts, (ii) all people who ever had a procedure, 		    	*/
/* (iii) all Enrolled People who ever had a procedure, then (iv) rates of incidence over those enrolled. 3 output files 		*/
/* (PX, DX, NDC) containing each of the four will be output.;													                */
/* This macro puts results from sites together for further analysis or comparison; 							  					*/
/********************************************************************************************************************************/
%macro VDWCountsAndRates2(medcodes=, /*Any combo of 'PX DX NDC' - no quotes - that you need tabulated					 */
						      path=, /*path to data files from sites, which SHOULD be stored in a directory by themselves*/
						     titl3=,  /*Optional additional title*/
						     InName= /*Text imbedded in filename */ );
libname path "&path";
options mprint;
/* Make a dummy dataset of site names so that each site ends up in the final table */
data SiteNames;
	length sitecode $4;
	sitecode='01 '; output;	 sitecode='02 '; output;  sitecode='03 '; output;  sitecode='04 '; output;
	sitecode='05 '; output;  sitecode='06 '; output;  sitecode='07 '; output;  sitecode='08 '; output;
	sitecode='09 '; output;  sitecode='10 '; output;  sitecode='11 '; output;  sitecode='12 '; output;
	sitecode='13 '; output;  sitecode='14 '; output;  sitecode='15 '; output;  sitecode='16 '; output;
	sitecode='17 '; output;
;
/*
	sitecode='01a';
	sitecode='01b';
*/
run;
/*Create a site name format;*/
proc format;
	value $sitef
	'01 ' = "GHC"  '02 ' = "KPNW"  '03 ' = "KPNC"  '04 ' = "KPSC"
	'05 ' = "KPHI" '06 ' = "KPCO"  '07 ' = "HPRF"	 '08 ' = "HPHC"
	'09 ' = "MPCI" '10 ' = "HFHS"  '11 ' = "KPGA"  '12 ' = "LHS"
	'13 ' = "MCRF" '14 ' = "GHS"   '15 ' = "SWH"   '16 ' = "MHS"
	'17 ' = "KPMA"
	'01a'='GHC-IGP'
	'01b'='GHC-Network'
	;
proc format;
    	value LessSix
    	.a = '<6'
    	other=[comma5.0];
run;

  proc sql noprint;
	create table thenames as
    select memname from dictionary.tables
    where libname = "PATH" and
          index(upper(memname),upper("_&InName._"))
    ;
    select  memname
    into :n1 separated by " " from thenames;
  quit;

options user=path;
data work.alldata;
	length sitecode $4 ;
	set &n1;
run;

%put &n1= ;

options user = work;

/* Count number of obs in each file to determine whether to run it*/
  proc sql;
	select count(distinct category) into :numcat from work.alldata;
	select distinct category into :catgn separated by "/" from work.alldata;
  quit;

%do j=1 %to &numcat.;
  %let catg = %scan(&catgn.,&j.,'/');

   ods tagsets.ExcelXP file="&path.\&sysdate. &catg. file &InName .xls" style=analysis
	options
    (embedded_titles="yes"	Embedded_footnotes="yes" 	Autofit_Height = "YES"
	default_column_width="50,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10");

    %local i cat;  %let i = 1;
    %let cat = %scan(%bquote(&medcodes),&i);

    %do %while(%bquote(&cat) ne);
		data _null_;
			dset=open('alldata');
			call symput('chk',left(trim(put(varnum(dset,"px"),2.))));
		run;

		%if &chk=0 %then %goto skip;

     	data &cat.;
			set alldata;
			if category="&catg.";
			if &cat. ne "" then output &cat.;
	 	run;

/* Create the format;*/
		data _g;
  			set &cat.;
  			retain fmtname "$fmt&cat.";
  			start = &cat.;
  			Label = description;
  			keep Fmtname Start Label;
		run;

		proc sort data=_g nodupkey; by start; run;
		proc format cntlin=_g ;

/* Prepare for tabulation*/
    	data dataclass;
     		set &cat. sitenames ;
	 		keep category  sitecode Description &cat;  *added description for non-ndc;
	 		if category='' then category="%upcase(&catg.)";
    	run;

/* Start tabulation*/
   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) All %upcase(&cat)s");

		data dataclass; set dataclass;
		if &cat.='~Total' then description="~All %upcase(&cat) - Number of All &cat.**";
		data &cat; set &cat;
		if &cat.='~Total' then description="~All %upcase(&cat) - Number of All &cat.**";

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq &cat.count;  format sitecode $sitef.;
			keylabel N="";
			class Description category sitecode;
			table Description, sitecode /box="All %upcase(&cat.)s" misstext='.'; *added description for non-ndc;
		%titlefoots;
   		run;

   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) People with %upcase(&cat.)s");

		data dataclass; set dataclass;
		if &cat.='~Total' then description="~All People - Number of All People with any &cat.**";
		data &cat; set &cat;
		if &cat.='~Total' then description="~All People - Number of All People with any &cat.**";

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq allpeople;  format sitecode $sitef.;
			keylabel N="";
			class &cat. Description category sitecode;
			table Description, sitecode /box="All People" misstext='.'; *added description for non-ndc;
	   	%titlefoots;
   		run;

   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) Enrolled With %upcase(&cat.)s");

		data dataclass; set dataclass;
		if &cat='~Total' then description="~Enrolled - Number of enrolled people with any &cat.**";
		data &cat; set &cat;
		if &cat='~Total' then description="~Enrolled - Number of enrolled people with any &cat.**";
		run;

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq allEnrolledPeople;  format sitecode $sitef.;
			keylabel N="";
			class Description category sitecode; *class &cat. category sitecode;
			table Description, sitecode /box="Enrolled People" misstext='.';
		%titlefoots;
   		run;


   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) Rates - All Enrollees");

		data dataclass; set dataclass;
		if &cat.='~Total' then description="~Rates - Rate of enrolled people with any &cat.**";run;
		data &cat; set &cat;
		if &cat.='~Total' then description="~Rates - Rate of enrolled people with any &cat.**";run;

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq rateallenr;  format sitecode $sitef.;
			keylabel N="Rate/10k";
			class Description category sitecode;
			table Description, sitecode /box="Enrolled Rates" misstext='.'; *added description for non-ndc;
	   	%titlefoots;
   		run;
   		title;
		   %skip:;
   		%let i = %eval(&i + 1);
   		%let cat = %scan(%bquote(&medcodes),&i);
   	%end; /*MEDCODES END*/
   ods tagsets.ExcelXP close;
%end;   /*CATG END*/

%mend VDWCountsAndRates2;

%macro check_dataset(dset =, obs_lim = max, eldest_age = 89) ;
  %local i ;
  %local inset_name ;
  %let inset_name = &dset ;

  %if %lowcase(&obs_lim) = max %then %do ;
    %** Nothing ;
  %end ;
  %else %do ;
    proc surveyselect
      data      = &inset_name
      out       = __sub_dset
      method    = srs
      sampsize  = &obs_lim SELECTALL
      seed      = 1234567
      noprint
    ;
    run;
    %let dset = __sub_dset ;
  %end ;

  %macro check_varname(regx, msg) ;
    create table possible_bad_vars as
    select name, label
    from these_vars
    where prxmatch(compress("/(&regx)/i"), name)
    ;

    %if &sqlobs > 0 %then %do ;
      insert into phi_warnings(dset, variable, label, warning)
      select "&inset_name" as dset, name, label, "&msg"
      from possible_bad_vars
      ;
    %end ;

  %mend check_varname ;

  %macro check_vars_for_mrn(length_limit = 6, obs_lim = max) ;
    %local char ;
    %let char = 2 ;
    proc sql noprint ;
      select name
      into :mrn_array separated by ' '
      from these_vars
      where type = &char and length ge &length_limit
      ;
    quit ;
    %if &sqlobs > 0 %then %do ;
      %put Checking these vars for possible MRN contents: &mrn_array ;
      data __gnu ;
        retain
          mrn_regex_handle
          badcount
        ;
        set &inset_name (obs = &obs_lim keep = &mrn_array) ;
        if _n_ = 1 then do ;
          mrn_regex_handle = prxparse("/&mrn_regex/") ;
          badcount = 0 ;
        end ;
        array p &mrn_array ;
        do i = 1 to dim(p) ;
          if prxmatch(mrn_regex_handle, p{i}) then do ;
            badvar = vname(p{i}) ;
            badvalue = p{i} ;
            badcount = _n_ ;
            output ;
          end ;
          keep badvar badvalue badcount ;
        end ;
      run ;
      proc sql noprint ;
        select compress(put(max(badcount), best.))
        into :badcount
        from __gnu
        ;
        insert into phi_warnings(dset, variable, warning)
        select distinct "&inset_name", badvar, "Could this var hold MRN values?  Contents of %trim(&badcount) records match the pattern given for MRN values.  MRNs should never move across sites."
        from __gnu ;
        drop table __gnu ;
      quit ;
    %end ;
  %mend check_vars_for_mrn ;

  %macro check_vars_for_oldsters(eldest_age = 89, obs_lim = max) ;
    %local dtfmts ;
    %let dtfmts = 'B8601DA','B8601DN','B8601DT','B8601DZ','B8601LZ','B8601TM','B8601TZ','DATE','DATEAMPM','DATETIME','DAY','DDMMYY',
                  'DDMMYYB','DDMMYYC','DDMMYYD','DDMMYYN','DDMMYYP','DDMMYYS','DOWNAME','DTDATE','DTMONYY','DTWKDATX','DTYEAR',
                  'DTYYQC','E8601DA','E8601DN','E8601DT','E8601DZ','E8601LZ','E8601TM','E8601TZ','HHMM','HOUR','JULDAY','JULIAN',
                  'MMDDYY','MMDDYYB','MMDDYYC','MMDDYYD','MMDDYYN','MMDDYYP','MMDDYYS','MMSS','MMYY','MMYY','MONNAME','MONTH','MONYY',
                  'PDJULG','PDJULI','QTR','QTRR','WEEKDATE','WEEKDATX','WEEKDAY','WEEKU','WEEKV','WEEKW','WORDDATE','WORDDATX',
                  'YEAR','YYMM','YYMMC','YYMMD','YYMMN','YYMMP','YYMMS','YYMMDD','YYMMDDB','YYMMDDC','YYMMDDD','YYMMDDN','YYMMDDP',
                  'YYMMDDS','YYMON','YYQ','YYQC','YYQD','YYQN','YYQP','YYQS','YYQR','YYQRC','YYQRD','YYQRN','YYQRP','YYQRS' ;

    %local num ;
    %let num = 1 ;

    proc sql noprint ;
      select name
      into :dat_array separated by ' '
      from these_vars
      where type = &num and (format in (&dtfmts) or lowcase(name) like '%date%')
      ;
      /* added by cb to shorten the process of looking at all dates */
      %if &sqlobs > 0 %then %do ;
        %put Checking these vars for possible DOB contents: &dat_array ;
        select 'min(' || trim(name) || ') as ' || name into :var_list separated by ','
        from these_vars
        where type = &num and (format in (&dtfmts) or lowcase(name) like '%date%')
        ;
        create table __gnu as
        select &var_list from &inset_name
        ;
      /* end cb additions */
    quit ;
      data __gnu ;
        set __gnu (obs = &obs_lim keep = &dat_array) ;
        array d &dat_array ;
        do i = 1 to dim(d) ;
          if n(d{i}) then maybe_age = %calcage(bdtvar = d{i}, refdate = "&sysdate9."d) ;
          if maybe_age ge &eldest_age then do ;
            badvar = vname(d{i}) ;
            badvalue = d{i} ;
            output ;
          end ;
          keep badvar badvalue maybe_age ;
        end ;
      run ;
      proc sql outobs = 30 nowarn ;
        insert into phi_warnings(dset, variable, warning)
        select distinct "&inset_name", badvar, "If this is a date, at least one value is " || compress(put(maybe_age, best.)) || " years ago, which is older than &eldest_age..  " ||
        "If this date applies to a person, the record is probably PHI."
        from __gnu ;
        drop table __gnu ;
      quit ;
    %end ;
    %else %do ;
      %put No obvious date variables found in &inset_name.--skipping age checks. ;
    %end ;
  %mend check_vars_for_oldsters ;

  proc contents noprint data = &inset_name out = these_vars ;
  run ;

  proc sql noprint ;
    create table phi_warnings (dset char(50), variable char(256), label char(256), warning char(200)) ;

    %check_varname(regx = mrn|hrn                                               , msg = %str(Name suggests this var may be an MRN, which should never move across sites.)) ;
    %check_varname(regx = birth_date|BirthDate|DOB|BDate                        , msg = %str(Name suggests this var may be a date of birth.)) ;
    %check_varname(regx = SSN|SocialSecurityNumber|social_security_number|socsec, msg = %str(Name suggests this var may be a social security number.)) ;

    %if %symexist(locally_forbidden_varnames) %then %do ;
      %check_varname(regx = &locally_forbidden_varnames, msg = %str(May be on the locally defined list of variables not allowed to be sent to other sites.)) ;
    %end ;

  quit ;

  %check_vars_for_mrn(obs_lim = &obs_lim) ;
  %check_vars_for_oldsters(obs_lim = &obs_lim, eldest_age = &eldest_age) ;

  title3 "WARNINGS for dataset &inset_name:" ;

  proc sql noprint ;
    select count(*) as num_warns into :num_warns from phi_warnings ;

    %if &num_warns = 0 %then %do ;
      reset print outobs = 5 NOWARN ;
      select "No obvious PHI-like data elements in &inset_name--BUT PLEASE INSPECT THE CONTENTS AND PRINTs TO FOLLOW" as x label = "No warnings for &inset_name"
      from &inset_name
      ;
      %do i = 1 %to 5 ;
        %put No obvious phi-like data elements in &inset_name.  BUT PLEASE INSPECT THE CONTENTS AND PRINTs CAREFULLY TO MAKE SURE OF THIS! ;
      %end ;
    %end ;
    %else %do ;
      reset print ;
      select variable, warning from phi_warnings
      order by variable, warning
      ;
      quit ;
    %end ;
    title3 "Dataset &inset_name" ;
    proc contents data = &inset_name varnum ;
    run ;
  /*
    proc print data = &inset_name (obs = 20) ;
    run ;
  */
    ** TODO: make the print print out recs that trip the value warnings. ;
    proc sql number ;
      select *
      from &inset_name (obs = 20)
      ;
    quit ;

  quit ;

  %RemoveDset(dset = __sub_dset) ;
  %RemoveDset(dset = possible_bad_vars) ;
  %RemoveDset(dset = phi_warnings) ;
  %RemoveDset(dset = these_vars) ;

%mend check_dataset ;

%macro detect_phi(transfer_lib, obs_lim = max, eldest_age = 89) ;

  %put ;
  %put ;
  %put ============================================================== ;
  %put ;
  %put Macro detect_phi: ;
  %put ;
  %put Checking all datasets found in %sysfunc(pathname(&transfer_lib)) for the following signs of PHI: ;
  %put   - Variable names signifying sensitive items like 'MRN', 'birth_date', 'SSN' and so forth. ;
  %if %symexist(locally_forbidden_varnames) %then %do ;
    %put   - Variable names on the list defined in the standard macro variable locally_forbidden_varnames (here those names are: &locally_forbidden_varnames). ;
  %end ;
  %put   - Contents of CHARACTER variables that match the pattern given in the standard macro variable mrn_regex (here that var is &mrn_regex) ;
  %put     Please note that numeric variables ARE NOT CHECKED FOR MRN-LIKE CONTENT. ;
  %put   - The contents of date variables (as divined by their formats) for values that, if they were DOBs, would indicate a person older than &eldest_age years. ;
  %put ;
  %put THIS IS BETA SOFTWARE-PLEASE SCRUTINIZE THE RESULTS AND REPORT PROBLEMS TO pardee.r@ghc.org. ;
  %put ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
  %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
  %put ;
  %put ;
  %put ============================================================== ;
  %put ;
  %put ;

  title1 "PHI-Detection Report for the datasets in %sysfunc(pathname(&transfer_lib))." ;
  title2 "please inspect all output carefully to make sure it comports with your data sharing agreement!!!" ;

  proc sql noprint ;
    ** describe table dictionary.tables ;

    select trim(libname) || '.' || memname as dset
    into   :d1-:d999
    from dictionary.tables
    where libname = "%upcase(&transfer_lib)" AND
          memtype = 'DATA'
    ;
    %local num_dsets ;
    %let num_dsets = &sqlobs ;
  quit ;

  %local i ;

  %if &num_dsets = 0 %then %do i = 1 %to 10 ;
    %put ERROR: NO DATASETS FOUND IN &transfer_lib!!!! ;
  %end ;

  %do i = 1 %to &num_dsets ;
    %put about to check &&d&i ;
    %check_dataset(dset = &&d&i, obs_lim = &obs_lim, eldest_age = &eldest_age) ;
  %end ;

%mend detect_phi ;

%** Author on this is Jack Hamilton of KPNC <Jack.Hamilton@kp.org>. ;
%macro data_set_list(
    library=work,
    macvar=data_set_list,   /* Name of macro variable in which to put list  */
    filter=1,               /* Data set name filter                         */
    order=1,                /* Default order is by name                     */
    in_prefix=,             /* If valued, create IN= data set option        */
    readpw=                 /* If there's a common read password            */
    );

    /* Make sure the output macro variable list exists */
    %global &MACVAR.;

    /* Get a list of data sets.  Could have used dictionary tables or ODS   */
    /* OUTPUT, but both of those methods may have bad side effects.         */
    proc datasets library=&LIBRARY. nolist nodetails
                %if %length(&READPW.) ne 0
                %then
                    %do;
                    read=&READPW.
                    %end;
                ;
        contents data=_all_ memtype=(data view) out=work._data_ noprint;
        run;
    quit;

    proc sql noprint;
        /* Filter and order the names and put into the macro variable.      */
        select distinct
            catt(
                "&LIBRARY..",
                memname
                %if %length(&IN_PREFIX.) ne 0
                %then
                    %do;
                    ,
                    catt(
                        " (in=&IN_PREFIX." ,
                        memname           ,
                        ')'
                        )
                    %end;
                )
        into
            :&MACVAR. separated by ' '
        from
            _last_
        where
            &FILTER.
        order by
            &ORDER.
        ;

        /* Drop the contents data set.   */
        drop table _last_;
    quit;

    /* Show what we got.  */
    %put INFO: &MACVAR.=&&&MACVAR.;

%mend data_set_list;

%** Author on this is Jack Hamilton of KPNC <Jack.Hamilton@kp.org>. ;
%macro Write_File(
    file= ,     /* Name of file to write to        */
    text= ,     /* Text to write to &FILE.         */
    mode=a      /* Write mode, A=Append, O=Output  */
    );

    %local fileref rc fid;
    %let fileref = ;

    /* Generate fileref name and assign to file.  */
    %let rc = %sysfunc(filename(fileref, &FILE.));

    /* Open file with Append access (if mode=a).  */
    %let fid = %sysfunc(fopen(&FILEREF., &MODE.));

    /* Write the text to the file, then close it.  */
    %if &FID. > 0
    %then
        %do;
        %let rc = %sysfunc(fput(&FID., &TEXT.));
        %let rc = %sysfunc(fwrite(&FID.));
        %let rc = %sysfunc(fclose(&FID.));
        %end;
    %else
        %put %sysfunc(sysmsg());

    %let rc = %sysfunc(filename(fileref));

%mend write_file;

%macro stack_datasets(inlib =, nom = , outlib = ) ;
  ** All input datasets live in inlib.
  ** All input dataset names begin with <<site abbreviation>>_ and end with the text passed in the nom parameter. ;
  ** This guy creates a big old UNION query against them all and then executes it to create a dataset named <<nom>> in the outlib library. ;

  %local i rgx ;
  %let rgx = (.*)_&nom.\s*$ ;

  proc sql ;
    ** create table s.drop_me as    select *    from dictionary.tables    ;

    ** Do we have any dsets w/0 vars?  These will cause barfage. ;
    create table __novars as
    select memname label = "THESE DATASETS HAVE 0 VARIABLES AND CANNOT BE USED!!!", memlabel
    from dictionary.tables
    where libname = "%upcase(&inlib)" AND
          nvar = 0 AND
          prxmatch("/&rgx./i", memname)
    ;

    %if &sqlobs > 0 %then %do ;
      %do i = 1 %to 5 ;
        %put WARNING: There are %trim(&sqlobs) datasets in &inlib that have 0 variables.  See the output for a list. ;
      %end ;
      select * from __novars ;
    %end ;

    drop table __novars ;

    reset noprint feedback ;

    select memname as dset
         , 'select *, "' || prxchange("s/&rgx./$1/i", -1, memname) || '" as site from ' || "&inlib.." || memname as sequel
         ,                  prxchange("s/&rgx./$1/i", -1, memname) as site
    into   :dset1-:dset100
         , :union_stmt separated by ' UNION ALL CORRESPONDING '
         , :sitelist separated by ', '
    from dictionary.tables
    where libname = "%upcase(&inlib)" AND
          nvar > 0 AND
          prxmatch("/&rgx./i", memname)
    ;

    %if &sqlobs = 0 %then %do ;
      %do i = 1 %to 5 ;
        %put ERROR: No datasets whose names end with "%trim(&nom)" found in input location %sysfunc(pathname(&inlib)) !!! ;
      %end ;
      reset print ;
      select libname, memname, '%' || "%upcase(&nom)" as match_expression, memlabel
      from dictionary.tables
      ;

    %end ;
    %else %do ;
      create table &outlib..&nom as
      &union_stmt
      ;
    %end ;
  quit ;

%mend stack_datasets ;

%macro generate_counts_rates(incodeset = /* Name of an input dset of data types, code types, categories and codes (see below). */
                          , start_date = /* Beginning of the period over which you want the counts/rates. */
                          , end_date   = /* End of the period over which you want the counts/rates. */
                          , cohort     = /* Optional--if your interest is limited to an enumerated population of peple, name the dset of MRNs identifying them here. */
                          , outpath    = /* Path giving the location where you want the output files that will contain the counts/rates. */
                          , outfile    = /* Base name of the output files (so--no extension).  'my_file' will produce '<<siteabbrev>>_my_file.sas7bdat' */
                          , censor_low = Y /* If set to N, it will skip the lowest-count redacting (mostly useful for debugging and single-site use). */
                        ) ;

  /*
    InCodeSet
      data_type: one of PX, DX, NDC, LAB.
      code_type: one of the valid values for px_codetype, dx_codetype, or null for NDCs/Labs.
      category: a user-specified string that can be used to group codes into categories (e.g., 'Analgesics', 'Therapeutic Radiation').
      descrip: a more fine-grained description of the particular code.  You could think of this as a subcategory (since codes w/the same descrip value get rolled up at the reporting stage).
      code: the actual NDC, ICD-9 dx code, etc.
  */

  libname __out "&outpath" ;

  %local __out ;
  %let __out = __out.&_SiteAbbr._&outfile ;

  %local _proceed ;

  %macro validate_codeset() ;
    %** Makes sure the input codeset has expected vars and values. ;
    proc contents noprint data = &incodeset out = _codevars ;
    run ;
    proc sql noprint ;
      ** select * from _codevars ;
      **describe table _codevars ;
      select count(*)
      into :num_vars
      from _codevars
      where lowcase(name) in ('data_type', 'code_type', 'category', 'code', 'descrip')
      ;
      drop table _codevars ;
    quit ;
    %if &num_vars < 5 %then %do ;
      %let _proceed = 0 ;
    %end ;
    %else %do ;
      %let _proceed = 1 ;
    %end ;
  %mend validate_codeset ;

  %validate_codeset ;

  %if &_proceed = 0 %then %do ;
    %do i = 1 %to 5 ;
      %put ERROR: Input dataset of codes &incodeset does not have the expected variables!!! ;
    %end ;
    %goto exit ;
  %end ;

  %macro gather_any_data(dtype = PX, dset = &_vdw_px, date_var = adate, join_condition = %str(d.px_codetype = i.code_type AND d.px = i.code), outset = __blah) ;
    proc sql ;
      create table __grist as
      select d.mrn, e.mrn as e_mrn, data_type, code_type, category, code, descrip
      from &dset as d INNER JOIN
           &incodeset as i
      on   &join_condition
           %if %length(&cohort) > 0 %then %do ;
            INNER JOIN &cohort as c
            on  d.mrn = c.mrn
           %end ;
           LEFT JOIN
           &_vdw_enroll as e
      on   d.mrn = e.mrn AND
           &date_var between e.enr_start and e.enr_end
      where  i.data_type = "&dtype" AND
             &date_var between "&start_date"d and "&end_date"d
      ;
      create table &outset as
      select data_type, category, descrip
            , count(*) as num_recs                      format = comma9.0 label = "No. records"
            , count(distinct mrn)   as num_ppl          format = comma9.0 label = "No. people (enrolled or not)"
            , count(distinct e_mrn) as num_enrolled_ppl format = comma9.0 label = "No. *enrolled* people"
      from __grist
      group by data_type, category, descrip
      ;

      create table __subt as
      select data_type, category
            , count(*) as num_recs                      format = comma9.0 label = "No. records"
            , count(distinct mrn)   as num_ppl          format = comma9.0 label = "No. people (enrolled or not)"
            , count(distinct e_mrn) as num_enrolled_ppl format = comma9.0 label = "No. *enrolled* people"
      from __grist
      group by data_type, category
      ;

      drop table __grist ;

      insert into &outset(data_type, category, descrip, num_recs, num_ppl, num_enrolled_ppl)
      select              data_type, category, "~SUBTOTAL for &dtype in this category:" as descrip, num_recs, num_ppl, num_enrolled_ppl
      from __subt
      ;

      drop table __subt ;

    quit ;

  %mend gather_any_data ;

  %macro gather_px(outset = _pxcounts) ;
    %gather_any_data(dtype = PX, dset = &_vdw_px, date_var = adate, join_condition = %str(d.px_codetype = i.code_type AND d.px = i.code), outset = &outset) ;
  %mend gather_px ;

  %macro gather_dx(outset = _dxcounts) ;
    %gather_any_data(dtype = DX, dset = &_vdw_dx, date_var = adate, join_condition = %str(d.dx_codetype = i.code_type AND d.dx = i.code), outset = &outset) ;
  %mend gather_dx ;

  %macro gather_rx(outset = _rxcounts) ;
    %gather_any_data(dtype = NDC, dset = &_vdw_rx, date_var = rxdate, join_condition = %str(d.ndc = i.code), outset = &outset) ;
  %mend gather_rx ;

  %macro gather_lab(outset = _labcounts) ;
    %gather_any_data(dtype = LAB, dset = &_vdw_lab, date_var = %str(coalesce(result_dt, lab_dt, order_dt)), join_condition = %str(d.test_type = i.code), outset = &outset) ;
  %mend gather_lab ;

  proc sql noprint ;
    select distinct lowcase(data_type) as dt
    into :dt1 - :dt4
    from &incodeset
    ;
    %let num_data_types = &sqlobs ;
  quit ;

  %if &num_data_types > 0 %then %do ;
    %removedset(dset = &__out) ;

    proc sql noprint ;
    	select count(distinct e.mrn) as EnrPple into :EnrPple
      from &_vdw_enroll as e
      %if %length(&cohort) > 0 %then %do ;
        INNER JOIN &cohort as c
        on  e.mrn = c.mrn
      %end ;
    	where "&start_date"d between e.enr_start and e.enr_end ;
    quit;

  %end ;

  %do i = 1 %to &num_data_types ;
    %let this_one = &&dt&i ;
    %put Working on &this_one ;
    %if &this_one = dx %then %do ;
      %gather_dx(outset = _counts) ;
    %end ;
    %else %if &this_one = ndc %then %do ;
      %gather_rx(outset = _counts) ;
    %end ;
    %else %if &this_one = lab %then %do ;
      %gather_lab(outset = _counts) ;
    %end ;
    %else %if &this_one = px %then %do ;
      %gather_px(outset = _counts) ;
    %end ;
    %else %do ;
      %do j = 1 %to 5 ;
        %put ERROR: Do not understand data_type value "&this_one"--skipping! ;
      %end ;
      %**goto exit ;
    %end ;
    proc append base = &__out data = _counts ;
    run ;
    %removedset(dset = _counts) ;
  %end ;

  data &__out (label = "Counts at site &_SiteName for period from &start_date to &end_date") ;
    set &__out ;
    %if %upcase(&censor_low) = Y %then %do ;
      ** Redact any counts that are less than &lowest_count ;
      array n num_recs num_ppl num_enrolled_ppl ;
      do i = 1 to dim(n) ;
        if n{i} gt 0 and n{i} lt &lowest_count then n{i} = .a ;
      end ;
      drop i ;
    %end ;
    if num_enrolled_ppl then rate_enrolled_ppl = int((num_enrolled_ppl / &EnrPple.) * 10000) ;

    label
      rate_enrolled_ppl = "Rate of enrolled people per 10k enrollees"
    ;
    format rate_enrolled_ppl comma8.0 ;
  run ;

  proc sort data = &__out ;
    by data_type category ;
  run ;

  %** Now supplement the output dset w/any codes that did not appear anywhere in the site data. ;
  proc sql ;
    create table __not_found as
    select distinct i.data_type
            , i.category
            , i.descrip
    from  &incodeset as i LEFT JOIN
          &__out as o
    on    i.data_type = o.data_type AND
          i.category = o.category
    where o.data_type IS NULL
    ;

    %if &sqlobs > 0 %then %do ;
      insert into &__out (data_type
                        , category
                        , descrip
                        , num_recs
                        , num_ppl
                        , num_enrolled_ppl
                        , rate_enrolled_ppl)
      select     data_type
                , category
                , descrip
                , 0 as num_recs
                , 0 as num_ppl
                , 0 as num_enrolled_ppl
                , 0 as rate_enrolled_ppl
      from __not_found
      ;
    %end ;

    drop table __not_found ;

  quit ;

  %** Switching to tabulate in order to avoid ERR: The ID columns were too wide for the LINESIZE to print
  %** the special report usually generated when BY and ID lists are identical. ;
	proc tabulate data = &__out (obs=200) missing format = comma9.0 ; ** classdata = &incodeset ;
		title1 "Here is a sample of what you are sending out" ;
		title2 "Please inspect the full dataset in &outpath.&_SiteAbbr._&outfile..sas7bdat before sending." ;
		class data_type descrip category / missing ;
		classlev descrip / style=[outputwidth=5.5in] ;
		var num_: rate_enrolled_ppl ;
		table data_type="Type of data" * (category * descrip="Event") , (num_recs num_ppl num_enrolled_ppl rate_enrolled_ppl)*SUM=" " / misstext = '.' box = "Data to be sent" ;
	run;

  %exit: ;

%mend generate_counts_rates ;

%macro report_counts_rates(inlib =        /* lib where the site-submitted dsets live */
                          , dset_name =   /* the stub dataset name to use to identify which dsets should be part of this report */
                          , outlib =      /* the lib where you want the output--a single aggregated dset + xls files for each category found */
                          , sitefmt =     /* optional--the name of the format to use for the site variable. */
                          ) ;

  ** title1 "Counts/Rates from &dset_name.." ;
  %local i rgx ;
  %let rgx = s/[^a-z]/_/ ;

  %stack_datasets(inlib = &inlib, nom = &dset_name, outlib = &outlib) ;

  proc format ;
    value $dt
      "PX" = "Procedure"
      "DX" = "Diagnosis"
      "NDC" = "Rx Fill"
      "LAB" = "Lab Result"
    ;
  quit ;

  %macro distinct(var =, outset = ) ;
    proc sort nodupkey data = gnu(keep = &var) out = &outset ;
      by &var ;
    run ;
  %mend distinct ;

  %macro new_sheet(tab_name, var, box_text = " ") ;
    ods tagsets.ExcelXP options (sheet_interval = 'none' sheet_name = "&tab_name") ;

    ** proc print ;
    **   var category code descrip &var ;
    ** run ;

 		proc tabulate data = gnu missing format = comma10.0 classdata = classes ;
  		freq &var;  ;
  		keylabel N=" ";
  		class data_type descrip category site / missing ;
   ** table category="Category" * (data_type="Type of data" * descrip="Event" * code="Signifying Code" all="Category Totals") , site*N*[style=[tagattr='format:#,###']] / misstext = '.' box = &box_text ;
   ** table category="Category" * (data_type="Type of data" * descrip="Event" all="Category Totals") , site*N*[style=[tagattr='format:#,###']] / misstext = '.' box = &box_text ;
  		table data_type="Type of data" * (descrip="Event") , site*N*[style=[tagattr='format:#,###']] / box = &box_text ; ** misstext = '.' ;
  		format data_type $dt. ;
  		%if %length(&sitefmt) > 0 %then %do ;
  		  format site &sitefmt ;
  		%end ;
 		run;


  %mend new_sheet ;

  %macro do_category(cat) ;
    %** Purpose: Runs a report for one of the categories. ;
    %let this_file = "%sysfunc(pathname(&outlib))/&cat..xls" ;
    %put Working on &cat.. ;
    %put File will be &this_file.. ;

    %** Subset to our category of interest ;
    proc sort data = &outlib..&dset_name out = gnu ;
      by data_type site descrip ;
      where prxchange("&rgx", -1, trim(lowcase(category))) = "&cat" ;
    run ;

    %** Create the classdata dataset (used in new_sheet above). ;
    %distinct(var = site, outset = _site) ;
    %distinct(var = %str(data_type category descrip), outset = _descr) ;

    proc sql noprint ;
      create table classes as
      select data_type, descrip, category, site
      from _descr CROSS JOIN _site
      ;

      select category
      into :category
      from classes
      ;
    quit ;

    title "&category" ;

    ods tagsets.ExcelXP
      file = &this_file
      style = analysis
      options (
                Frozen_Headers        = "5"
                Frozen_RowHeaders     = "2"
                embedded_titles       = "yes"
                embedded_footnotes    = "yes"
                autofit_height        = "yes"
                absolute_column_width = "12, 40, 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5"
                orientation           = "landscape"
                )
    ;

      %new_sheet(tab_name = Records   , var = num_recs          , box_text = "Raw record counts") ;
      %new_sheet(tab_name = People    , var = num_ppl           , box_text = "Counts of people (enrolled or not)") ;
      %new_sheet(tab_name = Enrollees , var = num_enrolled_ppl  , box_text = "Counts of people enrolled at the time of the event.") ;
      %new_sheet(tab_name = Rates     , var = rate_enrolled_ppl , box_text = "Rates per 10k enrollees ") ;

    ods tagsets.ExcelXP close ;
  %mend do_category ;

  proc sql noprint ; ;
    select distinct prxchange("&rgx", -1, trim(lowcase(category))) as cat
    into :cat1 - :cat999
    from &outlib..&dset_name
    ;
    %local num_cats ;
    %let num_cats = &sqlobs ;
  quit ;

  %do i = 1 %to &num_cats ;
    %let this_cat = &&cat&i ;
    %do_category(cat = &this_cat) ;
  %end ;

%mend report_counts_rates ;


/*********************************************
* Sharon Fuller
* Group Health Research Institute
* (206) 287-2552
* fuller.s@ghc.org
*
*Purpose: Prioritize and assign a single race per person
*					If only one race is listed, set CombinedRace to that race
*					If person is WH and one other, set CombinedRace to that other (or to "MU" depending on parameters)
*					If there is more than one non-WH race, or one of the races is "MU", set CombinedRace to "MU"
*					Otherwise, set CombinedRace to "UN"
*
*NOTES: this macro depends on the races being listed in the following order (which they currently are per VDW spec)
*				"HP" = "Native Hawaiian or Other Pacific Islander"
*				"IN" = "American Indian/Alaska Native"
*				"AS" = "Asian"
*				"BA" = "Black or African American"
*				"WH" = "White"
*				"MU" = "More than one race"
*				"UN" = "Unknown or Not Reported"
*      so, for example, if Race1 is WH, you know there will only be MU or UN in subsequent race fields
*
*********************************************/

%macro GetCombinedRace (Inset, 				/* The name of a dataset containing the MRNs of people
                     										whose race you want to identify. */
										Outset, 					/* The name of the output dataset - contains vars from inset,
																				plus CombinedRace and Race1--Race5.
																				Inset and Outset can be the same.*/
										Freqs = 'N', 			/*Defaults to 'N'.  If change to 'Y' will get some freqs in list file.*/
										WHOther = 'other' /*Options are 'other' and 'MU'.
																				If a person is White and one other race, should they be counted as
																				that other race (default), or as multiple.*/
										);

	proc sql;
		create table work.race as
		select i.*, Race1, Race2, Race3, Race4, Race5
		from &Inset. as i left outer join &_vdw_demographic d
			on i.mrn = d.mrn
		;
	quit;

	data &Outset. (drop = i);
		set work.race;
		length combinedrace $2. i 8.;
		combinedrace = "UN";
		array aryrace {*} Race1 Race2;
		do i=1 to dim(aryrace);
			if upcase(aryrace{i}) = "HP" then do;
				CombinedRace = "HP";
			end;
			else if upcase(aryrace{i}) in ( "IN" , "AS", "BA") then do;
				if combinedrace = "UN" then CombinedRace = aryrace{i};
				else combinedrace = "MU";
			end;
			else if upcase(aryrace{i}) = "WH" then do;
				if combinedrace ="UN" then CombinedRace = "WH";
				else if %upcase(&WHOther) = 'MU' then combinedrace = "MU";
			end;
			else if upcase(aryrace{i}) = "MU" then do;
				CombinedRace = "MU";
			end;
		end;
	run;

	%if %upcase(&freqs.) = 'Y' %then %do;
		proc freq data=&outset.;
		tables Race1 Race2 race3 race4 race5
							CombinedRace
							CombinedRace*Race1*Race2*Race3*Race4*Race5 /list nocum missing;
		run;
	%end;

%mend getcombinedrace;

%macro BloodCancerDefinition01(outds=CancerCases, startdt=01jan1990, enddt=31dec2007) ;
  **************************************************************************
  ** This defintion was used in the Stroke and Chemotherapy Project
  ** Added at the request of Gene Hart (206) 287-2949
  **************************************************************************;
  data &outds ;
      set &_vdw_tumor ;
  	where DxDate between "&startdt."d and "&enddt."d;
  	if morph ge '9650' and morph le '9667' then Hodgkin_Lymphoma = 1;
  		else Hodgkin_Lymphoma = 0;
  		if (morph ge '9590' and morph le '9596') then NonHodgkin_Lymphoma = 1;
  		else if (morph ge '9670' and morph le '9719') then  NonHodgkin_Lymphoma = 1;

  		else if (morph ge '9727' and morph le '9729')then NonHodgkin_Lymphoma = 1;
  		else NonHodgkin_Lymphoma = 0;
  	if  (morph ge '9800' and morph le '9948') then Leukemia = 1;
  		else Leukemia = 0;
  	if substr(icdosite, 1, 2)= 'C4'  and morph = '9731'  then Multiple_Myeloma = 1;
  		else if substr(icdosite, 1, 2)= 'C4' and morph = '9732' then Multiple_Myeloma = 1;
  		else if  substr(icdosite, 1, 2)= 'C4' and morph = '9761' then Multiple_Myeloma = 1;
  		else  Multiple_Myeloma = 0;
  run;
%mend BloodCancerDefinition01 ;

%macro CancerSchema(OutputDS,StartDt,EndDt);
/************************************************************************************************************************
* This macro takes cancers in your VDW Tumor file for the time period of interest and allocates them to cancer schema
* For AJCC 6th edition the variable created is CancerSchemaAjcc6thEdition - all cancers are included
*     https://cancerstaging.org/references-tools/deskreferences/Documents/AJCC6thEdCancerStagingManualPart1.pdf
*
* For AJCC 7th edition the variable created is CancerSchmaAjcc7thEdition - only 9 common cancers are currently defined in this macro
*     http://ebookee.org/AJCC-Cancer-Staging-Manual-7th-Edition_1494657.html
*
* Arguments
*   OutputDS is the name of the SAS dataset that will be output
*   StartDt is the start date of interest in the format 01jan2000
*   EndDt is the end date of interest in the format 31dec2000
************************************************************************************************************************/
;
proc sql;
  create table CancerSchema as
  select t.*,
         case
         when (ICDOSite between 'C500' and 'C506' or
              ICDOsite between 'C508' and 'C509') and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981' or
               Morph=        '9020')
              then 'Breast'

         when (ICDOSite='C619') and
              (MORPH between '8000' and '8110' or
               MORPH between '8140' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Prostate'

         when (ICDOSite='C180' or
               ICDOsite between 'C182' and 'C189') and
              (MORPH between '8000' and '8152' or
               MORPH between '8154' and '8231' or
               MORPH between '8243' and '8245' or
               MORPH      in('8247','8248')    or
               MORPH between '8250' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Colon'

         when (ICDOSite between 'C340' and 'C343' or
               ICDOsite between 'C348' and 'C349') and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Lung'

         when (ICDOSite between 'C670' and 'C679') and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Bladder'

         when (ICDOSite='C569' ) and
              (MORPH between '8000' and '8576' or
               MORPH between '8590' and '8671' or
               MORPH between '8930' and '9110')
              then 'Ovary'

         when (ICDOSite between 'C440' and 'C449' or
               ICDOsite between 'C510' and 'C512' or
               ICDOsite between 'C518' and 'C519' or
               ICDOsite between 'C600' and 'C602' or
               ICDOsite between 'C608' and 'C609' or
               ICDOsite= 'C632' ) and
              (MORPH between '8720' and '8790')
              then 'Melanoma'

         when (ICDOSite between 'C530' and 'C531' or
               ICDOsite between 'C538' and 'C539' ) and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Cervix'

         else 'Not yet coded'
         end as CancerSchemaAjcc7thEdition,

          case
    when ( ICDOsite BETWEEN 'C000' and 'C009' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Lip'

    when ( ICDOsite BETWEEN 'C019' and 'C029' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Tongue'

    when ( ICDOsite BETWEEN 'C079' and 'C089' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Salivary Gland'

    when ( ICDOsite BETWEEN 'C040' and 'C049' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Floor of Mouth'

    when ( (ICDOsite BETWEEN 'C030' and 'C039') or (ICDOsite BETWEEN 'C050' and 'C059') or ICDOsite BETWEEN 'C060' and 'C069' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Gum and other mouth'

    when ( ICDOsite BETWEEN 'C110' and 'C119' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Nasopharynx'

    when ( ICDOsite BETWEEN 'C090' and 'C099' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Tonsil'

    when ( ICDOsite BETWEEN 'C100' and 'C109' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Oropharynx'

    when ( (ICDOsite='C129') or (ICDOsite BETWEEN 'C130' and 'C139') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Oral Cavity and Pharynx'

    when ( (ICDOsite='C140') or (ICDOsite BETWEEN 'C142' and 'C148') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Hypopharynx'

    when ( ICDOsite BETWEEN 'C150' and 'C159' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Esophagus'

    when ( ICDOsite BETWEEN 'C160' and 'C169' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Stomach'

    when ( ICDOsite BETWEEN 'C170' and 'C179' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Lip'

    when ( ICDOsite='C180' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Cecum'

    when ( ICDOsite='C181' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Appendix'

    when ( ICDOsite='C182' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Ascending Colon'

    when ( ICDOsite='C183' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Hepatic Flexure'

    when ( ICDOsite='C184' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Transverse Colon'

    when ( ICDOsite='C185' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Splenic Flexure'

    when ( ICDOsite='C186' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Descending Colon'

    when ( ICDOsite='C187' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Sigmoid Colon'

    when ( (ICDOsite BETWEEN 'C188' and 'C189') or (ICDOsite='C260') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Large Intestine, NOS'

    when ( ICDOsite='C199' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Rectosigmoid Junction'

    when ( ICDOsite='C209' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Rectum'

    when ( (ICDOsite BETWEEN 'C210' and 'C212') or (ICDOsite='C218') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Anus, Anal Canal and Anorectum'

    when ( ICDOsite='C220' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Liver'

    when ( ICDOsite='C221' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Intrahepatic Bile Duct'

    when ( ICDOsite='C239' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Gall Bladder'

    when ( ICDOsite BETWEEN 'C240' and 'C249' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Biliary'

    when ( ICDOsite BETWEEN 'C250' and 'C259' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Pancreas'

    when ( ICDOsite='C480' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Retroperitoneum'

    when ( ICDOsite BETWEEN 'C481' and 'C482' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Peritoneum, Omentum and Mesentery'

    when ( (ICDOsite BETWEEN 'C268' and 'C269') or (ICDOsite='C488') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Digestive Organs'

    when ( (ICDOsite BETWEEN 'C300' and 'C301') or (ICDOsite BETWEEN 'C310' and 'C319') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Nose, Nasal Cavity and Middle Ear'

    when ( ICDOsite BETWEEN 'C320' and 'C329' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Larynx'

    when ( ICDOsite BETWEEN 'C340' and 'C349' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Lung and Bronchus'

    when ( (ICDOsite BETWEEN 'C381' and 'C383') or (ICDOsite in ('C339' 'C388' 'C390' 'C398' 'C399')) )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Trachea, Mediastinum and Other Respiratory Organs'

    when ( ICDOsite BETWEEN 'C400' and 'C419' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Bones and Joints'

    when ( (ICDOsite='C380') or (ICDOsite BETWEEN 'C470' and 'C479') or (ICDOsite BETWEEN 'C490' and 'C499') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Soft Tissue, including Heart'

    when ( ICDOsite BETWEEN 'C440' and 'C449' )
     and ( MORPH BETWEEN '8720' and '8790' )
       then 'Melanoma of the Skin'

    when ( ICDOsite BETWEEN 'C440' and 'C449' )
     and NOT( MORPH BETWEEN '8000' and '8005' ) and NOT( MORPH BETWEEN '8010' and '8046')
     and NOT( MORPH BETWEEN '8050' and '8084' ) and NOT( MORPH BETWEEN '8090' and '8110')
     and NOT( MORPH BETWEEN '8720' and '8790' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Non-Epithelial Skin'

    when ( ICDOsite BETWEEN 'C500' and 'C509' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Breast'

    when ( ICDOsite BETWEEN 'C530' and 'C539' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Cervix Uteri'

    when ( ICDOsite BETWEEN 'C540' and 'C549' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Corpus Uteri'

    when ( ICDOsite='C559' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Uterus, NOS'

    when ( ICDOsite='C569' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Ovary'

    when ( ICDOsite='C529' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Vagina'

    when ( ICDOsite BETWEEN 'C510' and 'C519' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Vulva'

    when ( ICDOsite BETWEEN 'C570' and 'C589' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Female Genital Organs'

    when ( ICDOsite='C619' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Prostate'

    when ( ICDOsite BETWEEN 'C620' and 'C629' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Testis'

    when ( ICDOsite BETWEEN 'C600' and 'C609' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Penis'

    when ( ICDOsite BETWEEN 'C630' and 'C639' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Male Genital Organs'

    when ( ICDOsite BETWEEN 'C670' and 'C679' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Urinary Bladder'

    when ( (ICDOsite='C649') or (ICDOsite='C659') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Kidney and Renal Pelvis'

    when ( ICDOsite='C669' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Ureter'

    when ( ICDOsite BETWEEN 'C680' and 'C689' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Urinary Organs'

    when ( ICDOsite BETWEEN 'C690' and 'C699' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Eye and Orbit'

    when ( ICDOsite BETWEEN 'C710' and 'C719' )
     and NOT( MORPH BETWEEN '9530' and '9539')
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Brain'

    when ( ICDOsite BETWEEN 'C710' and 'C719' )
       and ( MORPH BETWEEN '9530' and '9539' )
       then 'Cranial Nerves Other Nervous System'

    when ( (ICDOsite BETWEEN 'C700' and 'C709') or (ICDOsite BETWEEN 'C720' and 'C729') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Cranial Nerves Other Nervous System'

    when ( ICDOsite='C739' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Thyroid'

    when ( (ICDOsite='C739') or (ICDOsite BETWEEN 'C740' and 'C749') or (ICDOsite BETWEEN 'C750' and 'C759') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Endocrine including Thymus'

    when ( (ICDOsite in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) or (ICDOsite BETWEEN 'C770' and 'C779') )
       and (MORPH BETWEEN '9650' and '9667')
       then 'Hodgkin - Nodal'

    when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
       and (MORPH BETWEEN '9650' and '9667')
       then 'NHL - Extranodal'

  %if dxdate<='31DEC2009'd %then %do;
    when ( (ICDOsite in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) or (ICDOsite BETWEEN 'C770' and 'C779') )
     and (    ( MORPH BETWEEN '9590' and '9595' ) or ( MORPH BETWEEN '9670' and '9677' )
           or ( MORPH BETWEEN '9680' and '9688' ) or ( MORPH BETWEEN '9690' and '9698' )
       or ( MORPH BETWEEN '9700' and '9717' )
       or   MORPH in ( '9823' '9827' ) )
       then 'NHL - Nodal'

    when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
     and (    ( MORPH BETWEEN '9590' and '9595' ) or ( MORPH BETWEEN '9670' and '9677' )
           or ( MORPH BETWEEN '9680' and '9688' ) or ( MORPH BETWEEN '9690' and '9698' )
       or ( MORPH BETWEEN '9700' and '9717' ) )
       then 'NHL - Extranodal'

    when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C420' 'C421' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
     and (  MORPH in ('9823' '9827') )
       then 'NHL - Extranodal'

   when ( MORPH in ('9731' '9732') )
   then 'Myeloma'

   when ( MORPH in ('9821' '9828' '9836' '9837') )
   then 'Acute Lymphocytic Leukemia'

    when ( ICDOsite in ('C420' 'C421' 'C424') )
     and (  MORPH in ('9823') )
       then 'Chronic Lymphocytic Leukemia'

   when ( MORPH in ('9820' '9822' '9824' '9825' '9826') )
   then 'Other Lymphocytic Leukemia'

   when ( MORPH in ('9840' '9861' '9866' '9867' '9871' '9872' '9873' '9874') )
   then 'Acute Myeloid Leukemia'

   when ( MORPH in ('9891') )
   then 'Acute Monocytic Leukemia'

   when ( MORPH in ('9893') )
   then 'Chronic Monocytic Leukemia'

   when ( MORPH in ('9863' '9868') )
   then 'Chronic Myeloid Leukemia'

   when ( MORPH in ('9860' '9892' '9894') )
   then 'Other Monocytic Leukemia'

   when ( MORPH in ('9801' '9841' '9931' '9932') )
   then 'Other Acute Leukemia'

   when ( MORPH in ('9803' '9842') )
   then 'Other Chronic Leukemia'

   when ( MORPH in ('9800' '9802' '9804' '9830' '9850' '9870' '9880' '9900' '9910' '9930' '9940' '9941') )
   then 'Aleukemic, subleukemic and NOS'

   when ICDOsite in ('C420' 'C421' 'C424')
   and ( MORPH in ('9827') )
   then 'Aleukemic, subleukemic and NOS'

   when ( MORPH BETWEEN '9050' and '9055' )
   then 'Mesothelioma'

   when ( MORPH ='9140' )
   then 'Kaposi Sarcoma'

    when ( MORPH in ('9720' '9721' '9722' '9723' '9740' '9741' '9950' '9970' '9989')
       or (MORPH BETWEEN '9980' and '9984') or (MORPH BETWEEN '9760' and '9764') or (MORPH BETWEEN '9960' and '9962') )
    then 'Miscellaneous'

    when ( (MORPH='C809') or (ICDOsite BETWEEN 'C420' and 'C424') or (ICDOsite BETWEEN 'C760' and 'C768') or (ICDOsite BETWEEN 'C770' and 'C779') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Miscellaneous'
  %end;
  %if dxdate>='01JAN2010'd %then %do;
   when ( (ICDOsite in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) or (ICDOsite BETWEEN 'C770' and 'C779') )
     and (    ( MORPH BETWEEN '9590' and '9596' ) or ( MORPH BETWEEN '9689' and '9691' )
           or ( MORPH BETWEEN '9698' and '9702' ) or ( MORPH BETWEEN '9714' and '9719' )
       or ( MORPH BETWEEN '9727' and '9729' )
       or   MORPH in ( '9670' '9671' '9673' '9675' '9678' '9679' '9680' '9684' '9687' '9695'
                       '9705' '9708' '9709' '9823' '9827' ) )
       then 'NHL - Nodal'

    when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
     and (    ( MORPH BETWEEN '9590' and '9596' ) or ( MORPH BETWEEN '9689' and '9691' )
           or ( MORPH BETWEEN '9698' and '9702' ) or ( MORPH BETWEEN '9714' and '9719' )
       or ( MORPH BETWEEN '9727' and '9729' )
       or   MORPH in ( '9670' '9671' '9673' '9675' '9678' '9679' '9680' '9684' '9687' '9695'
                       '9705' '9708' '9709' '9823' '9827' ) )
       then 'NHL - Extranodal'

    when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C420' 'C421' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
     and (  MORPH in ('9823' '9827') )
       then 'NHL - Extranodal'

   when ( MORPH in ('9731' '9732' '9734') )
   then 'Myeloma'

   when ( MORPH in ('9826' '9835' '9836' '9837') )
   then 'Acute Lymphocytic Leukemia'

    when ( ICDOsite in ('C420' 'C421' 'C424') )
     and (  MORPH in ('9823') )
       then 'Chronic Lymphocytic Leukemia'

   when ( MORPH in ('9820' '9832' '9833' '9834' '9940') )
   then 'Other Lymphocytic Leukemia'

   when ( MORPH in ('9840' '9861' '9866' '9867' '9871' '9872' '9873' '9874' '9895' '9896' '9897' '9910' '9920') )
   then 'Acute Myeloid Leukemia'

   when ( MORPH in ('9891') )
   then 'Acute Monocytic Leukemia'

   when ( MORPH in ('9863' '9875' '9876' '9945' '9946') )
   then 'Chronic Myeloid Leukemia'

   when ( MORPH in ('9860' '9930') )
   then 'Other Myeloid/Monocytic Leukemia'

   when ( MORPH in ('9801' '9805' '9931') )
   then 'Other Acute Leukemia'

   when ( MORPH in ('9733' '9742' '9800' '9831' '9870' '9948' '9963' '9964') )
   then 'Aleukemic, subleukemic and NOS'

   when ICDOsite in ('C420' 'C421' 'C424')
   and ( MORPH in ('9827') )
   then 'Aleukemic, subleukemic and NOS'

   when ( MORPH BETWEEN '9050' and '9055' )
   then 'Mesothelioma'

   when ( MORPH ='9140' )
   then 'Kaposi Sarcoma'

    when ( MORPH in ('9740' '9741' '9950' '9960' '9961' '9962' '9970' '9975' '9980' '9989')
       or (MORPH BETWEEN '9750' and '9758') or (MORPH BETWEEN '9760' and '9769') or (MORPH BETWEEN '9982' and '9987') )
    then 'Miscellaneous'

    when ( (MORPH='C809') or (ICDOsite BETWEEN 'C420' and 'C429') or (ICDOsite BETWEEN 'C760' and 'C768') or (ICDOsite BETWEEN 'C770' and 'C779') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Miscellaneous'

  %end;
  else ''
  end as CancerSchemaAjcc6thEdition

  from &_vdw_tumor as t
  where dxdate between "&startdt."d and "&enddt."d
  ;
QUIT;

%mend CancerSchema;
