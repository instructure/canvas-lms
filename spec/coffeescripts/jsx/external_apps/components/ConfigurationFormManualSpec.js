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
import ConfigurationFormManual from 'jsx/external_apps/components/ConfigurationFormManual'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <ConfigurationFormManual
    name={data.name}
    consumerKey={data.consumerKey}
    sharedSecret={data.sharedSecret}
    url={data.url}
    domain={data.domain}
    privacyLevel={data.privacyLevel}
    customFields={data.customFields}
    description={data.description}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

QUnit.module('ExternalApps.ConfigurationFormManual', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('customFieldsToMultiLine', () => {
  const data = {
    name: 'My App',
    consumerKey: 'KEY',
    sharedSecret: 'SECRET',
    url: 'http://example.com',
    domain: '',
    privacyLevel: 'anonymous',
    customFields: {
      a: 1,
      b: 2,
      c: 3
    },
    description: 'My awesome app!'
  }
  const component = renderComponent(data)
  equal(component.customFieldsToMultiLine(), 'a=1\nb=2\nc=3')
})

test('isValid when not valid', () => {
  const data = {
    name: '',
    consumerKey: '',
    sharedSecret: '',
    url: '',
    domain: '',
    privacyLevel: '',
    customFields: {},
    description: ''
  }
  const component = renderComponent(data)
  ok(!component.isValid())
  deepEqual(component.state.errors, {
    name: 'This field is required',
    url: 'Either the url or domain should be set.',
    domain: 'Either the url or domain should be set.'
  })
})

test('isValid when valid', () => {
  const data = {
    name: 'My App',
    consumerKey: 'A',
    sharedSecret: 'B',
    url: 'http://google.com',
    domain: '',
    privacyLevel: '',
    customFields: {},
    description: ''
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
    url: 'http://google.com',
    domain: '',
    privacyLevel: '',
    customFields: {},
    description: ''
  }
  const expectedData = {
    name: 'My App',
    consumerKey: 'A',
    sharedSecret: 'B',
    url: 'http://google.com',
    domain: '',
    privacyLevel: '',
    customFields: '',
    description: '',
    verifyUniqueness: 'true'
  }
  const component = renderComponent(data)
  deepEqual(component.getFormData(), expectedData)
})
