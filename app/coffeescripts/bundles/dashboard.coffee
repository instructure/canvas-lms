require [
  'underscore'
  'Backbone',
  'jquery',
  'i18n!dashboard'
  'compiled/registration/incompleteRegistrationWarning'
], (_, {View}, $, I18n, incompleteRegistrationWarning) ->

  if ENV.INCOMPLETE_REGISTRATION
    incompleteRegistrationWarning(ENV.USER_EMAIL)

  class DashboardView extends View

    el: document.body

    events:
      'click .stream_header': 'expandDetails'
      'click .stream-details': 'handleDetailsClick'
      'beforeremove': 'updateCategoryCounts' # ujsLinks event

    expandDetails: (event) ->
      header   = $(event.currentTarget)
      details  = header.next('.details_container')
      expanded = details.attr('aria-expanded') == 'true'
      details.attr('aria-expanded', !expanded)
      details.toggle(!expanded)
      text = if expanded
               I18n.t('show_more', 'Show More') + ' ▼'
             else
               I18n.t('show_less', 'Show Less') + ' ▲'
      header.find('.toggle-details').text text

    handleDetailsClick: (event) ->
      row = $(event.target).closest('tr')
      link = row.find('a')

    # TODO: switch recent items to client rendering and skip all this
    # ridiculous dom manip that is likely to just get worse
    updateCategoryCounts: (event) ->
      parent = $(event.target).closest('li[class^=stream-]')
      items = parent.find('tbody tr').filter(':visible')
      if items.length
        parent.find('.count').text items.length
      else
        parent.remove()

  new DashboardView

