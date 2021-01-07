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

// CodeMirror requires functionality in the DOM that jsdom doesn't
// provide and that will be prohibitive to meaningfully
// mock. Let's just test that it renders and rely on INSTUI having
// tested the CodeEditor component

if (!document.createRange) {
  document.createRange = () => {
    return {
      setStart: () => {},
      setEnd: () => {},
      getBoundingClientRect: () => {
        return {
          left: 0,
          right: 0,
          width: 0,
          height: 0
        }
      },
      getClientRects: () => {
        return {
          length: 0
        }
      }
    }
  }
}

describe('RceHtmlEditor', () => {
  it('renders', () => {
    const editorRef = {current: null}
    const {getByText} = render(<RceHtmlEditor ref={editorRef} code="" />)
    expect(getByText('html code editor')).toBeInTheDocument()
  })
})
