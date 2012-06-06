/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_getcombinedrace.sas
*
* <<purpose>>
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

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\GetCombinedRace.sas" ;
%include '\\home\pardre1\SAS\SCRIPTS\sasntlogon.sas';
%include "//ghrisas/warehouse/sasdata/crn_vdw/lib/StdVars_Teradata.sas";

%macro gen_cohort(outset = s.cohort, n = 2000) ;
  %** Purpose: description ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from &_vdw_demographic
    where substr(mrn, 3, 1) = 'Q'
    ;
  quit ;
%mend gen_cohort ;

%gen_cohort ;

%GetCombinedRace (Inset = s.cohort, 				/* The name of a dataset containing the MRNs of people
                     										whose race you want to identify. */
										Outset = combinerace_test, 					/* The name of the output dataset - contains vars from inset,
																				plus CombinedRace and Race1--Race5.
																				Inset and Outset can be the same.*/
										Freqs = 'Y', 			/*Defaults to 'N'.  If change to 'Y' will get some freqs in list file.*/
										WHOther = 'other' /*Options are 'other' and 'MU'.
																				If a person is White and one other race, should they be counted as
																				that other race (default), or as multiple.*/
										);
