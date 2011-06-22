/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* c:\Documents and Settings\pardre1\My Documents\vdw\macros\GetVarList.sas
*
* Getting ready to wean this thing off dictionary.columns, which causes
* problems when there are a crap-ton of tables in the defined libnames
* (e.g., a lib defined against a clarity db).
*********************************************/

%macro GetVarList(DSet         /* Name of the dset you want collapsed. */
                , RecStart     /* Name of the var that contains the period start dates. */
                , RecEnd       /* Name of the var that contains the period end dates. */
               , PersonID  = MRN   /* Name of the var that contains a unique person identifier. */
                ) ;

   %** This is also a helper macro for CollapsePeriods--it creates a global macro var ;
   %** containing a list of all vars in the input named dset *other than* the ones that ;
   %** define the start/end of each record. ;

   %** I dont know a good way of passing a return value out of a macro--so this is made global. ;
   %global VarList ;

   %** If we got just a one-part dset name for a WORK dataset, add the WORK libname explicitly. ;

   %if %index(&Dset, .) = 0 %then %do ;
      %let Dset = work.&Dset ;
   %end ;

   %**put Dset is &Dset ; ;

  %** This used to use a query to dictionary.columns to grab this info--huge. pain. in. the. ass. ;
  %** Dont use d.c--SAS is not a good citizen when you have libnames defined against RDBMSs. ;
  proc contents noprint data = &dset out = gnu ;
  run ;

  proc sql noprint ;
    ** describe table dictionary.columns ;
    select name
    into :VarList separated by ' '
    from gnu
    where upcase(name) not in (%upcase("&RecStart"), %upcase("&RecEnd"), %upcase("&PersonID")) ;

    drop table gnu ;
  quit ;

%mend GetVarList ;

