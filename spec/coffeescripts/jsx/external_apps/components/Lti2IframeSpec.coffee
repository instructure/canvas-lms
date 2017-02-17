define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/Lti2Iframe'
], (React, ReactDOM, TestUtils, Lti2Iframe) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(Lti2Iframe, {
      registrationUrl: data.registrationUrl
      handleInstall: data.handleInstall
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.Lti2Iframe',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      registrationUrl: 'http://example.com'
      handleInstall: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Iframe)

  test 'renders any children after the iframe', ->
    element = React.createElement(Lti2Iframe,{
      registrationUrl: 'http://www.test.com',
      handleInstall: ->
    }, React.createElement('div', {id: 'test-child'}))
    component = TestUtils.renderIntoDocument(element)
    ok $(component.getDOMNode()).find('#test-child').length == 1


