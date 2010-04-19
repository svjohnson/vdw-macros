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

* OLD VARIABLES ;
  * libname locations specs ;
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

  * dataset name specs ;
  %let _TumorData               = tumor ;
  %let _EnrollData              = enroll2 ;
  %let _DemographicData         = demog ;
  %let _RxData                  = rx ;
  %let _EverNdcData             = EverNDC_1998_2007 ;
  %let _UtilizationData         = utilization ;
  %let _DeathData               = death ;
  %let _CODData                 = cod ;
  %let _DxData                  = dx ;
  %let _PxData                  = px ;
  %let _ProviderSpecialtyData   = specfile ;
  %let _VitalData               = vitalsigns ;
  %let _CensusData              = census2000 ;
  %let _LabData                 = lab_results ;
  %let _LabDataCharacter        = lab_results_character ;

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
  %let _SiteAbbr = GH ;
  %let _SiteName = Group Health ;

* NEW VARIABLES ;

  * Making this intentionally wacky so as to keep from colliding w/names likely to be chosen in application programs. ;
  libname __vdw "&_TumorLib" access = readonly ;

  %let _vdw_tumor               = __vdw.&_TumorData ;
  %let _vdw_enroll              = __vdw.&_EnrollData ;
  %let _vdw_demographic         = __vdw.&_DemographicData ;
  %let _vdw_rx                  = __vdw.&_RxData ;
  %let _vdw_everndc             = __vdw.&_EverNdcData ;
  %let _vdw_utilization         = __vdw.&_UtilizationData ;
  %let _vdw_death               = __vdw.&_DeathData ;
  %let _vdw_cause_of_death      = __vdw.&_CODData ;
  %let _vdw_dx                  = __vdw.&_DxData ;
  %let _vdw_px                  = __vdw.&_PxData ;
  %let _vdw_provider_specialty  = __vdw.&_ProviderSpecialtyData ;
  %let _vdw_vitalsigns          = __vdw.&_VitalData ;
  %let _vdw_census              = __vdw.&_CensusData ;
  %let _vdw_lab                 = __vdw.&_LabData ;
  %let _vdw_lab_character       = __vdw.&_LabDataCharacter ;


* NEW REFERENCE TO THE STANDARD MACROS FILE ;
  filename vdw_macs  FTP     "standard_macros.sas"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/vdwcode"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader" ;

