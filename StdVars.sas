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


** OLD VARIABLES--THESE ARE DEPRECATED--new code should use the single var names below. ;
  ** libname locations specs ;
  %let _RxRiskLib               = \\ctrhs-sas\warehouse\sasdata\rxrisk  ;

** NEW VARIABLES ;

  ** Note that this could easily be a sas/access specification, if you wanted to store your VDW data in say, a server database. ;
  ** You are also free to define any number of different libnames, if your VDW dsets are stored in different locations. ;

  ** Making this intentionally wacky so as to keep from colliding w/names likely to be chosen in application programs. ;
  libname __vdw "\\ctrhs-sas\warehouse\sasdata\crn_vdw"          access = readonly ;

  %let _vdw_tumor               = __vdw.tumor                   ;
  %let _vdw_enroll              = __vdw.enroll2_v2              ;
  %let _vdw_demographic         = __vdw.demog_view              ;
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


** NEW REFERENCE TO THE STANDARD MACROS FILE ;
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


** Version 3 Milestone file variables. ;

  ** These vars should point to datasets/views that meet the specs for the indicated milestone. ;
  ** So e.g., the data named in _vdw_enroll_m1 should have a var called enrollment_basis on it. ;
  ** These vars are temporary--will only exist during the v2 -> v3 transition.  ;
  ** See https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/version-3/implementation-plan for details. ;

  %let _vdw_enroll_m1               = __vdw.enroll3_vw ;
  %let _vdw_vitalsigns_m1           = __vdw.vitalsigns ;

  %let _vdw_utilization_m2          = __vdw.utilization ;
  %let _vdw_dx_m2                   = __vdw.dx ;
  %let _vdw_px_m2                   = __vdw.px ;
  %let _vdw_vitalsigns_m2           = __vdw.vitalsigns ;

  %let _vdw_demographic_m3          = __vdw.demog ;

  %let _vdw_lab_m4                  = __vdw.lab_results ;
  %let _vdw_lab_notes_m4       		  = __vdw.lab_notes ;

  %let _vdw_provider_specialty_m5   = __vdw.specfile ;
  %let _vdw_enroll_m6               = __vdw.enroll2 ;

