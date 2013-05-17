require [
  'compiled/conversations/Inbox'
  'jquery.google-analytics'
], (Inbox) ->
  new Inbox(ENV.CONVERSATIONS)

  # Google Analytics
  $('#create_message_form').on 'click', 'div.token_input', (e) ->
    $.trackEvent('Compose Message', 'Select Recipient', 'Text Field')

  $('#create_message_form').on 'click', 'a.browser', (e) ->
    $.trackEvent('Compose Message', 'Select Recipient', 'Picker Button')

  $('body').on 'click', 'div.autocomplete_menu li.selectable', (e) ->
    label = if $(e.currentTarget).hasClass('context') then 'Course/Group' else 'User'
    $.trackEvent('Autocomplete', 'Click', label)

  $('#context_tags_filter').on 'click', 'div.token_input', (e) ->
    $.trackEvent('Filter', 'From/To', 'Text Field')

  $('#context_tags_filter').on 'click', 'a.browser', (e) ->
    $.trackEvent('Filter', 'From/To', 'Picker Button')
