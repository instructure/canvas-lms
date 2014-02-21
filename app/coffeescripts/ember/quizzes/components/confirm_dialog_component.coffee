define [
  'ember'
  'jquery'
  'i18n!confirm_dialog'
  'jqueryui/dialog'
  'jqueryui/core'
  'compiled/jquery/fixDialogButtons'
], (Em, $, I18n) ->

  ###
  # All parameters except for title are optional.
  #
  # title: I18n'd title that is displayed as the dialog title.
  #
  # Defaults:
  #
  # on-confirm: Sends 'confirm' action.
  # on-cancel: Sends 'cancel' action.
  # cancel-text: I18n'd version of the word "Cancel"
  # confirm-text: I18n'd version of the word "Ok"
  #
  # Usage:
  #
  # {{#confirm-dialog
  #   on-confirm="myConfirmAction"
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

  CONFIRM_BTN = '.confirm-dialog-confirm-btn'
  CANCEL_BTN  = '.confirm-dialog-cancel-btn'

  ConfirmDialogComponent = Em.Component.extend

    '_destroyAction': '_destroyModal'

    # Defaults
    'on-confirm': 'confirm'
    'on-cancel': 'cancel'
    'confirm-text': I18n.t('ok', 'Ok')
    'cancel-text': I18n.t('cancel', 'Cancel')

    dialogize: (->
      unless @get('title')
        throw new Em.Error "You must provide a title to ConfirmDialogComponent!"
      @$().dialog
        autoOpen: false
        title: @get 'title'
        modal: true
        close: => @sendAction '_destroyAction'
      .fixDialogButtons()

      uiDialog = @$()
        .dialog('open')
        .data('dialog')
        .uiDialog

      uiDialog.focus()

      uiDialog.on 'keypress', (event) =>
        Em.run this, 'keyPress', event

      uiDialog.on 'click', CONFIRM_BTN, (event) =>
        Em.run this, 'closeAndConfirm'
        false

      uiDialog.on 'click', CANCEL_BTN, (event) =>
        Em.run this, 'closeAndCancel'
    ).on 'didInsertElement'

    _close: ->
      @$().dialog 'close'

    closeAndConfirm: ->
      @_close()
      @sendAction 'on-confirm'

    closeAndCancel: ->
      @_close()
      @sendAction 'on-cancel'

    destroyDialog: (->
      @$().data('dialog').uiDialog.off()
      @$().dialog 'destroy'
    ).on 'willDestroyElement'

    # Send the appropriate event when the enter key is pressed on the confirm
    # or cancel buttons.
    #
    # Will not block event propagation if the event target is not a button.
    keyPress: (event) ->
      return true unless event.keyCode is $.ui.keyCode.ENTER
      $target = $ event.target
      return true unless $target.is("button")
      if $target.hasClass CONFIRM_BTN.replace('.', '')
        @closeAndConfirm()
      else
        @closeAndCancel()

      false
