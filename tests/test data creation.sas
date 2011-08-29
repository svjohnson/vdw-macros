/*Macro to create 3 test dataset in the library called MYLIB.  The*/
/*location of the library MYLIB is specified by the programmer   */
/*Sandy Padmanabhan - 7/14/2011                                            */

/*Macro EDIT_SECTION let the user to specify the location where*/
/*they want the datasets to be stored.                                          */

%macro Edit_section;

  %global lib_loc;

  /*Please specify the location where the MYLIB has to be created*/

  %let lib_loc = \\ctrhs-sas\SASUser\pardre1\vdw\macro_testing ;

%mend edit_section;

/*Macro CRT_PRELIM creates a preliminery dataset which generates*/
/*the values for the variables.                                                           */

%macro crt_prelim;

  data newid;
    do _N_ = 1 to 70;
      rannum = int(uniform(0)*18);
	  if (10 <= rannum <= 36) then ranch = byte(rannum + 55);
      ranord = round(uniform(0) * 1000000000, 1);

	  /*creation of MRN variables*/
	  MRN = put(ranord, z9.);
	  MRN = cats(ranch,MRN);
	  STUDYID = MRN;
      sid = MRN;

	  /*creation of Social Secutiry Number Variables*/
	  SOCIAL = put(ranord+19, SSN11.);
	  SECURITY = put(ranord+33, SSN11.);
	  other_ssn = put(ranord-64, SSN11.);

	  /*creation of Birth_Date Variables*/
	  if mod(_N_, 5) = 0 then do;
	    BIRTH_DATE = intnx('YEAR', "&sysdate"d, -90, 's');
      end;
      else if mod(_N_, 4) = 0 then do;
        BIRTH_DATE = intnx('YEAR', "&sysdate"d, -88, 's');
      end;
	  else if mod(_N_, 3) = 0 then do;
	    BIRTH_DATE = intnx('YEAR', "&sysdate"d, -85, 's');
	  end;
	  else do;
	    BIRTH_DATE = intnx('YEAR', "&sysdate"d, -65, 's');
	  end;
	  BIRTH_DATE = intnx('WEEK', BIRTH_DATE , 3, 'e');
	  DOB = intnx('MONTH', BIRTH_DATE, 1, 's');
	  other_dat = intnx('WEEK', DOB, 1, 'e');
	  output;
	end;
	format BIRTH_DATE DOB other_dat mmddyy10.;
  run;

  proc sort data = newid;
    by MRN;
  run;

%mend crt_prelim;

/*Macro POPUL_MYLIB, populates the library MYLIB with 3*/
/*datasets each with 20 records.  It also deletes the         */
/*prelimenery dataset created in %CRT_PRELIM.                */

%macro popul_mylib;

  data mylib.transfer1(drop = rannum ranch ranord)
          mylib.transfer2(drop = rannum ranch ranord)
          mylib.transfer3(drop = rannum ranch ranord);
    set newid;
	where not missing(ranch);
    if _N_ le 20 then do;
	  output mylib.transfer1;
	end;
	else if _N_ gt 20 and _N_ le 40 then do;
	  output mylib.transfer2;
	end;
	else if _N_ gt 40 and _N_ le 60 then do;
	  output mylib.transfer3;
	end;
  run;

  proc sql noprint;
    drop table newid;
  quit;

%mend popul_mylib;

/*Macro CREAT_TEST_DATA calls all the above macros*/

%macro creat_test_Data;

  %edit_section;

  libname mylib "&lib_loc";

  %crt_prelim;
  %popul_mylib;

%mend creat_test_Data;

/*Calling CREAT_TEST_DATA*/

%creat_test_Data;
