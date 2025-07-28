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
import {Assignments} from '../Assignments'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('Assignments', () => {
  const mockData = {
    errors: {
      assignments: [
        {
          id: 1,
          name: 'Assignment 1',
          link: '/assignment/1',
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
          link: '/assignment/2',
          errors: {
            submission_types: {
              attribute: 'submission_type',
              type: 'unsupported',
              message: 'Submission type not supported',
            },
          },
        },
      ],
    },
  }

  it('renders nothing when no assignment errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {}}}>
        <Assignments />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.queryByText('Assignments')).toBeNull()
  })

  it('renders assignment items when errors exist', async () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <Assignments />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Assignments with Revisions (2 items)')).toBeInTheDocument()
    const toggle = screen.getByText('Assignments with Revisions')
    toggle.click()
    expect(screen.getByText('Assignment 1')).toBeInTheDocument()
    expect(screen.getByText('Assignment 2')).toBeInTheDocument()
  })

  it('displays correct translation for single item', () => {
    render(
      <HorizonToggleContext.Provider
        value={{
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
          },
        }}
      >
        <Assignments />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Assignments with Revisions (1 item)')).toBeInTheDocument()
    const toggle = screen.getByText('Assignments with Revisions')
    toggle.click()
    expect(screen.getByText('Assignment 1')).toBeInTheDocument()
  })
})
