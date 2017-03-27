# This file is to add the methods that depend on 'compiled/util/fcUtil'
# as registered handelbars helpers. These are not in app/coffeescripts/handlebars_helpers.coffee
# because otherwise everypage would load fullcalendar.js (which fcUtil depends on).
# So anything that depends on these helpers in their handlbars needs to make sure
# to require this file first, so they are available as helpers.

define [
  'timezone'
  'compiled/util/fcUtil'
  'handlebars/runtime'
], (tz, fcUtil, {default: Handlebars}) ->

  Handlebars.registerHelper name, fn for name, fn of {

    # convert a moment to a string, using the given i18n format in the date.formats namespace
    fcMomentToDateString : (date = '', i18n_format) ->
      return '' unless date
      tz.format(fcUtil.unwrap(date), "date.formats.#{i18n_format}")

    # convert a moment to a time string, using the given i18n format in the time.formats namespace
    fcMomentToString : (date = '', i18n_format) ->
      return '' unless date
      tz.format(fcUtil.unwrap(date), "time.formats.#{i18n_format}")
  }

  return Handlebars
