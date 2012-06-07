/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\ctrhs\chs\pardre1\GetSmokers.sas
*
* Identifies smokers from the VDW vital signs and diagnosis data.
*********************************************/

%macro GetSmokers(StartDt =
                  , EndDt =
                  , OutSet = smokers
                 ) ;

  proc sql noprint ;

    ** Find smokers.  First we look at vital signs. ;
    %let current_user = 1 ;
    %let cigarrettes = 1, 3 ;
    %let quit_status = 3 ;

    ** First we grab all people w/smoker-indication out of vital signs. ;
    create table vs_probable_smokers as
    select  mrn, max(measure_date) as last_date
    from    &_vdw_vitalsigns
    where   tobacco = &current_user and tobacco_type in (&cigarrettes) and
            measure_date between "&StartDt"d and "&EndDt"d
    group by mrn
    ;

    ** Now we grab out ppl w/a dx code of tobacco use disorder ;
    %let tobacco_use_disorder = "305.1" ;
    create table dx_smokers as
    select  mrn, max(adate) as last_date
    from    &_vdw_dx
    where   dx = &tobacco_use_disorder AND
            adate  between "&StartDt"d and "&EndDt"d
    group by mrn
    ;

    ** Combine. ;
    create table probable_smokers as
    select  mrn, max(last_date) as last_date
    from  (select mrn, last_date from vs_probable_smokers UNION ALL
           select mrn, last_date from dx_smokers)
    group by mrn
    ;

    drop table vs_probable_smokers ;
    drop table dx_smokers ;

    ** Now we remove any subsequent-quitters and output. ;
    create table &outset(label = "Probable cigarrette smokers, as determined by VDW encounter data between &StartDt and &EndDt..") as
    select  s.mrn, last_date as date_assessed format = mmddyy10. label = "Date on which the person's status as a cigarrette smoker was assessed."
    from    probable_smokers as s LEFT JOIN
            &_vdw_vitalsigns as v
    on      s.mrn = v.mrn AND
            s.last_date le v.measure_date AND
            v.tobacco = &quit_status
    where   v.mrn IS NULL
    ;

    drop table probable_smokers ;

  quit ;

%mend GetSmokers ;