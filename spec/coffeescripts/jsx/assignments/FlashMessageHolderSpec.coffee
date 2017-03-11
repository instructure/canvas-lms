define [
  'react'
  'react-dom'
  'jsx/assignments/FlashMessageHolder'
  'jsx/assignments/store/configureStore'
], (React, ReactDOM, FlashMessageHolder, configureStore) ->


  QUnit.module 'FlashMessageHolder',
    setup: ->
      @props =
        time: 123
        message: ''
        error: false
        onError: ->
        onSuccess: ->

      @flashMessageHolder = ReactDOM.render(React.createElement(FlashMessageHolder, @props), document.getElementById('fixtures'))

    teardown: ->
      @props = null
      ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))


  test 'renders nothing', ->
    ok ReactDOM.findDOMNode(@flashMessageHolder) == null, 'nothing was rendered'

  test 'calls proper function when state is an error', ->
    called = false
    @props.error = true
    @props.message = 'error'
    @props.time = 125
    @props.onError = -> called = true
    ReactDOM.render(React.createElement(FlashMessageHolder, @props), document.getElementById('fixtures'))

    ok called, 'called error'


  test 'calls proper function when state is not an error', ->
    called = false
    @props.error = false
    @props.message = 'success'
    @props.time = 125
    @props.onSuccess = -> called = true
    ReactDOM.render(React.createElement(FlashMessageHolder, @props), document.getElementById('fixtures'))

    ok called, 'called success'

  test 'only updates when the new time is greater than the old time', ->
    called = false
    errCalled = false
    @props.error = false
    @props.message = 'random'
    @props.time = 1
    @props.onSuccess = -> called = true
    @props.onError = -> errCalled = true
    ReactDOM.render(React.createElement(FlashMessageHolder, @props), document.getElementById('fixtures'))



    ok !called, 'did not call the success function'
    ok !errCalled, 'did not call the error function'
