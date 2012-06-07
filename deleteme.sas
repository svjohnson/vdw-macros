/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\deleteme.sas
*
* <<purpose>>
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  errors    = 5
  nocenter
  noovp
  nosqlremerge
  linesize  = 150
;

libname s '\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\OutputDatasets\Lots' ;
libname c 'C:\deleteme\counts_rates\' ;

%let dset = s.ghc_lots  ;
%**let dset = c.test_counts ;

%macro do_print() ;
  %** This was in the prior version of the macro--repeating it here for compatibility. ;
	proc print data = s.ghc_lots (obs=200) ;
		title1 "Here is a sample of what you are sending out" ;
		title2 "Please inspect the full dataset in <<something>> before sending." ;
    id data_type category ;
		var code descrip num_recs num_ppl num_enrolled_ppl rate_enrolled_ppl ;
		sum num_ppl num_enrolled_ppl rate_enrolled_ppl ;
    by data_type category ;
  run ;
%mend do_print ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%**let out_folder = \\home\pardre1\ ;
%let out_folder = C:\Documents and Settings\pardre1\My Documents\vdw\macros\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "FILE_NAME.html"
         (title = "FILE_NAME output")
          ;

	proc tabulate data = &dset missing format = comma9.0 ; ** classdata = classes ;
		class data_type descrip category / missing ;
		classlev descrip / style=[outputwidth=5.5in] ;
		var num_: rate_enrolled_ppl ;
		table data_type="Type of data" * (category * descrip="Event") , (num_recs num_ppl num_enrolled_ppl rate_enrolled_ppl)*SUM=" " / misstext = '.' box = "Data to be sent" ;
		** format data_type $dt. ;
	run;


run ;

ods _all_ close ;





