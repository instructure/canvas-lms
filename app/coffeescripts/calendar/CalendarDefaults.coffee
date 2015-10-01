define ['i18n!_core_en'], (I18n) ->
  allDayDefault: false
  fixedWeekCount: false
  timezone: window.ENV.TIMEZONE
  # We do our own caching with our EventDataSource, so there's no need for
  # fullcalendar to also cache.
  lazyFetching: false
  # Pulled calendar month and day translations from _core.js.
  monthNames: I18n.lookup('date.month_names')[1..12]
  monthNamesShort: I18n.lookup('date.abbr_month_names')[1..12]
  dayNames: I18n.lookup('date.day_names')
  dragRevertDuration: 0
  dayNamesShort: I18n.lookup('date.abbr_day_names')
