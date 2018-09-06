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
import {Simulate} from 'react-addons-test-utils'
import Modal from 'react-modal'
import ReregisterExternalToolButton from 'jsx/external_apps/components/ReregisterExternalToolButton'
import store from 'jsx/external_apps/lib/ExternalAppsStore'

const wrapper = document.getElementById('fixtures')
Modal.setAppElement(wrapper)

const createElement = data => <ReregisterExternalToolButton tool={data.tool} canAddEdit />

const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

const getDOMNodes = function(data) {
  const component = renderComponent(data)
  const btnTriggerReregister = component.refs.reregisterExternalToolButton
  return [component, btnTriggerReregister]
}

QUnit.module('ExternalApps.ReregisterExternalToolButton', {
  setup() {
    this.tools = [
      {
        app_id: 2,
        app_type: 'Lti::ToolProxy',
        description: null,
        enabled: true,
        installed_locally: true,
        name: 'Twitter',
        reregistration_url: 'http://some.lti/reregister'
      }
    ]
    store.reset()
    store.setState({externalTools: this.tools})
  },
  teardown() {
    store.reset()
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('open and close modal', function() {
  const data = {tool: this.tools[0]}
  const [component, btnTriggerReregister] = Array.from(getDOMNodes(data))
  Simulate.click(btnTriggerReregister)
  ok(component.state.modalIsOpen, 'modal is open')
  ok(component.refs.btnClose)
  ok(component.refs.reregisterExternalToolButton)
  Simulate.click(component.refs.btnClose)
  ok(!component.state.modalIsOpen, 'modal is not open')
  ok(!component.refs.btnClose)
})
