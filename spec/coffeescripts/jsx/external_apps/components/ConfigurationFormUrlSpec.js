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
import ConfigurationFormUrl from 'jsx/external_apps/components/ConfigurationFormUrl'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <ConfigurationFormUrl
    name={data.name}
    consumerKey={data.consumerKey}
    sharedSecret={data.sharedSecret}
    configUrl={data.configUrl}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

QUnit.module('ExternalApps.ConfigurationFormUrl', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('isValid when not valid', () => {
  const data = {
    name: '',
    consumerKey: '',
    sharedSecret: '',
    configUrl: ''
  }
  const component = renderComponent(data)
  ok(!component.isValid())
  deepEqual(component.state.errors, {
    name: 'This field is required',
    configUrl: 'This field is required'
  })
})

test('isValid when valid', () => {
  const data = {
    name: 'My App',
    consumerKey: 'A',
    sharedSecret: 'B',
    configUrl: 'http://google.com'
  }
  const component = renderComponent(data)
  ok(component.isValid())
  deepEqual(component.state.errors, {})
})

test('sets verifyUniqueness to true', () => {
  const data = {
    name: 'My App',
    consumerKey: 'A',
    sharedSecret: 'B',
    configUrl: 'http://google.com'
  }
  const expectedData = {
    name: 'My App',
    consumerKey: 'A',
    sharedSecret: 'B',
    configUrl: 'http://google.com',
    verifyUniqueness: 'true'
  }
  const component = renderComponent(data)
  deepEqual(component.getFormData(), expectedData)
})
