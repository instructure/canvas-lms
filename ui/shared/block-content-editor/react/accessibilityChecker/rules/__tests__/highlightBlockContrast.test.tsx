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
import {render, screen} from '@testing-library/react'
import {highlightBlockContrast} from '../highlightBlockContrast'
import {HighlightBlockLayout} from '../../../Blocks/HighlightBlock/HighlightBlockLayout'

const white = '#FFFFFF'
const lightGray = '#F5F5F5'
const darkRed = '#632D2D'
const lightYellow = '#FFFACD'

describe('highlightBlockContrast', () => {
  it('should pass for span with sufficient contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <span style={{backgroundColor: darkRed}}>High contrast highlight</span>
      </div>,
    )

    const span = document.querySelector('span') as HTMLSpanElement
    const result = highlightBlockContrast.test(span)

    expect(result).toBeTruthy()
  })

  it('should fail for span with insufficient contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <span style={{backgroundColor: lightGray}}>Low contrast highlight</span>
      </div>,
    )

    const span = document.querySelector('span') as HTMLSpanElement
    const result = highlightBlockContrast.test(span)

    expect(result).toBeFalsy()
  })

  it('should pass for spans without background color', () => {
    render(
      <div style={{backgroundColor: white}}>
        <span>No background span</span>
      </div>,
    )

    const span = document.querySelector('span') as HTMLSpanElement
    const result = highlightBlockContrast.test(span)

    expect(result).toBeTruthy()
  })

  it('should pass for non-span elements', () => {
    render(
      <div style={{backgroundColor: darkRed}}>
        <div>Not a span</div>
      </div>,
    )

    const div = document.querySelector('div div') as HTMLDivElement
    const result = highlightBlockContrast.test(div)

    expect(result).toBeTruthy()
  })

  it('should handle spans without parent element', () => {
    const span = document.createElement('span')
    span.style.backgroundColor = darkRed

    const result = highlightBlockContrast.test(span)

    expect(result).toBeTruthy()
  })

  it('should find issues with HighlightBlockLayout component', () => {
    render(
      <div style={{backgroundColor: lightYellow}}>
        <HighlightBlockLayout
          backgroundColor={lightGray}
          content="This highlight has poor contrast"
        />
      </div>,
    )

    const highlightBlock = screen.getByTestId('highlight-block')
    const result = highlightBlockContrast.test(highlightBlock)

    expect(result).toBeFalsy()
  })

  it('should pass for HighlightBlockLayout component with good contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <HighlightBlockLayout
          backgroundColor={darkRed}
          content="This highlight has good contrast"
        />
      </div>,
    )

    const highlightBlock = screen.getByTestId('highlight-block')
    const result = highlightBlockContrast.test(highlightBlock)

    expect(result).toBeTruthy()
  })
})
