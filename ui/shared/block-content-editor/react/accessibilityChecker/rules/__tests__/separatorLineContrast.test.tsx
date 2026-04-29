/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {separatorLineContrast} from '../separatorLineContrast'

const white = '#FFFFFF'
const darkRed = '#632D2D'

describe('separatorLineContrast', () => {
  it('should pass for separators with sufficient contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <hr style={{borderColor: darkRed}} />
      </div>,
    )

    const hr = document.querySelector('hr') as HTMLHRElement
    const result = separatorLineContrast.test(hr)

    expect(result).toBeTruthy()
  })

  it('should fail for separators with insufficient contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <hr style={{borderColor: white}} />
      </div>,
    )

    const hr = document.querySelector('hr') as HTMLHRElement
    const result = separatorLineContrast.test(hr)

    expect(result).toBeFalsy()
  })

  it('should handle separators without parent background', () => {
    render(<hr />)

    const hr = document.querySelector('hr') as HTMLHRElement
    const result = separatorLineContrast.test(hr)

    expect(result).toBeTruthy()
  })

  it('should pass for non-HR elements', () => {
    render(<div>Not a separator</div>)

    const div = document.querySelector('div') as HTMLDivElement
    const result = separatorLineContrast.test(div)

    expect(result).toBeTruthy()
  })
})
