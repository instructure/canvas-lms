define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/ConfigurationFormXml'
], (React, ReactDOM, TestUtils, ConfigurationFormXml) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(ConfigurationFormXml, {
      name: data.name
      consumerKey: data.consumerKey
      sharedSecret: data.sharedSecret
      xml: data.xml
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  module 'ExternalApps.ConfigurationFormXml',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'isValid when not valid', ->
    data =
      name: ''
      consumerKey: ''
      sharedSecret: ''
      xml: ''
    component = renderComponent(data)
    ok !component.isValid()
    deepEqual component.state.errors, {
      name: 'This field is required'
      xml: 'This field is required'
    }

  test 'isValid when valid', ->
    data =
      name: 'My App'
      consumerKey: 'A'
      sharedSecret: 'B'
      xml: '<foo>bar</foo>'
    component = renderComponent(data)
    component.isValid()
    deepEqual component.state.errors, {}
