/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\ReportCountsAndRates.sas
*
* Produces xls files combining the outputs of several sites runs of the VDWCountsAndRates macro.
*********************************************/

%macro report_counts_rates(inlib =        /* lib where the site-submitted dsets live */
                          , dset_name =   /* the stub dataset name to use to identify which dsets should be part of this report */
                          , outlib =      /* the lib where you want the output, single dset of counts/rates to be */
                          , report_name = /* the full path & filename of the output excel file. */ ) ;

  title1 "Counts/Rates from &dset_name.." ;

  %stack_datasets(inlib = &inlib, nom = &dset_name, outlib = &outlib) ;

  proc sort data = &outlib..&dset_name out = gnu ;
    by data_type site category code ;
  run ;

  %macro distinct(var) ;
    %** Purpose: description ;
    proc sort nodupkey data = gnu(keep = &var) out = _&var ;
      by &var ;
    run ;
  %mend distinct ;

  %**distinct(descrip) ;
  %**distinct(code) ;

  proc sort nodupkey data = gnu (keep = data_type category code descrip) out = _code ;
    by data_type category code descrip ;
  run ;

  %distinct(site) ;

  proc sql ;
    create table classes as
    select data_type, descrip, code, category, site
    from _code CROSS JOIN _site
    ;
  quit ;

  proc format ;
    value $dt
      "PX" = "Procedure"
      "DX" = "Diagnosis"
      "NDC" = "Rx Fill"
      "LAB" = "Lab Result"
    ;
  quit ;

  ods tagsets.ExcelXP
    file = "&report_name"
    style = analysis
    options (
              Frozen_Headers="5"
              Frozen_RowHeaders="1"
              embedded_titles="yes"
              embedded_footnotes="yes"
              autofit_height = "yes"
              /* suppress_bylines = 'yes' */
              absolute_column_width = "25, 12, 40, 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5"
              /* sheet_interval='bygroup'  */
              /* doc = 'help' */
              orientation = 'landscape'
              )
  ;

  %macro new_sheet(tab_name, var, box_text = " ") ;
    ods tagsets.ExcelXP options (sheet_interval = 'none' sheet_name = "&tab_name") ;

    ** proc print ;
    **   var category code descrip &var ;
    ** run ;

 		proc tabulate data = gnu missing format = comma9.0 classdata = classes ;
  		freq &var;  ;
  		keylabel N=" ";
  		class data_type descrip category site / missing ;
   ** table category="Category" * (data_type="Type of data" * descrip="Event" * code="Signifying Code" all="Category Totals") , site*N*[style=[tagattr='format:#,###']] / misstext = '.' box = &box_text ;
  		table category="Category" * (data_type="Type of data" * descrip="Event" all="Category Totals") , site*N*[style=[tagattr='format:#,###']] / misstext = '.' box = &box_text ;
  		format data_type $dt. ;
 		run;


  %mend new_sheet ;

  %new_sheet(tab_name = Records   , var = num_recs        , box_text = "Raw record counts") ;
  %new_sheet(tab_name = People    , var = num_ppl         , box_text = "Counts of people (enrolled or not)") ;
  %new_sheet(tab_name = Enrollees , var = num_enrolled_ppl, box_text = "Counts of people enrolled at the time of the event.") ;
  %new_sheet(tab_name = Rates     , var = rate_enrolled_ppl, box_text = "Rates per 10k enrollees ") ;


  ods tagsets.ExcelXP close ;


%mend report_counts_rates ;
