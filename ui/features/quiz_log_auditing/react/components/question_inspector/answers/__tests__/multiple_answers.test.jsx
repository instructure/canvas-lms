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
import MultipleAnswers from '../multiple_answers'

describe('canvas_quizzes/events/views/question_inspector/answers/multiple_answers', () => {
  it('renders', () => {
    const {getByTestId} = render(
      <MultipleAnswers
        question={{
          answers: [
            {id: 1, text: 'one'},
            {id: 2, text: 'two'},
            {id: 3, text: 'three'},
          ],
        }}
        answer={['1', '3']}
      />
    )

    expect(getByTestId('answer-1').checked).toBe(true)
    expect(getByTestId('answer-2').checked).toBe(false)
    expect(getByTestId('answer-3').checked).toBe(true)
  })
})
