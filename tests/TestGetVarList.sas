/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\TestGetVarList.sas
*
* Tests the getvarlist helper macro (part of simplecontinuous).
*
*********************************************/

%**include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

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

libname _all_ clear ;
libname u '\\ctrhs-sas\SASUser\pardre1\vdw\ute_troubleshooting' ;

%include "c:\Documents and Settings\pardre1\My Documents\vdw\macros\GetVarList.sas" ;

%let out_folder = c:\Documents and Settings\pardre1\My Documents\vdw\macros\tests\ ;

ods html path = "&out_folder" (URL=NONE)
         body = "TestGetVarList.html"
         (title = "TestGetVarList output")
          ;

%GetVarList(u.drg_hosps, recstart = ADMTDATE, recend = dschdate) ;

run ;

ods _all_ close ;

%put var list is &varlist ;

run ;
