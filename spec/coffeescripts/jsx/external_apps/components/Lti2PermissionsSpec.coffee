define [
  'old_unsupported_dont_use_react'
  'jsx/external_apps/components/Lti2Permissions'
], (React, Lti2Permissions) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    Lti2Permissions({
      tool: data.tool
      handleCancelLti2: data.handleCancelLti2
      handleActivateLti2: data.handleActivateLti2
    })

  renderComponent = (data) ->
    React.renderComponent(createElement(data), wrapper)

  module 'ExternalApps.Lti2Permissions',
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      tool: {
        "app_id": 3,
        "app_type": "Lti::ToolProxy",
        "description": null,
        "enabled": false,
        "installed_locally": true,
        "name": "Facebook"
      }
      handleCancelLti2: ->
      handleActivateLti2: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Permissions)