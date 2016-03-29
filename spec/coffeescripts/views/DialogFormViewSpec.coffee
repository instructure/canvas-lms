define [
  'jquery'
  'Backbone'
  'compiled/views/DialogFormView'
  'helpers/assertions'
  'helpers/util'
  'helpers/jquery.simulate'
], ($, Backbone, DialogFormView, assert, util) ->

  # global test vars
  server = null
  view = null
  model = null
  trigger = null

  # helpers
  openDialog = ->
    view.$trigger.simulate 'click'

  sendResponse = (method, json)->
    server.respond method, model.url, [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(json)]

  module 'DialogFormView',
    setup: ->
      @closeSpy = @spy DialogFormView::, 'close'
      server = sinon.fakeServer.create()
      model = new Backbone.Model id:1, is_awesome: true
      model.url = '/test'
      trigger = $('<button title="Edit Stuff" />').appendTo $('#fixtures')
      view = new DialogFormView
        model: model
        trigger: trigger
        template: ({is_awesome}) ->
          """
            <label><input
              type="checkbox"
              name="is_awesome"
              #{"checked" if is_awesome}
            > is awesome</label>
          """

    teardown: ->
      trigger.remove()
      server.restore()
      view.remove()

  test 'opening and closing the dialog with the trigger', ->
    assert.isHidden view.$el, 'before click'
    openDialog()
    assert.isVisible view.$el, 'after click'
    util.closeDialog()
    assert.isHidden view.$el, 'after dialog close'

  test 'submitting the form', ->
    openDialog()
    equal view.model.get('is_awesome'), true,
      'is_awesome starts true'
    view.$('label').simulate 'click'
    view.$('button[type=submit]').simulate 'click'
    sendResponse 'PUT', {id: 1, is_awesome: false}
    equal view.model.get('is_awesome'), false,
      'is_awesome is updated to false'
    assert.isHidden view.$el,
      'when form submission is complete'

  assertDialogTitle = (expected, message) ->
    dialogTitle = $('.ui-dialog-title:last').html()
    equal dialogTitle, expected, message

  test 'gets dialog title from tigger title', ->
    openDialog()
    assertDialogTitle trigger.attr('title'),
      "dialog title is taken from triggers title attribute"

  test 'gets dialog title from option', ->
    view.options.title = 'different title'
    openDialog()
    assertDialogTitle view.options.title,
      "dialog title is taken from triggers title attribute"

  test 'gets dialog title from trigger aria-describedby', ->
    trigger.removeAttr 'title'
    describer = $('<div/>', html: 'aria title', id: 'aria-describer').appendTo $('#fixtures')
    trigger.attr 'aria-describedby', 'aria-describer'
    openDialog()
    assertDialogTitle 'aria title',
      "dialog title is taken from triggers title attribute"
    describer.remove()

  test 'rendering', ->
    view.wrapperTemplate = -> 'wrapper:<div class="outlet"></div>'
    view.template = ({foo}) -> foo
    view.model.set 'foo', 'hello'
    equal view.$el.html(), '',
      "doesn't render until opened for the first time"
    openDialog()
    ok view.$el.html().match /wrapper/,
      "renders wrapper"
    equal view.$el.find('.outlet').html(), 'hello',
      "renders template into outlet"

  test 'closing the dialog calls view#close', ->
    openDialog()
    util.closeDialog()
    ok @closeSpy.called
