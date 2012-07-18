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
* NOT EVERYTHING IN THIS FILE IS PART OF THE VDW SPECS!  In particular--the __vdw
* libname chosen below is not part of the spec.  Users should not assume that a
* lib named __vdw will be defined at all sites.
*
* See: https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/the-vdw-standard-variables-file-stdvars.sas
* For further details.
*********************************************/

** This keeps SAS from dumping raw records into the log. ;
options errors = 0 ;

  ** libname locations specs ;

  ** This is the one lib var that makes sense to keep around--there are 4 different reference dsets ;
  ** that the rxrisk macro looks for--does not make sense to make 4 different _vdw vars for them. ;
  %let _RxRiskLib               = \\ghrisas\warehouse\sasdata\rxrisk  ;

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
  ** Note also that this is not a "standard" libname--there are no standard libnames.  Please see the above-referenced URL ;
  ** for details. ;

  ** Making this intentionally wacky so as to keep from colliding w/names likely to be chosen in application programs. ;
  libname __vdw "\\&__server_name.\warehouse\sasdata\crn_vdw" access = readonly ;

  %let _vdw_tumor               = __vdw.tumor                   ;
  %let _vdw_enroll              = __vdw.enroll3_vw              ;
  %let _vdw_demographic         = __vdw.demog                   ;
  %let _vdw_rx                  = __vdw.rx                      ;
  %let _vdw_everndc             = __vdw.everndc                 ;
  %let _vdw_utilization         = __vdw.utilization             ;
  %let _vdw_dx                  = __vdw.dx_vw                   ;
  %let _vdw_px                  = __vdw.px                      ;
  %let _vdw_provider_specialty  = __vdw.specfile                ;
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
    https://appliedresearch.cancer.gov/crnportal/data-resources/vdw/site-data-managers/participating-sites/overview
  */

  %let _SiteCode = 01 ;
  %let _SiteAbbr = GHC;
  %let _SiteName = Group Health ;

** Many sites/projects have something like blanket IRB approval for generating/sending frequency data, so long
** as cells with "low" counts are masked. This variable should hold what is considered "low" at your site. ;
** The most commonly used value is 5. ;

  %let lowest_count = 5 ;

** Variables used by the detect_phi macro. ;
  %** A regular expression giving the pattern that your MRN values follow. Used to check character vars for possibly holding MRNs. ;
  %** The pattern given below will match any 10 consecutive uppercase alpha or numeric characters. ;
  %let mrn_regex = ([A-Z0-9]{10}) ;

  %** OPTIONAL: A pipe-delimited list of variable names that should trigger a warning in the ouput of the macro detect_phi. ;
  %** Not case-sensitive. ;
  %** Do not include spaces between the pipes. ;
  %let locally_forbidden_varnames = consumno|chsid|ghriid|pat_mrn_id|pat_id|csr_num ;

** Legacy Version 2-compatible file variables. ;
  %** let _vdw_vitalsigns_v2           = __vdw.vitalsigns_view ;  /* REMOVE ON 12-AUG-2011 */
  %** let _vdw_demographic_v2          = __vdw.demog_view ;       /* REMOVE ON 12-AUG-2011 */
  %let _vdw_lab_v2                 = __vdw.lab_results_view         ; /* REMOVE ON 17-NOV-2011 */
  %let _vdw_lab_notes_v2           = __vdw.lab_results_notes_view   ; /* REMOVE ON 17-NOV-2011 */
  %let _vdw_enroll_v2              = __vdw.enroll2_v2               ; /* REMOVE ON 10-DEC-2011 */
  %let _vdw_utilization_v2         = __vdw.utilization_v2           ; /* REMOVE ON 30-MAR-2012 */
  %let _vdw_dx_v2                  = __vdw.dx_v2                    ; /* REMOVE ON 30-MAR-2012 */
  %let _vdw_px_v2                  = __vdw.px_v2                    ; /* REMOVE ON 30-MAR-2012 */
  %let _vdw_provider_specialty_v2  = __vdw.specfile_view            ; /* REMOVE ON 30-MAR-2012 */

** End of file. ;