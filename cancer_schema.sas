* [RP] Recieved from Gene Hart on 15-jan-2014. ;
%macro CancerSchema(OutputDS,StartDt,EndDt);
/************************************************************************************************************************
* This macro takes cancers in your VDW Tumor file for the time period of interest and allocates them to cancer schema
* For AJCC 6th edition the variable created is CancerSchemaAjcc6thEdition - all cancers are included
*     https://cancerstaging.org/references-tools/deskreferences/Documents/AJCC6thEdCancerStagingManualPart1.pdf
*
* For AJCC 7th edition the variable created is CancerSchmaAjcc7thEdition - only 9 common cancers are currently defined in this macro
*     http://ebookee.org/AJCC-Cancer-Staging-Manual-7th-Edition_1494657.html
*
* Arguments
*   OutputDS is the name of the SAS dataset that will be output
*   StartDt is the start date of interest in the format 01jan2000
*   EndDt is the end date of interest in the format 31dec2000
************************************************************************************************************************/
;
proc sql;
  create table CancerSchema as
  select t.*,
         case
         when (ICDOSite between 'C500' and 'C506' or
          	  ICDOsite between 'C508' and 'C509') and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981' or
         			 Morph=        '9020')
              then 'Breast'

         when (ICDOSite='C619') and
              (MORPH between '8000' and '8110' or
               MORPH between '8140' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Prostate'

         when (ICDOSite='C180' or
               ICDOsite between 'C182' and 'C189') and
              (MORPH between '8000' and '8152' or
               MORPH between '8154' and '8231' or
               MORPH between '8243' and '8245' or
			         MORPH      in('8247','8248')    or
               MORPH between '8250' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Colon'

         when (ICDOSite between 'C340' and 'C343' or
        			 ICDOsite between 'C348' and 'C349') and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Lung'

         when (ICDOSite between 'C670' and 'C679') and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Bladder'

         when (ICDOSite='C569' ) and
              (MORPH between '8000' and '8576' or
               MORPH between '8590' and '8671' or
               MORPH between '8930' and '9110')
              then 'Ovary'

         when (ICDOSite between 'C440' and 'C449' or
               ICDOsite between 'C510' and 'C512' or
               ICDOsite between 'C518' and 'C519' or
               ICDOsite between 'C600' and 'C602' or
               ICDOsite between 'C608' and 'C609' or
               ICDOsite= 'C632' ) and
              (MORPH between '8720' and '8790')
              then 'Melanoma'

         when (ICDOSite between 'C530' and 'C531' or
               ICDOsite between 'C538' and 'C539' ) and
              (MORPH between '8000' and '8576' or
               MORPH between '8940' and '8950' or
               MORPH between '8980' and '8981')
              then 'Cervix'

         else 'Not yet coded'
         end as CancerSchemaAjcc7thEdition,

         	case
	  when ( ICDOsite BETWEEN 'C000' and 'C009' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Lip'

	  when ( ICDOsite BETWEEN 'C019' and 'C029' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Tongue'

	  when ( ICDOsite BETWEEN 'C079' and 'C089' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Salivary Gland'

	  when ( ICDOsite BETWEEN 'C040' and 'C049' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Floor of Mouth'

	  when ( (ICDOsite BETWEEN 'C030' and 'C039') or (ICDOsite BETWEEN 'C050' and 'C059') or ICDOsite BETWEEN 'C060' and 'C069' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Gum and other mouth'

	  when ( ICDOsite BETWEEN 'C110' and 'C119' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Nasopharynx'

	  when ( ICDOsite BETWEEN 'C090' and 'C099' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Tonsil'

	  when ( ICDOsite BETWEEN 'C100' and 'C109' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Oropharynx'

	  when ( (ICDOsite='C129') or (ICDOsite BETWEEN 'C130' and 'C139') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Oral Cavity and Pharynx'

	  when ( (ICDOsite='C140') or (ICDOsite BETWEEN 'C142' and 'C148') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Hypopharynx'

	  when ( ICDOsite BETWEEN 'C150' and 'C159' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Esophagus'

	  when ( ICDOsite BETWEEN 'C160' and 'C169' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Stomach'

	  when ( ICDOsite BETWEEN 'C170' and 'C179' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Lip'

	  when ( ICDOsite='C180' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Cecum'

	  when ( ICDOsite='C181' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Appendix'

	  when ( ICDOsite='C182' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Ascending Colon'

	  when ( ICDOsite='C183' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Hepatic Flexure'

	  when ( ICDOsite='C184' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Transverse Colon'

	  when ( ICDOsite='C185' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Splenic Flexure'

	  when ( ICDOsite='C186' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Descending Colon'

	  when ( ICDOsite='C187' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Sigmoid Colon'

	  when ( (ICDOsite BETWEEN 'C188' and 'C189') or (ICDOsite='C260') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Large Intestine, NOS'

	  when ( ICDOsite='C199' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Rectosigmoid Junction'

	  when ( ICDOsite='C209' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Rectum'

	  when ( (ICDOsite BETWEEN 'C210' and 'C212') or (ICDOsite='C218') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Anus, Anal Canal and Anorectum'

	  when ( ICDOsite='C220' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Liver'

	  when ( ICDOsite='C221' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Intrahepatic Bile Duct'

	  when ( ICDOsite='C239' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Gall Bladder'

	  when ( ICDOsite BETWEEN 'C240' and 'C249' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Biliary'

	  when ( ICDOsite BETWEEN 'C250' and 'C259' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Pancreas'

	  when ( ICDOsite='C480' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Retroperitoneum'

	  when ( ICDOsite BETWEEN 'C481' and 'C482' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Peritoneum, Omentum and Mesentery'

	  when ( (ICDOsite BETWEEN 'C268' and 'C269') or (ICDOsite='C488') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Digestive Organs'

	  when ( (ICDOsite BETWEEN 'C300' and 'C301') or (ICDOsite BETWEEN 'C310' and 'C319') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Nose, Nasal Cavity and Middle Ear'

	  when ( ICDOsite BETWEEN 'C320' and 'C329' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Larynx'

	  when ( ICDOsite BETWEEN 'C340' and 'C349' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Lung and Bronchus'

	  when ( (ICDOsite BETWEEN 'C381' and 'C383') or (ICDOsite in ('C339' 'C388' 'C390' 'C398' 'C399')) )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Trachea, Mediastinum and Other Respiratory Organs'

	  when ( ICDOsite BETWEEN 'C400' and 'C419' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Bones and Joints'

	  when ( (ICDOsite='C380') or (ICDOsite BETWEEN 'C470' and 'C479') or (ICDOsite BETWEEN 'C490' and 'C499') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Soft Tissue, including Heart'

	  when ( ICDOsite BETWEEN 'C440' and 'C449' )
	   and ( MORPH BETWEEN '8720' and '8790' )
       then 'Melanoma of the Skin'

	  when ( ICDOsite BETWEEN 'C440' and 'C449' )
	   and NOT( MORPH BETWEEN '8000' and '8005' ) and NOT( MORPH BETWEEN '8010' and '8046')
	   and NOT( MORPH BETWEEN '8050' and '8084' ) and NOT( MORPH BETWEEN '8090' and '8110')
	   and NOT( MORPH BETWEEN '8720' and '8790' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Non-Epithelial Skin'

	  when ( ICDOsite BETWEEN 'C500' and 'C509' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Breast'

	  when ( ICDOsite BETWEEN 'C530' and 'C539' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Cervix Uteri'

	  when ( ICDOsite BETWEEN 'C540' and 'C549' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Corpus Uteri'

	  when ( ICDOsite='C559' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Uterus, NOS'

	  when ( ICDOsite='C569' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Ovary'

	  when ( ICDOsite='C529' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Vagina'

	  when ( ICDOsite BETWEEN 'C510' and 'C519' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Vulva'

	  when ( ICDOsite BETWEEN 'C570' and 'C589' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Female Genital Organs'

	  when ( ICDOsite='C619' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Prostate'

	  when ( ICDOsite BETWEEN 'C620' and 'C629' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Testis'

	  when ( ICDOsite BETWEEN 'C600' and 'C609' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Penis'

	  when ( ICDOsite BETWEEN 'C630' and 'C639' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Male Genital Organs'

	  when ( ICDOsite BETWEEN 'C670' and 'C679' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Urinary Bladder'

	  when ( (ICDOsite='C649') or (ICDOsite='C659') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Kidney and Renal Pelvis'

	  when ( ICDOsite='C669' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Ureter'

	  when ( ICDOsite BETWEEN 'C680' and 'C689' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Urinary Organs'

	  when ( ICDOsite BETWEEN 'C690' and 'C699' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Eye and Orbit'

	  when ( ICDOsite BETWEEN 'C710' and 'C719' )
	   and NOT( MORPH BETWEEN '9530' and '9539')
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Brain'

	  when ( ICDOsite BETWEEN 'C710' and 'C719' )
       and ( MORPH BETWEEN '9530' and '9539' )
       then 'Cranial Nerves Other Nervous System'

	  when ( (ICDOsite BETWEEN 'C700' and 'C709') or (ICDOsite BETWEEN 'C720' and 'C729') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Cranial Nerves Other Nervous System'

	  when ( ICDOsite='C739' )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Thyroid'

	  when ( (ICDOsite='C739') or (ICDOsite BETWEEN 'C740' and 'C749') or (ICDOsite BETWEEN 'C750' and 'C759') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Other Endocrine including Thymus'

	  when ( (ICDOsite in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) or (ICDOsite BETWEEN 'C770' and 'C779') )
       and (MORPH BETWEEN '9650' and '9667')
       then 'Hodgkin - Nodal'

	  when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
       and (MORPH BETWEEN '9650' and '9667')
       then 'NHL - Extranodal'

	%if dxdate<='31DEC2009'd %then %do;
	  when ( (ICDOsite in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) or (ICDOsite BETWEEN 'C770' and 'C779') )
	   and (    ( MORPH BETWEEN '9590' and '9595' ) or ( MORPH BETWEEN '9670' and '9677' )
	         or ( MORPH BETWEEN '9680' and '9688' ) or ( MORPH BETWEEN '9690' and '9698' )
			 or ( MORPH BETWEEN '9700' and '9717' )
			 or   MORPH in ( '9823' '9827' ) )
       then 'NHL - Nodal'

	  when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
	   and (    ( MORPH BETWEEN '9590' and '9595' ) or ( MORPH BETWEEN '9670' and '9677' )
	         or ( MORPH BETWEEN '9680' and '9688' ) or ( MORPH BETWEEN '9690' and '9698' )
			 or ( MORPH BETWEEN '9700' and '9717' ) )
       then 'NHL - Extranodal'

	  when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C420' 'C421' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
	   and (  MORPH in ('9823' '9827') )
       then 'NHL - Extranodal'

	 when ( MORPH in ('9731' '9732') )
	 then 'Myeloma'

	 when ( MORPH in ('9821' '9828' '9836' '9837') )
	 then 'Acute Lymphocytic Leukemia'

	  when ( ICDOsite in ('C420' 'C421' 'C424') )
	   and (  MORPH in ('9823') )
       then 'Chronic Lymphocytic Leukemia'

	 when ( MORPH in ('9820' '9822' '9824' '9825' '9826') )
	 then 'Other Lymphocytic Leukemia'

	 when ( MORPH in ('9840' '9861' '9866' '9867' '9871' '9872' '9873' '9874') )
	 then 'Acute Myeloid Leukemia'

	 when ( MORPH in ('9891') )
	 then 'Acute Monocytic Leukemia'

	 when ( MORPH in ('9893') )
	 then 'Chronic Monocytic Leukemia'

	 when ( MORPH in ('9863' '9868') )
	 then 'Chronic Myeloid Leukemia'

	 when ( MORPH in ('9860' '9892' '9894') )
	 then 'Other Monocytic Leukemia'

	 when ( MORPH in ('9801' '9841' '9931' '9932') )
	 then 'Other Acute Leukemia'

	 when ( MORPH in ('9803' '9842') )
	 then 'Other Chronic Leukemia'

	 when ( MORPH in ('9800' '9802' '9804' '9830' '9850' '9870' '9880' '9900' '9910' '9930' '9940' '9941') )
	 then 'Aleukemic, subleukemic and NOS'

	 when ICDOsite in ('C420' 'C421' 'C424')
	 and ( MORPH in ('9827') )
	 then 'Aleukemic, subleukemic and NOS'

	 when ( MORPH BETWEEN '9050' and '9055' )
	 then 'Mesothelioma'

	 when ( MORPH ='9140' )
	 then 'Kaposi Sarcoma'

		when ( MORPH in ('9720' '9721' '9722' '9723' '9740' '9741' '9950' '9970' '9989')
		   or (MORPH BETWEEN '9980' and '9984') or (MORPH BETWEEN '9760' and '9764') or (MORPH BETWEEN '9960' and '9962') )
	 	then 'Miscellaneous'

	  when ( (MORPH='C809') or (ICDOsite BETWEEN 'C420' and 'C424') or (ICDOsite BETWEEN 'C760' and 'C768') or (ICDOsite BETWEEN 'C770' and 'C779') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Miscellaneous'
	%end;
	%if dxdate>='01JAN2010'd %then %do;
	 when ( (ICDOsite in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) or (ICDOsite BETWEEN 'C770' and 'C779') )
	   and (    ( MORPH BETWEEN '9590' and '9596' ) or ( MORPH BETWEEN '9689' and '9691' )
	         or ( MORPH BETWEEN '9698' and '9702' ) or ( MORPH BETWEEN '9714' and '9719' )
			 or ( MORPH BETWEEN '9727' and '9729' )
			 or   MORPH in ( '9670' '9671' '9673' '9675' '9678' '9679' '9680' '9684' '9687' '9695'
			                 '9705' '9708' '9709' '9823' '9827' ) )
       then 'NHL - Nodal'

	  when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
	   and (    ( MORPH BETWEEN '9590' and '9596' ) or ( MORPH BETWEEN '9689' and '9691' )
	         or ( MORPH BETWEEN '9698' and '9702' ) or ( MORPH BETWEEN '9714' and '9719' )
			 or ( MORPH BETWEEN '9727' and '9729' )
			 or   MORPH in ( '9670' '9671' '9673' '9675' '9678' '9679' '9680' '9684' '9687' '9695'
			                 '9705' '9708' '9709' '9823' '9827' ) )
       then 'NHL - Extranodal'

	  when ( (ICDOsite NOT in ('C024' 'C098' 'C099' 'C111' 'C142' 'C379' 'C420' 'C421' 'C422')) and NOT(ICDOsite BETWEEN 'C770' and 'C779') )
	   and (  MORPH in ('9823' '9827') )
       then 'NHL - Extranodal'

	 when ( MORPH in ('9731' '9732' '9734') )
	 then 'Myeloma'

	 when ( MORPH in ('9826' '9835' '9836' '9837') )
	 then 'Acute Lymphocytic Leukemia'

	  when ( ICDOsite in ('C420' 'C421' 'C424') )
	   and (  MORPH in ('9823') )
       then 'Chronic Lymphocytic Leukemia'

	 when ( MORPH in ('9820' '9832' '9833' '9834' '9940') )
	 then 'Other Lymphocytic Leukemia'

	 when ( MORPH in ('9840' '9861' '9866' '9867' '9871' '9872' '9873' '9874' '9895' '9896' '9897' '9910' '9920') )
	 then 'Acute Myeloid Leukemia'

	 when ( MORPH in ('9891') )
	 then 'Acute Monocytic Leukemia'

	 when ( MORPH in ('9863' '9875' '9876' '9945' '9946') )
	 then 'Chronic Myeloid Leukemia'

	 when ( MORPH in ('9860' '9930') )
	 then 'Other Myeloid/Monocytic Leukemia'

	 when ( MORPH in ('9801' '9805' '9931') )
	 then 'Other Acute Leukemia'

	 when ( MORPH in ('9733' '9742' '9800' '9831' '9870' '9948' '9963' '9964') )
	 then 'Aleukemic, subleukemic and NOS'

	 when ICDOsite in ('C420' 'C421' 'C424')
	 and ( MORPH in ('9827') )
	 then 'Aleukemic, subleukemic and NOS'

	 when ( MORPH BETWEEN '9050' and '9055' )
	 then 'Mesothelioma'

	 when ( MORPH ='9140' )
	 then 'Kaposi Sarcoma'

		when ( MORPH in ('9740' '9741' '9950' '9960' '9961' '9962' '9970' '9975' '9980' '9989')
		   or (MORPH BETWEEN '9750' and '9758') or (MORPH BETWEEN '9760' and '9769') or (MORPH BETWEEN '9982' and '9987') )
	 	then 'Miscellaneous'

	  when ( (MORPH='C809') or (ICDOsite BETWEEN 'C420' and 'C429') or (ICDOsite BETWEEN 'C760' and 'C768') or (ICDOsite BETWEEN 'C770' and 'C779') )
       and NOT( MORPH BETWEEN '9050' and '9055' ) and NOT( MORPH = '9140' ) and NOT( MORPH BETWEEN '9590' and '9989' )
       then 'Miscellaneous'

	%end;
	else ''
	end as CancerSchemaAjcc6thEdition

	from &_vdw_tumor as t
	where dxdate between "&startdt."d and "&enddt."d
	;
QUIT;

%mend CancerSchema;




