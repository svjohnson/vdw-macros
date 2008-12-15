%macro Hypertension_BP(outfile, startdate, enddate, 
                       Diastolic_Min = 90, Systolic_Min = 140,
                       Strict_Equality = 0, Either = 1);

/***************************************************************************
****************************************************************************
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History: Created September 27, 2006

* Purpose:
*   Pulls all people with a systolic and-or diastolic BP reading above
*     specified threasholds over specified dates along with their highest
*     systolic and diastolic readings in that period. Can be used to defined
*     hypertension.
*
* Parameters:
*   Outfile = The name of the file that will be output
*   StartDate = The date from which you want to start looking for BP
*   EndDate   = The date to which you want to end looking for BP
*   Diastolic_Min = The minimum diastolic value that will be allowed in output
*   Systolic_Min  = The minimum systolic  value that will be allowed in output
*   Strict_Equality = 0 allows BP readings of min values and above
*                     1 only allows BP readings above the min values
*   Either = 0 requires a systolic AND a diastolic reading above the min
*            1 allows either a systolic OR a diastolic reading above the min
*
* Notes:
*   Systolic and diastolic readings above mins are not required to be on 
*   the same day when Either = 0 is specified.
*
***************************************************************************
**************************************************************************/

%if %sysfunc(abs("&StartDate"d > "&EndDate"d))=1 %then %do;
  %put PROBLEM: The StartDate must be on or before the EndDate;
  %put StartDate is &StartDate., EndDate is &EndDate.;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%if (&Diastolic_Min < 0 OR &Systolic_Min < 0) %then %do;
  %put PROBLEM: The min values for BP must be non-negative;
  %put Diastolic_Min = &Diastolic_Min. , Systolic_Min = &Systolic_Min.;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%if (&Strict_Equality. ^= 0 AND &Strict_Equality. ^= 1) %then %do;
  %put PROBLEM: The Strict_Equality variable must be 0 or 1;
  %put Strict_Equality = &Strict_Equality;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;
%if (&Either. ^= 0 AND &Either. ^= 1) %then %do;
  %put PROBLEM: The Either variable must be 0 or 1;
  %put Either = &Either;
  %put PROBLEM: Doing Nothing;
  %goto exit;
%end;

*Create conditional;
%if (&Strict_Equality. = 0 AND &Either. = 1) %then %do;
  %let Conditional= max(Diastolic) >= &Diastolic_Min. 
                 OR max(Systolic)  >= &Systolic_Min.;
%end;
%else %if (&Strict_Equality. = 1 AND &Either. = 1) %then %do;
  %let Conditional= max(Diastolic) > &Diastolic_Min. 
                 OR max(Systolic)  > &Systolic_Min.;
%end;
%else %if (&Strict_Equality. = 0 AND &Either. = 0) %then %do;
  %let Conditional= max(Diastolic) >= &Diastolic_Min. 
                AND max(Systolic)  >= &Systolic_Min.;
%end;
%else %if (&Strict_Equality. = 1 AND &Either. = 0) %then %do;
  %let Conditional= max(Diastolic) > &Diastolic_Min. 
                AND max(Systolic)  > &Systolic_Min.;
%end;

libname vs "&_VitalLib";

proc sql;
 create table &outfile. as
   select mrn
        , max(Diastolic) as Max_Diastolic 
 label = "Person's highest diastolic reading between &StartDate. and &EndDate."
        , max(Systolic)  as Max_Systolic
 label = "Person's highest systolic reading between &StartDate. and &EndDate."
   from vs.&_VitalData. (where=(Measure_Date between "&StartDate"d 
                                                 AND "&EndDate"d  ))
   group by mrn
   having &Conditional.
 ;
quit;

%exit: %mend Hypertension_BP;

/*TEST SECTION;
proc format;
  value sysf
    low  -  0    = "Non-positive"
    0   <-< 130  = "<130"
    130  -< 140  = "130 to 139"
    140          = "140"
    140 <-< 160  = "140 to 159"
    160  -< 180  = "160 to 179"
    180  -  high = "180+"
  ;
  value diaf
    low  -  0    = "Non-positive"
    0   <-< 80   = "<80"
    80   -< 90   = "80 to 89"
    90           = "90"
    90  <-< 100  = "90 to 99"
    100  -< 110  = "100 to 110"
    110  -  high = "110+"
  ;
quit;
*Problem 1;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2002);
*Problem 2;
%Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Diastolic_Min=-5, Systolic_Min=10);
*Problem 3;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006, 
                 Strict_Equality=Y);
*Problem 4;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006,
                 Either=2);


*Success 1;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006);
proc freq data=testing;
  title "Success 1";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
proc sort data=testing NODUPKEY; by mrn; run;
*Success 2;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006, 
                 Diastolic_Min=85, Systolic_Min=135);
proc freq data=testing;
  title "Success 2";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 3;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006, 
                 Strict_Equality=1, Either=1);
proc freq data=testing;
  title "Success 3";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 4;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006, 
                 Strict_Equality=0, Either=0);
proc freq data=testing;
  title "Success 4";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 5;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006, 
                 Strict_Equality=1, Either=0);
proc freq data=testing;
  title "Success 5";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*Success 6;
%*Hypertension_BP(outfile= testing, startdate= 04Jan2005, enddate= 15Feb2006, 
                 Diastolic_Min=90, Systolic_Min=150, Strict_Equality=1, Either=0);
proc freq data=testing;
  title "Success 6";
  format Max_Diastolic diaf. Max_Systolic sysf.;
  table Max_Diastolic*Max_Systolic /missing;
run;
*/