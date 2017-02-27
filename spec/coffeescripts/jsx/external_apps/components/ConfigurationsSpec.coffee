define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/Configurations'
], (React, ReactDOM, TestUtils, Configurations) ->

  wrapper = document.getElementById('fixtures')

  createElement = (data = {}) ->
    React.createElement(Configurations, data)

  renderComponent = (data = {}) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.Configurations',
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'renders', ->
    component = renderComponent({
      'env': {
        'APP_CENTER':{'enabled': true}
      }
    })
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Configurations)

  test 'canAddEdit', ->
    component = renderComponent({
        'env': {
          'PERMISSIONS': {
            'create_tool_manually': false
            },
          'APP_CENTER':{'enabled': true}
          }
      })
    notOk component.canAddEdit()

    test 'canAddEdit', ->
      component = renderComponent({
          'env': {
            'PERMISSIONS': {
              'create_tool_manually': true
              },
            'APP_CENTER':{'enabled': true}
            }
        })
      ok component.canAddEdit()

