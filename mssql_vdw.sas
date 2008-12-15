/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\mssql_vdw.sas
*
* Copies the vdw datafiles to the instance of mssql running on ctrhs-crn
*
*********************************************/

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' ;

/*
options COMAMID = TCP REMOTE = crnsas ;

%include '\\home\pardre1\SAS\SCRIPTS\sasntlogon.sas' ;
filename crnsas '\\ctrhs-sas\warehouse\remote\tcpwinbatch.scr';
signon crnsas ;
rsubmit ;
*/


/* libname mssql ODBC required = "DRIVER=SQL Server;Trusted_Connection=Yes;DATABASE=vdw;SERVER=mlt15t" BULKLOAD = YES DBCOMMIT = 1000 ; */
/* libname mssql ODBC required = "DRIVER=SQL Server;Trusted_Connection=Yes;DATABASE=vdw;SERVER=ctrhs-crn,1534" BULKLOAD = YES DBCOMMIT = 1000 ;*/
libname mssql ODBC required = "DRIVER=SQL Server;Trusted_Connection=Yes;DATABASE=vdw;SERVER=ctrhs-crn,1534" BULKLOAD = YES DBCOMMIT = 1000 ;

libname vdw "e:\vdw_data" ;

/*
proc sql ;
   create table tumor (id num(4) not null, site char(8)) ;
quit ;
*/

data dsets ;
input nom $20. ;
datalines ;
census2000
demog
dx
enroll
px
rx
tumor
utilization
vitalsigns
;

proc print ;

run ;

%macro DescribeTable(tname) ;
   describe table vdw.&tname ;
%mend DescribeTable ;

%macro MakeEmptyTable(tname) ;
   %put create table mssql.&tname like vdw.&tname ; ;
   drop table mssql.&tname ;
   create table mssql.&tname like vdw.&tname ;
   %* This does not work b/c odbc does not support alter tables... ;
   %* alter table mssql.&tname add primary key (id) ;
   %* connect to odbc as msql (required = "DRIVER=SQL Server;Trusted_Connection=Yes;DATABASE=vdw;SERVER=mlt15t") ;
   %* execute (alter table &tname alter column id int NOT NULL) by msql ;
   %* execute (alter table &tname add primary key (id)) by msql ;
   %* disconnect from msql ;
%mend MakeEmptyTable ;

%macro FillTable(tname) ;
   connect to odbc as msql (required = "DRIVER=SQL Server;Trusted_Connection=Yes;DATABASE=vdw;SERVER=ctrhs-crn,1534") ;
   execute (truncate table &tname) by msql ;
   * execute (drop table test&tname) by msql ;

   create table mssql.test&tname as
   select * from vdw.&tname
   ;


   %if %lowcase(&tname) = enroll %then %do ;
      execute (insert into enroll(MRN, enr_date, location, PrimryDr
                                 , PrmCrCln, MainNet, INS_Medicare
                                 , INS_Medicaid, INS_Commercial
                                 , INS_Privatepay, INS_Other, INS_BasicHealth)
               select  MRN, cast(cast(enr_month as varchar) + '/1/' + cast(enr_year as varchar) as datetime) as enr_date
                     , location, PrimryDr, PrmCrCln, MainNet, INS_Medicare, INS_Medicaid, INS_Commercial
                     , INS_Privatepay, INS_Other, INS_BasicHealth
               from testenroll) by msql ;

   %end ;
   %else %if %lowcase(&tname) = tumor %then %do ;

      execute(
               INSERT INTO TUMOR(idplan, mrn, DXDATE, Sequence, BDATE, IDReg, Race1, Race2, Race3,
               Race4, Race5, Hispanic, Tobacco, Gender, dxage, DXYear, ICDOsite, Laterality, Morph,
               Behav, Grade, Class, Analytic, StageAJ, StageGen, dcause, vital, DOD, DCnfrm, DSTZ,
               AJCC_Ed, DAJC1T_P, DAJC1N_P, DAJC1M_P, DAJC1T_C, DAJC1N_C, DAJC1M_C, DSRG_FAC, DRAD_FAC,
               DBCN_FAC, DCHM_FAC, DHRM_FAC, DIMM_FAC, DOTH_FAC, DNDI, DNDX, DTMRK1, DTMRK2, DTMRK3,
               CLN_STG, EOD, DT_SURG, DT_CHEMO, DT_HORM, DT_RAD, DT_BRM, DT_OTH, R_N_SURG, R_N_CHEMO,
               R_N_HORM, R_N_RAD, R_N_BRM, R_N_OTH, DSRG_SUM, DRAD_SUM, DBCN_SUM, DCHM_SUM, DHRM_SUM,
               DIMM_SUM, DOTH_SUM)
               SELECT DISTINCT idplan, mrn, DXDATE, Sequence, BDATE, IDReg, Race1, Race2, Race3,
               Race4, Race5, Hispanic, Tobacco, Gender, dxage, DXYear, ICDOsite, Laterality, Morph,
               Behav, Grade, Class, Analytic, StageAJ, StageGen, dcause, vital, DOD, DCnfrm, DSTZ,
               AJCC_Ed, DAJC1T_P, DAJC1N_P, DAJC1M_P, DAJC1T_C, DAJC1N_C, DAJC1M_C, DSRG_FAC, DRAD_FAC,
               DBCN_FAC, DCHM_FAC, DHRM_FAC, DIMM_FAC, DOTH_FAC, DNDI, DNDX, DTMRK1, DTMRK2, DTMRK3,
               CLN_STG, EOD, DT_SURG, DT_CHEMO, DT_HORM, DT_RAD, DT_BRM, DT_OTH, R_N_SURG, R_N_CHEMO,
               R_N_HORM, R_N_RAD, R_N_BRM, R_N_OTH, DSRG_SUM, DRAD_SUM, DBCN_SUM, DCHM_SUM, DHRM_SUM,
               DIMM_SUM, DOTH_SUM
               FROM TESTTUMOR
               where not (mrn = 'LLGW0MKGTH' and sequence = 60 and dxdate = '1976-07-15 00:00:00.000')

             ) by msql ;

   %end ;
   %else %if %lowcase(&tname) = rx %then %do ;
      %let smallint_limit = 32766 ;
      execute (INSERT INTO RX(MRN, RXDATE, NDC, RXSUP, RXAMT, RXMD, DRUGNAME, RXFILL, SOURCE)
               select MRN, RXDATE, NDC
                     , case when RXSUP < 0 then null else RXSUP end as RXSUP
                     , case when RXAMT < 0 then null when RXAMT > &smallint_limit then null else RXAMT end as RXAMT
                     , RXMD, DRUGNAME, RXFILL, SOURCE
               from testrx
              ) by msql ;
   %end ;
   %else %do ;
      execute (insert into &tname select * from test&tname) by msql ;
   %end ;

   execute (drop table test&tname) by msql ;

   disconnect from msql ;
%mend FillTable ;

%macro LoopDsets ;
   proc sql noprint feedback ;
      select nom into :dset1-:dset99
      from dsets
      where nom not in ('census2000', 'demog', 'dx', 'enroll', 'px', 'rx')
      ;
      %let num_dsets = &SQLOBS ;
      %do i = 1 %to &num_dsets ;
         %let this_dset = &&dset&i ;
         %put working on &this_dset ;
         %*MakeEmptyTable(&this_dset) ;
         %*DescribeTable(&this_dset) ;
         * reset noexec ;
         %FillTable(&this_dset) ;
      %end ;
   quit ;

%mend ;

* options obs = 2000 ;

run ;

proc sql noexec  ;
   * delete from mssql.census2000 ;
   connect to odbc as msql (required = "DRIVER=SQL Server;Trusted_Connection=Yes;DATABASE=vdw;SERVER=ctrhs-crn,1534") ;
   execute (truncate table census2000) by msql ;
   disconnect from msql ;
   %let var_list = mrn, geocode, medfamincome, education1, FAMINCOME1, FamPoverty, MEDHOUSINCOME, housincome1, houspoverty, fampoverty, education1, HOUSES_N, houses_own ;
   %*let var_list = mrn, geocode, medfamincome ;

   select houses_own, put(houses_own, best.) as unf
   from vdw.census2000
   where medfamincome is not null
   ;

   insert into mssql.census2000(&var_list)
   /* select mrn, geocode, medfamincome, education1, FAMINCOME1, FamPoverty, MEDHOUSINCOME, housincome1, houspoverty, fampoverty, education1, HOUSES_N, round(houses_own, .01) */
   select &var_list
   from vdw.census2000
   where medfamincome is not null
   ;

   * reset exec ;


quit ;

%LoopDsets ;

/*

endrsubmit ;
signoff crnsas ;
*/

endsas ;


proc sql ;
   create table mssql.rx as
   select *
   from vdw.rx
   ;

   create table mssql.enroll as
   select *
   from vdw.enroll
   ;

   create table mssql.utilization as
   select *
   from vdw.utilization
   ;

   create table mssql.px as
   select *
   from vdw.px
   ;

   create table mssql.dx as
   select *
   from vdw.dx
   ;

   create table mssql.tumor as
   select *
   from vdw.tumor
   ;
quit ;


endrsubmit ;
signoff crnsas ;
