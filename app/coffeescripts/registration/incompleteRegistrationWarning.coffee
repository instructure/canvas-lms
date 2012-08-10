define [
  'jquery'
  'i18n!registration'
  'jst/registration/incompleteRegistrationWarning'
], ($, I18n, template) ->
  (email) ->
    $(template(email: email)).
      appendTo($('body')).
      dialog
        title: I18n.t('welcome_to_canvas', 'Welcome to Canvas!')
        width: 400
        resizable: false
        buttons: [
          text: I18n.t('get_started', 'Get Started')
          click: -> $(this).dialog('close')
          class: 'btn-primary'
        ]
