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
  'react-modal'
  'jsx/external_apps/components/ReregisterExternalToolButton'
  'jsx/external_apps/lib/ExternalAppsStore'
], (React, ReactDOM, {Simulate}, Modal, ReregisterExternalToolButton, store) ->

  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  createElement = (data) ->
    React.createElement(ReregisterExternalToolButton, {
      tool: data.tool,
      canAddEdit: true
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component        = renderComponent(data)
    btnTriggerReregister = component.refs.reregisterExternalToolButton?.getDOMNode()
    [component, btnTriggerReregister]

  QUnit.module 'ExternalApps.ReregisterExternalToolButton',
    setup: ->
      @tools = [
        {
          "app_id": 2,
          "app_type": "Lti::ToolProxy",
          "description": null,
          "enabled": true,
          "installed_locally": true,
          "name": "Twitter",
          "reregistration_url": "http://some.lti/reregister"
        }
      ]
      store.reset()
      store.setState({ externalTools: @tools })
    teardown: ->
      store.reset()
      ReactDOM.unmountComponentAtNode wrapper

  test 'open and close modal', ->
    data = { tool: @tools[0] }
    [component, btnTriggerReregister] = getDOMNodes(data)
    Simulate.click(btnTriggerReregister)
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    ok component.refs.reregisterExternalToolButton
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
