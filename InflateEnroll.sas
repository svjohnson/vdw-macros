/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\InflateEnroll.sas
*
* Given an input dset of MRNs and dates over which the user
* wants enroll records, this macro creates an old-style 1-rec-
* per-member-per-month type dset, covering the specified
* period.
*********************************************/

%macro GetInflatedEnroll(InSet       /* Name of the dset containing the CHSIDs of the ppl whose ENROLL recs you want. */
                        , StartDt    /* The start of the period over which you want ENROLL recs--either a complete date constant ('01Jan1991'd) or the name of a date var in InSet */
                        , EndDt      /* The end of the period over which you want ENROLL recs, e.g., 30Jun2003 */
                        , OutSet     /* The name of the output dataset. */
                        , EarliestYear = 1980
                        , MinVars =
                        ) ;

   /*

      The major challenge will be dealing with any site-
      specific value-added vars that I dont know about.  I
      will need to generate a list of non-key vars and wrap
      them up in aggregate functions, without knowing
      anything about them.

      I will arbitrarily choose to wrap them in max().

   */

   libname enr "&_EnrollLib" access = readonly ;

   proc sql ;
      * Step 1: get the start/stop ENROLL recs that cover any part of the period of interest ;
      CREATE TABLE _svelte_enroll AS
      SELECT e.*
      FROM enr.&_enrolldata AS e INNER JOIN
            &InSet AS i
      ON    e.MRN = i.MRN
      where &StartDt le e.enr_end AND
            &EndDt   ge e.enr_start
      ORDER BY mrn, enr_start
      ;

      * While we are here, lets build a SELECT list for any non-standard vars that might exist. ;
      * reset noprint ;
      %if %length(&MinVars) > 0 %then %do ;
         SELECT case
                  when lowcase(name) in (%lowcase(&MinVars)) then 'min(' || compress(name) || ') as ' || name
                  else                                            'max(' || compress(name) || ') as ' || name
                end as c
      %end ;
      %else %do ;
         SELECT 'max(' || compress(name) || ') as ' || name as c
      %end ;
      INTO :agg_vars separated by ', '
      FROM dictionary.columns
      where libname = 'WORK' AND
            memname = '_SVELTE_ENROLL' AND
            lowcase(name) not in ('mrn', 'enr_year', 'enr_month', 'enr_start', 'enr_end')
      ;

      * Now calculate the earliest start date and latest end date. ;
      SELECT min(&StartDt) as min_start, max(&EndDt) as max_end
      INTO  :min_start, max_end
      from _svelte_enroll
      ;

   quit ;

   data _flags ;
      do ENR_Year = year("&min_start"d) to year("&max_end"d) ;
         do ENR_Month = 1 to 12 ;
            _enr_dat = mdy(enr_month, 15, enr_year) ;
            * Only output those recs that fall within the start/end dates ;
            if "&min_start"d le _enr_dat le "&max_end"d then output ;
         end ;
      end ;
   run ;

   proc sql ;
      alter table _flags add primary key (_enr_dat) ;

      create table &OutSet as
      select
           p.MRN
         , f.ENR_Year
         , f.ENR_Month
         , &agg_vars
      from  _svelte_enroll as p CROSS JOIN
            _flags as f
      where f._enr_dat BETWEEN p.enr_start AND p.enr_end
      group by p.mrn, ENR_Year, ENR_Month ;
   quit ;

%mend GetInflatedEnroll ;
