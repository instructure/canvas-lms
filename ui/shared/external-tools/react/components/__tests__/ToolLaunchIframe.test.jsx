/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import fakeENV from '@canvas/test-utils/fakeENV'
import ToolLaunchIframe from '../ToolLaunchIframe'

describe('ToolLaunchIframe', () => {
  const title = 'iframe'
  const renderIframe = (props = {}) => render(<ToolLaunchIframe title={title} {...props} />)

  beforeEach(() => {
    fakeENV.setup({
      LTI_LAUNCH_FRAME_ALLOWANCES: ['geolocation *', 'microphone *', 'camera *'],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('passes all props through', () => {
    const {getByTitle} = renderIframe({hello: 'world'})
    expect(getByTitle(title)).toHaveAttribute('hello', 'world')
  })

  it('uses default className', () => {
    const {getByTitle} = renderIframe()
    expect(getByTitle(title)).toHaveClass('tool_launch')
  })

  it('uses provided className', () => {
    const testClass = 'test_class'
    const {getByTitle} = renderIframe({className: testClass})
    expect(getByTitle(title)).toHaveClass(testClass)
  })

  it('adds data-lti-launch', () => {
    const {getByTitle} = renderIframe()
    expect(getByTitle(title)).toHaveAttribute('data-lti-launch')
  })

  it('supports ref', () => {
    const ref = React.createRef()
    render(<ToolLaunchIframe title={title} ref={ref} />)
    expect(ref.current instanceof HTMLIFrameElement).toBe(true)
  })

  describe('allow attribute', () => {
    it('sets iframe allow attribute at render time for microphone and camera permissions', () => {
      const {getByTitle} = renderIframe()
      expect(getByTitle(title)).toHaveAttribute('allow', ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
    })

    it('handles missing LTI_LAUNCH_FRAME_ALLOWANCES gracefully', () => {
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
      const {getByTitle} = renderIframe()
      // iframeAllowances() returns empty string when ENV is undefined
      expect(getByTitle(title)).toHaveAttribute('allow', '')
    })

    it('handles empty LTI_LAUNCH_FRAME_ALLOWANCES array', () => {
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES = []
      const {getByTitle} = renderIframe()
      expect(getByTitle(title)).toHaveAttribute('allow', '')
    })

    it('allows override of allow attribute via props', () => {
      const customAllow = 'microphone https://example.com; camera https://example.com'
      const {getByTitle} = renderIframe({allow: customAllow})
      // Props spread comes after default allow, so props override it
      expect(getByTitle(title)).toHaveAttribute('allow', customAllow)
    })

    it('applies permissions with wildcard origins correctly', () => {
      const {getByTitle} = renderIframe()
      const allowValue = getByTitle(title).getAttribute('allow')
      expect(allowValue).toContain('geolocation *')
      expect(allowValue).toContain('microphone *')
      expect(allowValue).toContain('camera *')
    })
  })
})
