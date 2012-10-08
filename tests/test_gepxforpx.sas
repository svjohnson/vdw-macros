/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\Local Settings\Temporary Internet Files\OLK5D3\deleteme123.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options
  linesize  = 150
  msglevel  = i
  formchar  = '|-++++++++++=|-/|<>*'
  dsoptions = note2err
  nocenter
  noovp
  nosqlremerge
;

** For inspecting SQL sent to a server. ;
** options sastrace = ',,,d' sastraceloc = saslog nostsuffix ;
%macro dw;
%setghriDWIP;
%include '\\home\hartje1\SAS\SCRIPTS\ghridw_startup_test.sas';
%timestart
%mend dw;

%**dw ;
%include "\\ctrhs-sas\Warehouse\Sasdata\CRN_VDW\lib\StdVars.sas" ;
%**include "\\mlt1q0\C$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

%macro test(n) ;
  %do i = 1 %to &n ;
    %put vdw px is &_vdw_px ;
  %end ;
%mend test ;

%**test(10) ;

data pxlst;
  PxVarName='45378';
  PxCodeTypeVarName='C4';
run;

options mprint mlogic ;

%GetPxForPx(
          PxLst             /*The name of a dataset containing the procedure
                                list you want. */
        , PxVarName         /*The name of the Px variable in PxLst  */
        , PxCodeTypeVarName /*Px codetype variable name in PxLst  */
        , 01jan2011           /*The date when you want to start collecting data*/
        , 31dec2011             /*The date when you want to stop collecting data*/
        , Outset            /*Name of the output dataset containing the data*/
        ) ;