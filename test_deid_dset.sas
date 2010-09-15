/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_deid_dset.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

data allgender;
input @3 ob @10 Gender $1. @20 Gender_Count @29 year $4.
    @35 mrn $char8.
;
cards;
  1      F         1859     1988  roy
  2      M         1318     1988  bob
  3      F         1895     1989  mary
  4      M         1356     1989  bill
  5      F         1945     1990  gene
  6      M         1374     1990  simone
  7      F         1961     1991  anne
  8      M         1387     1991  laurel
  9      F         1981     1992  kodos
 10      M         1399     1992  chai
 proc print;

%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;

%deiddset( InSet = allgender    /* Name of the dataset you want de-identified. */
               , XWalkSet = something /* Name of the output ID-crosswalk dset. */
               , OldIDVar = mrn /* Name of the ID variable you want removed. */
               , NewIDVar = blah /* Name for the new ID variable the macro creates. */
               , NewIDLen = 4  /* The length of the new ID variable.*/
               , StartIDsAt = 0)
               ;

proc print data = allgender ;
run ;
