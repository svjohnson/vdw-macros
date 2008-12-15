%macro GetRxRiskForPeople(InFile, OutFile, IndexDt);
/*************************************************
* Tyler Ross
* Center for Health Studies
* 206-287-2927
* ross.t@ghc.org
*
* GetRxRiskForPeople.sas
*
* Purpose:
*	Calculates RxRisk comorbidity for a list of MRN. Indicates diseases based on
*   Rx fills.
*
* Notes:
*	This code was based heavily on Jim Savarino's RxRisk macro program
*	written for use at CHS.
*	If enrollment data is not available for the day before IndexDt, the enrollee
*   is assumed to not be on Medicaid nor Medicare.  This is partly because the
*		CRN specs do not distinguish between non-Medicare and missing.
*	Weights are callibrated separately for adults and children. Disease categories
*   in many cases are applicable to only one of these two models. The lable of
*   each disease starts with A if adults only, P if pediatrics only, and AP if
*   both apply.
*
*   Be aware that this macro may take a while depending on the size of your
*     cohort and the size of your data structures.
*
* Dependencies:
*	A series of SAS data files that accompany this program and a libref assigned
*		to the directory they are stored in in StdVars.sas
*   (%let _RxRiskLib="\\DIRECTORY";).
*	StdVars.sas--the site-customized list of standard macro variables.
*	The following variables from the following data structures
*			Demographics: MRN, Birth_Date, Gender  (All required)
*			Enrollment: MRN, Ins_Medicare, Ins_Medicaid (Not required)
*			Pharmacy: MRN, RxDate, NDC (Required)
*
*			****************************************************
*			***IMPORTANT***IMPORTANT***IMPORTANT***IMPORTANT****
*
*			The Pharmacy file must have all fills one year prior
*			to the index date for each enrollee for the results
*			to be accurate!
*
*			***IMPORTANT***IMPORTANT***IMPORTANT***IMPORTANT****
*			****************************************************
*
* Inputs:
*	A file with variables MRN and &IndexDt to calculate RxRisk.
*
* Output:
*	A file with 52 variables:
*		MRN
*		RxRisk = The RxRisk estimate of MRN's expenditures for the year
*					starting on IndexDt
*		Model = The model used to calculate RxRisk
*					A = Adult
*					P = Pediatric
*		49 Diseases = Series of disease dummies based on Rx fills
*
* Parameters:
*	&InFile  = The name of a file with distinct MRN
*	&OutFile = The name of the file that will be outputted
*	&IndexDt = The variable that holds the first day of the year's expenditures
*              that you want to estimate for each individual (i.e. the date on
*			         which to calculate the comorbidity.
*
* Version History
*
*	Created:	01/17/2006
*	Modified:	03/28/2006
*		- Added disease-specific sub-categories for adults & children.
* Modified: 10/20/2006
*   - Adjusted enrollment merge to match new enrollment specs
*
* Users of RxRisk should cite these two papers, on which the work is based:
*
* Paul A. Fishman, Michael Goodman, Mark Hornbrook, Richard Meenan, Don Bachman,
*   Maureen O’Keefe Rossetti, "Risk Adjustment Using Automated Pharmacy Data:
*   the RxRisk Model," Medical Care 2003;41:84-99
*
* Paul Fishman and David Shay,
* "A Pediatric Chronic Disease Score from Automated Pharmacy Data",
*    Medical Care, 1999,37(9) pp 872-880.
*
*************************************************/

	%LET adultage=18;
	/*This limits the maximum number of different diseases a person can have*/
	%LET MaxDisease=20;

	libname dem "&_DemographicLib.";
	libname enr "&_EnrollLib.";
	libname rx "&_RxLib.";
	libname risk "&_RxRiskLib.";

	/*Get the Cases file ready*/
	proc sql;
	/*Add on gender and age from demographics*/
	create table GrabDem as
	select 	distinct i.mrn
			, &IndexDt.
			, coalesce(ifn(upcase(d.gender)="M", 0, .),
			           ifn(upcase(d.gender)="F", 1, .)) as gender
			, floor((intck('month',d.Birth_Date,&IndexDt.)
				- (day(&IndexDt.) < day(d.Birth_Date))) / 12) as age
	from &infile. as i
		LEFT JOIN
		 dem.&_DemographicData. as d
	on i.MRN = d.MRN
	;

	/*Add on Medicare and Medicaid from enrollment*/
	create table Cases as
	select 	  g.*
			, ifn(upcase(e.Ins_Medicare)="Y", 1, 0, 0) as Medicare
			, ifn(upcase(e.Ins_Medicaid)="Y", 1, 0, 0) as Medicaid
	from GrabDem as g
		INNER JOIN
		 enr.&_EnrollData. as e
	on g.MRN = e.MRN
	where &IndexDt. between e.Enr_Start and e.Enr_End
	;

	/*Get the drug file ready*/
	create table drugs as
	select    distinct i.mrn
			, i.&IndexDt.
			, r.RxDate
			, r.NDC
	from &infile as i
			LEFT JOIN
		 rx.&_RxData. as r
    on    i.MRN = r.MRN
    where r.RxDate BETWEEN (&IndexDt.-366) AND (&IndexDt.-1) ;

	/* Attach a cost for age, adult model  */
	create table adultcost as
	select    T1.*
			, T2.code
			, T3.cost
			,'A' as Model
	from  risk.adultcostcoefficient as T3
		, Cases as T1 inner join risk.adultageclassification as T2
	on t3.code=t2.code
	where T1.age >= &adultage and T2.female=T1.gender and
		 (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
	order by MRN;

	/* Attach a cost for age, pediatric model  */
	create table pedcost as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'P' as Model
	from risk.childcostcoefficient as T3
		, Cases as T1 inner join risk.childageclassification as T2
	on t3.code=t2.code
	where T1.age < &adultage and T2.female=T1.gender and
		(T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
	order by MRN
	;

	/* For adult model , compute a cost factor for Medicare  */
	create table carecost as
	select 	  T1.*
			, T2.code
			, T3.cost
			,'A' as Model
	from risk.adultcostcoefficient as T3
		, Cases as T1 inner join risk.medicareclassification as T2
	on t3.code=t2.code
	where (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
		and (T1.age >= &adultage ) and (T1.medicare=1)
	order by MRN
	;

	/* For adult, compute a cost factor for Medicaid when present  */
	create table caidcost as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'A' as Model
	from risk.adultcostcoefficient T3,
		Cases as T1 inner join risk.medicaidclassification as T2
	on t3.code=t2.code
	where (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
		and (T1.age >= &adultage ) and (T1.medicaid=1)
	order by MRN;

	/* For pediatric model, compute a cost factor for Medicaid when present  */
	create table caidchld as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'P' as Model
	from risk.adultcostcoefficient as T3
		, Cases as T1 inner join risk.medicaidclassification as T2
	on t3.code=t2.code
	where (T1.age >= T2.ageinclusive and T1.age < T2.ageexclusive)
		and (T1.age < &adultage ) and (T1.medicaid=1)
	order by MRN;
	quit;

	/* Rebuild case information with age cost factor and medicare cost added */
	data caseinfo;
  		set adultcost pedcost;
  		by mrn;
	run;

	/* Drop working tables to free disk space */
	proc sql;
		drop table adultcost;
		drop table pedcost;

	/* Screen out any medications not within time window  */
	create table workmeds as
	select 	  T1.*
			, T2.age
	from drugs as T1 INNER JOIN caseinfo as T2
	on T2.MRN=T1.MRN
	where ( (T2.&IndexDt.-T1.RxDate) > 0 ) AND ( (T2.&IndexDt.-T1.RxDate) <= 365 )
	;

	/* Attach a cost coefficient to each medication, adult model  */
	create table work1 as
	select	  T1.*
			, T2.code
			, T3.cost
			, 'A' as Model
	from risk.adultcostcoefficient as T3
		, workmeds as T1 inner join risk.adultdrugclassification as T2
	on t2.ndccode=t1.ndc
	where t3.code=t2.code AND T1.age >= &adultage
	;

	/* Attach a cost coefficient to each medication, pediatric model */
	create table work2 as
	select 	  T1.*
			, T2.code
			, T3.cost
			, 'P' as Model
	from risk.childcostcoefficient as T3
		, workmeds as T1 inner join risk.childdrugclassification as T2
	on t2.ndccode=t1.ndc
	where t3.code=t2.code AND T1.age < &adultage
	;

	proc sql;  drop table workmeds; quit;

	/* Now remove duplicate cost classifications at case id level
  	   for adults. Sorting separately to reduce cost of sort...
	*/
	%let byvars=mrn code;
	proc sort data=work1 nodupkey; by &byvars; run;

	/* Now remove duplicate cost classifications at case id level for children*/
	proc sort data=work2 nodupkey; by &byvars; run;

	/* Now produce file with rxrisk outcome */
	%let keepvars=MRN Model cost;
	data work3(keep=MRN model cost);
   		set work1(keep=&keepvars)
		    work2(keep=&keepvars)
			caseinfo(keep=&keepvars)
			carecost(keep=&keepvars)
			caidcost(keep=&keepvars)
			caidchld(keep=&keepvars);
	run;

	proc sql;
		drop table work1;
		drop table work2;
		drop table carecost;
		drop table caidcost;
		drop table caidchld;

	/*Create Rx Variable*/
	create table work4 as
	select 	  MRN
			, sum(cost) as rxrisk
			, model
	from work3
	group by MRN, model
	;
	drop table work3;

	/*****************************************************
	* Modification to add disease indicators starts here *
	*****************************************************/

	/*Add codes for children*/
	create table DiseaseKids as
	select a.mrn, B.code, c.age
	from drugs as a, risk.childdrugclassification as B, GrabDem as c
	where a.ndc=B.ndccode AND a.mrn=c.mrn AND (0<=c.age<&adultage.)
	;
	/*Add codes for adults*/
	create table DiseaseAll as
	select a.mrn, B.code, c.age
	from drugs as a, risk.adultdrugclassification as B, GrabDem as c
	where a.ndc=B.ndccode AND a.mrn=c.mrn AND c.age>=&adultage.
	;
	quit;
	/*Combine kids and adults*/
	proc append base=DiseaseAll data=DiseaseKids; run;

	/*Keep first instance of each disease*/
	proc sort data=DiseaseAll nodupkey; by mrn code; run;

    proc sort data=DiseaseAll; by mrn age; run;
	proc transpose data=DiseaseAll out=DiseaseAll prefix=CondCode;
		var code;
		by mrn age;
	run;

	/*Assign diseases*/
	data DiseaseAll (keep=mrn Acne--TB);
		set DiseaseAll;
		length Acne Allerg Alpha Amino Anxiety Asthma ADD Bipolar CAD CLS CAH PRV
		       CF Dep Dm2 Eczema Epi ESRD GAD Glaucoma Gout GHD HD Hemophilia HIV
		       Hyperlip HTN Immunod Iron IBS Lead	Liver Malabs Malig Ostomy Pain
		       Inflame Parkin Pituitary Psych Renal RDS RA Sickle	Steroid Thyroid
		       Trache Transplant TB 3
		;

		array Conds{*} Acne Allerg Alpha Amino Anxiety Asthma ADD Bipolar CAD CLS
		        CAH PRV CF Dep Dm2 Eczema	Epi ESRD GAD Glaucoma Gout GHD HD
		        Hemophilia HIV Hyperlip HTN Immunod Iron IBS Lead	Liver Malabs Malig
		        Ostomy Pain Inflame Parkin Pituitary Psych Renal RDS RA Sickle
		        Steroid Thyroid Trache Transplant TB
		;
		do i = 1 to dim(Conds);
   			Conds{i} = 0;
		end;
		array CondCodes{*} CondCode1-CondCode&MaxDisease.;
		do i = 1 to dim(CondCodes);
			if CondCodes{i} 	 = 1 & age<&adultage. 	  then Acne=1;
			else if CondCodes{i} = 2 & age<&adultage. 	then Allerg=1;
			else if CondCodes{i} = 3 & age<&adultage. 	then Alpha=1;
			else if CondCodes{i} = 4 & age<&adultage. 	then Amino=1;
   		else if CondCodes{i} = 5  					        then Anxiety=1;
   		else if CondCodes{i} = 6  					        then Asthma=1;
			else if CondCodes{i} = 7 & age<&adultage. 	then ADD=1;
   		else if CondCodes{i} = 8  					        then Bipolar=1;
   	  else if CondCodes{i} = 9  					        then CAD=1;
			else if CondCodes{i} = 10 & age<&adultage. 	then CLS=1;
			else if CondCodes{i} = 11 & age<&adultage.	then CAH=1;
			else if CondCodes{i} = 12 & age>=&adultage.	then PRV=1;
			else if CondCodes{i} = 13 					        then CF=1;
			else if CondCodes{i} = 14 					        then Dep=1;
			else if CondCodes{i} = 15 					        then Dm2=1;
			else if CondCodes{i} = 16 & age<&adultage.	then Eczema=1;
			else if CondCodes{i} = 17 					        then Epi=1;
			else if CondCodes{i} = 18 & age>=&adultage.	then ESRD=1;
			else if CondCodes{i} = 19 					        then GAD=1;
			else if CondCodes{i} = 20 & age>=&adultage.	then Glaucoma=1;
			else if CondCodes{i} = 21 & age>=&adultage.	then Gout=1;
			else if CondCodes{i} = 22 & age<&adultage.	then GHD=1;
			else if CondCodes{i} = 23 & age>=&adultage.	then HD=1;
			else if CondCodes{i} = 24 & age<&adultage.	then Hemophilia=1;
			else if CondCodes{i} = 25 					        then HIV=1;
			else if CondCodes{i} = 26 					        then Hyperlip=1;
			else if CondCodes{i} = 27 & age>=&adultage.	then HTN=1;
			else if CondCodes{i} = 28 & age<&adultage.	then Immunod=1;
			else if CondCodes{i} = 29 & age<&adultage.	then Iron=1;
			else if CondCodes{i} = 30 					        then IBS=1;
			else if CondCodes{i} = 31 & age<&adultage.	then Lead=1;
			else if CondCodes{i} = 32 					        then Liver=1;
			else if CondCodes{i} = 33 & age<&adultage.	then Malabs=1;
			else if CondCodes{i} = 34 					        then Malig=1;
			else if CondCodes{i} = 35 & age<&adultage.	then Ostomy=1;
			else if CondCodes{i} = 36 & age<&adultage.	then Pain=1;
			else if CondCodes{i} = 37 & age<&adultage.	then Inflame=1;
			else if CondCodes{i} = 38 & age>=&adultage.	then Parkin=1;
			else if CondCodes{i} = 39 & age<&adultage.	then Pituitary=1;
			else if CondCodes{i} = 40 					        then Psych=1;
			else if CondCodes{i} = 41 					        then Renal=1;
			else if CondCodes{i} = 42 & age<&adultage.	then RDS=1;
   		else if CondCodes{i} = 43 					        then RA=1;
			else if CondCodes{i} = 44 & age<&adultage.	then Sickle=1;
			else if CondCodes{i} = 45 & age<&adultage.	then Steroid=1;
			else if CondCodes{i} = 46 					        then Thyroid=1;
			else if CondCodes{i} = 47 & age<&adultage.	then Trache=1;
			else if CondCodes{i} = 48 					        then Transplant=1;
   		else if CondCodes{i} = 49 					        then TB=1;
		end;
	run;

	proc sql;
	/*Create Output File*/
	create table &outfile as
	select a.MRN
			 , a.rxrisk							            label ='RxRisk Comorbidity'
			 , a.model							            label ='Adult vs Pediatric Model'
		   , coalesce(b.Acne , 0) as Acne 		label ='P1 Acne'              length=3
		   , coalesce(b.Allerg , 0) as Allerg label ='P2 Allergic Rhinitis' length=3
		   , coalesce(b.Alpha , 0) as Alpha 	label ='P3 Alpha'             length=3
		   , coalesce(b.Amino , 0) as Amino	  label ='P4 Amino Acid Disorders'
		                                                                    length=3
		   , coalesce(b.Anxiety , 0) as Anxiety label ='AP5 Anxiety and Tension'
		                                                                    length=3
		   , coalesce(b.Asthma , 0) as Asthma label ='AP6 Asthma'           length=3
		   , coalesce(b.ADD , 0) as ADD 		  label ='P7 Attention Deficit Disorder'
		                                                                    length=3
		   , coalesce(b.Bipolar , 0) as Bipolar label ='AP8 Bipolar Disorder'
		                                                                    length=3
		   , coalesce(b.CAD , 0) as CAD		    label ='AP9 Cardiac Disease'  length=3
		   , coalesce(b.CLS , 0) as CLS	      label ='P10 Central Line Supplies'
		                                                                    length=3
		   , coalesce(b.CAH , 0) as CAH	  label ='P11 Congenital Adrenal Hypoplasia'
		                                                                    length=3
		   , coalesce(b.PRV , 0) as PRV	      label ='A12 Coronary/Peripheral Vasc'
		                                                                    length=3
		   , coalesce(b.CF , 0) as CF		      label ='AP13 Cystic Fibrosis' length=3
		   , coalesce(b.Dep , 0) as Dep	      label ='AP14 Depression'      length=3
		   , coalesce(b.Dm2 , 0) as Dm2	      label ='AP15 Diabetes'        length=3
		   , coalesce(b.Eczema , 0) as Eczema	label ='P16 Eczema'           length=3
		   , coalesce(b.Epi , 0) as Epi		    label ='AP17 Epilepsy'        length=3
		   , coalesce(b.ESRD , 0) as ESRD		  label ='A18 ESRD'             length=3
		   , coalesce(b.GAD , 0) as GAD	label ='AP19 Gastric Acid Disorder' length=3
		   , coalesce(b.Glaucoma , 0) as Glaucoma label ='A20 Glaucoma'     length=3
		   , coalesce(b.Gout , 0) as Gout		  label ='A21 Gout'             length=3
		   , coalesce(b.GHD , 0) as GHD		    label ='P22 Growth Hormone Deficiency'
		                                                                    length=3
		   , coalesce(b.HD , 0) as HD			   label ='A23 Heart Disease/Hypertension'
		                                                                    length=3
		   , coalesce(b.Hemophilia , 0) as Hemophilia label ='P24 Hemophilia'
		                                                                    length=3
		   , coalesce(b.HIV , 0) as HIV		    label ='AP25 HIV'             length=3
		   , coalesce(b.Hyperlip , 0) as Hyperlip label ='AP26 Hyperlipidemia'
		                                                                    length=3
		   , coalesce(b.HTN , 0) as HTN		    label ='A27 Hypertension'     length=3
		   , coalesce(b.Immunod , 0) as Immunod label ='P28 Immunodeficiency'
		                                                                    length=3
		   , coalesce(b.Iron , 0) as Iron		  label ='P29 Iron Overload'    length=3
		   , coalesce(b.IBS , 0) as IBS		    label ='AP30 Irritable Bowel Syndrome'
		                                                                    length=3
		   , coalesce(b.Lead , 0) as Lead		  label ='P31 Lead Poisoning'   length=3
		   , coalesce(b.Liver , 0) as Liver	  label ='AP32 Liver Disease'   length=3
		   , coalesce(b.Malabs , 0) as Malabs	label ='P33 Malabsorbtion'    length=3
		   , coalesce(b.Malig , 0) as Malig	  label ='AP34 Malignancies'    length=3
		   , coalesce(b.Ostomy , 0) as Ostomy	label ='P35 Ostomy'           length=3
		   , coalesce(b.Pain , 0) as Pain		  label ='P36 Pain'             length=3
		   , coalesce(b.Inflame , 0) as Inflame label ='P37 Pain and Inflammation'
		                                                                    length=3
		   , coalesce(b.Parkin , 0) as Parkin	label ='A38 Parkinsons Disease'
		                                                                    length=3
		   , coalesce(b.Pituitary , 0) as Pituitary label ='P39 Pituitary Hormone'
		                                                                    length=3
		   , coalesce(b.Psych , 0) as Psych	label ='AP40 Psychotic Illness' length=3
		   , coalesce(b.Renal , 0) as Renal	label ='AP41 Renal Disease'     length=3
		   , coalesce(b.RDS , 0) as RDS	label ='P42 Respiratory Distriess Syndrome'
		                                                                    length=3
		   , coalesce(b.RA , 0) as RA		label ='AP43 Rheumatoid Arthritis'  length=3
		   , coalesce(b.Sickle , 0) as Sickle	label ='P44 Sickle Cell Anemia'
		                                                                    length=3
		   , coalesce(b.Steroid,0) as Steroid label ='P45 Steroid Dependent Disease'
		                                                                    length=3
		   , coalesce(b.Thyroid , 0) as Thyroid label ='AP46 Thyroid Disorder'
		                                                                    length=3
		   , coalesce(b.Trache , 0) as Trache	label ='P47 Tracheostomy'     length=3
		   , coalesce(b.Transplant,0) as Transplant label ='AP48 Transplant'
		                                                                    length=3
		   , coalesce(b.TB, 0) as TB			label ='AP49 Tuberculosis'        length=3

	from work4 as a
		LEFT JOIN
		 DiseaseAll as b
	on a.mrn=b.mrn
	;

	drop table work4;
	quit;
%mend GetRxRiskForPeople;