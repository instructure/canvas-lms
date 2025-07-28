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
        {
          id: 2,
          name: 'Assignment 2',
          link: '/assignment2',
          errors: {
            submission_types: {
              attribute: 'submission_type',
              type: 'unsupported',
              message: 'Submission type not supported',
            },
          },
        },
        {
          id: 3,
          name: 'Assignment 3',
          link: '/assignment3',
          errors: {
            workflow_state: {
              attribute: 'workflow_state',
              type: 'unsupported',
              message: 'Can not be published',
            },
          },
        },
        {
          id: 4,
          name: 'Assignment 4',
          link: '/assignment4',
          errors: {
            workflow_state: {
              attribute: 'workflow_state',
              type: 'unsupported',
              message: 'Can not be published',
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

  it('includes Assignments section', () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <ContentChanges />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Assignments')).toBeInTheDocument()
  })

  it('includes Published Contents section', () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <ContentChanges />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Published Content')).toBeInTheDocument()
  })
})
