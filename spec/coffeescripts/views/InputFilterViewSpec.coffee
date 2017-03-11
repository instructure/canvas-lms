define [
  'Backbone'
  'jquery'
  'compiled/views/InputFilterView'
  'helpers/jquery.simulate'
], (Backbone, $, InputFilterView) ->

  view = null
  clock = null

  QUnit.module 'InputFilterView',
    setup: ->
      clock = sinon.useFakeTimers()
      view = new InputFilterView
      view.render()
      view.$el.appendTo $('#fixtures')

    teardown: ->
      clock.restore()
      view.remove()

  setValue = (term) ->
    view.el.value = term

  simulateKeyup = (opts={}) ->
    view.$el.simulate 'keyup', opts
    clock.tick view.options.onInputDelay

  test 'fires input event, sends value', ->
    spy = @spy()
    view.on 'input', spy
    setValue 'foo'
    simulateKeyup()
    ok spy.called
    ok spy.calledWith 'foo'

  test 'does not fire input event if value has not changed', ->
    spy = @spy()
    view.on 'input', spy
    setValue 'foo'
    simulateKeyup()
    simulateKeyup()
    ok spy.calledOnce

  test 'updates the model attribute', ->
    view.model = new Backbone.Model
    setValue 'foo'
    simulateKeyup()
    equal view.model.get('filter'), 'foo'

  test 'updates the collection parameter', ->
    view.collection = new Backbone.Collection
    setValue 'foo'
    simulateKeyup()
    actual = view.collection.options.params.filter
    equal actual, 'foo'

  test 'gets modelAttribute from input name', ->
    input = $('<input name="couch">').appendTo $('#fixtures')
    view = new InputFilterView
      el: input[0]
    equal view.modelAttribute, 'couch'

  test 'sets model attribute to empty string with empty value', ->
    view.model = new Backbone.Model
    setValue 'foo'
    simulateKeyup()
    setValue ''
    simulateKeyup()
    equal view.model.get('filter'), ''

  test 'deletes collection paramater on empty value', ->
    view.collection = new Backbone.Collection
    setValue 'foo'
    simulateKeyup()
    equal view.collection.options.params.filter, 'foo'
    setValue ''
    simulateKeyup()
    strictEqual view.collection.options.params.filter, undefined

  test 'does nothing with model/collection when the value is less than the minLength', ->
    view.model = new Backbone.Model filter: 'foo'
    setValue 'ab'
    simulateKeyup()
    equal view.model.get('filter'), 'foo', 'filter attribute did not change'

  test 'does setParam false when the value is less than the minLength and setParamOnInvalid=true', ->
    view.model = new Backbone.Model filter: 'foo'
    view.options.setParamOnInvalid = true
    setValue 'ab'
    simulateKeyup()
    equal view.model.get('filter'), false, 'filter attribute is false'

  test 'updates filter with small number', ->
    view.model = new Backbone.Model filter: 'foo'
    view.options.allowSmallerNumbers = false
    setValue '1'
    simulateKeyup()
    equal view.model.get('filter'), 'foo', 'filter attribute did not change'
    view.options.allowSmallerNumbers = true
    setValue '2'
    simulateKeyup()
    equal view.model.get('filter'), '2', 'filter attribute did change'
