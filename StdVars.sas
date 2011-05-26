/*********************************************
* Roy Pardee
* Group Health Research Institute
* (360) 447-8773
* pardee.r@ghc.org
*
* StdVars.sas
*
* A site-modified program that specifies a set of standard macro variables
* for things that vary by site (e.g., libname.dataset specifications) and yet should be
* relatively static.  The intent here is to minimize the amount of site-programmer
* editing required for new programs that use the VDW.
*
*********************************************/

** OLD VARIABLES--THESE ARE DEPRECATED--new code should use the single var names below. ;
  ** libname locations specs ;

  ** This is the one lib var that makes sense to keep around--there are 4 different reference dsets ;
  ** that the rxrisk macro looks for--does not make sense to make 4 different _vdw vars for them. ;
  %let _RxRiskLib               = \\ctrhs-sas\warehouse\sasdata\rxrisk  ;

/*

  Commenting these out as a prelude to removing them entirely.

  %let _TumorLib                = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _EnrollLib               = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _DemographicLib          = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _RxLib                   = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _UtilizationLib          = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _VitalLib                = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _CensusLib               = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _LabLib                  = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;
  %let _Deathlib                = \\ctrhs-sas\warehouse\sasdata\crn_vdw ;

  ** dataset name specs ;
  %let _TumorData               = tumor ;
  %let _EnrollData              = enroll2_v2 ;
  %let _DemographicData         = demog_view ;
  %let _VitalData               = vitalsigns_view ;
  %let _CensusData              = census2000 ;

  %let _RxData                  = rx ;
  %let _EverNdcData             = EverNDC_1998_2007 ;

  %let _UtilizationData         = utilization_v2 ;
  %let _DxData                  = dx_v2 ;
  %let _PxData                  = px_v2 ;
  %let _ProviderSpecialtyData   = specfile_view ;

  %let _LabData                 = lab_results ;
  %let _LabDataNotes            = lab_results_notes ;

  %let _DeathData               = death ;
  %let _CODData                 = cod ;

*/

** 'Standard' VDW DATASET VARIABLES ;

  ** Consider un-commenting this in order to keep off-site-written code from accessing ;
  ** data other than what is in your VDW libs. ;
  ** libname _all_ clear ;

  ** In the same vein, if youve got significant off-spec site-specific-enhancement vars in your VDW,    ;
  ** consider putting up very simple sql views that just select the official VDW vars, and point your   ;
  ** dset vars at *those* rather than the raw dsets.  That way if user code does a "select * from blah" ;
  ** they wont get extra stuff they wont be expecting (and you may not want to give!).                  ;

  ** Note that this could easily be a sas/access specification, if you wanted to store your VDW data in say, a server database. ;
  ** You are also free to define any number of different libnames, if your VDW dsets are stored in different locations. ;
  ** Making this intentionally wacky so as to keep from colliding w/names likely to be chosen in application programs. ;
  libname __vdw "\\ctrhs-sas\warehouse\sasdata\crn_vdw"          access = readonly ;

  %let _vdw_tumor               = __vdw.tumor                   ;
  %let _vdw_enroll              = __vdw.enroll2_v2              ;
  %let _vdw_demographic         = __vdw.demog                   ;
  %let _vdw_rx                  = __vdw.rx                      ;
  %let _vdw_everndc             = __vdw.everndc                 ;
  %let _vdw_utilization         = __vdw.utilization_v2          ;
  %let _vdw_dx                  = __vdw.dx_v2                   ;
  %let _vdw_px                  = __vdw.px_v2                   ;
  %let _vdw_provider_specialty  = __vdw.specfile_view           ;
  %let _vdw_vitalsigns          = __vdw.vitalsigns              ;
  %let _vdw_census              = __vdw.census2000              ;
  %let _vdw_lab                 = __vdw.lab_results             ;
  %let _vdw_lab_notes           = __vdw.lab_results_notes       ;
  %let _vdw_death               = __vdw.death                   ;
  %let _vdw_cause_of_death      = __vdw.cod                     ;


** REFERENCE TO THE STANDARD MACROS FILE ;
  filename vdw_macs  FTP     "standard_macros.sas"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/vdwcode"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader" ;


  /*
    Site code--pls use the codes/abbreviations listed on:
    https://appliedresearch.cancer.gov/crnportal/other-resources/orientation/participating-sites/overview
  */

  %let _SiteCode = 01 ;
  %let _SiteAbbr = GHC;
  %let _SiteName = Group Health ;


** Legacy Version 2-compatible file variables. ;
  %let _vdw_vitalsigns_v2           = __vdw.vitalsigns_view ;  /* REMOVE ON 12-AUG-2011 */
  %let _vdw_demographic_v2          = __vdw.demog_view ;       /* REMOVE ON 12-AUG-2011 */
  %let _vdw_lab_v2                  = __vdw.lab_results_view  ;        /* REMOVE ON 17-NOV-2011 */
  %let _vdw_lab_notes_v2            = __vdw.lab_results_notes_view  ;  /* REMOVE ON 17-NOV-2011 */


** Version 3 Milestone file variables. ;

  ** These vars should point to datasets/views that meet the specs for the indicated milestone. ;
  ** So e.g., the data named in _vdw_enroll_m1 should have a var called enrollment_basis on it. ;
  ** These vars are temporary--will only exist during the v2 -> v3 transition.  ;
  ** See https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/version-3/implementation-plan for details. ;

  %let _vdw_enroll_m1               = __vdw.enroll3_vw ;

  %let _vdw_utilization_m2          = __vdw.utilization ;
  %let _vdw_dx_m2                   = __vdw.dx ;
  %let _vdw_px_m2                   = __vdw.px ;

  %let _vdw_provider_specialty_m5   = __vdw.specfile ;
  %let _vdw_enroll_m6               = __vdw.enroll2 ;

