/***************************************************************************
****************************************************************************
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:
*   Created Sept 18, 2006
*
* Purpose:
*   For every variable in path.filename that has a date format, this macro
*     creates two global macro variables in date9 format with the names
*     TheDateVar_Min and TheDateVar_Max
*   You may optionally print the results to the lst file
*
* Parameters:
*   Path = The path name to the data file (which will get called as a libname)
*   Filename = The name of the data set
*   Print = Set to 0 will supress the date ranges printed to screen
*           Set to 1 (default) will show all date vars min and max values
*
* Examples:
*   %GetDateRange(&_TumorLib., &_TumorData.);
*   ...will create the global variables
*     DOD_Max, DOD_Min, BDate_Max, BDate_Min, DxDate_Max, DxDate_Min, 
*     DT_Surg_Max, DT_Surg_Min and so forth where...
*   &DOD_MAX = 09Sep2006
*   &DOD_Min = 01Feb1982
*   and so forth
*
***************************************************************************
**************************************************************************/

%include '\\home\rosstr1\My SAS Files\Scripts\Remote\RemoteStart.sas';

%macro GetDateRange(path, filename, print=1);

  libname __PATH "&path.";

  %if %sysfunc(exist(__Path.&filename.)) = 0 %then %do;
    %put PROBLEM: The file &filename. does not exist in the path you specified;
    %put PROBLEM: Path = &path.;
    %put PROBLEM: DOING NOTHING;
    %goto exit;
  %end;
  %else %if (&print. ^=0 AND &print. ^=1) %then %do;
    %put PROBLEM: The print parameter must be equal to zero (0) or one (1);
    %put PROBLEM: DOING NOTHING;
    %goto exit;
  %end;

  *Go through the select twice -once for the globals that will be made;
  *  Once for the locals for the summary proc;
  proc sql noprint;
      select compress(name) || "_Max " || compress(name) || "_Min" 
             into: ForGlobals separated by " " 
      from dictionary.columns
      where upcase(compress(type))    = "NUM" 
        AND upcase(compress(libname)) = "__PATH"
        AND upcase(compress(MemName)) = upcase("&filename")
        AND (
             index(upcase(format), "DATE") > 0
            OR
             index(upcase(format), "YY") > 0
            OR
             index(upcase(format), "JULIAN") > 0
            )
    ;
    select name into: DateVars_&filename. separated by " " 
      from dictionary.columns
      where upcase(compress(type))    = "NUM" 
        AND upcase(compress(libname)) = "__PATH"
        AND upcase(compress(MemName)) = upcase("&filename")
        AND (
             index(upcase(format), "DATE") > 0
            OR
             index(upcase(format), "YY") > 0
            OR
             index(upcase(format), "JULIAN") > 0
            )
    ;
  quit;
  
  *Verify that the macro variable exists (that there is at least one date var);
  %if %symexist(DateVars_&filename.) %then %do;
  
    %put The date variables in &filename. are &&DateVars_&filename;
    *Get the min and max of the date vars;
    proc summary data= __Path.&filename. noprint min max;
      var &&DateVars_&filename;
      output out=Ranges;
    run;
    *Make MAX come before MIN;
    proc sort data=Ranges; by _STAT_; run;

    *Allow user to see the results in the .lst file;
    %if &print. = 1 %then %do;
     proc print data=Ranges; 
     title "The minimum and maximum values of the date variables in &filename.";
        where upcase(compress(_STAT_)) in("MIN", "MAX");
     run;
    %end;
    
    *Declare the variables as global - call symput will default to local o.w.;
    %global &ForGlobals;
    *Create local variables holding the min and max values;
    data _NULL_;
      set Ranges (where=(upcase(compress(_STAT_)) in("MIN", "MAX")));
      
      array datevars {*} _NUMERIC_ ;
      if _n_ = 1 then do;
        do i=1 to dim(datevars);
          if vname(datevars{i}) NOT IN("_TYPE_", "_FREQ_", "_STAT_") then
            call symput(vname(datevars{i}) || "_Max", put(datevars{i}, date9.));
        end;
      end;
      else do;
        do i=1 to dim(datevars);
          if vname(datevars{i}) NOT IN("_TYPE_", "_FREQ_", "_STAT_") then
            call symput(vname(datevars{i}) || "_Min", put(datevars{i}, date9.));
        end;
      end;
    run;
    
    *Clean up;
    proc sql;
      drop table Ranges;
    quit;
  %end;
  %else %do;
    %put PROBLEM: Sorry, but no date variables were found in &filename;
    %put PROBLEM: Verify that &filename. has at least one numeric variable;
    %put PROBLEM: formatted as a date variable;
    %goto exit;
  %end;

%exit: %mend GetDateRange;

*TEST SECTION;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas";

/*******************
* Raise exceptions *
*******************/
*Print var out of range;
%GetDateRange(&_RxLib. , &_RxData., print=2);
*Data that doesnt exist;
%GetDateRange(&_RxLib. , NotReal);
*A file with no date variables;
%GetDateRange(&_RxLib. , &_EverNDCData);


*NOW FOR SUCCESSFUL RUNS;
%GetDateRange(&_UtilizationLib. , &_DXDATA.   , print=0);
%GetDateRange(&_TumorLib.       , &_TUMORDATA., print=1);
%GetDateRange(&_RxLib.          , &_RxData.   , print=1);
%GetDateRange(&_VitalLib.       , &_VitalData          );

%put _user_;

endrsubmit;
signoff chsdwsas;