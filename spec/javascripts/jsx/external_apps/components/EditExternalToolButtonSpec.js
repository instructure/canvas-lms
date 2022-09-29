/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import EditExternalToolButton from 'ui/features/external_apps/react/components/EditExternalToolButton'
import Store from 'ui/features/external_apps/react/lib/ExternalAppsStore'

const wrapper = document.getElementById('fixtures')
const prevEnvironment = ENV
const createElement = (data = {}) => <EditExternalToolButton {...data} returnFocus={() => {}} />
const renderComponent = (data = {}) => ReactDOM.render(createElement(data), wrapper)

QUnit.module('ExternalApps.EditExternalToolButton', {
  setup() {
    ENV.APP_CENTER = {enabled: true}
  },
  teardown() {
    let ENV
    ReactDOM.unmountComponentAtNode(wrapper)
    ENV = prevEnvironment
  },
})

test('allows editing of tools', () => {
  const tool = {name: 'test tool'}
  const component = renderComponent({
    tool,
    canAddEdit: true,
  })
  const disabledMessage = 'This action has been disabled by your admin.'
  const form = JSON.stringify(component.form())
  notOk(form.indexOf(disabledMessage) >= 0)
})

test('opens modal with expected tool state', () => {
  const tool = {
    name: 'test tool',
    description: 'New tool description',
    app_type: 'ContextExternalTool',
  }
  const data = {
    name: 'test tool',
    description: 'Old tool description',
    privacy_level: 'public',
  }
  const component = renderComponent({
    tool,
    canAddEdit: true,
  })
  component.setContextExternalToolState(data)
  ok(component.state.tool.description, 'New tool description')
})

test('sets new state from state store response', () => {
  const stub = sinon.stub(Store, 'fetch')
  const configurationType = 'manual'
  const data = {
    name: 'New Name',
    description: 'Current State',
    privacy_level: 'public',
  }
  const tool = {
    name: 'Old Name',
    description: 'Old State',
    app_type: 'ContextExternalTool',
  }
  const component = renderComponent({
    tool,
    canAddEdit: true,
  })
  component.saveChanges(configurationType, data)
  ok(component.state.tool.name, 'New Name')
  ok(component.state.tool.description, 'Current State')
  return stub.restore()
})

test('allows editing of tools (granular)', () => {
  const tool = {name: 'test tool'}
  const component = renderComponent({
    tool,
    canEdit: true,
  })
  const disabledMessage = 'This action has been disabled by your admin.'
  const form = JSON.stringify(component.form())
  notOk(form.indexOf(disabledMessage) >= 0)
})

test('opens modal with expected tool state (granular)', () => {
  const tool = {
    name: 'test tool',
    description: 'New tool description',
    app_type: 'ContextExternalTool',
  }
  const data = {
    name: 'test tool',
    description: 'Old tool description',
    privacy_level: 'public',
  }
  const component = renderComponent({
    tool,
    canEdit: true,
  })
  component.setContextExternalToolState(data)
  ok(component.state.tool.description, 'New tool description')
})

test('sets new state from state store response (granular)', () => {
  const stub = sinon.stub(Store, 'fetch')
  const configurationType = 'manual'
  const data = {
    name: 'New Name',
    description: 'Current State',
    privacy_level: 'public',
  }
  const tool = {
    name: 'Old Name',
    description: 'Old State',
    app_type: 'ContextExternalTool',
  }
  const component = renderComponent({
    tool,
    canEdit: true,
  })
  component.saveChanges(configurationType, data)
  ok(component.state.tool.name, 'New Name')
  ok(component.state.tool.description, 'Current State')
  return stub.restore()
})
