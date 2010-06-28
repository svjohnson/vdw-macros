/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_bmi_adult_macro.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;

%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\BMI_Adult_Macro.sas" ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

%macro get_test_cohort(outobs = s.test_vitals, n = 50) ;
  proc sql outobs = &n nowarn ;
    create table &outobs as
    select mrn
    from &_vdw_demographic
    where substr(mrn, 3, 1) = 'Z'
    ;
  quit ;
%mend ;

%get_test_cohort ;

options mprint ;

%GetAdultBMI(people = s.test_vitals, outset = s.test_adult_bmi, StartDt = '01jan2006'd, EndDt = '30jun2007'd) ;
