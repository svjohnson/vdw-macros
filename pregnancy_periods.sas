/*********************************************
* Roy Pardee
* Group Health Research Institute
* (206) 287-2078
* pardee.r@ghc.org
*
* \\groups\data\ctrhs\crn\s d r c\vdw\macros\pregnancy_periods.sas
*
* First attempt at a macro that pulls pregnancy-related events from
* ute for a cohort and attempts to spit out periods during which they
* were probably pregnant.
*********************************************/

%macro get_preg_events(inset =
                      , start_date =
                      , end_date =
                      , out_events = pregnancy_events) ;

  %** This is a helper macro for pregnancy_periods below--you will almost always want to use that. ;

  %** I split this up in order to make testing easier. ;


  %** Obtain the list of pregnancy-related codes from the FTP server ;
  %** These lists are managed in: ;
  %** \\groups\data\ctrhs\crn\s d r c\vdw\macros\manage_pregnancy_codes.sas ;
  filename preg_ftp  FTP     "pregnancy_codes.xpt"
                     HOST  = "vdw.hmoresearchnetwork.org"
                     CD    = "/vdwcode"
                     PASS  = "%2hilario36"
                     USER  = "VDWReader"
                     DEBUG
                     rcmd  = 'binary'
                     ;
  libname preg_ftp xport ;

  proc copy in = preg_ftp out = work ;
  run ;

  libname preg_ftp clear ;

  proc format ;
    ** Translates v2 style codetype values to v3 px_codetypes. ;
    value $pct
      'C' = 'C4'
      'H' = 'H4'
      'I' = '09'
    ;
  quit ;

  %** Pull the events. ;
  proc sql ;
    create table dx as
    select d.mrn, adate, d.dx as event_code, descr as description, sigs as signifies
    from  &_vdw_dx as d INNER JOIN
          &inset as c
    on    d.mrn = c.mrn INNER JOIN
          preg_dx as p
    on    d.dx = p.dx
    where d.adate between "&start_date"d and "&end_date"d
    ;
    create table px as
    select p.mrn, adate, p.px as event_code, descr as description, sigs as signifies
    from  &_vdw_px as p INNER JOIN
          &inset as c
    on    p.mrn = c.mrn  INNER JOIN
          preg_px as pp
    on    p.px = pp.px AND
          p.px_codetype = put(pp.codetype, $pct.)
    where p.adate between "&start_date"d and "&end_date"d
    ;

    create table &out_events as
    select *, 'dx' as source from dx
    UNION ALL
    select *, 'px' as source from px
    ;

    drop table dx ;
    drop table px ;

  quit ;

  proc sort nodupkey data = &out_events ;
    by mrn adate signifies event_code ;
  run ;

%mend get_preg_events ;

%macro make_preg_periods(inevents = pregnancy_events
                      , out_periods =
                      , max_pregnancy_length = 270) ;

  %** Make episodes out of the events. ;
  proc format ;
    %** The set of codes has a type G that signifies testing events--this version of the macro does not ;
    %** take those into account. ;
    value $evnt
      'P'   = 'pregnant'
      'D'   = 'delivered'
      'M'   = 'miscarried'
      'S'   = 'stillborn'
      'T'   = 'terminated'
      other = 'zah?'
    ;

    value $daysb
      'D'       = '270'
      'M'       = '98'
      'S', 'T'  = '112'
      other     = 'zah?'
    ;
  quit ;


  proc sort data = &inevents out = all_events ;
    by mrn adate ;
    where put(signifies, $evnt.) ne 'zah?' ;
  run ;

  proc sort data = all_events out = terminating_events ;
    by mrn adate signifies event_code ;
    where put(signifies, $evnt.) in ('delivered', 'miscarried', 'stillborn', 'terminated') ;
  run ;

  ** Reduce to one terminating event per person/date. ;
  ** Putting signifies in the above sort means that deliveries are favored over miscarriages, miscars are favored over ;
  ** stills, and stills over terminations. ;
  data terminating_events ;
    set terminating_events ;
    by mrn adate ;
    if first.adate ;
  run ;

  proc sql ;
    ** Remove all events happening on a termination date. ;
    create table events as
    select a.*
    from  all_events as a LEFT JOIN
          terminating_events as t
    on    a.mrn = t.mrn AND
          a.adate = t.adate
    where t.mrn IS NULL
    ;
  quit ;

  ** In GH data we frequently had multiple termination events w/in a few days of one another (e.g., missed abortion on day 1, followed by d and c on day 3);
  ** Reduce any such to a single termining event. ;
  data terminating_events ;
    retain _last_adate . ;
    set terminating_events ;
    by mrn adate ;
    if not first.mrn then do ;
      if (adate - _last_adate) le 2 then delete ;
    end ;
    _last_adate = adate ;
    drop _last_adate ;
  run ;

  ** Put those termination dates back in. ;
  proc append base = events data = terminating_events ;
  run ;

  ** Re-do the sort. ;
  proc sort data = events ;
    by mrn adate ;
  run ;


  ** ...and now the fun begins. ;
  data __outeps ;
    length
      outcome_category  $ 10
      outcome_code      $ 8
      first_sign_code   $ 8
    ;
    retain
      preg_episode      0
      first_sign_date   .
      first_sign_code   ''
      preg_code_count   0
      _last_event_date  .
    ;
    set events ;
    by mrn ;


    ** New episodes happen when: ;
      ** this is the first record for a new woman. ;
      ** the immediately prior record for this woman ended a pregnancy episode (in which case the _last_event_date will be set to missing.) ;
      ** the date on this record is too far away from the last date for it to be the same pregnancy . ;

    if first.mrn then do ;
      _last_event_date = . ;
      preg_episode = 0 ;
    end ;

    days_since = adate - coalesce(_last_event_date, adate) ;

    new_episode = (first.mrn or
                   (n(_last_event_date) = 0 ) or
                   (days_since gt &max_pregnancy_length)
                   ) ;

    if new_episode then do ;
      ** If we have exceeded max_pregnancy_length we need to output a record w/what we know thus far for the previous episode. ;
      if days_since gt &max_pregnancy_length then do ;
        outcome_category = 'unknown' ;
        outcome_date = _last_event_date ;
        outcome_code = '' ;
        output ;
      end ;

      preg_episode + 1 ;

      ** reset vars ;
      first_sign_date   = .  ;
      first_sign_code   = '' ;
      status            = '' ;
      _last_event_date  = .  ;
      preg_code_count   = 0  ;

      ** if this rec signifies a pregnancy, then it is the first sign. ;
      select(put(signifies, $evnt.)) ;
        when('pregnant') do ;
          first_sign_date = adate ;
          first_sign_code = event_code ;
        end ;
        otherwise do ;
          ** nothing ;
        end ;
      end ;
    end ;

    ** Regardless of where we are in an episode, these things need to be done. ;
    outcome_date = adate ;

    select(put(signifies, $evnt.)) ;
      when('pregnant') do ;
        preg_code_count + 1 ;
        _last_event_date = adate ;

        ** Special-case: if the record for this woman ends w/a pregnant event, spit out whatever we know by now. ;
        if last.mrn then do ;
          outcome_code = '' ;
          outcome_category = 'unknown' ;
          output ;
        end ;

      end ;
      when('delivered', 'miscarried', 'stillborn', 'terminated') do ;
        ** End this episode. ;
        outcome_code = event_code ;
        outcome_category = put(signifies, $evnt.) ;
        probable_onset = adate - input(put(signifies, $daysb.), best.) ;
        output ;
        ** reset _last_event_date so we start a new episode on the next record for this woman.. ;
        _last_event_date = . ;
      end ;
    end ;
  run ;

  proc sql ;
    create table &out_periods as
    select mrn
         , preg_episode      label = "Ordinal counter for the pregancy episode for the woman."
         , probable_onset    label = "Likely onset of the pregnancy.  Imputed from the type of outcome--be skeptical for outcomes other than 'delivered'." format = mmddyy10.
         , first_sign_date   label = "Date of the first 'prenatal' type event attributable to this pregnancy." format = mmddyy10.
         , first_sign_code   label = "The first-ocurring event code (dx/px) for a 'prenatal' type event during this pregnancy."
         , outcome_date      label = "The date the pregnancy episode ended (e.g., birth/termination/miscarriage if that is the outcome, or last sign of pregnacy if outcome unknown)" format = mmddyy10.
         , outcome_code      label = "The event code (dx/px) for the event that ended this pregnancy."
         , outcome_category  label = "Type of pregnancy outcome."
         , preg_code_count   label = "The number of 'prenatal' type events found during this pregnancy."
    from __outeps
    order by mrn, outcome_date, preg_episode
    ;
  quit ;
%mend make_preg_periods ;

%macro pregnancy_periods(inset                 =
                        , out_periods          =
                        , start_date           = 01jan1966
                        , end_date             = &sysdate9
                        , out_events           = pregnancy_events
                        , max_pregnancy_length = 270) ;

  %** Broke this macro into two in order to facilitate testing. ;
  %get_preg_events(inset = &inset
                  , start_date = &start_date
                  , end_date = &end_date
                  , out_events = &out_events) ;


  %make_preg_periods(inevents = &out_events
                  , out_periods = &out_periods
                  , max_pregnancy_length = &max_pregnancy_length) ;


%mend pregnancy_periods ;
