define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/ConfigurationFormManual'
], (React, ReactDOM, TestUtils, ConfigurationFormManual) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(ConfigurationFormManual, {
      name         : data.name
      consumerKey  : data.consumerKey
      sharedSecret : data.sharedSecret
      url          : data.url
      domain       : data.domain
      privacyLevel : data.privacyLevel
      customFields : data.customFields
      description  : data.description
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.ConfigurationFormManual',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'customFieldsToMultiLine', ->
    data =
      name: 'My App'
      consumerKey: 'KEY'
      sharedSecret: 'SECRET'
      url: 'http://example.com'
      domain: ''
      privacyLevel: 'anonymous'
      customFields: { a: 1, b: 2, c: 3 }
      description: 'My awesome app!'
    component = renderComponent(data)
    equal component.customFieldsToMultiLine(), "a=1\nb=2\nc=3"

  test 'isValid when not valid', ->
    data =
      name: ''
      consumerKey: ''
      sharedSecret: ''
      url: ''
      domain: ''
      privacyLevel: ''
      customFields: {}
      description: ''
    component = renderComponent(data)
    ok !component.isValid()
    deepEqual component.state.errors, {
      name: 'This field is required'
      url: 'Either the url or domain should be set.'
      domain: 'Either the url or domain should be set.'
    }

  test 'isValid when valid', ->
    data =
      name: 'My App'
      consumerKey: 'A'
      sharedSecret: 'B'
      url: 'http://google.com'
      domain: ''
      privacyLevel: ''
      customFields: {}
      description: ''
    component = renderComponent(data)
    ok component.isValid()
    deepEqual component.state.errors, {}
