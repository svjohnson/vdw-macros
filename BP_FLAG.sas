************************************************************************;
** Program: BP_FLAG.sas                                                 *;
**                                                                     *;
** Purpose: Create flags that can be used to determine quality of      *;
**          systolic and diastolic blood pressure fields.              *;
**          Cut-off recommendations reviewed by CVRN HTN Registry      *;
**          site PIs on 5/12/2010. This is meant to flag only those    *;
**          extreme values or situations where there is reason to      *;
**          suspect a data entry error, and further review may be      *;
**          warranted.                                                 *;
**                                                                     *;
**         Three variables are created:                                *;
**                                                                     *;
**         VARIABLE        VALUES                                      *;
**         ---------------------------------------------------------   *;
**         SYSTOLIC_QUAL   NULL, ABN_HIGH, ABN_LOW                     *;
**         DIASTOLIC_QUAL  NULL, ABN_HIGH                              *;
**         SYS_DIA_QUAL    SYSTOLIC <= DIASTOLIC, DIFFERENCE < 20,     *;
**                         DIFFERENCE > 100                            *;
**                                                                     *;
**         Note that NULL is only used when the other paired value for *;
**         the blood pressure is not null.                             *;
**                                                                     *;
** Author: Heather Tavel, KPCO                                         *;
**         Heather.M.Tavel@kp.org                                      *;
**                                                                     *;
** Revisions: Intial Creation 5/28/2010                                *;
**                                                                     *;
************************************************************************;
** Macro Parameters:                                                   *;
**                                                                     *;
** DSIN: Feed in fully qualified name, i.e. use libname and dataset    *;
**       name together if reading a permanent dataset. This macro      *;
**       program assumes that desired libraries have been defined      *;
**       previously in the program. StandardVars macro variables can   *;
**       be used.                                                      *;
**                                                                     *;
** DSOUT: Feed in fully qualified name, i.e. use libname and dataset   *;
**        name together if writing to a permanent dataset.             *;
**                                                                     *;
** KEEPVARS: Optional parameter indicating the values to keep in your  *;
**           quality checking dataset.  May be left blank to simply    *;
**           attach the three quality checking variables to an         *;
**           existing dataset.                                         *;
************************************************************************;
** Examples of use:                                                    *;
**                                                                     *;
** %bp_flag(dsin=&_vdw_vitalsigns,                                     *;
**          dsout=bp_qc,                                               *;
**          keepvars= mrn measure_date systolic diastolic)             *;
**                                                                     *;
** %bp_flag(dsin=cohort_vitals,                                        *;
**          dsout=cohort_vitals,                                       *;
**          keepvars=)                                                 *;
**                                                                     *;
** %bp_flag(dsin=&_vdw_vitalsigns,                                     *;
**          dsout=studylib.cohort_vitals,                              *;
**          keepvars=mrn measure_date systolic diastolic ht wt)        *;
**                                                                     *;
************************************************************************;
%macro bp_flag(dsin, dsout, keepvars);

data &dsout;
 set &dsin
     %if &keepvars ne %then %do; (keep=&keepvars)%end;
     ;

 ** Flag Systolic quality. Null values are suspect if diastolic exists ;

 if systolic gt 300          then SYSTOLIC_QUAL = 'ABN_HIGH';
  else if . < systolic < 50  then SYSTOLIC_QUAL = 'ABN_LOW';
  else if (systolic = . and
           diastolic ne .)   then SYSTOLIC_QUAL = 'NULL';

 ** Flag diastolic quality. Diastolic can go as low as 0, so there is no;
 ** lower limit.  Null values are OK in studies that may only care about;
 ** systolic.  This is just informative just in case it is needed.      ;
 ** DIA_ABN is set to 'NULL' only if a systolic value is entered on the ;
 ** same record.                                                        ;

 if diastolic gt 160          then DIASTOLIC_QUAL = 'ABN_HIGH';
  else if (systolic ne . and
           diastolic eq .)    then DIASTOLIC_QUAL = 'NULL';

 ** Now look at a comparative view between systolic and diastolic       ;
 ** systolic should always be greater than diastolic, and any difference;
 ** less than 20 or greater than 100 is suspect and should be reviewed  ;
 ** further.                                                            ;

 if systolic ne .
    and diastolic ne . then
    do;
	 if systolic < = diastolic
                            then SYS_DIA_QUAL = 'SYSTOLIC <= DIASTOLIC';
      else if systolic - diastolic < 20
                            then SYS_DIA_QUAL = 'DIFFERENCE < 20';
	  else if systolic-diastolic > 100
                            then SYS_DIA_QUAL = 'DIFFERENCE > 100';
	end;
run;

** Run a frequency on the results.  Can have more than one condition at ;
** a time;

proc freq data=&dsout;
 tables SYSTOLIC_QUAL
        DIASTOLIC_QUAL
        SYS_DIA_QUAL
        SYSTOLIC_QUAL*DIASTOLIC_QUAL
		SYSTOLIC_QUAL*SYS_DIA_QUAL
		DIASTOLIC_QUAL*SYS_DIA_QUAL/missing;
run;

%mend bp_flag;
