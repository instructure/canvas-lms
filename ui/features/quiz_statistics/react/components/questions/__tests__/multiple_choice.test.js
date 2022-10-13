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
import MultipleChoice from '../multiple_choice'
import {camelize} from '@canvas/quiz-legacy-client-apps/util/convert_case'

describe('canvas_quizzes/statistics/views/questions/multiple_choice', () => {
  it('renders', () => {
    const fixture = camelize({
      id: '11',
      question_type: 'multiple_choice_question',
      question_text: '<p>Which?</p>',
      position: 1,
      responses: 156,
      answers: [
        {
          id: '3866',
          text: 'I am a very long description of an answer that should span multiple lines.',
          correct: true,
          responses: 129,
        },
        {
          id: '2040',
          text: 'b',
          correct: false,
          responses: 1,
        },
        {
          id: '7387',
          text: 'c',
          correct: false,
          responses: 26,
        },
        {
          id: '4082',
          text: 'd',
          correct: false,
          responses: 0,
        },
      ],
      answered_student_count: 156,
      top_student_count: 42,
      middle_student_count: 72,
      bottom_student_count: 42,
      correct_student_count: 129,
      incorrect_student_count: 27,
      correct_student_ratio: 0.8269230769230769,
      incorrect_student_ratio: 0.17307692307692307,
      correct_top_student_count: 42,
      correct_middle_student_count: 72,
      correct_bottom_student_count: 15,
      variance: 0.14312130177514806,
      stdev: 0.3783137610174233,
      difficulty_index: 0.8269230769230769,
      alpha: null,
      point_biserials: [
        {
          answer_id: 3866,
          point_biserial: 0.7157094891780442,
          correct: true,
          distractor: false,
        },
        {
          answer_id: 2040,
          point_biserial: -0.0608778335993478,
          correct: false,
          distractor: true,
        },
        {
          answer_id: 7387,
          point_biserial: -0.7134960236217814,
          correct: false,
          distractor: true,
        },
        {
          answer_id: 4082,
          point_biserial: null,
          correct: false,
          distractor: true,
        },
      ],
    })

    render(<MultipleChoice {...fixture} />)
  })
})
