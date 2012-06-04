/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_countsandrates.sas
*
* Tests the rewrite of the counts-and-rates program.
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\CountsAndRates.sas" ;
%include '\\home\pardre1\SAS\SCRIPTS\sasntlogon.sas';
%include "//ghrisas/warehouse/sasdata/crn_vdw/lib/StdVars_Teradata.sas";

%let outt = \\ghrisas\SASUser\pardre1\ ;

libname s "&outt" ;

  /*
    InCodeSet
      data_type: one of PX, DX, NDC
      code_type: one of the valid values for px_codetype, dx_codetype, or null for NDCs.
      category: a user-specified string that can be used to group codes into categories (e.g., 'Analgesics', 'Therapeutic Radiation').
      code: the actual NDC, ICD-9 dx code, etc.
  */

data gnu ;
  infile datalines truncover ;
  input
    @1    data_type   $char3.
    @7    code_type   $char2.
    @13   category    $char30.
    @45   code        $char12.
    @59   descrip     $char200.
  ;
  ** if data_type = 'DX' ;
datalines ;
PX    C4    Pretend Category                99211         Evaluation/Maintenance of Existing Patient
PX    C4    DEXA Scans                      3095F         Central dual-energy X-ray absorptiometry (DXA) results documented (OP)
PX    C4    DEXA Scans                      3096F         Central dual-energy X-ray absorptiometry (DXA) ordered (OP)
PX    C4    DEXA Scans                      76075         DXA BONE DENSITY,  AXIAL
PX    C4    DEXA Scans                      76076         DXA BONE DENSITY/PERIPHERAL
PX    C4    DEXA Scans                      76077         DXA BONE DENSITY/V-FRACTURE
PX    C4    DEXA Scans                      77080         Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more site
PX    C4    DEXA Scans                      77081         Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more site
PX    C4    DEXA Scans                      77082         Dual-energy X-ray absorptiometry (DXA), bone density study, 1 or more site
PX    H4    DEXA Scans                      G8399         PATIENT WITH CENTRAL DUAL-ENERGY X-RAY ABSORPTIOMETRY (DXA) RESULTS DOCUME
PX    H4    DEXA Scans                      G8400         PATIENT WITH CENTRAL DUAL-ENERGY X-RAY ABSORPTIOMETRY (DXA) RESULTS NOT DO
PX    C4    Radiology Exams	                78315	        78315:Bone and/or joint imaging: 3 phase study
PX    C4    Radiology Exams	                78306	        78306:Bone and/or joint imaging: whole body
PX    C4    Radiology Exams	                78305	        78305:Bone and/or joint imaging: multiple areas
PX    C4    Radiology Exams	                78300	        78300:Bone and/or joint imaging: limited area
PX    C4    Radiology Exams	                78320	        78320:Bone and/or joint imaging: tomographic (SPECT)
DX    09    Pretend Category                V82.81        Screening for osteoporosis
DX    09    Pretend Category                V72.84        Pre-operative procedure, unspecified
NDC         Pretend Category                00002323704   Fascinating NDC.
LAB         Pretend Category                ALBUMIN       Lab tests I have known.
;
run ;

%macro gen_cohort(outset = s.cohort, n = 200) ;
  %** Purpose: description ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from &_vdw_demographic
    where substr(mrn, 3, 1) = 'Q'
    ;
  quit ;
%mend gen_cohort ;

%**gen_cohort ;

options mlogic mprint ;

options orientation = landscape ;
ods graphics / height = 6in width = 10in ;

%**let out_folder = \\home\pardre1\ ;
%let out_folder = \\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "test_counts_and_rates.html"
         (title = "test_counts_and_rates output")
          ;


%VDWCountsAndRates(incodeset   = gnu
                  , start_date = 01jan2007
                  , end_date = 31dec2008
                  /* , cohort = s.cohort */
                  , outpath = &outt
                  , outfile = test_counts
                  ) ;

run ;

ods _all_ close ;


