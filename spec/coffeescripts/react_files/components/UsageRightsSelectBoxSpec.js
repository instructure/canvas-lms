/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import UsageRightsSelectBox from 'jsx/files/UsageRightsSelectBox'

QUnit.module('UsageRightsSelectBox', {
  setup() {},
  teardown() {
    return $('div.error_box').remove()
  }
})

test('shows alert message if nothing is chosen and component is setup for a message', () => {
  const props = {showMessage: true}
  const uRSB = TestUtils.renderIntoDocument(<UsageRightsSelectBox {...props} />)
  ok(uRSB.refs.showMessageAlert !== undefined, 'message is being shown')
  ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)
})

test('fetches license options when component mounts', () => {
  const server = sinon.fakeServer.create()
  const props = {showMessage: false}
  const uRSB = TestUtils.renderIntoDocument(<UsageRightsSelectBox {...props} />)
  server.respond('GET', '', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify([
      {
        id: 'cc_some_option',
        name: 'CreativeCommonsOption'
      }
    ])
  ])
  equal(uRSB.state.licenseOptions[0].id, 'cc_some_option', 'sets data just fine')
  server.restore()
  ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)
})

test('inserts copyright into textbox when passed in', () => {
  const copyright = 'all dogs go to taco bell'
  const props = {copyright}
  const uRSB = TestUtils.renderIntoDocument(<UsageRightsSelectBox {...props} />)
  equal(uRSB.refs.copyright.getDOMNode().value, copyright)
  ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)
})

test('shows creative commons options when set up', () => {
  const server = sinon.fakeServer.create()
  const cc_value = 'helloooo_nurse'
  const props = {
    copyright: 'loony',
    use_justification: 'creative_commons',
    cc_value
  }
  const uRSB = TestUtils.renderIntoDocument(<UsageRightsSelectBox {...props} />)
  server.respond('GET', '', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify([
      {
        id: 'cc_some_option',
        name: 'CreativeCommonsOption'
      }
    ])
  ])
  equal(
    uRSB.refs.creativeCommons.getDOMNode().value,
    'cc_some_option',
    'shows creative commons option'
  )
  server.restore()
  ReactDOM.unmountComponentAtNode(uRSB.getDOMNode().parentNode)
})
