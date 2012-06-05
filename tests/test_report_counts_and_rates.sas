/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_report_counts_and_rates.sas
*
* <<purpose>>
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

** For inspecting SQL sent to a server. ;
** options sastrace = ',,,d' sastraceloc = saslog nostsuffix ;

%**let rt = C:\deleteme\counts_rates ;
%let rt = \\ghrisas\SASUser\pardre1\counts_rates ;

libname submit "&rt.\submitted" ;
libname main "&rt" ;

%**include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\stack_datasets.sas" ;
%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;
%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\ReportCountsAndRates.sas" ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%**let out_folder = \\home\pardre1\ ;
%let out_folder = c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "count_rate_report.html"
         (title = "count_rate_report output")
          ;

** ods rtf file = "&out_folder.count_rate_report.rtf" device = sasemf ;

%report_counts_rates(inlib = submit
                    , dset_name = chemo_counts
                    , outlib = main
                    , report_name = C:\deleteme\counts_rates\bubba.xls) ;


ods _all_ close ;



run ;
