/*********************************************
* Sharon Fuller
* Group Health Research Institute
* (206) 287-2552
* fuller.s@ghc.org
*
*Purpose: Prioritize and assign a single race per person
*					If only one race is listed, set CombinedRace to that race
*					If person is WH and one other, set CombinedRace to that other (or to "MU" depending on parameters)
*					If there is more than one non-WH race, or one of the races is "MU", set CombinedRace to "MU"
*					Otherwise, set CombinedRace to "UN"
*
*NOTES: this macro depends on the races being listed in the following order (which they currently are per VDW spec)
*				"HP" = "Native Hawaiian or Other Pacific Islander"
*				"IN" = "American Indian/Alaska Native"
*				"AS" = "Asian"
*				"BA" = "Black or African American"
*				"WH" = "White"
*				"MU" = "More than one race"
*				"UN" = "Unknown or Not Reported"
*      so, for example, if Race1 is WH, you know there will only be MU or UN in subsequent race fields
*
*********************************************/

%macro GetCombinedRace (Inset, 				/* The name of a dataset containing the MRNs of people
                     										whose race you want to identify. */
										Outset, 					/* The name of the output dataset - contains vars from inset,
																				plus CombinedRace and Race1--Race5.
																				Inset and Outset can be the same.*/
										Freqs = 'N', 			/*Defaults to 'N'.  If change to 'Y' will get some freqs in list file.*/
										WHOther = 'other' /*Options are 'other' and 'MU'.
																				If a person is White and one other race, should they be counted as
																				that other race (default), or as multiple.*/
										);

	proc sql;
		create table work.race as
		select i.*, Race1, Race2, Race3, Race4, Race5
		from &Inset. as i left outer join &_vdw_demographic d
			on i.mrn = d.mrn
		;
	quit;

	data &Outset. (drop = i);
		set work.race;
		length combinedrace $2. i 8.;
		combinedrace = "UN";
		array aryrace {*} Race1 Race2;
		do i=1 to dim(aryrace);
			if aryrace{i} = "HP" then do;
				CombinedRace = "HP";
			end;
			else if aryrace{i} in ( "IN" , "AS", "BA") then do;
				if combinedrace = "UN" then CombinedRace = aryrace{i};
				else combinedrace = "MU";
			end;
			else if aryrace{i} = "WH" then do;
				if combinedrace ="UN" then CombinedRace = "WH";
				else if &WHOther = 'MU' then combinedrace = "MU";
			end;
			else if aryrace{i} = "MU" then do;
				CombinedRace = "MU";
			end;
		end;
	run;

	%if %upcase(&freqs.) = 'Y' %then %do;
		proc freq data=&outset.;
		tables Race1 Race2 race3 race4 race5
							CombinedRace
							CombinedRace*Race1*Race2*Race3*Race4*Race5 /list nocum missing;
		run;
	%end;

%mend getcombinedrace;

/*********************************************************;
* Testing GetCombinedRace;
* ;
%include '\\Groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas';

proc sql outobs=10000;
	create table PeopleIn as
	select distinct mrn
	from vdw.enroll_with_type_vw
	where probably_denominator_safe = 1
	;
quit;

%GetCombinedRace(PeopleIn, PeopleOut, freqs = 'Y', WHOther = 'Other') ;
%GetCombinedRace(PeopleIn, PeopleOut, freqs = 'N', WHOther = 'MU') ;
**********************************************************/

