
data allgender;
input @3 ob @10 Gender $1. @20 Gender_Count @29 year $4.;
cards;
  1      F         1859     1988
  2      M         1318     1988
  3      F         1895     1989
  4      M         1356     1989
  5      F         1945     1990
  6      M         1374     1990
  7      F         1961     1991
  8      M         1387     1991
  9      F         1981     1992
 10      M         1399     1992
 proc print;
 
 proc gchart data=AllGender;
  hbar year/ subgroup=gender
  ;
 run;