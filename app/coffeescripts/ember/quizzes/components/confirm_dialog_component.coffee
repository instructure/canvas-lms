define [
  'ember'
  './dialog_mixin'
  'i18n!confirm_dialog_component'
], (Em, DialogMixin, I18n) ->

  ###
  # All parameters except for title are optional.
  #
  # title: I18n'd title that is displayed as the dialog title.
  #
  # Defaults:
  #
  # on-submit: Sends 'submit' action.
  # on-cancel: Sends 'cancel' action.
  # cancel-text: I18n'd version of the word "Cancel"
  # confirm-text: I18n'd version of the word "Ok"
  #
  # Usage:
  #
  # {{#confirm-dialog
  #   on-submit="myConfirmAction"
  #   on-cancel="myCancelAction"
  #   cancel-text=somePropertyWithI18nForCancellingTheAction
  #   title=myI18ndTitleProperty
  # }}
  #
  # {{#t "confirm_deletion_of_quiz"}}
  #   Are you sure you want to delete this quiz?
  #  {{/t}}
  #
  # {{/confirm-dialog}}
  #
  ###

  ConfirmDialogComponent = Em.Component.extend DialogMixin,
    'on-cancel': 'cancel'
    'confirm-text': I18n.t('ok', 'Ok')
