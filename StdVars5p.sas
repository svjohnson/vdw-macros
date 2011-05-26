/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* StdVars5p.sas
*
* A site-modified program that specifies a set of standard macro variables
* for things that vary by site (e.g., libname definitions) and yet should be
* relatively static.  The intent here is to minimize the amount of site-programmer
* editing required for new programs that use the VDW.
*
* THIS FILE POINTS AT THE 5-percent subsample version of these files!!!  It is intended to be useful
* for basic, fast syntax & logic testing.
*
*********************************************/

** OLD VARIABLES--THESE ARE DEPRECATED--new code should use the single var names below. ;
  ** libname locations specs ;

  ** This is the one lib var that makes sense to keep around--there are 4 different reference dsets ;
  ** that the rxrisk macro looks for--does not make sense to make 4 different _vdw vars for them. ;
  %let _RxRiskLib               = \\ctrhs-sas\warehouse\sasdata\rxrisk  ;

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
  libname __vdw "\\ctrhs-sas\warehouse\sasdata\crn_vdw\5percent_subset" access = readonly ;
  libname __full "\\ctrhs-sas\warehouse\sasdata\crn_vdw" access = readonly ;

  %let _vdw_tumor               = __vdw.tumor                   ;
  %let _vdw_enroll              = __vdw.enroll2_v2              ;
  %let _vdw_demographic         = __vdw.demog                   ;
  %let _vdw_rx                  = __vdw.rx                      ;
  %let _vdw_everndc             = __full.everndc                 ;
  %let _vdw_utilization         = __vdw.utilization_v2          ;
  %let _vdw_dx                  = __vdw.dx_v2                   ;
  %let _vdw_px                  = __vdw.px_v2                   ;
  %let _vdw_provider_specialty  = __full.specfile_view           ;
  %let _vdw_vitalsigns          = __vdw.vitalsigns              ;
  %let _vdw_census              = __vdw.census2000              ;
  %let _vdw_lab                 = __vdw.lab_results             ;
  %** We dont actually have a 5p lab notes--lets see if anybody notices. ;-) ;
  %**let _vdw_lab_notes           = __vdw.lab_results_notes       ;
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

  %let _SiteCode = 666 ;
  %let _SiteAbbr = GHC_5p;
  %let _SiteName = FIVE PERCENT Group Health ;

