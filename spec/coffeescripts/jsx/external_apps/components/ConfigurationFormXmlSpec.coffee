define [
  'react'
  'jsx/external_apps/components/ConfigurationFormXml'
], (React, ConfigurationFormXml) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    ConfigurationFormXml({
      name: data.name
      consumerKey: data.consumerKey
      sharedSecret: data.sharedSecret
      xml: data.xml
    })

  renderComponent = (data) ->
    React.renderComponent(createElement(data), wrapper)

  module 'ExternalApps.ConfigurationFormXml',
    teardown: ->
      React.unmountComponentAtNode wrapper

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