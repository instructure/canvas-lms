define [
  'react'
  'jsx/external_apps/components/ConfigurationFormLti2'
], (React, ConfigurationFormLti2) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    ConfigurationFormLti2({
      registrationUrl: data.registrationUrl
    })

  renderComponent = (data) ->
    React.renderComponent(createElement(data), wrapper)

  module 'ExternalApps.ConfigurationFormLti2',
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'renders', ->
    component = renderComponent({ registrationUrl: '' })
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, ConfigurationFormLti2)

  test 'validation', ->
    component = renderComponent({ registrationUrl: '' })
    ok !component.isValid()
    equal component.state.errors.registrationUrl, 'This field is required'

  test 'getFormData', ->
    component = renderComponent({ registrationUrl: 'http://example.com' })
    data = component.getFormData()
    deepEqual data, { registrationUrl: "http://example.com" }

