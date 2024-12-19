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
import userEvent from '@testing-library/user-event'
import BreakdownDetails from '../breakdown-details'

describe('Breakdown Details', () => {
  const defaultProps = () => ({
    ranges: [
      {
        scoring_range: {
          id: 1,
          rule_id: 1,
          lower_bound: 0.7,
          upper_bound: 1.0,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 2,
        students: [
          {
            user: {
              id: 1,
              name: 'foo',
              login_id: 'student1',
              avatar_image_url: '/images/messages/avatar-50.png',
            },
          },
          {
            user: {
              id: 2,
              name: 'bar',
              login_id: 'student2',
              avatar_image_url: '/images/messages/avatar-50.png',
            },
          },
        ],
      },
      {
        scoring_range: {
          id: 3,
          rule_id: 1,
          lower_bound: 0.4,
          upper_bound: 0.7,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
      {
        scoring_range: {
          id: 2,
          rule_id: 1,
          lower_bound: 0.0,
          upper_bound: 0.4,
          created_at: null,
          updated_at: null,
          position: null,
        },
        size: 0,
        students: [],
      },
    ],
    students: {
      1: {
        triggerAssignment: {
          assignment: {
            id: '1',
            name: 'hello world',
            points_possible: 100,
            grading_type: 'percent',
            submission_types: ['online_text_entry'],
          },
          submission: {
            submitted_at: '2016-08-22T14:52:43Z',
            grade: '100',
          },
        },
        followOnAssignments: [
          {
            assignment: {
              id: '2',
              name: 'hello world',
              points_possible: 100,
              grading_type: 'percent',
              submission_types: ['online_text_entry'],
            },
            submission: {
              submitted_at: '2016-08-22T14:52:43Z',
              grade: '100',
            },
          },
        ],
      },
      2: {
        triggerAssignment: {
          assignment: {
            id: '1',
            name: 'hello world',
            points_possible: 100,
            grading_type: 'percent',
            submission_types: ['online_text_entry'],
          },
          submission: {
            submitted_at: '2016-08-22T14:52:43Z',
            grade: '100',
          },
        },
        followOnAssignments: [
          {
            assignment: {
              id: '2',
              name: 'hello world',
              points_possible: 100,
              grading_type: 'percent',
              submission_types: ['online_text_entry'],
            },
            submission: {
              submitted_at: '2016-08-22T14:52:43Z',
              grade: '100',
            },
          },
        ],
      },
    },
    assignment: {
      id: 7,
      title: 'Points',
      description: '',
      points_possible: 15,
      grading_type: 'points',
      submission_types: ['on_paper'],
      grading_scheme: null,
      course_id: 1,
    },
    selectedPath: {
      range: 0,
      student: null,
    },
    showDetails: true,
    isStudentDetailsLoading: false,
    closeSidebar: () => {},
    selectStudent: () => {},
  })

  beforeEach(() => {
    // No need for fake timers in these tests
  })

  afterEach(() => {
    // No need for fake timers in these tests
  })

  it('renders component correctly', () => {
    const props = defaultProps()
    props.showDetails = true
    props.closeSidebar = jest.fn()
    render(<BreakdownDetails {...props} />)
    expect(screen.getByTestId('breakdown-details')).toBeInTheDocument()
  })

  it('clicking next student calls select student with the next student index', async () => {
    const props = defaultProps()
    props.selectedPath = {range: 0, student: 0}
    props.selectStudent = jest.fn()
    props.closeSidebar = jest.fn()
    const user = userEvent.setup()
    render(<BreakdownDetails {...props} />)

    await user.click(screen.getByRole('button', {name: /next/i}))
    expect(props.selectStudent).toHaveBeenCalledWith(1)
  })

  it('clicking next student on the last student wraps around to first student', async () => {
    const props = defaultProps()
    props.selectedPath = {range: 0, student: 1}
    props.selectStudent = jest.fn()
    props.closeSidebar = jest.fn()
    const user = userEvent.setup()
    render(<BreakdownDetails {...props} />)

    await user.click(screen.getByRole('button', {name: /next/i}))
    expect(props.selectStudent).toHaveBeenCalledWith(0)
  })

  it('clicking prev student calls select student with the correct student index', async () => {
    const props = defaultProps()
    props.selectedPath = {range: 0, student: 1}
    props.selectStudent = jest.fn()
    props.closeSidebar = jest.fn()
    const user = userEvent.setup()
    render(<BreakdownDetails {...props} />)

    await user.click(screen.getByRole('button', {name: /previous/i}))
    expect(props.selectStudent).toHaveBeenCalledWith(0)
  })

  it('clicking prev student on first student wraps around to last student', async () => {
    const props = defaultProps()
    props.selectedPath = {range: 0, student: 0}
    props.selectStudent = jest.fn()
    props.closeSidebar = jest.fn()
    const user = userEvent.setup()
    render(<BreakdownDetails {...props} />)

    await user.click(screen.getByRole('button', {name: /previous/i}))
    expect(props.selectStudent).toHaveBeenCalledWith(1)
  })

  it('clicking back on student details unselects student', async () => {
    const props = defaultProps()
    props.selectedPath = {range: 0, student: 0}
    props.selectStudent = jest.fn()
    const user = userEvent.setup()
    render(<BreakdownDetails {...props} />)

    // Click the back button in the student details view
    const backButton = screen.getByTestId('back-button')
    await user.click(backButton)

    expect(props.selectStudent).toHaveBeenCalledWith(null)
  })

  it('clicking back button calls closeSidebar', async () => {
    const props = defaultProps()
    props.selectedPath.student = 1
    props.closeSidebar = jest.fn()
    const user = userEvent.setup()
    render(<BreakdownDetails {...props} />)
    const closeButton = screen.getByTestId('breakdown-details-close')
    await user.click(closeButton)
    expect(props.closeSidebar).toHaveBeenCalled()
  })
})
