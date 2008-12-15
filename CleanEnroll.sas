%macro CleanEnroll(OutLib, Clean=N, Dirty=N, Report=Y);
/***************************************************************************
* Parameters:
*   OutLib  = The library name you've already declared where you want output
*             you elect to save (Clean="Y", Dirty="Y") to go.
*   Clean   = "Y" outputs a table (in OutLib) with enroll records deemed clean.
*             Any other value will not output this table.
*   Dirty   = "Y" outputs a table (in Outlib) with enroll records deemed dirty.
*             along with DirtyReason, a text variable explaining why the record
*             is dirty.  Any other value will not output this file.
*   Report  = "Y" will do a freq tabulation on the dirty data by DirtyReason,
*             report misspecified variable lengths, and perform freq tables on
*             the clean data.
*             Any other value will suppress this calculation.
*
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:
*   Created October 13, 2006
**************************************************************************/

  /*Catch Errors*/
  %if &Clean ^= Y AND &Dirty ^= Y AND &Report ^= Y %then %do;
    %put ERROR: YOU MUST SPECIFY AT LEAST ONE TABLE TO OUTPUT OR TO PRODUCE;
    %put ERROR: A REPORT. SET <<CLEAN>>, <<DIRTY>>, AND/OR <<REPORT>> TO "Y";
  %end;
  %else %do;
    /*This mess is so that we save a little IO time depending on whether
      programmer wants the datasets saved.*/
    %if &Report ^= Y AND &Clean ^= Y %then %do;
      %let DataStatement = &OutLib..Dirty;
      %let DirtyReturn   = output &Outlib..dirty;
      %let CleanReturn   = ;
    %end;
    %else %if &Report ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &OutLib..Clean (drop=DirtyReason LastEnd);
      %let DirtyReturn = ;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty ^= Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason LastEnd) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output clean;
    %end;
    %else %if &Report = Y AND &Clean = Y AND &Dirty ^= Y %then %do;
      %let DataStatement = &Outlib..Clean (drop=DirtyReason LastEnd) Dirty;
      %let DirtyReturn = output dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;
    %else %if &Report = Y AND &Clean ^= Y AND &Dirty = Y %then %do;
      %let DataStatement = Clean (drop=DirtyReason LastEnd) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output clean;
    %end;
    %else %do; /*They want both clean and dirty, regardless of report*/
  %let DataStatement = &Outlib..Clean (drop=DirtyReason LastEnd) &Outlib..Dirty;
      %let DirtyReturn = output &Outlib..dirty;
      %let CleanReturn = output &Outlib..clean;
    %end;

    /*Clean the data*/
    libname __enroll "&_EnrollLib.";
    proc sort data=__enroll.&_EnrollData out=ToClean;
      by mrn enr_start;
    run;

    data &DataStatement;
      set ToClean;
      by mrn enr_start;
      length DirtyReason $40 LastEnd 4 DaysEnrolled 8;

      DaysEnrolled = Enr_End - Enr_Start + 1;
      
      if MISSING(MRN)=1 then do;
        DirtyReason = "Missing MRN";
        &DirtyReturn;
      end;
      else if MISSING(enr_start)=1 then do;
        DirtyReason = "Missing ENR_Start";
        &DirtyReturn;
      end;
      else if MISSING(enr_end)=1 then do;
        DirtyReason = "Missing ENR_End";
        &DirtyReturn;
      end;
      else if enr_end < enr_start then do;
        DirtyReason = "Enr_end is BEFORE enr_start";
        &DirtyReturn;
      end;
      else if first.MRN = 0 AND LastEND > enr_start then do;
        DirtyReason = "Enroll period overlaps with other obs";
        &DirtyReturn;
      end;
      else if INS_MEDICARE NOT IN("Y", "") then do;
        DirtyReason = "Invalid value for INS_MEDICARE";
        &DirtyReturn;
      end;
      else if INS_MEDICAID NOT IN("Y", "") then do;
        DirtyReason = "Invalid value for INS_MEDICAID";
        &DirtyReturn;
      end;
      else if INS_Commercial NOT IN("Y", "") then do;
        DirtyReason = "Invalid value for INS_COMMERCIAL";
        &DirtyReturn;
      end;
      else if INS_PRIVATEPAY NOT IN("Y", "") then do;
        DirtyReason = "Invalid value for INS_PRIVATEPAY";
        &DirtyReturn;
      end;
      else if INS_OTHER NOT IN("Y", "") then do;
        DirtyReason = "Invalid value for INS_OTHER";
        &DirtyReturn;
      end;
      else if DRUGCOV NOT IN("Y", "N", "") then do;
        DirtyReason = "Invalid value for DRUGCOV";
        &DirtyReturn;
      end;
      else do;
        &CleanReturn;
      end;
      LastEnd = enr_end;
      retain LastEnd;
    run;

    %if &Report = Y %then %do;
      proc format;
        value DEnrollf
          1           = "1 Day"
          2    - 27   = "2 to 27 days"
          28   - 31   = "28 to 31 days"
          32   - 93   = "32 to 93 days"
          94   - 186  = "94 to 186 days"
          187  - 363  = "187 to 363 days"
          364  - 366  = "364 to 366 days"          
          367  - 1096 = "367 to 1096 days (3 years)"
          1096 - high = "More than 1096 days"
          other       = "Other?!"
        ;
      run;
      proc freq data= %if(&Clean=Y) %then &Outlib..Clean; %else Clean;;
        title "Frequency Distributions of Obs That Are Clean";
        format Enr_Start MMYY. Enr_End MMYY. DaysEnrolled DEnrollf.;
        table Enr_Start Enr_End DaysEnrolled Ins_Medicare Ins_Medicaid 
              Ins_Commercial Ins_PrivatePay Ins_Other DRUGCOV;
      run;
      proc freq data= %if(&Dirty=Y) %then &Outlib..Dirty noprint;
                      %else Dirty noprint;;
        table DirtyReason / out=DirtyReport;
      run;
      proc contents data=__enroll.&_EnrollData. out=EnrollContents noprint; 
      run;
      
      data WrongLength (keep=vname YourLength SpecLength);
        set EnrollContents;
        length vname $32. YourLength 8 SpecLength 8;
        vname = upcase(compress(name));
        if vname='MRN' then do;
          call symput('TotalRecords', compress(nobs));
          return;
        end;
        else if vname="INS_MEDICARE" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else if vname="INS_MEDICAid" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else if vname="INS_COMMERCIAL" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else if vname="INS_PRIVATEPAY" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else if vname="INS_OTHER" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else if vname="DRUGCOV" AND length^=1 then do;
          YourLength=length;
          SpecLength=1;
          output;
        end;
        else return;
      run;
      
      *This should not error nor print if WrongLength is empty;
      proc print data=WrongLength;
        title "Table of Variables Having the Wrong Length";
      run;
      title "Frequency of Observations Not up to Specs by Reason";
      proc sql;
        select DirtyReason
             , COUNT as Frequency
             , COUNT/&TotalRecords. as PercentOfAllEnroll
             , Percent as PercentOfDirtyEnroll
        from DirtyReport
        ;
      quit;
    %end;
  %end;
%mend CleanEnroll;