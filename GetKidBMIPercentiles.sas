%macro GetKidBMIPercentiles(Inset  /* Dset of MRNs on whom you want kid BMI recs */
                        , OutSet
                        , StartDt = 01jan1960
                        , EndDt = &sysdate9
                        ) ;


   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro GetKidBMIPercentiles: ;
   %put ;
   %put Creating a dataset "&OutSet", which will contain all BMI measures  ;
   %put on record for the people whose MRNs are contained in "&InSet" which ;
   %put were taken while the people were between the ages of 2 and 17 and ;
   %put taken between "&StartDt" and "&EndDt". ;
   %put  ;
   %put The output dataset will contain a variable calculated by the CDCs ;
   %put normative sample percentile score program found here: ;
   %put http://www.cdc.gov/nccdphp/dnpao/growthcharts/resources/sas.htm ;
   %put ;
   %put From this variable (called BMIPCT) you can categorize the children ;
   %put into normal/overweight/obese brackets with the following format: ;
   %put  ;
   %put proc format ;                                                ;
   %put    value bmipct                                              ;
   %put       low -< 5    = 'Underweight < 5th percentile'           ;
   %put       5   -< 85   = 'Normal weight 5th to 84.9th percentile' ;
   %put       85  -< 95   = 'Overweight 85th to 94.9th percentile'   ;
   %put       95  -  high = 'Obese >=95th percentile'                ;
   %put    ;                                                         ;
   %put quit ;                                                       ;
   %put                                                             ;
   %put ============================================================== ;
   %put ;
   %put ;





   proc sql ;
      ** Gather the demog data for our input dset. ;
      create table __demog as
      select i.mrn
            , case d.gender when 'M' then 1 when 'F' then 2 else . end as sex label = '1 = Male; 2 = Female'
            , d.birth_date
      from  &InSet as i LEFT JOIN
           &_vdw_demographic as d
      on    i.mrn = d.mrn
      ;

      ** Now gather any ht/wt measures that occurred prior to the 18th birthday. ;
      create table _indata as
      select d.mrn
            , d.sex
            , d.birth_date
            , measure_date
            , ht*2.54         as height label = 'Height in centimeters'
            , wt*0.45359237   as weight label = 'Weight in kilograms'
            , bmi             as original_bmi label = 'BMI as originally calculated'
            , ((measure_date - birth_date)/365.25 * 12) as agemos label = 'Age at measure in months'
            , days_diff
            , %CalcAge(bdtvar = birth_date, refdate = measure_date) as age_at_measure
            , . as recumbnt   label = 'Recumbent flag (not implemented in VDW)'
            , . as headcir    label = 'Head circumference (not implemented in VDW)'
      from  __demog as d INNER JOIN
            &_vdw_vitalsigns as v
      on    d.mrn = v.mrn
      where calculated age_at_measure between 2 and 17 AND
            ht IS NOT NULL AND
            wt IS NOT NULL AND
            days_diff = 0 AND
            measure_date between "&StartDt"d and "&EndDt"d
      ;
   quit ;

   ** ROY--REMOVE THIS!! ;
   data s.sample_bmipct_inset ;
      set _indata ;
   run ;


   ** ROY--CHANGE THIS BACK TO PULLING FROM THE FTP SERVER!!! ;
  filename kid_bmi   FTP     "gc-calculate-BIV.sas"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/vdwcode"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader" ;


   ** filename kid_bmi "\\groups\data\CTRHS\Crn\S D R C\VDW\VitalSigns\gc-calculate-BIV.sas" ;

   data _indata ;
      set _indata ;

   %include kid_bmi ;

   run ;

   data &OutSet ;
      set _indata ;

      label
         HTPCT    = 'percentile for length-for-age or stature-for-age'
         HAZ      = 'z-score for length-for-age or stature-for-age'
         WTPCT    = 'percentile for weight-for-age'
         WAZ      = 'z-score for weight-for-age'
         WHPCT    = 'percentile for weight-for-length or weight-for-stature'
         WHZ      = 'z-score for weight-for-length or weight-for-stature'
         BMIPCT   = 'percentile for body mass index-for-age'
         BMIZ     = 'z-score for body mass index-for-age'
         BMI      = 'calculated body mass index value [weight(kg)/height(m)2 ]'
         HCPCT    = 'percentile for head circumference-for-age'
         HCZ      = 'z-score for head circumference-for-age'
         _BIVHT   = 'outlier variable for height-for-age (0 – acceptable normal range; 1 – too low; 2 – too high)'
         _BIVWT   = 'outlier variable for weight-for-age (0 – acceptable normal range; 1 – too low; 2 – too high)'
         _BIVWHT  = 'outlier variable for weight-for-height (0 – acceptable normal range; 1 – too low; 2 – too high)'
         _BIVBMI  = 'outlier variable for body mass index-for-age (0 – acceptable normal range; 1 – too low; 2 – too high)'
      ;
      %* Note--these are dropped only b/c I dont know what they are--could not find ;
      %* documentation on them on the CDC website. ;
      drop
         _SDLGZLO
         _SDLGZHI
         _FLAGLG
         _SDSTZLO
         _SDSTZHI
         _FLAGST
         _SDWAZLO
         _SDWAZHI
         _FLAGWT
         _SDBMILO
         _SDBMIHI
         _FLAGBMI
         _SDHCZLO
         _SDHCZHI
         _FLAGHC
         _BIVHC
         _FLAGWLG
         _FLAGWST
      ;

   run ;

%mend GetKidBMIPercentiles ;
