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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import Lti2Iframe from 'jsx/external_apps/components/Lti2Iframe'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <Lti2Iframe
    registrationUrl={data.registrationUrl}
    handleInstall={data.handleInstall}
    reregistration={data.reregistration}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)

QUnit.module('ExternalApps.Lti2Iframe', {
  setup() {
    this.allowances = ['midi', 'media']
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = this.allowances
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }
})

test('renders', () => {
  const data = {
    registrationUrl: 'http://example.com',
    handleInstall() {}
  }
  const component = renderComponent(data)
  ok(component.isMounted())
  ok(TestUtils.isCompositeComponentWithType(component, Lti2Iframe))
})

test('renders any children after the iframe', () => {
  const element = (
    <Lti2Iframe registrationUrl="http://www.test.com" handleInstall={function() {}}>
      <div id="test-child" />
    </Lti2Iframe>
  )
  const component = TestUtils.renderIntoDocument(element)
  ok($(component.getDOMNode()).find('#test-child').length === 1)
})

test('getLaunchUrl returns the launch url if doing reregistration', () => {
  const data = {
    registrationUrl: 'http://example.com',
    handleInstall() {},
    reregistration: true
  }
  const component = renderComponent(data)
  equal(component.getLaunchUrl(), 'http://example.com')
})

test('getLaunchUrl returns about:blank if not doing reregistration', () => {
  const data = {
    registrationUrl: 'http://example.com',
    handleInstall() {},
    reregistration: false
  }
  const component = renderComponent(data)
  equal(component.getLaunchUrl(), 'about:blank')
})

test('renders any children after the iframe', function() {
  const element = (
    <Lti2Iframe registrationUrl="http://www.test.com" handleInstall={function() {}}>
      <div id="test-child" />
    </Lti2Iframe>
  )
  const component = TestUtils.renderIntoDocument(element)
  equal(component.iframe.getAttribute('allow'), this.allowances.join('; '))
})
