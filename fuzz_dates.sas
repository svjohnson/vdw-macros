/*********************************************
* Roy Pardee
* Center For Health Studies
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\Desktop\deleteme.sas
*
* <<purpose>>
*********************************************/

%macro commify(lst) ;
  %let re = %sysfunc(prxparse(s/\s+/", "/)) ;
  %upcase(%sysfunc(prxchange(&re, -1, "&lst")))
%mend commify ;

/*

  create xwalk by:
    union all desired dsets together, taking only id var.
    add a uniform(0) randy
    sort by randy.
    transform randy onto the desired scale for fuzz_days.

    MRN
    study_id
    fuzz_days.

  create dset of all columns in the indicated tables.
  select distinct table names into macro array for looping.

  for each table desired fuzzed:

    generate field lists w/selective fuzz transforms.

    create table <<fuzzed_table_name>> as
    select &field_list
    from <<unfuzzed table name>> as u INNER JOIN
         xwalk as x
    on  u.<<id_var>> = x.<<id_var>>
    ;

  next table


*/

%macro fuzz_dates(
          inlib       = /* libname where your to-be-fuzzed dsets live*/
        , outlib      = /* name of the libname where you want the fuzzed dsets */
        , dsets       = /* a space-delimited list of the dataset(s) whose dates you want fuzzed */
        , XWalk       = /* name you want for the xwalk dataset */
        , IdVar       = /* the id variable in common among the input datasets (which gets removed & replaced by a study_id) */
        , datevars    = /* a space-delimited list of the date variables you want fuzzed. Not all date vars are found in all datasets */
        , FuzzDays    = /* max number of days to add */
      ) ;

  proc sql noprint ;
    * Get names of the columns in the to-be-fuzzed tables. ;
    create table __all_columns as
    select memname as table_name, name as field_name, format as field_format, label as field_label
    from dictionary.columns
    where upcase(libname) = "%upcase(&inlib)" AND
          upcase(memname) in (%commify(&dsets)) AND
          upcase(name) NOT = %upcase("&IdVar")
    ;

    * Read the table names into a macro array. ;
    select distinct table_name
    into :tname1-:tname99
    from __all_columns
    ;

    %let num_tables = &sqlobs ;

    * Generate a UNION query to create our xwalk dset. ;
    select distinct "select &IdVar from &InLib.." || table_name
    into :union_statement separated by " union "
    from __all_columns
    ;

    * How long should our studyid be? ;
    %let studyid_digits = %eval(%length(&sqlobs) + 1) ;

    * Execute the UNION ;
    create table &xwalk as
    &union_statement
    ;

  quit ;

  * Add the fuzz_days var to xwalk. ;
  data &xwalk ;
    set &xwalk ;
    fuzz_days = 0 ;
    * Disallow values of 0 ;
    do while(fuzz_days = 0) ;
      randy = uniform(0) ;
    * fuzz_days = round(((30 - (- 30) + 1) * randy + (- 30)), 1) ; ;
    * fuzz_days = round(((&FuzzDays - (- &FuzzDays) + 1) * randy + (- &FuzzDays)), 1) ;
    * fuzz_days = round(((&fuzz_hi - &fuzz_lo + 1) * randy + &fuzz_lo), 1) ;
    * fuzz_days = ceil((2*&fuzzdays + 1)*uniform(0)) - (&fuzzdays + 1);
    fuzz_days = round(2 * (&FuzzDays+0.5) * randy - (&FuzzDays+0.5), 1.0) ;
    end ;
    label
      randy = "A random variable generated with uniform(0)--used to calculate fuzz_days."
      fuzz_days = "The constant added to the dates &datevars"
    ;
  run ;

  proc sort data = &xwalk ;
    by randy ;
  run ;

  data &outlib..&xwalk ;
    length study_id $ 10 ;
    set &xwalk ;
    study_id = put(_n_, z&studyid_digits..0) ;
    label
      study_id = "Arbitrary person identifier (randomly assigned)."
    ;
  run ;

  %* Now we loop through the tables, generating SELECT statements & writing the output dsets as necessary. ;

  %do i = 1 %to &num_tables ;
    %let this_table = &&tname&i ;

    %put Working on &this_table ;


    proc sql noprint feedback ;
      * Using intnx means that this should also work with datetimes. ;
      select  case
                when upcase(field_name) in (%commify(&datevars)) then
                  'intnx("day", ' || trim(field_name) || ', x.fuzz_days, "sameday") as ' || field_name || ' format = ' || field_format || ' label = "' || trim(field_label) || " (fuzzed +/- &fuzzdays days)"""
                else field_name
              end as var_name
      into :field_list separated by ', '
      from __all_columns
      where table_name = "&this_table" ;
      ;

      * Writed the fuzzed version. ;
      create table &outlib..&this_table._fuzzed as
      select study_id, &field_list
      from  &inlib..&this_table as u INNER JOIN
            &outlib..&xwalk as x
      on    u.&IdVar = x.&IdVar
      ;
    quit ;

  %end ;

%mend fuzz_dates ;
