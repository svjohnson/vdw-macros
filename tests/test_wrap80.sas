/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
*
*
* test_wrap80.sas
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

libname t '\\ctrhs-sas\SASUser\pardre1\nlp' ;



/*
**The following two data steps create two test data sets - although I would love it if tests used real data!;
**234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890*234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890;
data testdata100;
  input rowid 101-104 type $ 106 comment $ 1-100 mrn $ 108-116 Test_Type $ 118-127;
  cards;
Now is the time for all good men to come to the aid of their country.  Whatwill, we do next about    123 N 987654321 K
this?  Perhaps I should just keep typing away?  No, no that would be boring.  I'm thinking of a      123 N 987654321 K
plan.  This line is too short.  I want some comments to flow over to the next line.                  123 N 987654321 K
We now need more data for a second person.                                                           234 N 123456789 HGBA1C
Third person...                                                                                      345 N 432143214 HGBA1C
dfasdasd, asdadasd, adasdadadad, adfdgfdfghfhjfhj, s fsdfsfsf, sfsfsfs, sf, sdfsgdhdhfjfj, dfgf      345 R 432143214 HGBA1C
klsdkjsdkf, sklsdkljsf,sd sdkjfkdglls slfl, kjdfjxcidikcjchjdhk, sd sdflisdf, sd sdf                 345 R 432143214 HGBA1C
run;
data testdata200;
  input rowid $ 201-204 type $ 206 comment $ 1-200 mrn $ 208-216 Test_Type $ 218-227;
  cards;
Now is the time for all good men to come to the aid of their country.  Whatwill, we do next about this?  Perhaps I should just keep typing away?  No, no that would be boring.  I'm thinking of a plan.  123 N 987654321 K
This line is too short.  I want some comments to flow over to the next line.                                                                                                                             123 N 987654321 K
We now need more data for a second person.                                                                                                                                                               234 N 123456789 HGBA1C
Third person...                                                                                                                                                                                          345 N 432143214 HGBA1C
dfasdasd, asdadasd, adasdadadad, adfdgfdfghfhjfhj, s fsdfsfsf, sfsfsfs, sf, sdfsgdhdhfjfj, dfgf klsdkjsdkf, sklsdkljsf,sd sdkjfkdglls slfl, kjdfjxcidikcjchjdhk, sd sdflisdf, sd sdfadd more             345 R 432143214 HGBA1C
not many breaks in this linekkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk,kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkP 345 R 432143214 HGBA1C
but there are breaks in this line la la la klsdfo8rjgfnsdiingfnvlitjoirjnirtlrjroooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo more breaks       345 R 432143214 HGBA1C
run;
*/

*The WRAP80 macro takes comments that are longer than 80 bytes and wraps them into
 the data set variable Result_Note which has a length of 80 bytes.  Additional observations
 are created as necessary.

*Since the maximum length for character variables = 32767 in any operating system this
 code will theoretically work for a comment variable with up to 16383 bytes storage;

*WRAP80 Macro Parameters ==>
  *  &readDS=data set that is being read and can be a permanent or temporary data set.
       This data set should have, at a minimum the variables ROWID, TYPE and COMMENT.
       COMMENT can be any length up to 16383 bytes.  It is assumed that the records are
       sorted by ROWID and TYPE with the COMMENTs in the desired order.
       COMMENT will be wrapped into RESULT_NOTE with 80 bytes of storage.  More records will
       be created as needed with breaks occurring at desired characters only.
       LINE, the fourth variable in the LAB_NOTES data set, will be calculated.
       This variable is a required positional parameter.

  *  &writeDS=data set being created and can be a permanent or temporary data set.
       This data set will contain ROWID, RESULT_NOTE, TYPE and LINE
       This variable is a required positional parameter.

  *  &addon_vars allows the user to keep additional site specific variables
       This variable is an optional positional parameter.;

 /*  &split_at=list of characters where split can occur in COMMENT to create Result_Note variable
       This variable is an optional keyword parameter and has a default value of blank . ; , ? and !
 */
;

%include '\\groups\data\CTRHS\Crn\S D R C\VDW\Macros\draft_WRAPnote80_20100401.sas' ;

data gnu ;
  set t.merged_path(obs = 10000 rename = (chsid = mrn diagdesc = comment)) ;
  rowid = _n_ ;
  type = 'R' ;
  test_type = 'path' ;
  keep rowid type comment mrn test_type ;
run ;

%wrap80(readDS = gnu, writeDS = s.wrap80_test) ;
