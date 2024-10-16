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
import {GlobalStyle} from '..'
import {css} from '@emotion/react'
import {render} from '@testing-library/react'

const getGlobalStyle = () => {
  const styleTags = document.querySelectorAll('style[data-emotion]')
  return Array.from(styleTags)
    .map(tag => tag.textContent)
    .join('')
}

describe('GlobalStyle', () => {
  // skipped for InstUI 9 upgrade, should be fixed or removed
  // see FOO-4979
  it.skip('applies the correct global styles FOO-4979', () => {
    render(<GlobalStyle />)
    const globalCSS = getGlobalStyle()
    expect(globalCSS).toContain('html,body{overflow-x:hidden;}')
    expect(globalCSS).toContain('html{height:100%;}')
    expect(globalCSS).toContain('body{min-height:100%;margin:0;}')
  })
})
