/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import { mount } from 'enzyme'
import CollaborationsToolLaunch from  'jsx/collaborations/CollaborationsToolLaunch'

let fixtures

QUnit.module('CollaborationsToolLaunch screenreader functionality', {
  setup () {
    fixtures = $('#fixtures')
    fixtures.append('<div id="main" style="height: 700px; width: 700px" />')
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  },

  teardown () {
    fixtures.empty()
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }
})

test('shows beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <CollaborationsToolLaunch />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.before_external_content_info_alert').simulate('focus')
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '-4px' })
})

test('shows ending info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <CollaborationsToolLaunch />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.after_external_content_info_alert').simulate('focus')
  equal(wrapper.state().afterExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '-4px' })
})

test('hides beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <CollaborationsToolLaunch />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.before_external_content_info_alert').simulate('focus')
  wrapper.find('.before_external_content_info_alert').simulate('blur')
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
})

test('hides ending info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <CollaborationsToolLaunch />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  wrapper.find('.after_external_content_info_alert').simulate('focus')
  wrapper.find('.after_external_content_info_alert').simulate('blur')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
})

test("doesn't show alerts or add border to iframe by default", () => {
  const wrapper = mount(
    <CollaborationsToolLaunch />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {})
})

test("sets the iframe allowances", () => {
  const wrapper = mount(
    <CollaborationsToolLaunch />
  )
  wrapper.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  ok(wrapper.find('.tool_launch').instance().getAttribute('allow'), ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
})
