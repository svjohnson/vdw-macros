/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\My Documents\vdw\macros\CountsAndRates.sas
*
* A rewrite of the VDWCountsAndRates1 macro.
*********************************************/

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
