define [
  'jquery'
  'compiled/views/InputFilterView'
  'helpers/jquery.simulate'
], ($, InputFilterView) ->

  view = null
  clock = null

  module 'InputFilterView',
    setup: ->
      clock = sinon.useFakeTimers()
      view = new InputFilterView
      view.render()
      view.$el.appendTo $('#fixtures')

    teardown: ->
      clock.restore()

  setValue = (term) ->
    view.el.value = term

  simulateKeyup = (opts={}) ->
    view.$el.simulate 'keyup', opts
    clock.tick view.options.onInputDelay

  test 'fires input event, sends value', ->
    spy = sinon.spy()
    view.on 'input', spy
    setValue 'foo'
    simulateKeyup()
    ok spy.called
    ok spy.calledWith 'foo'

  test 'does not fire input event if value has not changed', ->
    spy = sinon.spy()
    view.on 'input', spy
    setValue 'foo'
    simulateKeyup()
    simulateKeyup()
    ok spy.calledOnce

