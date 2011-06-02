/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* <<program name>>
*
* <<purpose>>
*********************************************/

/* This is managed in the login script so that it doesnt 
   actually try to login when the machine is not connected
   to the network */
%include "\\home\pardre1\SAS\Scripts\dw_login.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;


%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\StdVars.sas" ;
%include "\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\CRN_VDW_MACROS.sas" ;

libname d "&_DemographicLib" ;

data victims ;
   set d.&_DemographicData(firstobs = 1000 obs = 11000) ;
run ;

%GetUtilizationForPeople(People = victims
                        , StartDt = 01Jan2005
                        , EndDt   = 31Dec2005
                        , OutSet  = ute) ;

run ;

proc freq data = ute ;
   tables adate / missing ;
   format adate monyy5. ;
run ;

endsas ;