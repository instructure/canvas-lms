#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/ConfigurationForm'
], (React, ReactDOM, TestUtils, ConfigurationForm) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  handleSubmit = ->
    ok true, 'handleSubmit called successfully'

  createElement = (data) ->
    React.createElement(ConfigurationForm,{
      configurationType: data.configurationType
      handleSubmit: data.handleSubmit
      tool: data.tool
      showConfigurationSelector: data.showConfigurationSelector
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component = renderComponent(data)
    {
      component: component
      configurationFormManual: component.refs.configurationFormManual?.getDOMNode()
      configurationFormUrl: component.refs.configurationFormUrl?.getDOMNode()
      configurationFormXml: component.refs.configurationFormXml?.getDOMNode()
      configurationFormLti2: component.refs.configurationFormLti2?.getDOMNode()
      configurationTypeSelector: component.refs.configurationTypeSelector?.getDOMNode()
      submitLti2: component.refs.submitLti2?.getDOMNode()
      submit: component.refs.submit?.getDOMNode()
    }

  QUnit.module 'ExternalApps.ConfigurationForm',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders manual form with new tool', ->
    data =
      configurationType: 'manual'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.component.isMounted()
    ok TestUtils.isCompositeComponentWithType(nodes.component, ConfigurationForm)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormManual

  test 'renders url form with new tool', ->
    data =
      configurationType: 'url'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormUrl

  test 'renders xml form with new tool', ->
    data =
      configurationType: 'xml'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormXml

  test 'renders lti2 form with new tool', ->
    data =
      configurationType: 'lti2'
      handleSubmit: handleSubmit
      tool: {}
      showConfigurationSelector: true
    nodes = getDOMNodes(data)
    ok nodes.configurationTypeSelector
    ok nodes.configurationFormLti2

  test 'renders manual form with existing tool and no selector', ->
    data =
      configurationType: 'manual'
      handleSubmit: handleSubmit
      tool: {
        name          : 'My App'
        consumerKey   : 'KEY'
        sharedSecret  : 'SECRET'
        url           : 'http://example.com'
        domain        : ''
        privacy_level : 'anonymous'
        customFields  : { a: 1, b: 2, c: 3 }
        description   : 'My super awesome example app'
      }
      showConfigurationSelector: false
    nodes = getDOMNodes(data)
    ok nodes.configurationFormManual
    ok !nodes.configurationTypeSelector
