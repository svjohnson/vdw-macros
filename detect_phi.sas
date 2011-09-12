/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\detect_phi.sas
*
* Macros for inspecting to-be-transferred datasets for obvious
* Protected Health Information (PHI), and sounding an alarm if any is
* found.
*
* NOT INTENDED TO BE A SUBSTITUTE FOR HUMAN INSPECTION!!!
*
*********************************************/

/*

  Things to check for:
    Var names:
      MRN
      birth_date
      BirthDate
      DOB
      BDate
      SSN
      SocialSecurityNumber
      social_security_number
      socsec

      Anything on a comma-delimited list of locally-specified vars to check (e.g., consumno, hrn).

    Content checks:
      Any char vars > 6 long should be evaulated w/a site-specified regular expression as a check for MRN-type identifiers.
      Anything thats a date (based on format as reported by proc contents) should be evaluated as if it were a DOB.  Would anybody be
      over age 85?  If so--report.
        (right?)

    Output should be:
      - warnings
      - proc contents
      - proc print obs = 20
      - repeat of warnings

      Can we do some styling depending on whether a given dset is warning-worthy, to make particular bits of output jump out?

  To-do:
    date checks
      sensitive age is 89, but make that a defaulted parameter
    banner with warning

*/

%macro check_dataset(dset =, obs_lim = max, eldest_age = 89) ;
  %macro check_varname(regx, msg) ;
    create table possible_bad_vars as
    select name, label
    from these_vars
    where prxmatch(compress("/(&regx)/i"), name)
    ;

    %if &sqlobs > 0 %then %do ;
      insert into phi_warnings(dset, variable, label, warning)
      select "&dset" as dset, name, label, "&msg"
      from possible_bad_vars
      ;
    %end ;

  %mend check_varname ;

  %macro check_vars_for_mrn(length_limit = 6, obs_lim = max) ;
    %local char ;
    %let char = 2 ;
    proc sql noprint ;
      select name
      into :mrn_array separated by ' '
      from these_vars
      where type = &char and length ge &length_limit
      ;
    quit ;
    %if &sqlobs > 0 %then %do ;
      %put Checking these vars for possible MRN contents: &mrn_array ;
      data __gnu ;
        retain
          mrn_regex_handle
          badcount
        ;
        set &dset (obs = &obs_lim keep = &mrn_array) ;
        if _n_ = 1 then do ;
          mrn_regex_handle = prxparse("/&mrn_regex/") ;
          badcount = 0 ;
        end ;
        array p &mrn_array ;
        do i = 1 to dim(p) ;
          if prxmatch(mrn_regex_handle, p{i}) then do ;
            badvar = vname(p{i}) ;
            badvalue = p{i} ;
            badcount = _n_ ;
            output ;
          end ;
          keep badvar badvalue badcount ;
        end ;
      run ;
      proc sql noprint ;
        select compress(put(max(badcount), best.))
        into :badcount
        from __gnu
        ;
        insert into phi_warnings(dset, variable, warning)
        select distinct "&dset", badvar, "Could this var hold MRN values?  Contents of &badcount records match the pattern given for MRN values.  MRNs should never move across sites."
        from __gnu ;
        drop table __gnu ;
      quit ;
    %end ;
  %mend check_vars_for_mrn ;

  %macro check_vars_for_oldsters(eldest_age = 89, obs_lim = max) ;
    %local dtfmts ;
    %let dtfmts = 'B8601DA','B8601DN','B8601DT','B8601DZ','B8601LZ','B8601TM','B8601TZ','DATE','DATEAMPM','DATETIME','DAY','DDMMYY',
                  'DDMMYYB','DDMMYYC','DDMMYYD','DDMMYYN','DDMMYYP','DDMMYYS','DOWNAME','DTDATE','DTMONYY','DTWKDATX','DTYEAR',
                  'DTYYQC','E8601DA','E8601DN','E8601DT','E8601DZ','E8601LZ','E8601TM','E8601TZ','HHMM','HOUR','JULDAY','JULIAN',
                  'MMDDYY','MMDDYYB','MMDDYYC','MMDDYYD','MMDDYYN','MMDDYYP','MMDDYYS','MMSS','MMYY','MMYY','MONNAME','MONTH','MONYY',
                  'PDJULG','PDJULI','QTR','QTRR','WEEKDATE','WEEKDATX','WEEKDAY','WEEKU','WEEKV','WEEKW','WORDDATE','WORDDATX',
                  'YEAR','YYMM','YYMMC','YYMMD','YYMMN','YYMMP','YYMMS','YYMMDD','YYMMDDB','YYMMDDC','YYMMDDD','YYMMDDN','YYMMDDP',
                  'YYMMDDS','YYMON','YYQ','YYQC','YYQD','YYQN','YYQP','YYQS','YYQR','YYQRC','YYQRD','YYQRN','YYQRP','YYQRS' ;

    %local num ;
    %let num = 1 ;

    proc sql noprint ;
      select name
      into :dat_array separated by ' '
      from these_vars
      where type = &num and format in (&dtfmts)
      ;
    quit ;
    %if &sqlobs > 0 %then %do ;
      %put Checking these vars for possible DOB contents: &dat_array ;
      data __gnu ;
        set &dset (obs = &obs_lim keep = &dat_array) ;
        array d &dat_array ;
        do i = 1 to dim(d) ;
          if n(d{i}) then maybe_age = %calcage(bdtvar = d{i}, refdate = "&sysdate9."d) ;
          if maybe_age ge &eldest_age then do ;
            badvar = vname(d{i}) ;
            badvalue = d{i} ;
            output ;
          end ;
          keep badvar badvalue maybe_age ;
        end ;
      run ;
      proc sql outobs = 30 nowarn ;
        insert into phi_warnings(dset, variable, warning)
        select distinct "&dset", badvar, "If this is a birth date, at least one person is " || compress(put(maybe_age, best.)) || " years old, which means this record is PHI."
        from __gnu ;
        drop table __gnu ;
      quit ;
    %end ;
  %mend check_vars_for_oldsters ;

  proc contents noprint data = &dset out = these_vars ;
  run ;

  ** proc print data = these_vars ; run ;

  proc sql noprint ;
    create table phi_warnings (dset char(50), variable char(255), label char(255), warning char(200)) ;

    %check_varname(regx = mrn|hrn                                               , msg = %str(Name suggests this var may be an MRN, which should never move across sites.)) ;
    %check_varname(regx = birth_date|BirthDate|DOB|BDate                        , msg = %str(Name suggests this var may be a date of birth.)) ;
    %check_varname(regx = SSN|SocialSecurityNumber|social_security_number|socsec, msg = %str(Name suggests this var may be a social security number.)) ;

    %if %symexist(locally_forbidden_varnames) %then %do ;
      %check_varname(regx = &locally_forbidden_varnames, msg = %str(May be on the locally defined list of variables not allowed to be sent to other sites.)) ;
    %end ;



  quit ;

  %check_vars_for_mrn(obs_lim = &obs_lim) ;
  %check_vars_for_oldsters(obs_lim = &obs_lim, eldest_age = &eldest_age) ;

  proc sql noprint ;
    select count(*) as num_warns into :num_warns from phi_warnings ;

    %if :num_warns = 0 %then %do i = 1 %to 5 ;
      %put No obvious phi-like data elements in &dset.  BUT PLEASE INSPECT THE CONTENTS AND PRINTs CAREFULLY TO MAKE SURE OF THIS! ;
    %end ;
    %else %do ;
      reset print ;
      title3 "WARNINGS for dataset &dset:" ;
      select variable, warning from phi_warnings
      order by variable, warning
      ;
      quit ;

      title3 " " ;
    %end ;
    title1 "Dataset &dset" ;
    proc contents data = &dset varnum ;
    run ;
/*
    proc print data = &dset (obs = 20) ;
    run ;
*/
    proc sql number ;
      select *
      from &dset (obs = 20)
      ;
    quit ;

  quit ;

  %RemoveDset(dset = possible_bad_vars) ;
  %RemoveDset(dset = phi_warnings) ;
  %RemoveDset(dset = these_vars) ;

%mend check_dataset ;

%macro detect_phi(transfer_lib, obs_lim = max, eldest_age = 89) ;

   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put Macro detect_phi: ;
   %put ;
   %put Checking all datasets found in %sysfunc(pathname(&transfer_lib)) for the following signs of PHI: ;
   %put   - Variable names signifying sensitive items like 'MRN', 'birth_date', 'SSN' and so forth. ;
   %put   - Variable names on the list defined in the standard macro variable locally_forbidden_varnames (here those names are: &locally_forbidden_varnames). ;
   %put   - Contents of CHARACTER variables that match the pattern given in the standard macro variable mrn_regex (here that var is &mrn_regex) ;
   %put     Please note that numeric variables ARE NOT CHECKED FOR MRN-LIKE CONTENT. ;
   %put   - The contents of date variables (as divined by their formats) for values that, if they were DOBs, would indicate a person older than &eldest_age years. ;
   %put ;
   %put THIS IS BETA SOFTWARE-PLEASE SCRUTINIZE THE RESULTS AND REPORT PROBLEMS TO pardee.r@ghc.org. ;
   %put ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put THIS MACRO IS NOT A SUBSTITUTE FOR HUMAN INSPECTION AND THOUGHT--PLEASE CAREFULLY INSPECT ALL VARIABLES--WHETHER ;
   %put OR NOT THEY TRIP A WARNING--TO MAKE SURE THE DATA COMPORTS WITH YOUR DATA SHARING AGREEMENT!!! ;
   %put ;
   %put ;
   %put ============================================================== ;
   %put ;
   %put ;

  title1 "PHI-Detection Report for the datasets in %sysfunc(pathname(&transfer_lib))." ;
  title2 "please inspect all output carefully to make sure it comports with your data sharing agreement!!!" ;

  proc sql noprint ;
    ** describe table dictionary.tables ;

    select trim(libname) || '.' || memname as dset
    into   :d1-:d999
    from dictionary.tables
    where libname = "%upcase(&transfer_lib)" AND
          memtype = 'DATA'
    ;
    %local num_dsets ;
    %let num_dsets = &sqlobs ;
  quit ;

  %local i ;

  %if &num_dsets = 0 %then %do i = 1 %to 10 ;
    %put ERROR: NO DATASETS FOUND IN &transfer_lib!!!! ;
  %end ;

  %do i = 1 %to &num_dsets ;
    %put about to check &&d&i ;
    %check_dataset(dset = &&d&i, obs_lim = &obs_lim) ;
  %end ;

%mend detect_phi ;

