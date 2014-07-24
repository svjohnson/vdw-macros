/********************************************************************************/
/* Title: Collapse Location macro
/* Author: David Tabano, KPCO
/* Contact: David.C.Tabano@kp.org; 303-614-1348
/* Date: 05/27/2014
/*
/* Purpose: Roll up continuous location spans in the VDW Census_Location
/*			table (or any dataset containing MRN, LOC_START, LOC_END and GEOCODE
/*			variables) by geographic level. 
/********************************************************************************/

%MACRO COLLAPSE_LOCATION(n, 	    		/* Number of days gaps to remove (i.e. 30-day gaps) */
						 geolevel,  		/* Values include: STATE, COUNTY, TRACT, BLKGROUP, BLK */
						 dset_in,   		/* Input Census Dataset (can be full VDW Census_LOC or subset */
						 dset_out,  		/* Output dataset name */
						 MRN_dates_only=  	/* Input "Y" if you only want output of MRN, LOC_START and LOC_END (no geographic data); leave blank otherwise */
						 );

  proc format;
    value $st_fips
			'al'='01' 'ak'='02' 'az'='04' 'ar'='05' 'ca'='06' 'co'='08' 'ct'='09' 'de'='10' 'dc'='11'
			'fl'='12' 'ga'='13' 'hi'='15' 'id'='16' 'il'='17' 'in'='18' 'ia'='19' 'ks'='20' 'ky'='21'
			'la'='22' 'me'='23' 'md'='24' 'ma'='25' 'mi'='26' 'mn'='27' 'ms'='28' 'mo'='29' 'mt'='30'
			'ne'='31' 'nv'='32' 'nh'='33' 'nj'='34' 'nm'='35' 'ny'='36' 'nc'='37' 'nd'='38' 'oh'='39'
			'ok'='40' 'or'='41' 'pa'='42' 'ri'='44' 'sc'='45' 'sd'='46' 'tn'='47' 'tx'='48' 'ut'='49'
			'vt'='50' 'va'='51' 'wa'='53' 'wv'='54' 'wi'='55' 'wy'='56' 'pr'='72';

    value $fips_st
      '01'='Alabama' '17'='Illinois' '30'='Montana' '44'='Rhode Island'
      '02'='Alaska' '18'='Indiana' '31'='Nebraska' '45'='South Carolina'
      '04'='Arizona' '19'='Iowa' '32'='Nevada' '46'='South Dakota'
      '05'='Arkansas' '20'='Kansas' '33'='New Hampshire' '47'='Tennessee'
      '06'='California' '21'='Kentucky' '34'='New Jersey' '48'='Texas'
      '08'='Colorado' '22'='Louisiana' '35'='New Mexico' '49'='Utah'
      '09'='Connecticut' '23'='Maine' '36'='New York' '50'='Vermont'
      '10'='Delaware' '24'='Maryland' '37'='North Carolina' '51'='Virginia'
      '11'='District of Columbia' '25'='Massachusetts' '38'='North Dakota' '53'='Washington'
      '12'='Florida' '26'='Michigan' '39'='Ohio' '54'='West Virginia'
      '13'='Georgia' '27'='Minnesota' '40'='Oklahoma' '55'='Wisconsin'
      '15'='Hawaii' '28'='Mississippi' '41'='Oregon' '56'='Wyoming'
      '16'='Idaho' '29'='Missouri' '42'='Pennsylvania' '72'='Puerto Rico';
 quit;

DATA VDW_CENSUS_LOC;
LENGTH MRN_GEO_&geolevel $25.;
SET &dset_in;
	STATE=SUBSTR(GEOCODE,1,2);
	STATE_ABBR=PUT(SUBSTR(GEOCODE,1,2),$fips_st.);
	COUNTY=SUBSTR(GEOCODE,3,3);
	TRACT=SUBSTR(GEOCODE,6,6);
	BLKGRP=SUBSTR(GEOCODE,12,1);
	BLK=SUBSTR(GEOCODE,13,3);
	%IF %upcase(&geolevel)=STATE %then %do; MRN_GEO_&geolevel=CATS(MRN,"_",SUBSTR(GEOCODE,1,2)); %END;
	%ELSE %IF %upcase(&geolevel)=COUNTY %then %do; MRN_GEO_&geolevel=CATS(MRN,"_",SUBSTR(GEOCODE,1,5)); %END;
	%ELSE %IF %upcase(&geolevel)=TRACT %then %do; MRN_GEO_&geolevel=CATS(MRN,"_",SUBSTR(GEOCODE,1,11)); %END;
	%ELSE %IF %upcase(&geolevel)=BLKGRP %then %do; MRN_GEO_&geolevel=CATS(MRN,"_",SUBSTR(GEOCODE,1,12)); %END;
	%ELSE %IF %upcase(&geolevel)=BLK %then %do; MRN_GEO_&geolevel=CATS(MRN,"_",SUBSTR(GEOCODE,1,15)); %END;
RUN;


PROC SORT DATA=VDW_CENSUS_LOC;
BY MRN_GEO_&geolevel LOC_START LOC_END;
RUN;


DATA CENSUS_LOC_NOGAPS;
    DO UNTIL (last.MRN_GEO_&geolevel);
        SET VDW_CENSUS_LOC;
        BY MRN_GEO_&geolevel LOC_START LOC_END;
        IF (FIRST.MRN_GEO_&geolevel) THEN DO;
            ptrStart=LOC_START;
            ptrEnd=LOC_END;
        END;
        ELSE DO;
            *continuous
        -if continuous do not output until the last record (output only 1 record with the first LOC_START and the final LOC_END);
            IF LOC_START le ptrEnd+&n THEN DO; *LOC_END-ptrend <= &n days*;
                IF LOC_END = . THEN
                    ptrEnd= .; *do not be fooled by missing LOC_END values*;
                ELSE
                    ptrEnd=max(LOC_END,ptrEnd); *if continuous set ptrEnd to the latest LOC_END date;
            END;
            *not continuous, output each discontinuous record;
			*reset pointers to reflect more recent LOC_START and LOC_END;
            ELSE DO;
                OUTPUT;
                ptrStart=LOC_START;
                ptrEnd=LOC_END;               
            END;            
        END;
        IF LAST.MRN_GEO_&geolevel THEN OUTPUT;
    END;
        FORMAT ptrStart ptrEnd MMDDYY10.;
    DROP LOC_START
         LOC_END;
RUN;

%IF &MRN_dates_only=Y %THEN %DO;
PROC SQL;
    CREATE TABLE &dset_out (index=(MRN)) AS
    SELECT distinct MRN,
                    LOC_START AS LOC_START,
                    LOC_END as LOC_END
    FROM CENSUS_LOC_NOGAPS (rename=(ptrstart=LOC_START ptrend=LOC_END))
    order by MRN,
             LOC_START,
             LOC_END            
;
DROP TABLE VDW_CENSUS_LOC;
QUIT;
%END;

%ELSE %DO;
PROC SQL;
    CREATE TABLE &dset_out (index=(MRN)) AS
    SELECT distinct MRN,
					GEOCODE,
					STATE_ABBR,
					%IF %upcase(&geolevel)=STATE %then %do; STATE, %END;
					%ELSE %IF %upcase(&geolevel)=COUNTY %then %do; COUNTY, %END;
					%ELSE %IF %upcase(&geolevel)=TRACT %then %do; TRACT, %END;
					%ELSE %IF %upcase(&geolevel)=BLKGRP %then %do; BLKGRP, %END;
					%ELSE %IF %upcase(&geolevel)=BLK %then %do; BLK, %END;
                    LOC_START AS LOC_START,
                    LOC_END as LOC_END
    FROM CENSUS_LOC_NOGAPS (rename=(ptrstart=LOC_START ptrend=LOC_END))
    order by MRN,
             LOC_START,
             LOC_END            
;
DROP TABLE VDW_CENSUS_LOC;
QUIT;
%END;
%MEND;

/************ EXAMPLE MACRO CALL ******************/
/*
%COLLAPSE_LOCATION(		 
					30, 	   	
					COUNTY, 
					&_vdw_census_loc, 
					Census_loc_cont2,
					MRN_dates_only=Y
					);
*/
