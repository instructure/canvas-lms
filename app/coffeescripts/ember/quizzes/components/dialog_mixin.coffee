define [
  'ember'
  'jquery'
  'i18n!confirm_dialog'
  'jqueryui/dialog'
  'compiled/jquery/fixDialogButtons'
], (Ember, $, I18n) ->

  CONFIRM_BTN = '.confirm-dialog-confirm-btn'
  CANCEL_BTN  = '.confirm-dialog-cancel-btn'

  DialogMixin = Ember.Mixin.create
    # header element at the top of the page
    # Need to know this so we can decrease its z-index
    # so the overlay appears as correctly as possible
    headerElement: '#header'
    height: '500'
    width: '550'
    position:
      my: 'center'
      at: 'center'
      of: window
    'fix-dialog-buttons': true
    'confirm-text': I18n.t('submit', 'Submit')
    'cancel-text': I18n.t('cancel', 'Cancel')
    'on-submit': 'submit'

    # Default Destroy Action

    '_destroyAction': '_destroyModal'
    turnIntoDialog: (->
      unless @get('title')
        throw new Em.Error "You must provide a title to a Dialog Component!"
      $el = @$()
      $el.dialog
        autoOpen: false
        title: @get('title')
        modal: true
        height: @get('height')
        width: @get('width')
        fixDialogButtons: @get('fix-dialog-buttons')
        position: @get('position')
        close: => @sendAction('_destroyAction')

      @set("dialog", $el)

      uiDialog = $el
      .dialog('open')
      .data('dialog')
      .uiDialog

      @_moveWithinEmberAppScope($el, uiDialog)

      uiDialog.on 'keypress', (event) =>
        Em.run this, 'keyPress', event

      uiDialog.on 'click', CONFIRM_BTN, (event) =>
        Em.run this, 'closeAndConfirm'

      uiDialog.on 'click', CANCEL_BTN, (event) =>
        Em.run this, 'closeAndCancel'

    ).on 'didInsertElement'

    adjustDimensions: (->
      @get('dialog').dialog("option", "height", @get('height'))
      @get('dialog').dialog("option", "width",  @get('width'))
    ).observes('height', 'width')

    _close: ->
      @$().dialog 'close'

    # Need to move the element within the Ember app root element,
    # otherwise, things like {{action}} won't be handled by Ember.
    _moveWithinEmberAppScope: ($el, uiDialog) ->
      $overlay = $el.dialog().data('dialog').overlay.$el
      $overlay.css('position', 'fixed')
      rootElement = Em.get('App.rootElement' || '#content')
      $content = $ rootElement
      uiDialog.appendTo $content
      $overlay.appendTo $content
      uiDialog.position(@get('position'))
      uiDialog.focus()

      # Bring the "Courses", "Assignments", etc menu down in z-index
      # so the overlay doesn't get hidden by it.
      $('#header').css('z-index', '0')

    closeAndConfirm: ->
      @_close()
      @sendAction 'on-submit'
      false

    closeAndCancel: ->
      @_close()
      @sendAction 'on-cancel'
      false

    destroyDialog: (->
      Ember.$('#header').css 'z-index', '11'
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
