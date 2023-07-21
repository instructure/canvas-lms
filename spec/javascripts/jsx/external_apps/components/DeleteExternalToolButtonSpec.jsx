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
import TestUtils from 'react-dom/test-utils'
import Modal from '@canvas/react-modal'
import DeleteExternalToolButton from 'ui/features/external_apps/react/components/DeleteExternalToolButton'
import store from 'ui/features/external_apps/react/lib/ExternalAppsStore'
import {mount} from 'enzyme'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
Modal.setAppElement(wrapper)
const createElement = data => (
  <DeleteExternalToolButton
    tool={data.tool}
    canDelete={data.canDelete}
    canAddEdit={data.canAddEdit}
    returnFocus={data.returnFocus}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)
const getDOMNodes = function (data) {
  const component = renderComponent(data)
  const btnTriggerDelete = component.refs.btnTriggerDelete
  return [component, btnTriggerDelete]
}

QUnit.module('ExternalApps.DeleteExternalToolButton', {
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
      },
      {
        app_id: 2,
        app_type: 'Lti::ToolProxy',
        description: null,
        enabled: true,
        installed_locally: true,
        name: 'Twitter',
      },
    ]
    store.reset()
    return store.setState({externalTools: this.tools})
  },
  teardown() {
    store.reset()
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('does not render when the canAddEdit permission is false', () => {
  const tool = {name: 'test tool'}
  const component = renderComponent({tool, canAddEdit: false, returnFocus: () => {}})
  const node = ReactDOM.findDOMNode(component)
  notOk(node)
})

test('open and close modal', function () {
  const data = {tool: this.tools[1], canAddEdit: true, returnFocus: () => {}}
  const [component, btnTriggerDelete] = Array.from(getDOMNodes(data))
  Simulate.click(btnTriggerDelete)
  ok(component.state.modalIsOpen, 'modal is open')
  component.closeModal()
  ok(!component.state.modalIsOpen, 'modal is not open')
})

test('deletes a tool', function () {
  sinon.spy(store, 'delete')
  const wrapper = mount(
    <DeleteExternalToolButton tool={this.tools[0]} canAddEdit returnFocus={() => {}} />
  )
  wrapper.instance().deleteTool({preventDefault: () => {}})
  ok(store.delete.called)
  store.delete.restore()
  wrapper.unmount()
})

test('does not render when the canDelete permission is false (granular)', () => {
  const tool = {name: 'test tool'}
  const component = renderComponent({tool, canDelete: false, returnFocus: () => {}})
  const node = ReactDOM.findDOMNode(component)
  notOk(node)
})

test('open and close modal (granular)', function () {
  const data = {tool: this.tools[1], canDelete: true, returnFocus: () => {}}
  const [component, btnTriggerDelete] = Array.from(getDOMNodes(data))
  Simulate.click(btnTriggerDelete)
  ok(component.state.modalIsOpen, 'modal is open')
  component.closeModal()
  ok(!component.state.modalIsOpen, 'modal is not open')
})

test('deletes a tool (granular)', function () {
  sinon.spy(store, 'delete')
  const wrapper = mount(
    <DeleteExternalToolButton tool={this.tools[0]} canDelete returnFocus={() => {}} />
  )
  wrapper.instance().deleteTool({preventDefault: () => {}})
  ok(store.delete.called)
  store.delete.restore()
  wrapper.unmount()
})
