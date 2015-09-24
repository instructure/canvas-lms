define [
  'react'
  'jsx/assignments/FlashMessageHolder'
  'jsx/assignments/store/configureStore'
], (React, FlashMessageHolder, configureStore) ->

  TestUtils = React.addons.TestUtils

  module 'FlashMessageHolder',
    setup: ->
      @props =
        time: 123
        message: ''
        error: false
        onError: ->
        onSuccess: ->

      @flashMessageHolder = React.render(FlashMessageHolder(@props), document.getElementById('fixtures'))

    teardown: ->
      @props = null
      React.unmountComponentAtNode(document.getElementById('fixtures'))


  test 'renders nothing', ->
    ok @flashMessageHolder.getDOMNode() == null, 'nothing was rendered'

  test 'calls proper function when state is an error', ->
    called = false
    @props.error = true
    @props.message = 'error'
    @props.time = 125
    @props.onError = -> called = true
    React.render(FlashMessageHolder(@props), document.getElementById('fixtures'))

    ok called, 'called error'


  test 'calls proper function when state is not an error', ->
    called = false
    @props.error = false
    @props.message = 'success'
    @props.time = 125
    @props.onSuccess = -> called = true
    React.render(FlashMessageHolder(@props), document.getElementById('fixtures'))

    ok called, 'called success'

  test 'only updates when the new time is greater than the old time', ->
    called = false
    errCalled = false
    @props.error = false
    @props.message = 'random'
    @props.time = 1
    @props.onSuccess = -> called = true
    @props.onError = -> errCalled = true
    React.render(FlashMessageHolder(@props), document.getElementById('fixtures'))



    ok !called, 'did not call the success function'
    ok !errCalled, 'did not call the error function'