define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/ConfigurationFormUrl'
], (React, ReactDOM, TestUtils, ConfigurationFormUrl) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(ConfigurationFormUrl,{
      name: data.name
      consumerKey: data.consumerKey
      sharedSecret: data.sharedSecret
      configUrl: data.configUrl
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  module 'ExternalApps.ConfigurationFormUrl',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'isValid when not valid', ->
    data =
      name: ''
      consumerKey: ''
      sharedSecret: ''
      configUrl: ''
    component = renderComponent(data)
    ok !component.isValid()
    deepEqual component.state.errors, {
      name: 'This field is required'
      configUrl: 'This field is required'
    }

  test 'isValid when valid', ->
    data =
      name: 'My App'
      consumerKey: 'A'
      sharedSecret: 'B'
      configUrl: 'http://google.com'
    component = renderComponent(data)
    ok component.isValid()
    deepEqual component.state.errors, {}
