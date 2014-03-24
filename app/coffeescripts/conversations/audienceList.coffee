define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/util/listWithOthers'
  'jquery.instructure_misc_helpers'
], (I18n, $, _, h, listWithOthers) ->

  format = (person) ->
    str = h(person.name)
    str = "<span class='active-filter'>#{str}</span>" if person.activeFilter
    $.raw str

  (audience, options={}) ->
    if options.highlightFilters
      audience = _.groupBy(audience, (user) -> user.activeFilter)
      audience = (audience[true] ? []).concat(audience[false] ? [])
    audience = (format(person) for person in audience)
  
    if audience.length == 0
      "<span>#{h(I18n.t('notes_to_self', 'Monologue'))}</span>"
    else
      listWithOthers(audience)
