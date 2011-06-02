/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\ctrhs\crn\s d r c\vdw\macros\test_getpxforpx.sas
*
* Does a basic sanity check on the getpxforpx macro.
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize = 150
  nocenter
  msglevel = i
  NOOVP
  formchar = '|-++++++++++=|-/|<>*'
  sastrace = ',,,d'
  sastraceloc = saslog nostsuffix
  dsoptions="note2err" NOSQLREMERGE
;

data codelist ;
  input
    @1    px        $char5.
    @9   codetype       $char1.
    @13   description    $char25.
  ;
datalines ;
S9075   H   SMOKING CESSATION TREATME
S9453   H   SMOKING CESSATION CLASS N
;
run ;

proc print ;
run ;

libname b '\\groups\data\CTRHS\Crn\S D R C\VDW\Macros' ;
data codelist ;
  set b.codelist ;
run ;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

%getpxforpx(codelist,px,codetype,01Jan1994,31dec2009,pxOut) ;

/*
%GetPxForPx(  PxLst = gnu
            , PxVarName = px_code
            , PxCodeTypeVarName = code_type
            , StartDt = 01Jan1994
            , EndDt = 31dec2009
            , OutSet = smoke_cess )  ;

%GetPxForPx(  PxLst = gnu
            , PxVarName = px_code
            , PxCodeTypeVarName = code_type
            , StartDt = 01Jan1994
            , EndDt = 31dec2009
            , OutSet = smoke_cess )  ;

*/

