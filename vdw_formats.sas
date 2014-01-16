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

%macro vdw_formats(lib = work, tweaked_descriptions = 0) ;
  filename vdw_fmt   FTP     "formats.xpt"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/Alfresco/Sites/vdwcode/documentLibrary"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader"
                     ;

  libname  vdw_fmt xport ;

  *recode label to be of the form CODE(DESCRIPTION) if label only contains DESCRIPTION;
  data vdw_formats;
    set vdw_fmt.formats;
    %if &tweaked_descriptions = 1 %then %do ;
      if (not(label =: strip(start)) or index(label,'(')=0) and start = end then
        label = strip(start) || ' (' || strip(label) || ')' ; *prepend code to desc;
    %end ;
  run;

  proc format lib = &lib cntlin = vdw_formats ;
  run ;

  proc datasets nolist;  delete vdw_formats;  run; *Clean up workspace;

%mend vdw_formats ;

