%macro CleanEnroll(OutLib, Clean=N, Dirty=N, Report=Y, EnrollDset = &_vdw_enroll);
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
* Modified by:
*   David Tabano
*   Institute for Health Research, Kaiser Permanente Colorado
*   (303)614-1348
*   david.c.tabano@kp.org
*
* History:
*   Created October 13, 2006
*   Modified August 23, 2011
**************************************************************************/

  /*Catch Errors*/
  %if &Clean ^= Y AND &Dirty ^= Y AND &Report ^= Y %then %do;
    %put ERROR: YOU MUST SPECIFY AT LEAST ONE TABLE TO OUTPUT OR TO PRODUCE;
    %put ERROR: A REPORT. SET <<CLEAN>>, <<DIRTY>>, AND/OR <<REPORT>> TO "Y";
  %end;
  %else %do;
    /*This mess is so that we save a little IO time depending on whether
      programmer wants the datasets saved.*/
    %local DataStatement ;
    %local DirtyReturn ;
    %local CleanReturn ;
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


    %** helper macro ;
    %macro checkflag(var, flag_vals = %str('Y', 'N', 'U')) ;
      else if &var NOT IN(&flag_vals) then do;
        DirtyReason = "Invalid value for &var";
        &DirtyReturn;
      end;
    %mend checkflag ;

    /*Clean the data*/

    proc sort data=&_vdw_enroll out=ToClean;
      by mrn enr_start;
    run;

    data &DataStatement;
      set &_vdw_enroll end = last ;
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

      %checkflag(var = ins_medicare)
      %checkflag(var = ins_medicare_a)
      %checkflag(var = ins_medicare_b)
      %checkflag(var = ins_medicare_c)
      %checkflag(var = ins_medicare_d)
      %checkflag(var = ins_medicaid)
      %checkflag(var = ins_commercial)
      %checkflag(var = ins_privatepay)
      %checkflag(var = ins_selffunded)
      %checkflag(var = ins_statesubsidized)
      %checkflag(var = ins_highdeductible)
      %checkflag(var = ins_other)

      %checkflag(var = enrollment_basis, flag_vals = %str('G', 'I', 'B'))

      %checkflag(var = plan_hmo)
      %checkflag(var = plan_ppo)
      %checkflag(var = plan_pos)
      %checkflag(var = plan_indemnity)

      %checkflag(var = outside_utilization)

      %checkflag(var = drugcov)
      else do;
        &CleanReturn;
      end;
      LastEnd = enr_end;
      retain LastEnd;
      ** Putting this here b/c proc contents spits out a missing for obs when run against a view. ;
      if last then do ;
        call symput('TotalRecords', put(_n_, best.)) ;
      end ;
      format LastEnd mmddyy10. ;
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
      proc contents data=&_vdw_enroll out=EnrollContents noprint;
      run;

      data WrongLength (keep=vname YourLength SpecLength);
        set EnrollContents;
        length vname $32. YourLength 8 SpecLength 8;

        vname = upcase(compress(name));

        select (vname) ;
          when ('MRN') do ;
            ** Doing this is the dsetp above b/c the below does not work if _vdw_enroll points to a view. ;
            ** call symput('TotalRecords', put(nobs, best.));
            return;
          end ;
          when ('INS_MEDICARE'
                , 'INS_MEDICAID'
                , 'INS_COMMERCIAL'
                , 'INS_PRIVATEPAY'
                , 'INS_OTHER'
                , 'DRUGCOV'
                , "INS_STATESUBSIDIZED"
                , "INS_SELFFUNDED"
                , "INS_HIGHDEDUCTIBLE"
                , "INS_MEDICARE_A"
                , "INS_MEDICARE_B"
                , "INS_MEDICARE_C"
                , "INS_MEDICARE_D"
                , "PLAN_HMO"
                , "PLAN_POS"
                , "PLAN_PPO"
                , "PLAN_INDEMNITY"
                , "OUTSIDE_UTILIZATION"
                , "ENROLLMENT_BASIS"
                ) do ;
            YourLength = length ;
            SpecLength = 1 ;
          end ;
          ** Dropping the PCC PCP length checks b/c the spec allows those to vary. ;
          otherwise do ;
            ** put "Got " vname= "--doing nothing." ;
          end ;
        end ;
        if YourLength ne SpecLength then output ;
      run ;

      **This should not error nor print if WrongLength is empty;
      proc print data=WrongLength;
        title "Table of Variables Having the Wrong Length";
      run;
      title "Frequency of Observations Not up to Specs by Reason";
      proc sql;

        select DirtyReason
             , COUNT as Frequency
             , (COUNT / &TotalRecords ) * 100 as PercentOfAllEnroll
             , Percent as PercentOfDirtyEnroll
          from DirtyReport
        ;
      quit;
    %end;
  %end;
%mend CleanEnroll;