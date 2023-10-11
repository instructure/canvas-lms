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

import React, {Suspense} from 'react'
import {render, waitFor} from '@testing-library/react'
import RceHtmlEditor from '../RceHtmlEditor'

// CodeMirror requires functionality in the DOM that jsdom doesn't
// provide and that will be prohibitive to meaningfully
// mock. Let's just test that it renders and rely on INSTUI having
// tested the CodeEditor component
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

const renderEditor = async (editorRef, code) => {
  const component = render(
    <Suspense fallback="Loading">
      <RceHtmlEditor ref={editorRef} code={code} />
    </Suspense>
  )

  await waitFor(() => {
    expect(editorRef.current).not.toBeNull()
  })

  return component
}

describe('RceHtmlEditor', () => {
  beforeEach(() => jest.useFakeTimers())

  it('renders', async () => {
    const editorRef = {current: null}
    const {getByText} = await renderEditor(editorRef, '')
    expect(getByText('html code editor')).toBeInTheDocument()
  })

  it('beautifies the passed-in code', async () => {
    const editorRef = {current: null}
    const {container} = await renderEditor(editorRef, '<div><div>Text</div></div>')

    jest.advanceTimersByTime(1000)

    const el = container.querySelector('.CodeMirror')

    expect(el.CodeMirror.getValue()).toBe('<div>\n    <div>Text</div>\n</div>')
  })

  it('does not add non-semantic whitespace when beautifying', async () => {
    const editorRef = {current: null}
    const {container} = await renderEditor(editorRef, '<a><span>Links</span> are great</a>')

    jest.advanceTimersByTime(1000)

    const el = container.querySelector('.CodeMirror')

    expect(el.CodeMirror.getValue()).toBe('<a><span>Links</span> are great</a>')
  })
})
