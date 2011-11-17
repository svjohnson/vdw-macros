%macro data_set_list(
    library=work,
    macvar=data_set_list,   /* Name of macro variable in which to put list  */
    filter=1,               /* Data set name filter                         */
    order=1,                /* Default order is by name                     */
    in_prefix=,             /* If valued, create IN= data set option        */
    readpw=                 /* If there's a common read password            */
    );

    /* Make sure the output macro variable list exists */
    %global &MACVAR.;

    /* Get a list of data sets.  Could have used dictionary tables or ODS   */
    /* OUTPUT, but both of those methods may have bad side effects.         */
    proc datasets library=&LIBRARY. nolist nodetails
                %if %length(&READPW.) ne 0
                %then
                    %do;
                    read=&READPW.
                    %end;
                ;
        contents data=_all_ memtype=(data view) out=work._data_ noprint;
        run;
    quit;

    proc sql noprint;
        /* Filter and order the names and put into the macro variable.      */
        select distinct
            catt(
                "&LIBRARY..",
                memname
                %if %length(&IN_PREFIX.) ne 0
                %then
                    %do;
                    ,
                    catt(
                        " (in=&IN_PREFIX." ,
                        memname           ,
                        ')'
                        )
                    %end;
                )
        into
            :&MACVAR. separated by ' '
        from
            _last_
        where
            &FILTER.
        order by
            &ORDER.
        ;

        /* Drop the contents data set.   */
        drop table _last_;
    quit;

    /* Show what we got.  */
    %put INFO: &MACVAR.=&&&MACVAR.;

%mend data_set_list;
