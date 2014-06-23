define ['ember', 'i18nObj', 'jquery', 'jquery.instructure_date_and_time'], (Ember, I18n, $) ->

  # http://emberjs.com/guides/templates/writing-helpers/
  # http://emberjs.com/api/classes/Ember.Handlebars.html

  Ember.Handlebars.helper 'tDateToString', (date, i18n_format) ->
    return '' unless date
    fmt = "date.formats.#{i18n_format}"
    I18n.l(fmt, date)

  Ember.Handlebars.helper 'friendlyDatetime', (time) ->
    return '' unless time
    $.friendlyDatetime time
