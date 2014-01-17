define ['ember', 'i18nObj'], (Ember, I18n) ->

  # http://emberjs.com/guides/templates/writing-helpers/
  # http://emberjs.com/api/classes/Ember.Handlebars.html

  Ember.Handlebars.helper 'tDateToString', (date, i18n_format) ->
    return '' unless date
    fmt = "date.formats.#{i18n_format}"
    I18n.l(fmt, date)
