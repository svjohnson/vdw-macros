/*********************************************
* Gene Hart
* Group Health Research Institute
* (206) 287-2949
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\BloodCancerDefinition01.sas
*
*
*********************************************/

%macro BloodCancerDefinition01(outds=CancerCases, startdt=01jan1990, enddt=31dec2007) ;
  **************************************************************************
  * This defintion was used in the Stroke and Chemotherapy Project
  **************************************************************************;
  data &outds ;
      set &_vdw_tumor ;
  	where DxDate between "&startdt."d and "&enddt."d;
  	if morph ge '9650' and morph le '9667' then Hodgkin_Lymphoma = 1;
  		else Hodgkin_Lymphoma = 0;
  		if (morph ge '9590' and morph le '9596') then NonHodgkin_Lymphoma = 1;
  		else if (morph ge '9670' and morph le '9719') then  NonHodgkin_Lymphoma = 1;

  		else if (morph ge '9727' and morph le '9729')then NonHodgkin_Lymphoma = 1;
  		else NonHodgkin_Lymphoma = 0;
  	if  (morph ge '9800' and morph le '9948') then Leukemia = 1;
  		else Leukemia = 0;
  	if substr(icdosite, 1, 2)= 'C4'  and morph = '9731'  then Multiple_Myeloma = 1;
  		else if substr(icdosite, 1, 2)= 'C4' and morph = '9732' then Multiple_Myeloma = 1;
  		else if  substr(icdosite, 1, 2)= 'C4' and morph = '9761' then Multiple_Myeloma = 1;
  		else  Multiple_Myeloma = 0;
  run;
%mend BloodCancerDefinition01 ;