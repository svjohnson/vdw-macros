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

  %macro gather_px(outset = _pxcounts) ;
    %** Purpose: Grabs raw px data for the counting. ;
    proc sql ; ** inobs = 1000 nowarn ;
      create table &outset as
      select data_type, code_type, category, code, descrip
            , count(*) as num_recs                      format = comma9.0 label = "No. records"
            , count(distinct p.mrn) as num_ppl          format = comma9.0 label = "No. people (enrolled or not)"
            , count(distinct e.mrn) as num_enrolled_ppl format = comma9.0 label = "No. *enrolled* people"
      from &_vdw_px as p INNER JOIN
           &incodeset as i
      on   p.px_codetype = i.code_type AND
           p.px = i.code
           %if %length(&cohort) > 0 %then %do ;
            INNER JOIN &cohort as c
            on  p.mrn = c.mrn
           %end ;
           LEFT JOIN
           &_vdw_enroll as e
      on   p.mrn = e.mrn AND
           p.adate between e.enr_start and e.enr_end
      where  i.data_type = 'PX' AND
             p.adate between "&start_date"d and "&end_date"d
      group by data_type, code_type, category, code, descrip
      ;
    quit ;
  %mend gather_px ;

  %macro gather_dx(outset = _dxcounts) ;
    %** Purpose: description ;
    proc sql ; ** inobs = 1000 nowarn ;
      create table &outset as
      select data_type, code_type, category, code, descrip
            , count(*) as num_recs                      format = comma9.0 label = "No. records"
            , count(distinct d.mrn) as num_ppl          format = comma9.0 label = "No. people (enrolled or not)"
            , count(distinct e.mrn) as num_enrolled_ppl format = comma9.0 label = "No. *enrolled* people"
      from &_vdw_dx as d INNER JOIN
           &incodeset as i
      on   d.dx_codetype = i.code_type AND
           d.dx = i.code
           %if %length(&cohort) > 0 %then %do ;
            INNER JOIN &cohort as c
            on  d.mrn = c.mrn
           %end ;
           LEFT JOIN
           &_vdw_enroll as e
      on   d.mrn = e.mrn AND
           d.adate between e.enr_start and e.enr_end
      where  i.data_type = 'DX' AND
             d.adate between "&start_date"d and "&end_date"d
      group by data_type, code_type, category, code, descrip
      ;
    quit ;
  %mend gather_dx ;

  %macro gather_rx(outset = _rxcounts) ;
    %** Purpose: description ;
    proc sql ; ** inobs = 1000 nowarn ;
      create table &outset as
      select data_type, code_type, category, code, descrip
            , count(*) as num_recs                      format = comma9.0 label = "No. records"
            , count(distinct r.mrn) as num_ppl          format = comma9.0 label = "No. people (enrolled or not)"
            , count(distinct e.mrn) as num_enrolled_ppl format = comma9.0 label = "No. *enrolled* people"
      from &_vdw_rx as r INNER JOIN
           &incodeset as i
      on   r.ndc = i.code
           %if %length(&cohort) > 0 %then %do ;
            INNER JOIN &cohort as c
            on  r.mrn = c.mrn
           %end ;
           LEFT JOIN
           &_vdw_enroll as e
      on    r.mrn = e.mrn AND
            r.rxdate between e.enr_start and e.enr_end
      where i.data_type = 'NDC' AND
            r.rxdate between "&start_date"d and "&end_date"d
      group by data_type, code_type, category, code, descrip
      ;
    quit ;
  %mend gather_rx ;

  %macro gather_lab(outset = _labcounts) ;
    %** Purpose: description ;
    proc sql ; ** inobs = 1000 nowarn ;
      create table &outset as
      select data_type, code_type, category, code, descrip
            , count(*) as num_recs                      format = comma9.0 label = "No. records"
            , count(distinct l.mrn) as num_ppl          format = comma9.0 label = "No. people (enrolled or not)"
            , count(distinct e.mrn) as num_enrolled_ppl format = comma9.0 label = "No. *enrolled* people"
      from &_vdw_lab as l INNER JOIN
           &incodeset as i
      on   l.test_type = i.code
           %if %length(&cohort) > 0 %then %do ;
            INNER JOIN &cohort as c
            on  l.mrn = c.mrn
           %end ;
           LEFT JOIN
           &_vdw_enroll as e
      on    l.mrn = e.mrn AND
            coalesce(result_dt, lab_dt, order_dt) between e.enr_start and e.enr_end
      where i.data_type = 'LAB' AND
            coalesce(result_dt, lab_dt, order_dt) between "&start_date"d and "&end_date"d
      group by data_type, code_type, category, code, descrip
      ;
    quit ;
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
    ** Redact any counts that are less than &lowest_count ;
    array n num_recs num_ppl num_enrolled_ppl ;
    do i = 1 to dim(n) ;
      if n{i} gt 0 and n{i} lt &lowest_count then n{i} = .a ;
    end ;

    if num_enrolled_ppl then rate_enrolled_ppl = int((num_enrolled_ppl / &EnrPple.) * 10000) ;

    label
      rate_enrolled_ppl = "Rate of enrolled people per 10k enrollees"
    ;
    format rate_enrolled_ppl comma8.0 ;
    drop i ;
  run ;

  proc sort data = &__out ;
    by data_type category ;
  run ;

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
