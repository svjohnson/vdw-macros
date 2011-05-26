/****************************************************************************************************/
%macro vdwcountsandrates1(medcodes,   /* -Any or all of 'PX DX NDC' - no quotes, depending on codes to run in FileIN 					  */
						start_date,               /* -Earliest day to pull codes, otherwise Date of beginning of study 								  */
						  end_date,               /* -Latest date by which to pull codes 															  */
						   fileIN=,               /* -File with the Codes of Interest, in the form 'libname.filename' 							      */
						   cohort=,               /* -If a cohort file (a file with sample MRNs of interest over which to restrict codes is available,*/
						   			                  /*  this will be the cohort-filename in the form 'libname.cohortfilename'						      */
						  outpath=);              /* -This is the unquoted path to where the Codes of Interest reside. eg \\groups\data\Directory.    */
									                    /*  The output file will also be placed here.														  */
/****************************************************************************************************/
/******************************************************************************************************************************************/
/*	This macro collects counts and rates of supplied codes at a given site over a specified time period. 								  */
/*	Over this time period, and for each category in the study, counts are collected for 												  */
/*	(i) the total number of times a certain medcode (px, dx, ndc) was encountered														  */
/* (ii) the total number of people who were assigned this code																			  */
/*(iii) the total number of enrolled people who were assigned this code.																  */
/* (iv) A rate of incidence per 10,000 people is calculated over the enrolled people. 													  */
/*  																																	  */
/* An example of calling the macro in general (when there is no cohort file)is as follows (leave the cohort= argument blank): 			  */
/* %vdwcountsandrates1(px,'01jan09'd,'31dec09'd, fileIN=lib1.outds, COHORT=, 															  */
/*		outpath=\\groups\data\CTRHS\Crn\S D R C\VDW\Radiology\sasdata\InputData\Finalized Input Counts and Rates);						  */
/*																																		  */
/* When a cohort file exists, here is another way to call the macro: 																	  */
/* %vdwcountsandrates1(px,'01jan09'd,'31dec09'd, fileIN=path.outds, COHORT=lib2.cohorttest, 											  */
/*		outpath=\\groups\data\CTRHS\Crn\S D R C\VDW\Data\Counts and Rates\Data) 														  */
/******************************************************************************************************************************************/

libname path "&outpath.";

/*The lack of symmetry in the table names requires a small twist*/
%let _vdw_px=&_vdw_px; %let _vdw_dx=&_vdw_dx; %let _vdw_ndc=&_vdw_rx;
%let ndcdate=rxdate;   %let pxdate=adate;     %let dxdate=adate;

/*Determine which medical codes are available in the supplied data*/
data combined_px combined_dx combined_ndc;
	set &fileIN.;
	if substr(upcase(medcode),1,2)="PX" then do;
		CodeType=substr(upcase(medcode),4,1);
		output combined_px;
	end;
	else if substr(upcase(medcode),1,2)="DX" then output combined_dx;
	else if substr(upcase(medcode),1,3)="NDC" then output combined_ndc;
run;

%if %upcase(&cohort.) eq %then %do;
/*We'll later use this step to calc rates - rates are count/enrPple *10k
Here and below, handling is required for the cohort yes or no instance*/
proc sql;
	select count(distinct mrn) as EnrPple into :EnrPple
	from &_vdw_enroll.
	where &start_date between enr_start and enr_end;
quit;
%end;

%else %if %upcase(&cohort.) ne %then %do;
/*We'll later use this next step to calc rates - rates are count/enrPple *10k*/
proc sql;
	select count(distinct mrn) as EnrPple into :EnrPple
	from &cohort. where mrn in (select mrn from &_vdw_enroll
	where &start_date between enr_start and enr_end);
quit;
%end;

/*Run for all specified medical code categories: 'px dx ndc' or a combo of the 3 - if they're not in &fileIn, skip to next*/
%local i cat;
  %do i=1 %to %sysfunc(countw(&medcodes));
		%let cat = %scan(%bquote(&medcodes),&i,' ');
 		proc sql; select count(*) into :numb from combined_&cat.; quit;
		%if &numb=0 %then %do;
  		%put **********************************************************;
  		%put No %upcase(&cat) Codes in &FileIn.. Skipping.;
  		%put **********************************************************;
      %goto skip;
		%end;
		/*else, start processing the medcode*/
		%put NOTE: Commencing to Run &cat. codes.;

		data vdw&cat.;
			set &&&_vdw_&cat.;
			where &&&cat.date between &start_date. and &end_date.;
		run;

		/*Create tables- All People, Modify code if code is/is not available*/
		%if %upcase(&cohort.) ne %then %let addcohort = %str(AND mrn in (select distinct mrn from &cohort.));
		%else %let addcohort=;

		proc sql;
		/*Count all people with PX/DX/NDC of Interest*/
			create table allPple as
			select description, &cat., Category, count(&cat.) as &cat.count, count(distinct mrn) as allPeople
			from combined_&cat. as a
			left join vdw&cat. as b
			on a.code = b.&cat.
			where &&&cat.date between &start_date. and &end_date. &addcohort.
			group by &cat., description, category;

		/*Create tables- All Enrolled People, modify code for cohort yes or no*/
		create table enrolledpple as
			select &cat.,description, count(distinct mrn) as allEnrolledPeople from
			(select mrn, &cat., description
			from combined_&cat. as a left join vdw&cat. as b on a.code =b.&cat.
			where &&&cat.date between &start_date. and &end_date. &addcohort.)
			where mrn in
 			(select distinct mrn from &_vdw_enroll where &start_date. between enr_start and enr_end)
		group by &cat., description;

		/*Create table with distinct totals*/
			create table combined&cat. as
			select distinct a.description, a.&cat., Category, a.&cat.count label="%upcase(&cat.) Count",
			allPeople label="All People", allEnrolledPeople label="All Enrolled People"
			from allpple as a
			left join enrolledpple as b
			on a.&cat.=b.&cat.;

  		/*There may be many categories in the study - account for each here*/
  		select distinct category into :category separated by "/" from combined_&cat;
  		select count(distinct category) as catgct into :catgct from combined_&cat;
    quit ;


		%do j=1 %to &catgct.;
			%let catg = %scan(&category., &j., '/');

			proc sql;
				select count(distinct mrn) as EnrPple&cat. into :EnrPple&cat. from
	 			(select distinct mrn, &cat.
 	  			from combined_&cat. as a left join vdw&cat. as b on a.code =b.&cat.
	  			where compress(category)=%sysfunc(compress("&catg.")))
 				where mrn in
  	 			(select distinct mrn from &_vdw_enroll where &start_date between enr_start and enr_end &addcohort.);

			insert into combined&cat.
				(description, &cat., Category, &cat.count, allPeople, allEnrolledPeople)
				values("~TOTAL FOR %upcase(&catg.) %upcase(&cat.) CODES**","~Total","&catg.",.,.,&&EnrPple&cat.);
		%end;

		/*Create tables- Include the rates - one on all enrolled people*/
		create table combined2&cat. as
			select distinct description, a.&cat., Category, a.&cat.count label="%upcase(&cat.) Count",
			allPeople label="All People",
			allEnrolledPeople label="All Enrolled People",
			int((allEnrolledPeople/&EnrPple.)*10000) as RateAllEnr label="Rate/10K Over All Enrolled People"
			from combined&cat. as a order by &cat. ;
		/*the final stage- creating the end table*/
		create table catg&cat. as
			select distinct description, Category, Code as &cat. label="Medical Code"
			from combined_&cat. order by &cat. ;

		data final&cat.;
			merge catg&cat. (in=a) combined2&cat. (in=b);
			by &cat. ;
			if a or b;
		run;

		/*Clean up a little, add Site Code*/
		data final&cat.;
			set final&cat.;
			if allPeople <=6 then allPeople=.; if allEnrolledPeople<=5 then allEnrolledPeople=.;
			if allEnrolledPeople <=6 then rateallenr=.;
			Sitecode="&_sitecode.";
		run;

		proc sort data=final&cat. out=path.final&cat._&_sitecode. /*nodupkey*/; by &cat.; run;

		proc print data=path.final&cat._&_sitecode. (obs=10);
			title "Here is a sample of what you are sending to &_siteabbr.";
		run;
  %skip:
  %end;
%mend vdwcountsandrates1;



