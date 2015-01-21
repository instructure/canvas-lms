define [
  'old_unsupported_dont_use_react'
  'jsx/external_apps/components/Lti2Edit'
], (React, Lti2Edit) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    Lti2Edit({
      tool: data.tool
      handleActivateLti2: data.handleActivateLti2
      handleDeactivateLti2: data.handleDeactivateLti2
      handleCancel: data.handleCancel
    })

  renderComponent = (data) ->
    React.renderComponent(createElement(data), wrapper)

  module 'ExternalApps.Lti2Edit',
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
      handleActivateLti2: ->
      handleDeactivateLti2: ->
      handleCancel: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Edit)