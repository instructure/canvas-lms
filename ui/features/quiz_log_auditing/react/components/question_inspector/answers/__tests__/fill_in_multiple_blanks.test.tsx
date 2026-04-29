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

import {render} from '@testing-library/react'
import React from 'react'
import FillInMultipleBlanks from '../fill_in_multiple_blanks'

describe('canvas_quizzes/events/views/question_inspector/answers/fill_in_multiple_blanks', () => {
  it('renders', () => {
    render(<FillInMultipleBlanks answer={{one: 'yea!'}} />)
    expect(document.body.textContent).toMatch('yea!')
  })
})
