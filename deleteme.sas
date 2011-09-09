
** filename vdw_fmt   FTP     "formats.xpt"
**                   HOST  = "vdw.hmoresearchnetwork.org"
**                   CD    = "/vdwcode"
**                   PASS  = "%2hilario36"
**                   USER  = "VDWReader"
**                   DEBUG
**                   rcmd  = 'binary'
**                   ;

** Does this work here? ;
%vdw_formats ;

** Change this to wherever you put your copy of formats.xpt ;
filename vdw_fmt 'C:\Documents and Settings\pardre1\My Documents\vdw\macros\data\formats.xpt' ;

libname  vdw_fmt xport ;

proc format lib = work cntlin = vdw_fmt.formats ;
run ;

