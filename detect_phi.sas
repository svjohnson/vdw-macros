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

*/

%macro check_dataset(dset =, obs_lim = max) ;
  %macro check_varname(regx, msg) ;
    create table possible_bad_vars as
    select name, label
    from these_vars
    where prxmatch("/(&regx)/i", name)
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
        retain mrn_regex_handle ;
        set &dset (obs = &obs_lim keep = &mrn_array) ;
        if _n_ = 1 then do ;
          mrn_regex_handle = prxparse("/&mrn_regex/") ;
        end ;
        array p &mrn_array ;
        do i = 1 to dim(p) ;
          if prxmatch(mrn_regex_handle, p{i}) then do ;
            badvar = vname(p{i}) ;
            badvalue = p{i} ;
            output ;
          end ;
          keep badvar badvalue ;
        end ;
      run ;
      proc sql ;
        insert into phi_warnings(dset, variable, warning)
        select distinct "&dset", badvar, "Contents match the pattern given for an MRN value."
        from __gnu ;
        drop table __gnu ;
      quit ;
    %end ;
  %mend check_vars_for_mrn ;

  proc contents noprint data = &dset out = these_vars ;
  run ;

  ** proc print data = these_vars ; run ;

  proc sql noprint ;
    create table phi_warnings (dset char(50), variable char(255), label char(255), warning char(200)) ;

    %check_varname(regx = mrn|hrn                                               , msg = %str(Name suggests this var may be an MRN, which is not supposed to move between VDW sites.)) ;
    %check_varname(regx = birth_date|BirthDate|DOB|BDate                        , msg = %str(Name suggests this var may be a date of birth.)) ;
    %check_varname(regx = SSN|SocialSecurityNumber|social_security_number|socsec, msg = %str(Name suggests this var may be a social security number.)) ;

    %if %symexist(locally_forbidden_varnames) %then %do ;
      %check_varname(regx = &locally_forbidden_varnames, msg = %str(May be on the locally defined list of variables not allowed to be sent to other sites.)) ;
    %end ;
  quit ;

  %check_vars_for_mrn(obs_lim = &obs_lim) ;

  proc sql noprint ;
    select count(*) as num_warns into :num_warns from phi_warnings ;

    %if :num_warns = 0 %then %do i = 1 %to 5 ;
      %put No obvious phi-like data elements in &dset.  BUT PLEASE INSPECT THE CONTENTS AND PRINTs CAREFULLY TO MAKE SURE OF THIS! ;
    %end ;
    %else %do ;
      reset print ;
      title1 "WARNINGS for dataset &dset:" ;
      select * from phi_warnings
      order by variable, warning
      ;
      title1 " " ;
    %end ;
    title1 "Dataset &dset" ;
    proc contents data = &dset varnum ;
    run ;

    proc print data = &dset (obs = 20) ;
    run ;

  quit ;

  %RemoveDset(dset = possible_bad_vars) ;
  %RemoveDset(dset = phi_warnings) ;
  %RemoveDset(dset = these_vars) ;

%mend check_dataset ;

%macro detect_phi(transfer_lib, obs_lim = max) ;
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

