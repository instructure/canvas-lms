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

import {act, render, fireEvent} from '@testing-library/react'
import React from 'react'
import ScreenReaderContent from '../screen_reader_content'
import assertChange from 'chai-assert-change'

describe('canvas_quizzes/components/screen_reader_content', () => {
  it('renders', () => {
    render(<ScreenReaderContent>yea!</ScreenReaderContent>)
    expect(document.body.textContent).toMatch('yea!')
  })

  it('forces sentence delimiter', () => {
    render(<ScreenReaderContent forceSentenceDelimiter>yea!</ScreenReaderContent>)
    expect(document.body.textContent).toMatch('yea!')
  })

  it('rejects html', () => {
    render(<ScreenReaderContent forceSentenceDelimiter dangerouslySetInnerHTML={{__html: '<span>yea!</span>'}} />)

    expect(document.body.textContent).not.toMatch('yea!')
  })
})
