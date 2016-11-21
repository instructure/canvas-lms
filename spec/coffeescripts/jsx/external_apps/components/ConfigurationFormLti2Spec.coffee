define [
  'react'
  'react-dom'
  'jsx/external_apps/components/ConfigurationFormLti2'
], (React, ReactDOM, ConfigurationFormLti2) ->

  TestUtils = React.addons.TestUtils
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(ConfigurationFormLti2, {
      registrationUrl: data.registrationUrl
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  module 'ExternalApps.ConfigurationFormLti2',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

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

