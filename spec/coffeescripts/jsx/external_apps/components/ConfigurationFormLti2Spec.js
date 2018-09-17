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
import ConfigurationFormLti2 from 'jsx/external_apps/components/ConfigurationFormLti2'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => <ConfigurationFormLti2 registrationUrl={data.registrationUrl} />
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

QUnit.module('ExternalApps.ConfigurationFormLti2', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders', () => {
  const component = renderComponent({registrationUrl: ''})
  ok(component)
  ok(TestUtils.isCompositeComponentWithType(component, ConfigurationFormLti2))
})

test('validation', () => {
  const component = renderComponent({registrationUrl: ''})
  ok(!component.isValid())
  equal(component.state.errors.registrationUrl, 'This field is required')
})

test('getFormData', () => {
  const component = renderComponent({registrationUrl: 'http://example.com'})
  const data = component.getFormData()
  deepEqual(data, {registrationUrl: 'http://example.com'})
})
