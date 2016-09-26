define [
  'react'
  'jsx/external_apps/components/Configurations'
], (React, Configurations) ->

  TestUtils = React.addons.TestUtils
  wrapper = document.getElementById('fixtures')
  prevEnvironment = ENV

  createElement = (data = {}) ->
    React.createElement(Configurations, data)

  renderComponent = (data = {}) ->
    React.render(createElement(data), wrapper)

  module 'ExternalApps.Configurations',
    teardown: ->
      React.unmountComponentAtNode(wrapper)

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

