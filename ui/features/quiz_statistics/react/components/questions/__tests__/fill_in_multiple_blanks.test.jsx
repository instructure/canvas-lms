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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import FillInMultipleBlanks from '../fill_in_multiple_blanks'
import assertChange from 'chai-assert-change'
import {camelize} from '@canvas/quiz-legacy-client-apps/util/convert_case'

describe('canvas_quizzes/statistics/views/questions/fill_in_multiple_blanks', () => {
  const fixture = camelize({
    id: '16',
    question_type: 'fill_in_multiple_blanks_question',
    question_text: '<p>Roses are [color1], violets are [color2]</p>',
    position: 6,
    responses: 155,
    answered: 136,
    correct: 73,
    partially_correct: 41,
    incorrect: 42,
    answer_sets: [
      {
        id: 'dddce03739867ad935a78cda255ec4dd',
        text: 'color1',
        answers: [
          {
            id: '9711',
            text: 'Red',
            correct: true,
            responses: 91,
          },
          {
            id: '2700',
            text: 'Blue',
            correct: true,
            responses: 23,
          },
          {
            id: 'none',
            text: 'No Answer',
            correct: false,
            responses: 20,
          },
          {
            id: 'other',
            text: 'Other',
            correct: false,
            responses: 22,
          },
        ],
      },
      {
        id: '2c442e61b76cc00acf08a1118eae7852',
        text: 'color2',
        answers: [
          {
            id: '9702',
            text: 'bonkers',
            correct: true,
            responses: 73,
          },
          {
            id: '7150',
            text: 'mumbojumbo',
            correct: true,
            responses: 0,
          },
          {
            id: 'other',
            text: 'Other',
            correct: false,
            responses: 82,
          },
          {
            id: 'none',
            text: 'No Answer',
            correct: false,
            responses: 1,
          },
        ],
      },
    ],
  })

  it('renders', () => {
    render(<FillInMultipleBlanks {...fixture} />)
  })

  it('can switch answer sets', () => {
    const {getByTestId} = render(<FillInMultipleBlanks {...fixture} />)

    assertChange({
      fn: () => {
        fireEvent.click(getByTestId(`choose-answer-set-2c442e61b76cc00acf08a1118eae7852`))
      },
      of: () => getByTestId('answer-table').textContent.includes('mumbojumbo'),
      from: false,
      to: true,
    })
  })
})
