/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* CDS.sas
*
* Computes several versions of the Clark chronic disease score.
*
* Based on Parker Pettus' cdscore.sas program.
*
*********************************************/

/* This is managed in the login script so that it doesnt
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
libname dm "&_DemographicLib" ;
libname rx "&_RxLib" ;

* Should this go in the macro lib? ;
%macro CalcAge(BDtVar, RefDate) ;
   intck('YEAR', &BDtVar, &RefDate) -
   (mdy(month(&RefDate), day(&RefDate), 2004) <
    mdy(month(&BDtVar) , day(&BDtVar) , 2004))
%mend CalcAge ;

%macro CalcCDS(People, DateVar, NDCFlags, Model, Outset) ;

   * This is funky format notation--never seen this before Parkers program. ;
   proc format ;
      value agegrp  18-<25 = '1'
                    25-<35 = '2'
                    35-<45 = '3'
                    45-<55 = '4'
                    55-<65 = '5'
                    65-<75 = '6'
                    75-<85 = '7'
                   85-high = '8'
      ;
   run ;

   proc sql ;

      * Get age/sex, and chuck the under-18 crowd. ;
      create table ppl as
      select p.*
            , upcase(d.gender) || put(%CalcAge(BDtVar = birth_date, RefDate = &DateVar), agegrp.) as GenderAge
      from  &People as p INNER JOIN
            dm.&_DemographicData as d
      on    p.MRN = d.MRN
      where %CalcAge(BDtVar = birth_date, RefDate = &DateVar) ge 18 ;

      * People get a certain base CDS score just on the basis of their age and sex--bring those in. ;
      create table ppl as
      select p.*
            , cm.ClarkTotCost
            , cm.ClarkOutPtCost
            , cm.ClarkPrmCrVis
      from  ppl as p INNER JOIN
            &Model as cm
      on    p.GenderAge = cm.CDSCat ;

      select * from ppl ;

      * And those intercepts are deviations about a grand intercept--add that in ;
      create table ppl as
      select p.MRN
            , p.GenderAge
            , p.&DateVar
            , sum(p.ClarkTotCost, cm.ClarkTotCost)       as ClarkTotCost
            , sum(p.ClarkOutPtCost, cm.ClarkOutPtCost)   as ClarkOutPtCost
            , sum(p.ClarkPrmCrVis, cm.ClarkPrmCrVis)     as ClarkPrmCrVis
      from  ppl as p CROSS JOIN
            &Model as cm
      where cm.CDSCat = 'XX' ;

      select * from ppl ;

      * Gather fills for each person in People for the six months ending on &DateVar ;
      create table fills as
      select p.MRN
            , r.NDC
      from rx.&_RxData as r INNER JOIN
            ppl as p
      on    r.MRN = p.MRN
      where rx.RxDate between (p.&DateVar - 180) and p.&DateVar ;

      * Translate from NDCs to CDS categories.  This is a select distinct  ;
      * b/c multiple fills that set the same flag are only counted once. ;
      create table PersonFlags as
      select distinct
            f.MRN
            , u.CDSCat
      from fills as f LEFT JOIN
            &NDCFlags as u
      on    f.NDC = u.NDC
      where u.CDSCat is not null ;

      drop table fills ;

      * If a person has both an A7 flag (Cardiac Disease) and an A15 (Heart Disease ;
      * /Hypertension) we need to discount the A15 ;
      delete from PersonFlags
      where CDSCat = 'A15' AND
            MRN in (select MRN from PersonFlags where CDSCat = 'A7') ;

      * Now bring in the CDS scores applicable to each flag & sum over person. ;
      create table PersonFlags as
      select p.MRN
            , sum(cm.ClarkTotCost  ) as ClarkTotCost
            , sum(cm.ClarkOutPtCost) as ClarkOutPtCost
            , sum(cm.ClarkPrmCrVis ) as ClarkPrmCrVis
      from  PersonFlags as p INNER JOIN
            &Model as cm
      on    p.CDSCat = cm.CDSCat
      group by p.MRN
      ;

      * Now we add the PersonFlag values to the Gender/Age scores and we are done! ;
      create table &Outset as
      select p.MRN
            , p.GenderAge
            , p.&DateVar
            , sum(p.ClarkTotCost,   pf.ClarkTotCost)     as ClarkTotCost
            , sum(p.ClarkOutPtCost, pf.ClarkOutPtCost)   as ClarkOutPtCost
            , sum(p.ClarkPrmCrVis,  pf.ClarkPrmCrVis)    as ClarkPrmCrVis
      from  ppl as p LEFT JOIN
            PersonFlags as pf
      on    p.MRN = pf.MRN ;

   quit ;
%mend CalcCDS ;

%macro TestCalcCDS ;
   libname cds "\\groups\data\CTRHS\Crn\S D R C\VDW\Parker\cds" ;
   libname scratch "\\ctrhs-dbserver\warehouse\Sasdata\CRN_VDW\scratch" ;
   * This is the location of the UNIFORM file--the dset of NDCs and the flags they set ;
   libname un "\\groups\data\CTRHS\Crn\S D R C\VDW\Parker" ;

   /*
   proc sql ;
      reset outobs = 50 nowarn ;
      * Group enrolled for first 6 months of 2004. ;
      create table scratch.ppl as
      select mrn
      from vdw.enroll
      where enr_year = 2004 AND
            enr_month between 1 and 6
      group by mrn
      having count(*) = 6 ;
   quit ;

   */

   data ppl ;
      set scratch.ppl ;
      CDSDate = "30Jun2004"d ;
      format CDSDate mmddyy10. ;
   run ;

   proc sql noexec ;
      create table ppl as
      select p.*
            , birth_date format = mmddyy10.
            , gender
            , %CalcAge(BDtVar = birth_date, RefDate = CDSDate) as Age
            , put(calculated age, agegrp.) as FmtAge
            /* , upcase(d.gender) || put(%CalcAge(BDtVar = birth_date, RefDate = &DateVar), agegrp.) as GenderAge */
      from  ppl as p INNER JOIN
            dm.&_DemographicData as d
      on    p.MRN = d.MRN
      where %CalcAge(BDtVar = birth_date, RefDate = CDSDate) ge 18 ;
   quit ;

   options mprint ;

   %CalcCDS(People = ppl
         , DateVar = CDSDate
         , NDCFlags = un.uniform
         , Model = cds.cdsmodels
         , Outset = scratch.test_cds) ;
   run ;

%mend TestCalcCDS ;

%TestCalcCDS ;

endsas ;