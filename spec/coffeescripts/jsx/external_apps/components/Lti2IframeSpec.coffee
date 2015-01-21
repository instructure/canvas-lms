define [
  'old_unsupported_dont_use_react'
  'jsx/external_apps/components/Lti2Iframe'
], (React, Lti2Iframe) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    Lti2Iframe({
      registrationUrl: data.registrationUrl
      handleInstall: data.handleInstall
    })

  renderComponent = (data) ->
    React.renderComponent(createElement(data), wrapper)

  module 'ExternalApps.Lti2Iframe',
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      registrationUrl: 'http://example.com'
      handleInstall: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Iframe)