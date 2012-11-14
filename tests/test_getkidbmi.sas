/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_getkidbmi.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ; ** dsoptions="note2err" NOSQLREMERGE ;

%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;
%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
%include "\\ctrhs-sas\Warehouse\sasdata\CRN_VDW\lib\StdVars.sas" ;

* %include vdw_macs ;
%**include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\GetKidBMIPercentiles.sas" ;


%macro get_test_kids(n = 300, outset = s.test_kids) ;
  proc sql outobs = &n nowarn ;
    create table &outset as
    select mrn
    from vdw.demog
    where birth_date gt '13jan1994'd and
          substr(mrn, 4, 1) = 'K'
    ;
  quit ;
%mend get_test_kids ;

%get_test_kids ;

%GetKidBMIPercentiles(Inset = s.test_kids /* Dset of MRNs on whom you want kid BMI recs */
                        , OutSet = s.test_kid_bmis
                        , StartDt = 01jan2009
                        , EndDt = &sysdate9
                        ) ;
