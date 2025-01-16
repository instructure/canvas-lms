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

import {render} from '@testing-library/react'
import React from 'react'
import GlobalStyle from '../GlobalStyle'

describe('GlobalStyle', () => {
  it('applies global styles to html and body', () => {
    const html = document.documentElement
    const body = document.body
    // before
    const htmlBefore = window.getComputedStyle(html)
    expect(htmlBefore.overflowX).not.toBe('hidden')
    expect(htmlBefore.height).not.toBe('100%')
    const bodyBefore = window.getComputedStyle(body)
    expect(bodyBefore.minHeight).not.toBe('100%')
    expect(bodyBefore.margin).not.toBe('0px')
    // apply styles
    render(<GlobalStyle />)
    // after
    const htmlAfter = window.getComputedStyle(html)
    expect(htmlAfter.overflowX).toBe('hidden')
    expect(htmlAfter.height).toBe('100%')
    const bodyAfter = window.getComputedStyle(body)
    expect(bodyAfter.minHeight).toBe('100%')
    expect(bodyAfter.margin).toBe('0px')
  })
})
