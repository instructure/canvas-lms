/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import RceHtmlEditor from '../RceHtmlEditor'

// @ts-expect-error
document.createRange = () => {
  return {
    setStart: () => {},
    setEnd: () => {},
    getBoundingClientRect: () => {
      return {
        left: 0,
        right: 0,
        width: 0,
        height: 0,
      }
    },
    getClientRects: () => {
      return {
        length: 0,
      }
    },
  }
}

describe('RceHtmlEditor', () => {
  beforeEach(() => jest.useFakeTimers())

  it('renders', () => {
    const editorRef = {current: null}
    // @ts-expect-error
    const {getByText} = render(<RceHtmlEditor ref={editorRef} code="" />)
    expect(getByText('html code editor')).toBeInTheDocument()
  })

  it('beautifies the passed-in code', async () => {
    const editorRef = {current: null}
    const onChange = jest.fn()
    const {container} = render(
      // @ts-expect-error
      <RceHtmlEditor ref={editorRef} code="<div><div>Text</div></div>" onChange={onChange} />,
    )
    jest.advanceTimersByTime(1000)

    // is 1 without beautify.html(), 3 with
    expect(container.querySelectorAll('.cm-line')).toHaveLength(3)
  })

  it('does not add non-semantic whitespace when beautifying', () => {
    const editorRef = {current: null}
    const {container} = render(
      // @ts-expect-error
      <RceHtmlEditor ref={editorRef} code="<a><span>Links</span> are great</a>" />,
    )
    jest.advanceTimersByTime(1000)

    expect(container.querySelectorAll('.cm-line')).toHaveLength(1)
  })
})
