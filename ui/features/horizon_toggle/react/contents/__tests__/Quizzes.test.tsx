/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {Quizzes} from '../Quizzes'
import {HorizonToggleContext} from '../../HorizonToggleContext'
import {CanvasCareerValidationResponse} from '../../types'

describe('Quizzes', () => {
  const mockData: CanvasCareerValidationResponse = {
    errors: {
      quizzes: [
        {
          id: 1,
          name: 'Quiz 1',
          link: '/quiz/1',
          errors: {
            quiz_type: {
              attribute: 'quiz_type',
              type: 'unsupported',
              message: 'Quiz type not supported',
            },
          },
        },
        {
          id: 2,
          name: 'Quiz 2',
          link: '/quiz/2',
          errors: {
            quiz_type: {
              attribute: 'quiz_type',
              type: 'unsupported',
              message: 'Quiz type not supported',
            },
          },
        },
      ],
    },
  }

  it('renders nothing when no quiz errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {}}}>
        <Quizzes />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.queryByText('Classic Quizzes')).not.toBeInTheDocument()
  })

  it('renders quiz items when errors exist', async () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <Quizzes />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Classic Quizzes (2 items)')).toBeInTheDocument()
    const toggle = screen.getByText('Classic Quizzes')
    toggle.click()
    expect(screen.getByText('Quiz 1')).toBeInTheDocument()
    expect(screen.getByText('Quiz 2')).toBeInTheDocument()
  })
})
