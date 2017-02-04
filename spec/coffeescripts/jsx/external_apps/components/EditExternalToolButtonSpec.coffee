define [
  'react'
  'react-dom'
  'jsx/external_apps/components/EditExternalToolButton'
], (React, ReactDOM, EditExternalToolButton) ->

  wrapper = document.getElementById('fixtures')
  prevEnvironment = ENV

  createElement = (data = {}) ->
    React.createElement(EditExternalToolButton, data)

  renderComponent = (data = {}) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.EditExternalToolButton',
    setup: ->
      ENV.APP_CENTER = {'enabled': true}

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)
      ENV = prevEnvironment

  test 'allows editing of tools', ->
    tool = {'name': 'test tool'}
    component = renderComponent({'tool': tool, 'canAddEdit': true})
    disabledMessage = 'This action has been disabled by your admin.'
    form = JSON.stringify(component.form())
    notOk form.indexOf(disabledMessage) >= 0

  test 'does not allows editing of tools when insufficient permissions', ->
    tool = {'name': 'test tool'}
    component = renderComponent({'tool': tool, 'canAddEdit': false})
    disabledMessage = 'This action has been disabled by your admin.'
    form = JSON.stringify(component.form())
    ok form.indexOf(disabledMessage) >= 0

