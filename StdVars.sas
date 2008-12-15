/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* StdVars.sas
*
* A site-modified program that specifies a set of standard macro variables
* for things that vary by site (e.g., libname definitions) and yet should be
* relatively static.  The intent here is to minimize the amount of site-programmer
* editing required for new programs that use the VDW.
*
*********************************************/

* Dataset locations and names ;
%let _TumorLib                = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _EnrollLib               = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _DemographicLib          = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _RxLib                   = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _UtilizationLib          = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _RxRiskLib               = \\ctrhs-sas\warehouse\sasdata\rxrisk  ;
%let _VitalLib                = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _CensusLib               = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _LabLib                  = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
%let _Deathlib                = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;

%let _TumorData               = tumor ;
%let _EnrollData              = enroll2 ;
%let _DemographicData         = demog ;
%let _RxData                  = rx ;
%let _EverNdcData             = everndc ;
%let _UtilizationData         = utilization ;
%let _DeathData               = death ;
%let _CODData                 = cod ;
* Testing going after the base table named in the diag view--now that it has been "realized". ;
%*let _DxData                  = diag ;
%let _DxData                  = dx ;
%let _PxData                  = px ;
%let _ProviderSpecialtyData   = specfile ;
%let _VitalData               = vitalsigns ;
%let _CensusData              = census2000 ;
%let _LabData                 = lab_results ;

* Site names ;
%let _SiteName = Group Health ;
%let _SiteAbbr = GHC ;


/*
   Site code--pls use the following:
   01 = GHC
   02 = KPNW
   03 = KPNC
   04 = KPSC
   05 = KPHI
   06 = KPCO
   07 = HP	 (HealthPartners)
   08 = HPHC (Harvard Pilgrim Health Care)
   09 = FALLON
   10 = HFHS (Henry Ford)
   11 = KPG
   12 = LSHS (Lovelace)
   13 = MCRF (Marshfield)
   14 = GHS  (Geisinger)
*/

%let _SiteCode = 01 ;

* Making this intentionally wacky so as to keep from colliding w/names likely to be chosen in application programs. ;
libname __vdw '\\ctrhs-sas\warehouse\Sasdata\CRN_VDW' access = readonly ;

%let _TumorDset               = __vdw.tumor ;
%let _EnrollDset              = __vdw.enroll2 ;
%let _DemographicDset         = __vdw.demog ;
%let _RxDset                  = __vdw.rx ;
%let _EverNdcDset             = __vdw.everndc ;
%let _UtilizationDset         = __vdw.utilization ;
%let _DeathDset               = __vdw.death ;
%let _CODDset                 = __vdw.cod ;
%let _DxDset                  = __vdw.dx ;
%let _PxDset                  = __vdw.px ;
%let _ProviderSpecialtyDset   = __vdw.specfile ;
%let _VitalDset               = __vdw.vitalsigns ;
%let _CensusDset              = __vdw.census2000 ;
%let _LabDset                 = __vdw.lab_results ;
