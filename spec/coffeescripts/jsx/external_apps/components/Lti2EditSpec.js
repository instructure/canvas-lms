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
import Lti2Edit from 'jsx/external_apps/components/Lti2Edit'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <Lti2Edit
    tool={data.tool}
    handleActivateLti2={data.handleActivateLti2}
    handleDeactivateLti2={data.handleDeactivateLti2}
    handleCancel={data.handleCancel}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

QUnit.module('ExternalApps.Lti2Edit', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders', () => {
  const data = {
    tool: {
      app_id: 3,
      app_type: 'Lti::ToolProxy',
      description: null,
      enabled: false,
      installed_locally: true,
      name: 'Twitter'
    },
    handleActivateLti2() {},
    handleDeactivateLti2() {},
    handleCancel() {}
  }
  const component = renderComponent(data)
  ok(component.isMounted())
  ok(TestUtils.isCompositeComponentWithType(component, Lti2Edit))
})
