/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\vdw_formats.sas
*
* A to-be-standard macro that pulls a cntlin dataset down from hmorn.org to
* define some VDW-useful formats.
*********************************************/

%macro vdw_formats(lib = work) ;
  filename vdw_fmt   FTP     "formats.xpt"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/vdwcode"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader"
                     DEBUG
                     /* rcmd  = 'binary' this makes the macro barf w/an access violation at Essentia--it is not necessary. */
                     ;

  libname  vdw_fmt xport ;

  proc format lib = &lib cntlin = vdw_fmt.formats ;
  run ;

%mend vdw_formats ;