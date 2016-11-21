define [
  'react'
  'react-dom'
  'jsx/external_apps/components/Lti2Iframe'
], (React, ReactDOM, Lti2Iframe) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(Lti2Iframe, {
      registrationUrl: data.registrationUrl
      handleInstall: data.handleInstall
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  module 'ExternalApps.Lti2Iframe',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      registrationUrl: 'http://example.com'
      handleInstall: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Iframe)
