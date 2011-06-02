/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_make_inclusion_table.sas
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
filename crn_macs  FTP     "CRN_VDW_MACROS.sas"
                   HOST  = "centerforhealthstudies.org"
                   CD    = "/CRNSAS"
                   PASS  = "%1thunder#dog"
                   USER  = "CRNReader" ;

%include crn_macs ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\make_inclusion_table.sas" ;

%macro make_test_cohort ;
  proc sql outobs = 10000 nowarn ;
    create table s.test_cohort as
    select mrn
    from vdw.demog
    where substr(mrn, 4, 1) = 'G'
    ;
  quit ;
%mend ;

%*make_test_cohort ;

ods html path = "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\" (URL=NONE)
         body = "test_make_inclusion_table.html"
         (title = "test_make_inclusion_table output")
          ;


options mprint ;

%make_inclusion_table(cohort = s.test_cohort) ;

run ;
ods html close ;

