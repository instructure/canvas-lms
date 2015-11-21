define ['i18n!_core_en', 'compiled/calendar/CalendarLocaleConverter'], (I18n, LocaleConverter) ->
  allDayDefault: false
  fixedWeekCount: false
  timezone: window.ENV.TIMEZONE
  # We do our own caching with our EventDataSource, so there's no need for
  # fullcalendar to also cache.
  lazyFetching: false
  dragRevertDuration: 0

  # localization config
  # note: timeFormat && columnFormat change based on lang

  lang: LocaleConverter.localeToLang(window.ENV.LOCALE)