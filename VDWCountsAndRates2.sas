/*Last modified 5/31/11 by Lawrence Madziwa to add optional title
Also corrected misspelling in macro variable (%'uppcase') that made it fail to resolve
/*Last modified 6/07/11 by Lawrence Madziwa to add logic to change last row in each tabulation. Tweaked _g
/*Last modified 7/05/11 by Lawrence Madziwa to make parameters all keyword
Also to roll up dx and px on description, not on dx/px codes
*************************************************************************************************************/

/****************************************************************************************************************************************/
/* This macro, %VDWCountsAndRates2, tabulates results from %VDWCountsAndRates1.															*/
/* It takes three arguments: (i) The list of medcodes to tabulate (Any combo of 'PX DX NDC' separated by space, no quotes)              */
/* 						    (ii) The path location of the results from the first macro. The tabulated tables will be placed there too.  */
/*                         (iii) An optional title to allow better documentation                                                        */ 
/****************************************************************************************************************************************/

 /*This is for repetitive titles and footnotes;*/
%macro titlefoots;
title "Some Codes Related to %upcase(&catg.)";
	title2 "Counts of All %upcase(&cat.) over period of interest by site within HMORN.";
	title3 "&titl3.";
	footnote1 "Preliminary: The above exhibit shows the incidence of selected codes at sites. The list is not exhaustive," ;
	footnote2 " and may need augumenting. The motive is to assess data quality across sites over selected codes." ;
	footnote3 "**Only Calculated on Enrolled so far";
	footnote4 "Prepared on &sysdate.";
%mend titlefoots;
/********************************************************************************************************************************/
/* This macro tabulates results from sites 4 ways: (i) procedure counts, (ii) all people who ever had a procedure, 		    	*/
/* (iii) all Enrolled People who ever had a procedure, then (iv) rates of incidence over those enrolled. 3 output files 		*/
/* (PX, DX, NDC) containing each of the four will be output.;													                */
/* This macro puts results from sites together for further analysis or comparison; 							  					*/					
/********************************************************************************************************************************/
%macro VDWCountsAndRates2(medcodes=, /*Any combo of 'PX DX NDC' - no quotes - that you need tabulated					 */
						      path=, /*path to data files from sites, which SHOULD be stored in a directory by themselves*/
						     titl3=,  /*Optional additional title*/
						     InName= /*Text imbedded in filename */ );
libname path "&path";
options mprint; 
/* Make a dummy dataset of site names so that each site ends up in the final table */
data SiteNames;
	length sitecode $4;
	sitecode='01 '; output;	 sitecode='02 '; output;  sitecode='03 '; output;  sitecode='04 '; output;
	sitecode='05 '; output;  sitecode='06 '; output;  sitecode='07 '; output;  sitecode='08 '; output;
	sitecode='09 '; output;  sitecode='10 '; output;  sitecode='11 '; output;  sitecode='12 '; output;
	sitecode='13 '; output;  sitecode='14 '; output;  sitecode='15 '; output;  sitecode='16 '; output;
	sitecode='17 '; output;
;
/*
	sitecode='01a';
	sitecode='01b';
*/
run;
/*Create a site name format;*/
proc format;
	value $sitef
	'01 ' = "GHC"  '02 ' = "KPNW"  '03 ' = "KPNC"  '04 ' = "KPSC"
	'05 ' = "KPHI" '06 ' = "KPCO"  '07 ' = "HPRF"	 '08 ' = "HPHC"
	'09 ' = "MPCI" '10 ' = "HFHS"  '11 ' = "KPGA"  '12 ' = "LHS"
	'13 ' = "MCRF" '14 ' = "GHS"   '15 ' = "SWH"   '16 ' = "MHS"
	'17 ' = "KPMA"
	'01a'='GHC-IGP'
	'01b'='GHC-Network'
	;
proc format;
    	value LessSix
    	.a = '<6'
    	other=[comma8.0];    
run;

  proc sql noprint;
	create table thenames as
    select memname from dictionary.tables
    where libname = "PATH" and 
          index(upper(memname),upper("_&InName._"))
    ;
    select  memname 
    into :n1 separated by " " from thenames;
  quit;

options user=path;
data work.alldata;
	length sitecode $4 ;
	set &n1;
run;

%put &n1= ;

options user = work;

/* Count number of obs in each file to determine whether to run it*/
  proc sql;
	select count(distinct category) into :numcat from work.alldata;
	select distinct category into :catgn separated by "/" from work.alldata;
  quit;

%do j=1 %to &numcat.;
  %let catg = %scan(&catgn.,&j.,'/');

   ods tagsets.ExcelXP file="&path.\&sysdate. &catg. file &InName .xls" style=analysis
	options
    (embedded_titles="yes"	Embedded_footnotes="yes" 	Autofit_Height = "YES" Frozen_Headers="8"  Frozen_RowHeaders="1"
	Absolute_Column_Width="40,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5");

    %local i cat;  %let i = 1;
    %let cat = %scan(%bquote(&medcodes),&i);
		 
    %do %while(%bquote(&cat) ne);
		data _null_;
			dset=open('alldata');
			call symput('chk',left(trim(put(varnum(dset,"px"),2.))));
		run; 

		%if &chk=0 %then %goto skip;

     	data &cat.;
			set alldata;
			if category="&catg.";
			if &cat. ne "" then output &cat.;
	 	run;
    
/* Create the format;*/
		data _g;
  			set &cat.;
  			retain fmtname "$fmt&cat.";
  			start = &cat.;
  			Label = description;  
  			keep Fmtname Start Label;
		run;

		proc sort data=_g nodupkey; by start; run;
		proc format cntlin=_g ;

/* Prepare for tabulation*/
    	data dataclass;
     		set &cat. sitenames ;
	 		keep category  sitecode Description &cat;  *added description for non-ndc;
	 		if category='' then category="%upcase(&catg.)";
    	run;

/* Start tabulation*/
   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) All %upcase(&cat)s");

		data dataclass; set dataclass;
		if &cat.='~Total' then description="~All %upcase(&cat) - Number of All &cat.**";
		data &cat; set &cat;
		if &cat.='~Total' then description="~All %upcase(&cat) - Number of All &cat.**";

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq &cat.count;  format sitecode $sitef.;
			keylabel N="";		
			class Description category sitecode;
			table Description, sitecode /box="All %upcase(&cat.)s" misstext='.'; *added description for non-ndc;
		%titlefoots;
   		run;

   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) People with %upcase(&cat.)s");

		data dataclass; set dataclass;
		if &cat.='~Total' then description="~All People - Number of All People with any &cat.**";
		data &cat; set &cat;
		if &cat.='~Total' then description="~All People - Number of All People with any &cat.**";

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq allpeople;  format sitecode $sitef.;
			keylabel N="";
			class &cat. Description category sitecode; 
			table Description, sitecode /box="All People" misstext='.'; *added description for non-ndc;
	   	%titlefoots;
   		run;

   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) Enrolled With %upcase(&cat.)s");

		data dataclass; set dataclass;
		if &cat='~Total' then description="~Enrolled - Number of enrolled people with any &cat.**";
		data &cat; set &cat;
		if &cat='~Total' then description="~Enrolled - Number of enrolled people with any &cat.**";
		run;

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq allEnrolledPeople;  format sitecode $sitef.;
			keylabel N="";    
			class Description category sitecode; *class &cat. category sitecode; 
			table Description, sitecode /box="Enrolled People" misstext='.';	
		%titlefoots;
   		run;
		

   		ods tagsets.ExcelXP options (Sheet_name="(%upcase(&cat.)) Rates - All Enrollees");
		
		data dataclass; set dataclass;
		if &cat.='~Total' then description="~Rates - Rate of enrolled people with any &cat.**";run;
		data &cat; set &cat;
		if &cat.='~Total' then description="~Rates - Rate of enrolled people with any &cat.**";run;

   		proc tabulate data = &cat. missing format=LessSix. classdata=dataclass;
			where upcase(Category)="%upcase(&catg.)";
			freq rateallenr;  format sitecode $sitef.;
			keylabel N="Rate/ 10k";
			class Description category sitecode; 
			table Description, sitecode /box="Enrolled Rates" misstext='.'; *added description for non-ndc;
	   	%titlefoots;
   		run;
   		title;
		   %skip:;
   		%let i = %eval(&i + 1);
   		%let cat = %scan(%bquote(&medcodes),&i); 
   	%end; /*MEDCODES END*/
   ods tagsets.ExcelXP close;
%end;   /*CATG END*/
 
%mend VDWCountsAndRates2;

