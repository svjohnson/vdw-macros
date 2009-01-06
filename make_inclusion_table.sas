/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\make_inclusion_table.sas
*
* <<purpose>>
*********************************************/

%macro make_inclusion_table(cohort = ) ;
  libname __d "&_DemographicLib" access = readonly ;
  %local demog ;
  %let demog = __d.&_DemographicData ;

  proc format ;
    value $Hispani
      'Y' = '1 Hispanic or Latino'
      'N' = '2 Not Hispanic or Latino'
      ' '
      , ''
      , Missing = '3 Unknown (Individuals not reporting ethnicity)'
    ;
    value $Gender
      'M' = 'Males'
      'F' = 'Females'
      Other = 'Unknown or Not Reported'
    ;

    /*
    I would love it if someone could check my geography here--I am especially
    unsure of the Native Hawaiian or Other Pac Islander category.
    */
    value $Race
      '01' = '5 White'
      '02' = '4 Black or African American'
      '03' = '1 American Indian/Alaska Native'
      '04'
      , '05'
      , '06'
      , '08'
      , '09'
      , '10'
      , '11'
      , '12'
      , '13'
      , '14'
      , '96' = '2 Asian'
        '07'
      , '20'
      , '21'
      , '22'
      , '25'
      , '26'
      , '27'
      , '28'
      , '30'
      , '31'
      , '32'
      , '97' = '3 Native Hawaiian or Other Pacific Islander'
        '-1' = '6 More than one race'
      Other = '7 Unknown or Not Reported'
    ;
  quit ;

  * TODO: the macro should check for the presence of gender, race1 and hispanic, and only pull them if necessary. ;
  proc sql ;
    create table _reportable as
    select d.mrn, d.race1 as race label = "Racial Category"
          , d.hispanic label = "Ethnic Category"
          , d.gender label = "Sex/Gender"
    from &demog as d INNER JOIN
         &cohort as c
    on    d.mrn = c.mrn
    ;

    create table genders (gender char(1)) ;
    insert into genders(gender) values ('F') ;
    insert into genders(gender) values ('M') ;
    insert into genders(gender) values ('U') ;

    create table races(race char(2)) ;
    insert into races(race) values ('01') ;
    insert into races(race) values ('02') ;
    insert into races(race) values ('03') ;
    insert into races(race) values ('04') ;
    insert into races(race) values ('  ') ;
    insert into races(race) values ('97') ;
    insert into races(race) values ('-1') ;

    create table ethnicities(hispanic char(1)) ;
    insert into ethnicities(hispanic) values('Y') ;
    insert into ethnicities(hispanic) values('N') ;
    insert into ethnicities(hispanic) values(' ') ;

    create table class_levels as
    select gender, race, hispanic
    from genders CROSS JOIN races CROSS JOIN ethnicities ;

  quit ;

  title1 "Inclusion Enrollment Report" ;

  title2 "PART A TOTAL ENROLLMENT REPORT" ;
  proc tabulate data = _reportable missing format = comma15.0 order = formatted classdata = class_levels ;
    class hispanic race gender ;
    keylabel N = ' ' ;
    tables hispanic all='Total of all subjects:', gender all = 'Total' / printmiss misstext = '0' box = 'Ethnic Category' ;
    tables race     all='Total of all subjects:', gender all = 'Total' / printmiss misstext = '0' box = 'Racial Categories' ;
    format race $race. hispanic $hispani. gender $gender. ;
  quit ;

  title2 "PART B HISPANIC ENROLLMENT REPORT" ;
  proc tabulate data = _reportable missing format = comma15.0 order = formatted  classdata = class_levels ;
    class hispanic race gender ;
    keylabel N = ' ' ;
    tables race all='Total of Hispanics or Latinos:', gender all = 'Total' / printmiss misstext = '0' box = 'Racial Categories' ;
    format race $race. hispanic $hispani. gender $gender. ;
    where put(hispanic, $hispani.) = '1 Hispanic or Latino' ;
  quit ;

  libname __d clear ;

%mend make_inclusion_table ;

