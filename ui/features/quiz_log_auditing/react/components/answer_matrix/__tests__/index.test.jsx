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
import {MemoryRouter} from 'react-router-dom'
import AnswerMatrix from '../index'
import assertChange from 'chai-assert-change'
import K from '../../../../constants'

describe('canvas_quizzes/events/views/answer_matrix', () => {
  it('renders', () => {
    render(
      <MemoryRouter>
        <AnswerMatrix />
      </MemoryRouter>
    )
  })

  it('truncates', () => {
    const {getByText, getByTestId} = render(
      <MemoryRouter>
        <AnswerMatrix
          maxVisibleChars={5}
          questions={[{id: 'q1', questionType: K.Q_SHORT_ANSWER}]}
          events={[
            {
              id: 'e1',
              type: K.EVT_QUESTION_ANSWERED,
              createdAt: '2014-11-16T13:39:19Z',
              data: [{quizQuestionId: 'q1', answer: 'hello world', answered: true}],
            },
          ]}
          submission={{
            startedAt: '2014-11-16T13:37:19Z',
          }}
        />
      </MemoryRouter>
    )

    // we must expand it first
    fireEvent.click(getByTestId('event-toggler-e1'))

    assertChange({
      fn: () => fireEvent.click(getByText('Truncate textual answers')),
      of: () => getByTestId('cell-e1').textContent,
      from: 'hello world',
      to: 'hello...',
    })
  })

  it('expands all events', () => {
    const {getByText, getByTestId} = render(
      <MemoryRouter>
        <AnswerMatrix
          maxVisibleChars={5}
          questions={[{id: 'q1', questionType: K.Q_SHORT_ANSWER}]}
          events={[
            {
              id: 'e1',
              type: K.EVT_QUESTION_ANSWERED,
              createdAt: '2014-11-16T13:39:19Z',
              data: [{quizQuestionId: 'q1', answer: 'hello world', answered: true}],
            },
          ]}
          submission={{
            startedAt: '2014-11-16T13:37:19Z',
          }}
        />
      </MemoryRouter>
    )

    assertChange({
      fn: () => fireEvent.click(getByText('Expand all answers')),
      of: () => {
        try {
          return !!getByTestId('cell-e1')
        } catch (e) {
          return false
        }
      },
      from: false,
      to: true,
    })
  })

  it('inverts', () => {
    const {getByText, getByTestId} = render(
      <MemoryRouter>
        <AnswerMatrix
          maxVisibleChars={5}
          questions={[{id: 'q1', questionType: K.Q_SHORT_ANSWER}]}
          events={[
            {
              id: 'e1',
              type: K.EVT_QUESTION_ANSWERED,
              createdAt: '2014-11-16T13:39:19Z',
              data: [{quizQuestionId: 'q1', answer: 'hello world', answered: true}],
            },
          ]}
          submission={{
            startedAt: '2014-11-16T13:37:19Z',
          }}
        />
      </MemoryRouter>
    )

    assertChange({
      fn: () => fireEvent.click(getByText('Invert')),
      of: () => {
        try {
          return !!getByTestId('question-toggler-q1')
        } catch (e) {
          return false
        }
      },
      from: false,
      to: true,
    })
  })
})
