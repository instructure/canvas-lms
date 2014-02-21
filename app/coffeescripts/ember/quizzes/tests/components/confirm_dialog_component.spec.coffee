define [
  'ember'
  '../start_app'
  'i18n!confirm_dialog'
  'jquery'
  'helpers/jquery.simulate'
  'jqueryui/dialog'
], (Ember, startApp, I18n, $) ->

  {run} = Ember
  component = null
  containerView = null
  stub = null
  App = null
  confirmButton = null
  cancelButton = null

  assertDialogClosed = ->
    ok $(component.$()).is(':hidden'), 'hides dialog'

  module "ConfirmDialogComponent",

    setup: ->
      App = startApp()
      run ->
        containerView = Ember.ContainerView.create container: App.__container__
        component = App.ConfirmDialogComponent.create
          container: App.__container__
          layout: Ember.TEMPLATES['components/confirm-dialog']
          title: 'ohi quiz'
        containerView.pushObject component
        containerView.appendTo '#fixtures'
        stub = sinon.stub component, 'sendAction'
      $el = component.$().dialog().data('dialog').uiDialog
      confirmButton = $ $el.find('.confirm-dialog-confirm-btn')
      cancelButton = $ $el.find('.confirm-dialog-cancel-btn')

    teardown: ->
      run ->
        component.destroy()
        App.destroy()

  test "closes when confirm button clicked", ->
    confirmButton.click()
    ok stub.calledWith 'on-confirm'
    assertDialogClosed()

  test "closes when cancel button clicked", ->
    cancelButton.click()
    ok stub.calledWith 'on-cancel'
    assertDialogClosed()

  test "closes when cancel button clicked by keyPress", ->
    cancelButton.simulate 'keypress', keyCode: $.ui.keyCode.ENTER
    ok stub.calledWith 'on-cancel'
    assertDialogClosed()

  test "closes when confirm button clicked by keyPress", ->
    confirmButton.simulate 'keypress', keyCode: $.ui.keyCode.ENTER
    ok stub.calledWith 'on-confirm'
    assertDialogClosed()

  test "throws an error unless you provide a title", ->
    throws ->
      run ->
        withoutTitle = App.ConfirmDialogComponent.create
          container: App.__container__
          layout: Ember.TEMPLATES['components/confirm-dialog']
        containerView.pushObject withoutTitle
    , /you must provide a title/i

  test "default texts", ->
    equal component.get('confirm-text'), I18n.t('ok', 'Ok'), 'default confirm-text'
    equal component.get('cancel-text'), I18n.t('cancel', 'Cancel'), 'default cancel-text'

  test "default actions", ->
    equal component.get('on-confirm'), 'confirm', 'default on-confirm'
    equal component.get('on-cancel'), 'cancel', 'dfeault on-cancel'
