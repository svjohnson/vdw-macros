%include '\\home\rosstr1\My SAS Files\Scripts\Remote\RemoteStart.sas';
libname vdw '\\ctrhs-sas\warehouse\sasdata\crn_vdw' access=readonly;

%macro GetVitalSignsForPeople (
              People  /* The name of a dataset containing the people whose
                           vitals you want*/
            , StartDt /* The date on which you want to start collecting vitals*/
            , EndDt   /* The date on which you want to stop collecting vitals */
            , Outset  /* The name of the output dataset containing the vitals */
            ) ;
            
   libname __vitals "&_VitalLib" access = readonly ;
   
   /*Catch and Throw*/
   %if &People = &Outset %then %do ;
    %put PROBLEM: The People dataset must be different from the OutSet dataset.;
    %put PROBLEM: Both parameters are set to "&People". ;
    %put PROBLEM: Doing nothing. ;
   %end ;
   %else %if "&StartDt"d > "&EndDt"d %then %do ;
     %put PROBLEM: The start date you entered occurrs after the end date ;
     %put PROBLEM: Start date is "&StartDt." and end date is "&EndDt." ;
     %put PROBLEM: Doing nothing. ;
   %end ;
   %else %if %sysfunc(exist(&People))=0 %then %do;
     %put PROBLEM: The People dataset (&People.) does not exist. ;
     %put PROBLEM: Doing nothing. ;
   %end;
   %else %do;
     proc sql;
       create table &OutSet. as
         select v.*
         from &People as p
           INNER JOIN
              __vitals.&_VitalData as v
         on p.mrn = v.mrn
         where v.Measure_Date BETWEEN "&StartDt"d AND "&EndDt"d 
       ;
     quit;   
   %end;
%mend GetVitalSignsForPeople;

/*Test it out*/
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas";
proc sql;
  create table Afew as select distinct mrn from vdw.&_VitalData
    where Measure_Date between '01May2005'd AND '15May2005'd;
quit;
*Error 1;
%GetVitalSignsForPeople(afew,   05May2005, 10May2005, afew);
*Error 2;
%GetVitalSignsForPeople(afew,   05May2005, 01Jan1999, myout);
*Error 3;
%GetVitalSignsForPeople(nodata, 05May2005, 10May2005, myout);
*No errors;
%GetVitalSignsForPeople(afew,   05May2005, 10May2005, myout);


endrsubmit;
signoff chsdwsas;