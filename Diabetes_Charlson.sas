%include '\\home\rosstr1\My SAS Files\Scripts\Remote\RemoteStart.sas';

%macro Diabetes_Charlson(outfile, startdate, enddate, EncType = A);
/***************************************************************************
****************************************************************************
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:  Created September 15, 2006
* 
* Purpose:
*   For the diabetes dx as defined by Charlson, this macro creates
*    - A dataset called Diabetes_Charlson with the dx and descriptions
*    - A format called Diabetes_Charlson with the dx
*    - A dataset called &outfile with all people having diabetes
*
* Parameters:
*   Outfile = the file that will contain the list of MRN of those with diabetes
*   StartDate = Date from which you want to start looking for diabetes dx
*   EndDate   = Date from which you want to stop looking for diabetes dx
*   EncType   = Value of A will search All encounters (default),
*               Value of I will search only Inpatient encounters
*               Value of B will search Both IP and OP for dx (but not others)
*
* Dependencies:
*   The Dx file (with the EncType variable as the char(2) version if you use
*                EncType = I or B options
*   A call to input standard vars before running the macro
*
***************************************************************************
**************************************************************************/

*Catch and Throw;
%let EncType = %upcase(&EncType.);
%if (&EncType.^= A AND &EncType. ^= I AND &EncType. ^= B) %then %do;
  %put PROBLEM: The parameter 'Inpatient' must be among 'A', 'I', or 'B';
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%else %if "&StartDate"d > "&EndDate"d %then %do;
  %put PROBLEM: The Startdate must be on or before the EndDate;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;

/**************************************
*From the Charlson Macro
***Diabetess;
     "250   "-"250.33",
	   "250.7 "-"250.73" = "DIAB"
***Diabetes with chronic complications
	   "250.4 "-"250.63" = "DIABC"
**************************************/

libname util "&_UtilizationLib." access = readonly ;

proc format;
  value $Diabetes_Charlson
     "250   "-"250.33",
	   "250.7 "-"250.73",
	   "250.4 "-"250.63"  = "DIABC"
  ;
run;

data Diabetes_Charlson;
*Note - Datalines are not allowed in macros;
  length diabetes_dx $6 description $50;

diabetes_dx="250"   ; description="DIABETES MELLITUS"          ; output;                     
*Just in case lets throw one in with the decimal;
diabetes_dx="250."  ; description="DIABETES MELLITUS"          ; output;                     
diabetes_dx="250.22"; description="DM2/NOS W HYPEROSMOL UNC"   ; output;                     
diabetes_dx="250.50"; description="DM2/NOS W EYE MANIF NSU"    ; output;                     
diabetes_dx="250.0" ; description="DIABETES MELLITUS UNCOMP"   ; output;                     
diabetes_dx="250.23"; description="DM1 HYPEROSMOLARITY UNC"    ; output;                     
diabetes_dx="250.51"; description="DM1 W EYE MANIFEST NSU"     ; output;                     
diabetes_dx="250.00"; description="DM2/NOS UNCOMP NSU"         ; output;                     
diabetes_dx="250.29"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.52"; description="DM2/NOS W EYE MANIF UNC"    ; output;                     
diabetes_dx="250.01"; description="DM1 UNCOMP NSU"             ; output;                     
diabetes_dx="250.3" ; description="DIABETES W COMA NEC"        ; output;                     
diabetes_dx="250.53"; description="DM1 W EYE MANIFEST UNC"     ; output;                     
diabetes_dx="250.02"; description="DM2/NOS UNCOMP UNC"         ; output;                     
diabetes_dx="250.30"; description="DM2/NOS W COMA NEC NSU"     ; output;                     
diabetes_dx="250.59"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.03"; description="DM1 UNCOMP UNC"             ; output;                           
diabetes_dx="250.31"; description="DM1 W COMA NEC NSU"         ; output;                     
diabetes_dx="250.6" ; description="DM2 NEUROLOGIC MANIFEST"    ; output;                     
diabetes_dx="250.09"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="503.2" ; description="DM2/NOS W COMA NEC UNC"     ; output;                     
diabetes_dx="250.60"; description="DM2/NOS W NEUR MANIF NSU"   ; output;                     
diabetes_dx="250.1" ; description="DIABETES W KETOACIDOSIS"    ; output;                     
diabetes_dx="250.33"; description="DM1 W COMA NEC UNC"         ; output;                     
diabetes_dx="250.61"; description="DM1 W NEURO MANIFEST NSU"   ; output;                     
diabetes_dx="250.10"; description="DM2/NOS W KETOACID NSU"     ; output;                     
diabetes_dx="250.4" ; description="DM W RENAL MANIFESTATION"   ; output;                     
diabetes_dx="250.62"; description="DM2/NOS W NEUR MANIF UNC"   ; output;                     
diabetes_dx="250.11"; description="DM1 W KETOACIDOSIS NSU"     ; output;                     
diabetes_dx="250.40"; description="DM2/NOS W REN MANIF NSU"    ; output;                     
diabetes_dx="250.63"; description="DM1 W NEURO MANIFEST UNC"   ; output;                     
diabetes_dx="250.12"; description="DM2/NOS W KETOACID UNC"     ; output;                     
diabetes_dx="250.41"; description="DM1 W RENAL MANIFEST NSU"   ; output;                     
diabetes_dx="250.7" ; description="DM W CIRC DISORDER"         ; output;                     
diabetes_dx="250.13"; description="DM1 W KETOACIDOSIS UNC"     ; output;                     
diabetes_dx="250.42"; description="DM2/NOS W REN MANIF UNC"    ; output;                     
diabetes_dx="250.70"; description="DM2/NOS W CIRC DIS NSU"     ; output;                     
diabetes_dx="250.19"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.43"; description="DM1 W RENAL MANIFEST UNC"   ; output;                    
diabetes_dx="250.71"; description="DM1 W CIRC DISORD NSU"      ; output;                     
diabetes_dx="250.2" ; description="DM W HYPEROSMOLARITY"       ; output;                     
diabetes_dx="250.49"; description="Unspec: adult-onset vs juvenile type";output;
diabetes_dx="250.72"; description="DM2/NOS W CIRC DIS UNC"     ; output;                     
diabetes_dx="250.20"; description="DM2/NOS W HYPEROSMOL NSU"   ; output;                     
diabetes_dx="250.5" ; description="DM W OPHTHALMIC MANIFEST"   ; output;                     
diabetes_dx="250.73"; description="DM1 W CIRC DISORD UNC"      ; output;                     
diabetes_dx="250.21"; description="DM1 HYPEROSMOLARITY NSU";   ; output;
run;

proc sql noprint;
  create table &outfile as
    select distinct mrn
    from util.&_DxData
    where dx in(select diabetes_dx from diabetes_charlson)
      AND adate between "&startdate"d AND "&EndDate"d
%if       %upcase(&EncType.) = I %then AND EncType = "IP";
%else %if %upcase(&EncType.) = B %then AND EncType in("AV", "IP");
  ;
quit;

%exit: %mend Diabetes_Charlson;

*TEST SECTION;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas";

*Problem 1;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = Z);
*Problem 2;
%Diabetes_Charlson(outfile=MyTest, startdate=15May2004, enddate=01Mar2002
                 , EncType = A);

*Success 1;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = A);
*Success 2;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = I);
*Success 3;
%Diabetes_Charlson(outfile=MyTest, startdate=01May2004, enddate=15May2004
                 , EncType = B);
                 
endrsubmit;
signoff chsdwsas;