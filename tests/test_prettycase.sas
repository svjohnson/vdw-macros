/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\test_prettycase.sas
*
* Pretty-case is mangling hyphenated last names.  Can we improve w/out compromising e.g., street-address perf??
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

data test ;
  input
    @1 test_string $char30.
  ;
datalines ;
377 S 23ST STREET APT 3G
11 HAPSBURG PL
REMERS-PARDEE
ROYSET-MANNING
WEBBER-AGNEW
;
run ;

proc print ;
run ;

%PrettyCase(InSet   = test
          , OutSet  = pc_out
          , VarList = test_string) ;

proc print data = pc_out ;
run ;


