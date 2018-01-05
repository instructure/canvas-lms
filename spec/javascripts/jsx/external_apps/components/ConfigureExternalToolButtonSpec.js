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
import ReactDOM from 'react-dom'
import { mount } from 'enzyme'
import ConfigureExternalToolButton from  'jsx/external_apps/components/ConfigureExternalToolButton'

let tool
let event
let el

QUnit.module('ConfigureExternalToolButton screenreader functionality', {
  setup () {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
    tool = {
      name: 'test tool',
      tool_configuration: {
        url: 'http://example.com/launch'
      }
    }

    event = {
      preventDefault () {}
    }
  },
  teardown () {
    $('.ReactModalPortal').remove()
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }
})

test('shows beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  wrapper.instance().handleAlertFocus({ target: { className: "before" } })
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '300px' })
})

test('shows ending info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  wrapper.instance().handleAlertFocus({ target: { className: "after" } })
  equal(wrapper.state().afterExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '300px' })
})

test('hides beginning info alert and adds styles to iframe', () => {
  wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  el = $('.ReactModalPortal')
  wrapper.instance().handleAlertBlur({ target: { className: "before" } })
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
})

test('hides ending info alert and adds styles to iframe', () => {
  wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  wrapper.instance().handleAlertBlur({ target: { className: "after" } })
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
})

test("doesn't show alerts or add border to iframe by default", () => {
  wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {})
})

test('sets the iframe allowances', () => {
  const wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )

  wrapper.instance().openModal(event)
  wrapper.instance().handleAlertFocus({ target: { className: "before" } })
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  ok(wrapper.node.iframe.getAttribute('allow'), ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
})
