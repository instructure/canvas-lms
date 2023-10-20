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
import ToolLaunchIframe from '../ToolLaunchIframe'

describe('ToolLaunchIframe', () => {
  const title = 'iframe'
  const renderIframe = (props = {}) => render(<ToolLaunchIframe title={title} {...props} />)

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
})
