/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_get_lab.sas
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

%macro get_test_cohort(outset = , n = 100) ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from vdw.demog
    where substr(mrn, 4, 1) = 'L'
    ;
  quit ;
%mend ;

data tests_wanted ;
input test_type $ ;
datalines ;
LDL
;
run ;

%get_test_cohort(outset = ppls) ;


%GetLabForPeopleAndLab(
							People = ppls
						, LabLst = tests_wanted
						, StartDt = 01jan2006
						, EndDt = 31dec2006
						, Outset = s.test_tests
						) ;

