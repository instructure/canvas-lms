define ['i18n!_core_en'], (I18n) ->
  allDayDefault: false
  fixedWeekCount: false
  timezone: window.ENV.TIMEZONE
  # We do our own caching with our EventDataSource, so there's no need for
  # fullcalendar to also cache.
  lazyFetching: false
  dragRevertDuration: 0

  # localization config
  # note: timeFormat && columnFormat change based on lang

  lang: window.ENV.FULLCALENDAR_LOCALE
