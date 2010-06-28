************************************************************************;
** Program: BMI_adult_macro.sas                                        *;
**                                                                     *;
** Purpose: Calculate BMI for adults and include a flag for reason     *;
**          that a BMI was not calculated. This flag can have values   *;
**          of:  MISSING AGE                                           *;
**               UNDER AGE 18                                          *;
**               NO WT                                                 *;
**               NO HT                                                 *;
**               NO HT OR WT                                           *;
**               WT OUT OF RANGE                                       *;
**               BMI OUT OF RANGE                                      *;
**                                                                     *;
**          The BMI algorithm and cut-off recommendations were         *;
**          reviewed by the Obesity special interest group.            *;
**          This is meant to flag only those extreme values or         *;
**          situations where there is reason to suspect a data entry   *;
**          error, and further review may be warranted.                *;
**                                                                     *;
**          The macro assumes that the program is placed into the      *;
**          middle of a program. It assumes that libnames have been    *;
**          defined prior to the macro call, and indicates that the    *;
**          macro parameters have be fully qualified dataset names.    *;
**                                                                     *;
**                                                                     *;
**         Three variables are created:                                *;
**                                                                     *;
**         VARIABLE       DECRIPTION                  FORMAT           *;
**         ---------------------------------------------------------   *;
**         BMI            BMI FOR ADULTS              Numeric          *;
**         HT_MEDIAN      MEDIAN HT FOR ADULTS        Numeric          *;
**         BMI_flag       BMI QC FLAG                 $16.             *;
**                                                                     *;
** Author: G. Craig Wood, Geisinger Health System                      *;
**         cwood@geisinger.edu                                         *;
**                                                                     *;
** Revisions: Intial Creation 6/7/2010                                 *;
**                                                                     *;
************************************************************************;
** Macro Parameters:                                                   *;
**                                                                     *;
** VITALS_IN: These needs to have the following variables:             *;
**        MRN, HT, WT, and measure_date.                               *;
**        Feed in fully qualified name, i.e. use libname and           *;
**        dataset name together if reading a permanent dataset.        *;
**        This macro program assumes that desired libraries have been  *;
**        defined previously in the program. StandardVars macro        *;
**        variables can be used.                                       *;
**                                                                     *;
** DEMO_IN: These needs to have the following variables:               *;
**        MRN, birth_date.                                             *;
**        Feed in fully qualified name, i.e. use libname and           *;
**        dataset name together if reading a permanent dataset.        *;
**        This macro program assumes that desired libraries have been  *;
**        defined previously in the program. StandardVars macro        *;
**        variables can be used.                                       *;
**                                                                     *;
** VITALS_OUT: Feed in fully qualified name, i.e. use libname and      *;
**        dataset name together if writing to a permanent dataset.     *;
**                                                                     *;
** KEEPVARS: Optional parameter indicating the values to keep in your  *;
**           quality checking dataset.  May be left blank to simply    *;
**           attach the two new variables to an existing dataset.      *;
************************************************************************;
** Examples of use:                                                    *;
**                                                                     *;
** %bp_flag(vitals_in=&_vdw_vitalsigns,                                *;
**          demo_in=&_vdw_demographic,                                 *;
**          vitals_out=BMI_qc,                                         *;
**          keepvars= mrn measure_date BMI BMIFLAG)                    *;
**                                                                     *;
** %bp_flag(vitals_in=cohort_vitals,                                   *;
**          demo_in=cohort_demo,                                       *;
**          vitals_out=BMI_qc,                                         *;
**          keepvars= mrn measure_date BMI BMIFLAG ht wt)              *;
**                                                                     *;
** %bp_flag(vitals_in=cohort_vitals,                                   *;
**          demo_in=&_vdw_demographic,                                 *;
**          vitals_out=lib_out.BMI_qc,                                 *;
**          keepvars= )                                                *;
**                                                                     *;
************************************************************************;


%MACRO BMI_adult_macro(vitals_in, demo_in, vitals_out, keepvars);


PROC SQL;
CREATE TABLE one AS SELECT A.*, B.birth_date, ((measure_date-birth_date)/365.25)AS AGE FROM &vitals_in A LEFT OUTER JOIN &demo_in  B
ON A.MRN = B.MRN;
QUIT;

proc means noprint nway data=one; class mrn; var ht; WHERE (ht>=48 AND ht<=84) AND AGE>=18; output out=outHT (drop=_type_ _freq_) median=HT_median; run;
proc sort; by mrn; run;

data &vitals_out; merge one outht; by mrn;
        %if &keepvars ne %then %do; keep &keepvars; %end;

        format BMIflag $16.;

        if age = . THEN BMIflag = 'MISSING AGE';
        if age<18 AND age NE . then BMIflag='UNDER AGE 18';
        if age<18 then HT_median=.;
        if BMIflag=' ' and HT_median=. and wt=. then BMIflag='NO HT OR WT';
        if BMIflag=' ' and HT_median=. then BMIflag='NO HT';
        if BMIflag=' ' and wt=. then BMIflag='NO WT';
        if BMIflag=' ' and wt ne . and (wt<50 or wt>700) then BMIflag='WT OUT OF RANGE';

        if BMIflag=' ' then BMI=round((703*wt/(HT_median*HT_median)),0.01);
        if BMIflag=' ' and BMI ne . and (BMI<15 or BMI>90) then do;
                BMIflag='BMI OUT OF RANGE';
                BMI=.;
                end;
        drop age birth_date;
        run;


PROC DATASETS NOLIST; DELETE one outht; QUIT;

%MEND BMI_adult_macro;

/*
  GetAdultBMI

  A little wrapper macro that lets users supply a cohort dset & an optional time period, for whom/over which they
  would like BMI data (as calculated by the vital signs WGs official code).

  Author: Roy Pardee
*/
%macro GetAdultBMI(people = , outset = , StartDt = "01jan1960"d, EndDt = "&sysdate"d) ;
  proc sql ;
    create table __in_demog as
    select distinct p.mrn, birth_date
    from  &people as p INNER JOIN
          &_vdw_demographic as d
    on    p.mrn = d.mrn
    ;
  quit ;

  proc sql ;
    create table __in_vitals as
    select v.*
    from  &_vdw_vitalsigns as v INNER JOIN
          &people as p
    on    v.mrn = p.mrn
    where v.measure_date between &StartDt and &EndDt
    ;
  quit ;

  %BMI_adult_macro(vitals_in = __in_vitals, demo_in = __in_demog, vitals_out = &outset) ;

%mend GetAdultBMI ;
