/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\deleteme.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  errors    = 5
  nocenter
  noovp
  nosqlremerge
;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
%include vdw_macs ;

data test ;
  input
    @1  mrn $char10.
    @13 contact_date date9.
  ;
  end_date = contact_date + 30 ;
  format
    contact_date end_date mmddyy10.
  ;
datalines ;
roy         01jan2001
roy         01feb2001
roy         15jun2002
roy         14jul2002
roy         03aug2005
;
run ;

proc print ;
run ;

%collapseperiods(lib = work, dset = test
      , recstart = contact_date
      , recend = end_date) ;

proc print ;
run ;
