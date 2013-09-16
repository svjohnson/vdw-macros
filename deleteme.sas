/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\users/pardre1/documents/vdw/macros/deleteme.sas
*
* purpose
*********************************************/

* %include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;
data these_vars ;
  input
    @1    name      $char9.
    @11   label     $char21.
  ;
datalines ;
mrn       medical record number
something mind-blowing variable
nolabel
run ;

* proc print ;
* run ;
libname togo "\\groups\data\CTRHS\CHS\pardre1\repos\faux_enroll\SPAN_PROXY_ENROLL_WP02V01\SHARE" ;
libname s "//ghrisas/SASUser/pardre1" ;


proc contents noprint data = TOGO.NO_P_IN_POOL_GHC out = these_vars ;
run ;

  data s.these_vars ;
    set these_vars ;
  run ;

 proc sql noprint ;
   create table phi_warnings (dset char(50), variable char(255), label char(256), warning char(200)) ;

   create table possible_bad_vars as
   select name, label
   from these_vars
   where prxmatch(compress("/(mrn|hrn)/i"), name)
   ;

   insert into phi_warnings(dset, variable, label, warning)
      select "TOGO.NO_P_IN_POOL_GHC" as dset
            , name
            , label
            , "Name suggests this var may be an MRN, which should never move across sites."
      from possible_bad_vars
    ;
  quit ;
