/*
*Below is code that I have created in reponse to the request made at the Denver 2009 meeting for
 a macro to wrap code to the 80 byte length for Result_note in the Lab_Notes data set.
 Please try and break it.  (Shouldn't be too hard :o)
 I welcome your suggestions for improvement.  I hope to get this off my plate and out to all the
 site data managers by mid May.
 With all everyone has to do please let me know if you haven't gotten to this in a month.  We can
 probably extend...
 Specific questions that I have:
 1) What do you think of the list of default split characters?
 2) The input data set requires RowID, Type and Comment.  Do you see any problems with that?
    Should comment be called something else?
 3) Are comments in the code clear?  Do they need to be reworded?  Expanded?
 Thanks for your time and keep your chin up!
 Gwyn
 4/2010
*/

%macro wrap80(readDS,writeDS,addon_vars,split_at=" .;,?!");
  %*Determine libname and data set name of the data set being read;
  %if %index(readDS,".") %then %do;
    %let lib=scan(readDS,1,".");
    %let ds=scan(readDS,2,".");
  %end;
  %else %do;
    %let lib=work;
    %let ds=&readDS;
  %end;
  %*Determine type and length for the variables in the data set being read;
  proc sql;
    create table attribute1 as
    select upcase(name) as col_name, type, length
      from dictionary.columns
      where libname=%upcase("&lib") and (upcase(memname)=%upcase("&ds"))
      order by col_name;
  quit;
  %*Store length for COMMENT and type and length for ROWID in macro variables;
  data _null_;
    set attribute1;
    if col_name='COMMENT' then call symput('commentbytes',put(length,8.));
    else if col_name='ROWID' then do;
      call symput('rowid_length',put(length,8.));
  	if type='char' then call symput('rowid_type','$');
  	else call symput('rowid_type', ' ');
    end;
  run;
  %*Store the maximum size possible for two COMMENTs concatenated together in macro variable;
  %let commentbytes2=%eval(&commentbytes*2);
  %*This data step splits COMMENT at the last appropiate character before the maximum length
    of 80 is exceeded.  If no split character is found the comment is forced to split at 80 and
    a message is written to the log;
  data &writeDS(keep=rowid result_note type line &addon_vars);  *** <==> COMMENT OUT KEEP= WHEN TESTING;
    length RowID &rowid_type &rowid_length Result_Note $ 80 Type $ 1 Line 4 commentplus $ &commentbytes2 leftover $ &commentbytes2 ;
    Line=0;
    do until(last.type);
      set &readDS(keep=rowid type comment &addon_vars);
  	by rowid type;
      commentplus=left(trimn(left(leftover))||' '||comment);
      do while (substr(commentplus,80) ne '');
        split=80-indexc(reverse(substr(commentplus,1,80)),&split_at);
  	  trap=split;
  	  if split=80 then do;
          split=79; *no split_at character was found and split will be forced;
  		put 'No split character was found and split was forced at position 80. ' rowid= type= line=;
  		put comment=;
  		put;
  	  end;
  	  result_note=left(substr(commentplus,1,split+1));*add 1 to split ,otherwise split;
  	  commentplus=left(substr(commentplus,split+2));         *occurs in front of split character;
  	  Line+1;
  	  output;
  	  *if line gt 40 then stop;*** <==> UNCOMMENT SAFE GUARD FOR TESTING unless you like endless loops :o);
      end;
  	leftover=commentplus;
      if last.type and leftover ne '' then do;
        result_note=left(leftover);
        leftover='';
  	  Line+1;
  	  output;
      end;
    end;*until;
  run;
%mend wrap80;

