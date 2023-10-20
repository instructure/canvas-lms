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
import ShortAnswer from '../short_answer'
import {camelize} from '@canvas/quiz-legacy-client-apps/util/convert_case'

describe('canvas_quizzes/statistics/views/questions/short_answer', () => {
  it('renders', () => {
    const fixture = camelize({
      id: '15',
      question_type: 'short_answer_question',
      question_text: '<p>Type something</p>',
      position: 5,
      responses: 156,
      answers: [
        {
          id: '4684',
          text: 'Something',
          correct: true,
          responses: 58,
        },
        {
          id: '1797',
          text: 'False',
          correct: true,
          responses: 97,
        },
        {
          id: 'other',
          text: 'Other',
          correct: false,
          responses: 1,
        },
      ],
      correct: 155,
    })

    render(<ShortAnswer {...fixture} />)
  })
})
