/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* C:\Documents and Settings\pardre1\Desktop\stack_datasets.sas
*
* Examples code for collating results.
*********************************************/

%macro stack_datasets(inlib =, nom = , outlib = ) ;
  ** All input datasets live in inlib.
  ** All input dataset names begin with <<site abbreviation>>_ and end with the text passed in the nom parameter. ;
  ** This guy creates a big old UNION query against them all and then executes it to create a dataset named <<nom>> in the outlib library. ;
  ** So its a vertical stack as written. ;
  ** Note that you could also loop through the :dset macro vars it creates (in say, a SET statement) if you want a horizontal stacking. ;
  %do i = 1 %to 4 ;
    %put Working on &nom. ;
  %end ;

  proc sql noprint ;
    select memname as dset
         , 'select *, "' || substr(memname, 1, index(memname, "_") -1) || '" as site from sub.' || memname as sequel
         ,                  substr(memname, 1, index(memname, "_") -1) as site
    into   :dset1-:dset100
         , :union_stmt separated by ' UNION ALL CORRESPONDING '
         , :sitelist separated by ', '
    from dictionary.tables
    where libname = "%upcase(&inlib)" AND
          memname like '%' || "%upcase(&nom)"
    ;
    %let num_dsets = &SQLOBS ;

    reset feedback ;

    create table &outlib..&nom as
    &union_stmt
    ;
  quit ;

%mend stack_datasets ;

