%macro charlson(inputds
              , IndexDateVarName
              , outputds
              , IndexVarName
              , inpatonly=I
              , malig=N
              );
/*********************************************

* Charlson comorbidity macro.sas
*
* Computes the Deyo version of the Charleson
*
*
*  Programmer
*     Hassan Fouayzi
*
*
* Input data required:
*
*     VDW Utilization files
*     Input SAS dataset INPUTDS
*        contains the variables MRN, STUDYID, and INDEXDT
*        INPATONLY flag - defauts to Inpatient only (I).  Valid values are
*                           I-inpatient or B-Both inpatient and outpatient
*                           or A-All encounter types
*        MALIG flag - Defaults to no(N).  If MALIG is yes (Y) then the weights
*                         of Metastasis and Malignancy are set to zero.
*                     This may be useful in a study of cancer.
* Outputs:
*     Dataset &outputsd with on record per studyid
*     Variables
*       MI= "Myocardial Infarction: "
*       CHD= "Congestive heart disease: "
*       PVD= "Peripheral vascular disorder: "
*       CVD= "Cerebrovascular disease: "
*       DEM= "Dementia: "
*       CPD= "Chronic pulmonary disease: "
*       RHD= "Rheumatologic disease: "
*       PUD= "Peptic ulcer disease: "
*       MLIVD= "Mild liver disease: "
*       DIAB= "Diabetes: "
*       DIABC= "Diabetes with chronic complications: "
*       PLEGIA= "Hemiplegia or paraplegia: "
*       REN= "Renal Disease: "
*       MALIGN= "Malignancy, including leukemia and lymphoma: "
*       SLIVD= "Moderate or severe liver disease: "
*       MST= "Metastatic solid tumor: "
*       AIDS= "AIDS: "
*       &IndexVarName= "Charlson score: "
*
*
* Dependencies:
*
*     StdVars.sas--the site-customized list of standard macro variables.
*     The DX and PROC files to which stdvars.sas refer
*
*
* Example of use:
*     %charlson(testing,oot, Charles, inpatonly=B)
*
* Notes:
*   You will often need to remove certain disease format categories for your
*   project. For instance, the Ovarian Ca EOL study removed Metastatic Solid
*   Tumor since all were in end stages. It would be inappopriate not to exclude
*   this category in this instance. Please use this macro wisely.
*
*   There are several places that need to be modified.
*     1.  Comment the diagnosis category in the format.
*     2.  Remove that diagnosis category in 2 arrays.
*     3.  Select the time period for the source data and a reference point.
*     4.  Data selection.  All diagnoses and procedures?  Inpt only?  The user
*         may want to remove certain types of data to make the sources from all
*         sites consistent.
*
* Version History
*
*     Written by Hassan Fouayzi starting with source from Rick Krajenta
*     Modified into a SAS Macro format           Gene Hart         2005/04/20
*     Malig flag implemented                     Gene Hart         2005/05/04
*     Add flag to mark thos with no visits       Gene Hart         2005/05/09
*     Add additional codes to disease            Tyler Ross        2006/03/31
*     Changed EncType for IP visits to new ut
*       specs and allowed all visit types option Tyler Ross       2006/09/15
*     Removed "456" from Moderate/Severe Liver   Hassan Fouayzi    2006/12/21
*
*     Should the coalesce function be on studyid or mrn?  1 MRN with 2 STUDYIDs
*       could happen
*
*     move then proc codes to a format
*
* Source publication
*     From: Fouayzi, Hassan [mailto:hfouayzi@meyersprimary.org]
*     Sent: Wednesday, May 04, 2005 9:07 AM
*     Subject: RE: VDW Charlson macro
...
*     “Deyo RA, Cherkin DC, Ciol MA. Adapting a clinical comorbidity Index for
*     use with ICD-9-CM administrative databases.
*       J Clin Epidemiol 1992; 45: 613-619”.
*     We added CPT codes and a couple of procedures for Peripheral
*       vascular disorder.
*
*********************************************/

/**********************************************/
/*Define and format diagnosis codes*/
/**********************************************/
PROC FORMAT;
   VALUE $ICD9CF
/* Myocardial infraction */
	"410   "-"410.92",
	"412   " = "MI"
/* Congestive heart disease */
	"428   "-"428.9 " = "CHD"
/* Peripheral vascular disorder */
	"440.20"-"440.24",
	"440.31"-"440.32",
	"440.8 ",
	"440.9 ",
	"443.9 ",
	"441   "-"441.9 ",
	"785.4 ",
	"V43.4 ",
	"v43.4 " = "PVD"
/* Cerebrovascular disease */
    "430   "-"438.9 " = "CVD"
/* Dementia */
	"290   "-"290.9 " = "DEM"
/* Chronic pulmonary disease */
	"490   "-"496   ",
	"500   "-"505   ",
	"506.4 " =  "CPD"
/* Rheumatologic disease */
	"710.0 ",
  "710.1 ",
 	"710.4 ",
  "714.0 "-"714.2 ",
  "714.81",
  "725   " = "RHD"
/* Peptic ulcer disease */
	"531   "-"534.91" = "PUD"
/* Mild liver disease */
	"571.2 ",
	"571.5 ",
	"571.6 ",
	"571.4 "-"571.49" = "MLIVD"
/* Diabetes */
	"250   "-"250.33",
	"250.7 "-"250.73" = "DIAB"
/* Diabetes with chronic complications */
	"250.4 "-"250.63" = "DIABC"
/* Hemiplegia or paraplegia */
	"344.1 ",
	"342   "-"342.92" = "PLEGIA"
/* Renal Disease */
	"582   "-"582.9 ",
	"583   "-"583.7 ",
	"585   "-"586   ",
	"588   "-"588.9 " = "REN"
/*Malignancy, including leukemia and lymphoma */
	"140   "-"172.9 ",
	"174   "-"195.8 ",
	"200   "-"208.91" = "MALIGN"
/* Moderate or severe liver disease */
	"572.2 "-"572.8 ",
	"456.0 "-"456.21" = "SLIVD"
/* Metastatic solid tumor */
	"196   "-"199.1 " = "MST"
/* AIDS */
	"042   "-"044.9 " = "AIDS"
/* Other */
   other   = "other"
;
run;

* For debugging. ;
%let sqlopts = feedback sortmsg stimer ;
%*let sqlopts = ;

******************************************************************************;
* subset to the utilization data of interest (add the people with no visits  *;
*    back at the end                                                         *;
******************************************************************************;
libname util "&_UtilizationLib." access = readonly ;

**********************************************;
* implement the Inpatient and Outpatient Flags;
********************************************** ;
%if &inpatonly =I %then %let inpatout= AND EncType in ('IP');
%else %if &inpatonly =B %then %let inpatout= AND EncType in ('IP','AV');
%else %if &inpatonly =A %then %let inpatout=;
%else %do;
  %Put ERROR in Inpatonly flag.;
  %Put Valid values are I for Inpatient and B for both Inpatient and Outpatient;
%end;

proc sql &sqlopts ;

   create table _ppl as
   select MRN, Min(&IndexDateVarName) as &IndexDateVarName format = mmddyy10.
   from &inputds
   group by MRN ;

   %let TotPeople = &SQLOBS ;

  alter table _ppl add primary key (MRN) ;

  create table  _DxSubset as
  select sample.mrn, &IndexDateVarName,adate, put(dx, $icd9cf.)as CodedDx
  from util.&_DxData as d, _ppl as sample
  where d.mrn = sample.mrn
        and adate between sample.&IndexDateVarName-1
                  and sample.&IndexDateVarName-365
            &inpatout.
  ;

   select count(distinct MRN) as DxPeople format = comma.
     label = "No. people having any Dxs w/in a year prior to &IndexDateVarName"
         , (CALCULATED DxPeople / &TotPeople) as PercentWithDx
            format = percent6.2 label = "Percent of total"
   from _DxSubset ;

  create table _PxSubset as
  select p.*
  from util.&_PxData as p, _ppl as sample
  where p.mrn = sample.mrn
        and adate between sample.&IndexDateVarName-1
                      and sample.&IndexDateVarName-365
        &inpatout.
  ;

   select count(distinct MRN) as PxPeople format = comma.
     label = "No. people who had any Pxs w/in a year prior to &IndexDateVarName"
         , (CALCULATED PxPeople / &TotPeople) as PercentWithPx
             format = percent6.2 label = "Percent of total sample"
   from _PxSubset ;

quit ;

proc sort data = _DxSubset ;
   by MRN ;
run ;

proc sort data = _PxSubset ;
   by MRN ;
run ;

/**********************************************/
/*** Assing DX based flagsts                ***/
/***                                        ***/
/***                                        ***/
/**********************************************/

%let var_list = MI CHD PVD CVD DEM CPD RHD PUD MLIVD DIAB
                DIABC PLEGIA REN MALIGN SLIVD MST AIDS ;

data _DxAssign ;
array COMORB (*) &var_list ;

length &var_list 3 ; *<-This is host-specific--are we sure we want to do this?;

retain           &var_list ;
keep   mrn  &var_list ;
set _DxSubset;
by mrn;
if first.mrn then do;
   do I=1 to dim(COMORB);
      COMORB(I) = 0 ;
   end;
end;
select (CodedDx);
   when ('MI')    MI     = 1;
   when ('CHD')   CHD    = 1;
   when ('PVD')   PVD    = 1;
   when ('CVD')   CVD    = 1;
   when ('DEM')   DEM    = 1;
   when ('CPD')   CPD    = 1;
   when ('RHD')   RHD    = 1;
   when ('PUD')   PUD    = 1;
   when ('MLIVD') MLIVD  = 1;
   when ('DIAB')  DIAB   = 1;
   when ('DIABC') DIABC  = 1;
   when ('PLEGIA')PLEGIA = 1;
   when ('REN')   REN    = 1;
   when ('MALIGN')MALIGN = 1;
   when ('SLIVD') SLIVD  = 1;
   when ('MST')   MST    = 1;
   when ('AIDS')  AIDS   = 1;
   otherwise ;
end;
if last.mrn then output;
run;

/** Procedures: Peripheral vascular disorder **/
data _PxAssign;
   set _PxSubset;
   by mrn;
   retain PVD ; * [RP] Added 5-jul-2007, at Hassan Fouyazis suggestion. ;
   keep mrn PVD;
   if first.mrn then PVD = 0;
   if    PX= "38.48" or
         PX ="93668" or
         PX in ("34201","34203","35454","35456","35459","35470") or
                "35355" <= PX <= "35381" or
         PX in ("35473","35474","35482","35483","35485","35492","35493",
                "35495","75962","75992") or
         PX in ("35521","35533","35541","35546","35548","35549","35551",
                "35556","35558","35563","35565","35566","35571","35582",
                "35583","35584","35585","35586","35587","35621","35623",
                "35641","35646","35647","35651","35654","35656","35661",
                "35663","35665","35666","35671")
         then PVD=1;
   if last.mrn then output;
run;

/** Connect DXs and PROCs together  **/
proc sql &sqlopts ;
  create table _DxPxAssign as
   select  coalesce(D.MRN, P.MRN) as MRN
         , D.MI
         , D.CHD
         , max(D.PVD, P.PVD) as PVD
         , D.CVD
         , D.DEM
         , D.CPD
         , D.RHD
         , D.PUD
         , D.MLIVD
         , D.DIAB
         , D.DIABC
         , D.PLEGIA
         , D.REN
         , D.MALIGN
         , D.SLIVD
         , D.MST
         , D.AIDS
   from  WORK._DXASSIGN as D full outer join
         WORK._PXASSIGN P
   on    D.MRN = P.MRN
   ;
quit ;

*****************************************************;
* Assign the weights and compute the index
*****************************************************;

Data _WithCharlson;
  set _DxPxAssign;
  M1=1;M2=1;M3=1;

* implement the MALIG flag;
   %if &malig =N %then %do; O1=1;O2=1; %end;
   %else %if &malig =Y %then  %do; O1=0; O2=0; %end;
   %else %do;
     %Put ERROR in MALIG flag.  Valid values are Y (Cancer study. Zero weight;
     %Put ERROR the cancer vars)  and N (treat cancer normally);
   %end;

  if SLIVD=1 then M1=0;
  if DIABC=1 then M2=0;
  if MST=1 then M3=0;

&IndexVarName =   MI + CHD + PVD + CVD + DEM + CPD + RHD +
                  PUD + M1*MLIVD + M2*DIAB + 2*DIABC + 2*PLEGIA + 2*REN +
                  O1*2*M3*MALIGN + 3*SLIVD + O2*6*MST + 6*AIDS;

Label
MI= "Myocardial Infarction: "
CHD= "Congestive heart disease: "
PVD= "Peripheral vascular disorder: "
CVD= "Cerebrovascular disease: "
DEM= "Dementia: "
CPD= "Chronic pulmonary disease: "
RHD= "Rheumatologic disease: "
PUD= "Peptic ulcer disease: "
MLIVD= "Mild liver disease: "
DIAB= "Diabetes: "
DIABC= "Diabetes with chronic complications: "
PLEGIA= "Hemiplegia or paraplegia: "
REN= "Renal Disease: "
MALIGN= "Malignancy, including leukemia and lymphoma: "
SLIVD= "Moderate or severe liver disease: "
MST= "Metastatic solid tumor: "
AIDS= "AIDS: "
&IndexVarName= "Charlson score: "
;

keep MRN &var_list &IndexVarName ;

run;

/* add the people with no visits back in, and create the final dataset */
/* people with no visits or no comorbidity DXs have all vars set to zero */

proc sql &sqlopts ;
  create table &outputds as
  select distinct i.MRN
      , i.&IndexDateVarName
      , coalesce(w.MI           , 0) as  MI
                   label = "Myocardial Infarction: "
      , coalesce(w.CHD          , 0) as  CHD
                   label = "Congestive heart disease: "
      , coalesce(w.PVD          , 0) as  PVD
                   label = "Peripheral vascular disorder: "
      , coalesce(w.CVD          , 0) as  CVD
                   label = "Cerebrovascular disease: "
      , coalesce(w.DEM          , 0) as  DEM
                   label = "Dementia: "
      , coalesce(w.CPD          , 0) as  CPD
                   label = "Chronic pulmonary disease: "
      , coalesce(w.RHD          , 0) as  RHD
                   label = "Rheumatologic disease: "
      , coalesce(w.PUD          , 0) as  PUD
                   label = "Peptic ulcer disease: "
      , coalesce(w.MLIVD        , 0) as  MLIVD
                   label = "Mild liver disease: "
      , coalesce(w.DIAB         , 0) as  DIAB
                   label = "Diabetes: "
      , coalesce(w.DIABC        , 0) as  DIABC
                   label = "Diabetes with chronic complications: "
      , coalesce(w.PLEGIA       , 0) as  PLEGIA
                   label = "Hemiplegia or paraplegia: "
      , coalesce(w.REN          , 0) as  REN
                   label = "Renal Disease: "
      , coalesce(w.MALIGN       , 0) as  MALIGN
                   label = "Malignancy, including leukemia and lymphoma: "
      , coalesce(w.SLIVD        , 0) as  SLIVD
                   label = "Moderate or severe liver disease: "
      , coalesce(w.MST          , 0) as  MST
                   label = "Metastatic solid tumor: "
      , coalesce(w.AIDS         , 0) as  AIDS
                   label = "AIDS: "
      , coalesce(w.&IndexVarName, 0) as  &IndexVarName
                   label = "Charlson score: "
      , (w.MRN is null)              as  NoVisitFlag
                   label = "No visits for this person"
  from _ppl as i left join _WithCharlson as w
  on i.MRN = w.MRN
  ;

/* clean up work sas datasets */
proc datasets nolist ;
 delete _DxSubset
        _PxSubset
        _DxAssign
        _PxAssign
        _DxPxAssign
        _WithCharlson
        _NoVisit
        _ppl
        ;
%mend charlson;