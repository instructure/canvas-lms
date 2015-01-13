define ['i18n!_core_en'], (I18n) ->
  weekMode: 'variable'
  allDayDefault: false
  # In order to display times in the time zone configured in the user's profile,
  # and NOT the system timezone, we tell fullcalendar to ignore timezones and
  # give it Date objects that have had times shifted appropriately.
  ignoreTimezone: true
  # We do our own caching with our EventDataSource, so there's no need for
  # fullcalendar to also cache.
  lazyFetching: false
  # Pulled calendar month and day translations from _core.js.
  monthNames: I18n.lookup('date.month_names')[1..12]
  monthNamesShort: I18n.lookup('date.abbr_month_names')[1..12]
  dayNames: I18n.lookup('date.day_names')
  dayNamesShort: I18n.lookup('date.abbr_day_names')
