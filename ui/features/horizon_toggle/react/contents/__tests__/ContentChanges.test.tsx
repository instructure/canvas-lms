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
import {ContentChanges} from '../ContentChanges'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('ContentChanges', () => {
  const mockData = {
    errors: {
      assignments: [
        {
          id: 1,
          name: 'Assignment 1',
          link: '/assignment1',
          errors: {
            submission_types: {
              attribute: 'submission_type',
              type: 'unsupported',
              message: 'Submission type not supported',
            },
          },
        },
      ],
      quizzes: [
        {
          id: 1,
          name: 'Quiz 1',
          link: '/quiz1',
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

  it('includes Assignments and Quizzes sections', () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <ContentChanges />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Assignments')).toBeInTheDocument()
    expect(screen.getByText('Quizzes')).toBeInTheDocument()
  })

  it('renders only Assignments section when no quiz errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {assignments: mockData.errors.assignments}}}>
        <ContentChanges />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Assignments')).toBeInTheDocument()
    expect(screen.queryByText('Quizzes')).not.toBeInTheDocument()
  })

  it('renders only Quizzes section when no assignment errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {quizzes: mockData.errors.quizzes}}}>
        <ContentChanges />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Quizzes')).toBeInTheDocument()
    expect(screen.queryByText('Assignments')).not.toBeInTheDocument()
  })
})
