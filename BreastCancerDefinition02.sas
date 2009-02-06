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
          behav in ("&behav_primary", "&behav_unknown_prim_meta")
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
        %PUT BCD2 NOTE: There may be as many as %eval(&SQLOBS/2) people with > 1 tumor dignosed on the same day, each with different receptor statuses or stages. ;
        %PUT BCD2 NOTE: The macro will output composite records for each such person e.g., w/max(stage), ER+ if any are +, etc.. ;
      %end ;
      %if %length(&OutMultFirsts) > 0 %then %do ;
        create table &OutMultFirsts as
        select *
        from _multiple_firsts
        ;

        %put BCD2 NOTE: The multiple-first-tumor records have been written out to &OutMultFirsts ;
        %put BCD2 NOTE: The multiple-first-tumor records have been written out to &OutMultFirsts ;
        %put BCD2 NOTE: The multiple-first-tumor records have been written out to &OutMultFirsts ;
        %put BCD2 NOTE: The multiple-first-tumor records have been written out to &OutMultFirsts ;
      %end ;

    %end ;

    create table &OutSet as
    select *
    from _FirstBTs
    ;
  quit ;

%mend BreastCancerDefinition02 ;

