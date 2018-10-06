/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import Modal from 'react-modal'
import ConfigureExternalToolButton from 'jsx/external_apps/components/ConfigureExternalToolButton'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
Modal.setAppElement(wrapper)
const createElement = tool => <ConfigureExternalToolButton tool={tool} />
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)
const getDOMNodes = function(data) {
  const component = renderComponent(data)
  const btnTriggerModal = component.refs.btnTriggerModal
  return [component, btnTriggerModal]
}

QUnit.module('ExternalApps.ConfigureExternalToolButton', {
  setup() {
    this.tools = [
      {
        app_id: 1,
        app_type: 'ContextExternalTool',
        description:
          'Talent provides an online, interactive video platform for professional development',
        enabled: true,
        installed_locally: true,
        name: 'Talent',
        tool_configuration: {url: 'http://example.com'}
      },
      {
        app_id: 2,
        app_type: 'Lti::ToolProxy',
        description: null,
        enabled: true,
        installed_locally: true,
        name: 'Twitter',
        tool_configuration: null
      }
    ]
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('open and close modal', () => {
  const tool = {
    app_id: 1,
    app_type: 'ContextExternalTool',
    description:
      'Talent provides an online, interactive video platform for professional development',
    enabled: true,
    installed_locally: true,
    name: 'Talent',
    tool_configuration: {url: 'http://example.com'}
  }
  const [component, btnTriggerModal] = Array.from(getDOMNodes(tool))
  Simulate.click(btnTriggerModal)
  ok(component.state.modalIsOpen, 'modal is open')
  ok(component.refs.btnClose)
  Simulate.click(component.refs.btnClose)
  ok(!component.state.modalIsOpen, 'modal is not open')
  ok(!component.refs.btnClose)
})
