/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\ReportCountsAndRates.sas
*
* Produces xls files combining the outputs of several sites runs of the generate_counts_rates macro.
*********************************************/

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
