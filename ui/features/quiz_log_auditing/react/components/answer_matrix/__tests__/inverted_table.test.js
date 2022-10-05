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
import InvertedTable from '../inverted_table'
import assertChange from 'chai-assert-change'

describe('canvas_quizzes/events/views/answer_matrix/inverted_table', () => {
  it('renders', () => {
    render(
      <InvertedTable
        expandAll={true}
        questions={[{id: 'q1'}]}
        events={[
          {
            id: 'e1',
            type: 'question_answered',
            createdAt: '2014-11-16T13:39:19Z',
            data: [{quizQuestionId: 'q1', answer: null, answered: false}],
          },
        ]}
        submission={{
          startedAt: '2014-11-16T13:37:19Z',
        }}
      />
    )
  })

  it('expands a question when clicked', () => {
    const {getByTestId} = render(
      <InvertedTable
        questions={[{id: 'q1'}]}
        events={[
          {
            id: 'e1',
            type: 'question_answered',
            createdAt: '2014-11-16T13:39:19Z',
            data: [{quizQuestionId: 'q1', answer: 'ANSWER!', answered: false}],
          },
        ]}
        submission={{
          startedAt: '2014-11-16T13:37:19Z',
        }}
      />
    )

    assertChange({
      fn: () => fireEvent.click(getByTestId('question-toggler-q1')),
      of: () => !!document.body.textContent.match('ANSWER!'),
      from: false,
      to: true,
    })
  })
})
