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
    @1    px              $char5.
    @9    codetype        $char2.
    @13   description     $char25.
  ;
  ** Creating some dupes to test for that warning. ;
  do i = 1 to 3 ;
    output ;
  end ;
  drop i ;
datalines ;
S9075   H4   SMOKING CESSATION TREATME
S9453   H4   SMOKING CESSATION CLASS N
;
run ;

** proc print ; run ;

filename theinput (
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\Cervical Cancer Screening.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\Breast Cancer Surgery.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\Ovarian Cancer Surgery Related Codes.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiationTherapy.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\ColonCancerScreening_SEARCH.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\ChemoTherapyPX.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyOther.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyCT.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyNucsPetCt.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyNUCs.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyUltrasound.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyDrugType.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyMRI.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\RadiologyNucsPet.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\Radiologyxrayc.dat',
'\\groups\data\CTRHS\Crn\S D R C\VDW\Programs\CountsAndRates\InputCodes\Radiologyxray.dat')
;



data pxin;
            infile theinput delimiter = '|' MISSOVER DSD lrecl=500 ;
            informat Code $12.  MedCode $10. Descrip $200. Category $30. ;
            input Code $  MedCode $ Descrip $ category $;
        select (MedCode);
          when ("PX-CPT4") MedCode = "C4";
          when ("PX-Rev") MedCode = "RV";
          otherwise;
        end;

run;



%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;


%**include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\standard_macros.sas" ;
%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\standard_macros.sas" ;

options mprint mlogic ;

%getpxforpx(pxin, code, codetype, 01Jun2008, 31dec2008, pxOut) ;

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

