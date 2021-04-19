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
import {mount} from 'enzyme'
import ConfigureExternalToolButton from 'ui/features/external_apps/react/components/ConfigureExternalToolButton.js'

let tool
let event
let el

QUnit.module('ConfigureExternalToolButton screenreader functionality', {
  setup() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
    tool = {
      name: 'test tool',
      tool_configuration: {
        url: 'http://example.com/launch'
      }
    }

    event = {
      preventDefault() {}
    }
  },
  teardown() {
    $('.ReactModalPortal').remove()
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }
})

test('uses the tool configuration "url" when present', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} modalIsOpen />)
  ok(
    wrapper
      .instance()
      .getLaunchUrl({url: 'https://my.tool.com', target_link_uri: 'https://advantage.tool.com'})
      .includes('url=https%3A%2F%2Fmy.tool.com&display=borderless')
  )
  wrapper.unmount()
})

test('uses the tool configuration "target_link_uri" when "url" is not present', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} modalIsOpen />)
  ok(
    wrapper
      .instance()
      .getLaunchUrl({target_link_uri: 'https://advantage.tool.com'})
      .includes('url=https%3A%2F%2Fadvantage.tool.com&display=borderless')
  )
  wrapper.unmount()
})

test('shows beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} modalIsOpen />)
  wrapper.instance().handleAlertFocus({target: {className: 'before'}})
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, {border: '2px solid #008EE2', width: '300px'})
  wrapper.unmount()
})

test('shows ending info alert and adds styles to iframe', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} modalIsOpen />)
  wrapper.instance().handleAlertFocus({target: {className: 'after'}})
  equal(wrapper.state().afterExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, {border: '2px solid #008EE2', width: '300px'})
  wrapper.unmount()
})

test('hides beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} />)
  wrapper.instance().openModal(event)
  el = $('.ReactModalPortal')
  wrapper.instance().handleAlertBlur({target: {className: 'before'}})
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {border: 'none', width: '100%'})
  wrapper.unmount()
})

test('hides ending info alert and adds styles to iframe', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} />)
  wrapper.instance().openModal(event)
  wrapper.instance().handleAlertBlur({target: {className: 'after'}})
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {border: 'none', width: '100%'})
  wrapper.unmount()
})

test("doesn't show alerts or add border to iframe by default", () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} />)
  wrapper.instance().openModal(event)
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {})
  wrapper.unmount()
})

test('sets the iframe allowances', () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} modalIsOpen />)

  wrapper.instance().handleAlertFocus({target: {className: 'before'}})
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  ok(wrapper.instance().iframe.getAttribute('allow'), ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
  wrapper.unmount()
})

test("sets the 'data-lti-launch' attribute on the iframe", () => {
  const wrapper = mount(<ConfigureExternalToolButton tool={tool} modalIsOpen />)
  equal(wrapper.instance().iframe.getAttribute('data-lti-launch'), 'true')
  wrapper.unmount()
})
