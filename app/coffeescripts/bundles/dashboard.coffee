require [
  'Backbone',
  'jquery',
  'i18n!dashboard'
  'compiled/registration/incompleteRegistrationWarning'
], ({View}, $, I18n, incompleteRegistrationWarning) ->

  if ENV.INCOMPLETE_REGISTRATION
    incompleteRegistrationWarning(ENV.USER_EMAIL)

  class DashboardView extends View

    el: document.body

    events:
      'click .stream_header': 'expandDetails'
      'click .stream-details': 'handleDetailsClick'

    expandDetails: (event) ->
      header   = $(event.currentTarget)
      details  = header.next('.details_container')
      expanded = details.attr('aria-expanded') == 'true'
      details.attr('aria-expanded', !expanded)
      details.toggle(!expanded)
      header.find('.toggle-details').text(
        if expanded
          I18n.t('show_more', 'Show More') + ' ▼'
        else
          I18n.t('show_less', 'Show Less') + ' ▲'
      )

    handleDetailsClick: (event) ->
      row = $(event.target).closest('tr')
      link = row.find('a')

  new DashboardView()
