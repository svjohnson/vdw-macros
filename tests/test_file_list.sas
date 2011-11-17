options obs=max nosymbolgen nomprint nocenter;

/* Some sample data sets */
data
    Apr2011_KPNC_LabSum
    Apr2011_KPNC_OrdSum
    Apr2011_KPNW_LabSum
    Apr2011_KPNW_OrdSum
    May2011_KPGA_RxSum;

    dummy = 0;

    output;

run;

%include "\\mlt1q0\c$\Documents and Settings\pardre1\My Documents\vdw\macros\file_list.sas" ;


/* All data sets in work library */
%data_set_list(macvar=alldatasets)

/* All LabSum data sets, with IN= */
%data_set_list(library=work, macvar=labdatasets, in_prefix=in_,
               filter=memname contains 'LABSUM')

/* All Apr2011 OrdSum data sets */
%data_set_list(library=work, macvar=orddatasets, in_prefix=in_,
               filter=prxmatch('/^apr2011_.*ordsum/i', memname))
