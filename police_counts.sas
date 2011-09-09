/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\My Documents\vdw\macros\police_counts.sas
*
* Checks every dataset in &transfer_lib for a variable named
* COUNT.  If found, it checks whether any of the rows have
* counts lower than &lowest_count.  If there are any, the rows
* will be printed out to the lst file.
*
* If you want to have the macro actually recode those low
* counts, call it with the check_or_recode parameter set to R.
* If you do that and there are rows to recode, the macro will:
*
*   - create a new copy of the original dset called ::dataset
*     name::_ORIG, and
*
*   - replace COUNT and PERCENT variables with whatever you
*     specify in the &replace_with parameter.
*
* If you have it mask your low counts, PLEASE REMEMBER NOT TO
* SEND OFF THE _ORIG DATASETS!!!
*
*********************************************/

%macro police_counts(transfer_lib = , lowest_count = 5, check_or_recode = C, replace_with = .a) ;
  %local i ;
  %local j ;
  %local k ;

  %let check_or_recode = %upcase(&check_or_recode) ;
  %if &check_or_recode = C %then %do ;
    %** Nothing. ;
  %end ;
  %else %if &check_or_recode = R %then %do ;
    %** Nothing. ;
  %end ;
  %else %do ;
    %do j = 1 %to 10 ;
      %put ERROR!!! do not understand the check_or_recode parameter--that must be either [C]heck only, or [R]ecode and check. ;
    %end ;
    %goto bail ;
  %end ;

  proc sql noprint ;
    select trim(libname) || '.' || memname as dset
    into   :d1-:d999
    from dictionary.tables
    where libname = "%upcase(&transfer_lib)" AND
          memtype = 'DATA'
    ;
    %local num_dsets ;
    %let num_dsets = &sqlobs ;
  quit ;


  %if &num_dsets = 0 %then %do j = 1 %to 10 ;
    %put ERROR: NO DATASETS FOUND IN &transfer_lib!!!! ;
  %end ;

  %do i = 1 %to &num_dsets ;
    %local this_dset ;
    %let this_dset = &&d&i ;
    %put PC: Checking &this_dset for variables that seem to be counts. ;

    data working_on_dset_&i ;
      dset = "&this_dset" ;
      output ;
    run ;

    proc contents noprint data = &this_dset out = this_dset ;
    run ;
    ** proc print data = this_dset ; run ;
    proc sql noprint ;
      %local numeric ;
      %let numeric = 1 ;
      select name
      into :recodes separated by " = &replace_with, "
      from this_dset
      where type = &numeric and prxmatch("/(count|cnt|freq|frq|percent|pct)\s*$/i", name) gt 0
      ;
      select name
      into :countvar1-:countvar99
      from this_dset
      where type = &numeric and prxmatch("/(count|cnt|freq|frq)\s*$/i", name) gt 0
      ;
    quit ;

    %if &sqlobs > 0 %then %do ;
      %put PC: Found a COUNTish looking var (&countvar1) in &this_dset--checking for values between 1 and %eval(&lowest_count - 1). ;
      %local wh ;
      %let wh = where &countvar1 between 1 and (&lowest_count - 1) ;
      proc sql ;
        title "Counts lower than &lowest_count in &this_dset" ;
        select * from &this_dset
        &wh
        ;
        %if &sqlobs > 0 %then %do ;
          %if &check_or_recode eq R %then %do ;
            %put PC: Recoding the count and percent variables to &replace_with in &this_dset ;
            create table &this_dset._ORIG as select * from &this_dset ;
            %** Assuming that where there is COUNT there is also PERCENT--this is cheesey. ;
            update &this_dset
            set    &recodes = &replace_with
            &wh
            ;
          %end ;
        %end ;
        %else %put PC: No low counts found in &this_dset. ;
      quit ;
    %end ;
    %else %do ;
      %put PC: COUNTish variables not found in &this_dset.. ;
    %end ;
    %removedset(dset = this_dset) ;
  %end ;
%bail:
%mend police_counts ;

