/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import CollaborationsToolLaunch from '../CollaborationsToolLaunch'

let fixtures

describe('CollaborationsToolLaunch screenreader functionality', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="main" style="height: 700px; width: 700px" />'
    fixtures = document.getElementById('main')
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  })

  afterEach(() => {
    fixtures.innerHTML = ''
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  })

  test('shows beginning info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(<CollaborationsToolLaunch ref={ref} />)
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    const alert = wrapper.container.querySelector('.before_external_content_info_alert')
    alert.focus()
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('')
    expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
  })

  test('shows ending info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(<CollaborationsToolLaunch ref={ref} />)
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    const alert = wrapper.container.querySelector('.after_external_content_info_alert')
    alert.focus()
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('')
    expect(ref.current.state.iframeStyle).toEqual({border: '2px solid #0374B5', width: '-4px'})
  })

  test('hides beginning info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(<CollaborationsToolLaunch ref={ref} />)
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    const alert = wrapper.container.querySelector('.before_external_content_info_alert')
    alert.focus()
    alert.blur()
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
  })

  test('hides ending info alert and adds styles to iframe', () => {
    const ref = React.createRef()
    const wrapper = render(<CollaborationsToolLaunch ref={ref} />)
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    const alert = wrapper.container.querySelector('.after_external_content_info_alert')
    alert.focus()
    alert.blur()
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({border: 'none', width: '100%'})
  })

  test("doesn't show alerts or add border to iframe by default", () => {
    const ref = React.createRef()
    render(<CollaborationsToolLaunch ref={ref} />)
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.iframeStyle).toEqual({})
  })

  test('sets the iframe allowances', () => {
    const ref = React.createRef()
    const wrapper = render(<CollaborationsToolLaunch ref={ref} />)
    ref.current.setState({toolLaunchUrl: 'http://localhost:3000/messages/blti'})
    expect(ref.current.state.beforeExternalContentAlertClass).toEqual('screenreader-only')
    expect(ref.current.state.afterExternalContentAlertClass).toEqual('screenreader-only')
    expect(wrapper.container.querySelector('.tool_launch').getAttribute('allow')).toEqual(
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')
    )
  })

  test("sets the 'data-lti-launch' attribute on the iframe", () => {
    const wrapper = render(<CollaborationsToolLaunch />)
    expect(wrapper.container.querySelector('.tool_launch').getAttribute('data-lti-launch')).toEqual(
      'true'
    )
  })
})
