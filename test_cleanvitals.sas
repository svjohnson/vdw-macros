/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\CTRHS\Crn\S D R C\VDW\Macros\test_cleanvitals.sas
*
* <<purpose>>
*********************************************/

%include "\\home\pardre1\SAS\Scripts\remoteactivate.sas" ;

options linesize = 150 nocenter msglevel = i NOOVP formchar='|-++++++++++=|-/|<>*' dsoptions="note2err" NOSQLREMERGE ;

/***************************************************************************
* Parameters:
*   OutLib  = The library name you've already declared where you want output
*             you elect to save (Clean="Y", Dirty="Y") to go.
*   Clean   = "Y" outputs a table (in OutLib) with records deemed clean.
*             Any other value will not output this table.
*   Dirty   = "Y" outputs a table (in Outlib) with records deemed dirty.
*             along with DirtyReason, a text variable explaining why the record
*             is dirty.  Any other value will not output this file.
*   Report  = "Y" will do a freq tabulation on the dirty data by DirtyReason,
*             report misspecified variable lengths, and perform freq tables on
*             the clean data.
*             Any other value will suppress this calculation.
*   Limits  = "Y outputs a table called LIMITS (in Outlib) with only those
*             values in the vitals sign dataset that values compatible with life
*
* Programmer:
*   Tyler Ross
*   Center For Health Studies
*   (206) 287-2927
*   ross.t@ghc.org
*
* History:
*   Created January 8, 2007
**************************************************************************/
%CleanVitals(OutLib, Clean=N, Dirty=N, Report=Y, Limits=N);

