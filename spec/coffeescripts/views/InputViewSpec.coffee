define [
  'Backbone'
  'jquery'
  'compiled/views/InputView'
], (Backbone, $, InputView) ->

  view = null

  QUnit.module 'InputView',
    setup: ->
      view = new InputView
      view.render()
      view.$el.appendTo $('#fixtures')

    teardown: ->
      view.remove()

  setValue = (term) ->
    view.el.value = term

  test 'updates the model attribute', ->
    view.model = new Backbone.Model
    setValue 'foo'
    view.updateModel()
    equal view.model.get('unnamed'), 'foo'

  test 'updates the collection parameter', ->
    view.collection = new Backbone.Collection
    setValue 'foo'
    view.updateModel()
    actual = view.collection.options.params.unnamed
    equal actual, 'foo'

  test 'gets modelAttribute from input name', ->
    input = $('<input name="couch">').appendTo $('#fixtures')
    view = new InputView
      el: input[0]
    equal view.modelAttribute, 'couch'

  test 'sets model attribute to empty string with empty value', ->
    view.model = new Backbone.Model
    setValue 'foo'
    view.updateModel()
    setValue ''
    view.updateModel()
    equal view.model.get('unnamed'), ''

  test 'deletes collection paramater on empty value', ->
    view.collection = new Backbone.Collection
    setValue 'foo'
    view.updateModel()
    equal view.collection.options.params.unnamed, 'foo'
    setValue ''
    view.updateModel()
    strictEqual view.collection.options.params.unnamed, undefined

