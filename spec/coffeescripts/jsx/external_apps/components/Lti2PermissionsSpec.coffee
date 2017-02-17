define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/Lti2Permissions'
], (React, ReactDOM, TestUtils, Lti2Permissions) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(Lti2Permissions, {
      tool: data.tool
      handleCancelLti2: data.handleCancelLti2
      handleActivateLti2: data.handleActivateLti2
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.Lti2Permissions',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      tool: {
        "app_id": 3,
        "app_type": "Lti::ToolProxy",
        "description": null,
        "enabled": false,
        "installed_locally": true,
        "name": "Twitter"
      }
      handleCancelLti2: ->
      handleActivateLti2: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Permissions)
