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

   /*

   Dictionary.Columns is a dynamically-created dataset, consisting of one row per
   variable per dataset, in all of the currently defined libraries.

   My understanding is that sas will only create this 'table' if you issue
   a query against it.

   There can be ersatz errors caused by the creation of this table when there
   are sql views contained in a defined libname whose source tables
   are not resolvable.

   Dictionary.columns looks like this:

   create table DICTIONARY.COLUMNS
  (
   libname  char(8)     label='Library Name',
   memname  char(32)    label='Member Name',
   memtype  char(8)     label='Member Type',
   name     char(32)    label='Column Name',
   type     char(4)     label='Column Type',
   length   num         label='Column Length',
   npos     num         label='Column Position',
   varnum   num         label='Column Number in Table',
   label    char(256)   label='Column Label',
   format   char(16)    label='Column Format',
   informat char(16)    label='Column Informat',
   idxusage char(9)     label='Column Index Type'
  );

   */

   %** If we got just a one-part dset name for a WORK dataset, add the WORK libname explicitly. ;

   %if %index(&Dset, .) = 0 %then %do ;
      %let Dset = work.&Dset ;
   %end ;

   %**put Dset is &Dset ; ;

   proc sql noprint ;
      ** describe table dictionary.columns ;
      select name
      into :VarList separated by ' '
      from dictionary.columns
      where memtype ne 'VIEW' AND
            upcase(compress(libname || '.' || memname)) = %upcase("&Dset") AND
            upcase(name) not in (%upcase("&RecStart"), %upcase("&RecEnd"), %upcase("&PersonID")) ;
   quit ;

%mend GetVarList ;

