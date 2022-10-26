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
import Cell from '../cell'
import K from '../../../../constants'

describe('canvas_quizzes/events/views/answer_matrix/cell', () => {
  it('renders', () => {
    render(
      <Cell
        question={{
          id: 'q1',
        }}
        event={{
          data: [{quizQuestionId: 'q1'}],
        }}
      />
    )
  })

  it('renders nothing if there is no event', () => {
    render(<Cell question={{id: 'q1'}} />)
  })

  describe('when not expanded', () => {
    const question = {
      question: {id: '1', questionType: 'multiple_choice_question'},
    }

    it('shows an emblem for an empty answer', function () {
      const {getByTestId} = render(
        <Cell {...question} event={{data: [{quizQuestionId: '1', answer: null}]}} />
      )

      expect(getByTestId('emblem').classList).toContain('is-empty')
    })

    it('shows an emblem for an answer', function () {
      const {getByTestId} = render(
        <Cell
          {...question}
          event={{
            data: [{quizQuestionId: '1', answer: '123', answered: true}],
          }}
        />
      )

      expect(getByTestId('emblem').classList).toContain('is-answered')
    })

    it('shows an emblem for the last answer', function () {
      const {getByTestId} = render(
        <Cell
          {...question}
          event={{
            data: [{quizQuestionId: '1', answer: '123', answered: true, last: true}],
          }}
        />
      )

      expect(getByTestId('emblem').classList).toContain('is-answered')
      expect(getByTestId('emblem').classList).toContain('is-last')
    })

    it('shows nothing for no answer', function () {
      const {queryByTestId} = render(<Cell {...question} />)

      expect(queryByTestId('emblem')).toBeFalsy()
    })
  })

  it('expands and truncates', () => {
    render(
      <Cell
        expanded={true}
        shouldTruncate={true}
        maxVisibleChars={5}
        question={{
          id: 'q1',
          questionType: K.Q_SHORT_ANSWER,
        }}
        event={{
          data: [{quizQuestionId: 'q1', answer: 'hello world'}],
        }}
      />
    )

    expect(document.body.textContent).toMatch('hello...')
  })

  it('expands as json', () => {
    render(
      <Cell
        expanded={true}
        shouldTruncate={true}
        question={{
          id: 'q1',
          questionType: K.Q_MULTIPLE_CHOICE,
        }}
        event={{
          data: [{quizQuestionId: 'q1'}],
        }}
      />
    )
  })
})
