/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import '@testing-library/jest-dom'
import StudentDetailsComponent from '../student-details-view'

describe('StudentDetailsView', () => {
  const defaultProps = {
    isLoading: false,
    student: {
      id: 3,
      name: 'foo',
      sortable_name: 'student@instructure.com',
      short_name: 'student@instructure.com',
      login_id: 'student',
    },
    triggerAssignment: {
      assignment: {
        id: '1',
        name: 'hello world',
        points_possible: 100,
        grading_type: 'percent',
      },
      submission: {
        submitted_at: '2016-08-22T14:52:43Z',
        grade: '100',
      },
    },
    followOnAssignments: [
      {
        score: 100,
        trend: 1,
        assignment: {
          id: '2',
          name: 'hello world',
          grading_type: 'percent',
          points_possible: 100,
          submission_types: ['online_text_entry'],
        },
      },
    ],
    selectNextStudent: jest.fn(),
    selectPrevStudent: jest.fn(),
    unselectStudent: jest.fn(),
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the student details component', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByTestId('student-details')).toBeInTheDocument()
  })

  it('displays the student header section', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByTestId('student-details-header')).toBeInTheDocument()
  })

  it('displays the student profile section', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByTestId('student-details-profile')).toBeInTheDocument()
  })

  it('displays the assignment scores section', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByTestId('student-details-scores')).toBeInTheDocument()
  })

  it('displays the correct student name', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByText('foo')).toBeInTheDocument()
  })

  it('displays the correct assignment name', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByTestId('student-details-scores')).toHaveTextContent('hello world')
  })

  it('displays the correct submission date', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByText('Submitted: August 22, 2016')).toBeInTheDocument()
  })

  it('renders navigation links', () => {
    render(<StudentDetailsComponent {...defaultProps} />)
    expect(screen.getByRole('link', {name: 'Send Message'})).toBeInTheDocument()
    expect(screen.getByRole('link', {name: 'View Submission'})).toBeInTheDocument()
  })
})
