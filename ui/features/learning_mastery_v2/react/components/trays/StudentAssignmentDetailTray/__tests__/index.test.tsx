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
import userEvent from '@testing-library/user-event'
import {StudentAssignmentDetailTray} from '..'
import {MOCK_OUTCOMES, MOCK_STUDENTS} from '../../../../__fixtures__/rollups'

describe('StudentAssignmentDetailTray', () => {
  const defaultProps = {
    open: true,
    onDismiss: jest.fn(),
    outcome: MOCK_OUTCOMES[0],
    courseId: '123',
    student: MOCK_STUDENTS[0],
    assignment: {
      id: '456',
      name: 'Test Assignment',
      htmlUrl: '/courses/123/assignments/456',
    },
    assignmentNavigator: {
      hasPrevious: true,
      hasNext: true,
      onPrevious: jest.fn(),
      onNext: jest.fn(),
    },
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders when open', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    expect(screen.getByTestId('student-assignment-detail-tray')).toBeInTheDocument()
  })

  it('displays the outcome title', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    expect(screen.getByText(defaultProps.outcome.title)).toBeInTheDocument()
  })

  it('displays the assignment name as a link', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    const link = screen.getByRole('link', {name: /Test Assignment/i})
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/courses/123/assignments/456')
  })

  it('renders SpeedGrader button', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    const speedGraderButton = screen.getByRole('link', {name: /SpeedGrader/i})
    expect(speedGraderButton).toBeInTheDocument()
    expect(speedGraderButton).toHaveAttribute(
      'href',
      '/courses/123/gradebook/speed_grader?assignment_id=456&student_id=1',
    )
  })

  it('renders assignment navigator', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} />)
    expect(screen.getByTestId('assignment-navigator')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', async () => {
    const user = userEvent.setup()
    const onDismiss = jest.fn()
    render(<StudentAssignmentDetailTray {...defaultProps} onDismiss={onDismiss} />)

    const closeButton = screen.getByRole('button', {name: /close/i})
    await user.click(closeButton)

    expect(onDismiss).toHaveBeenCalledTimes(1)
  })

  it('calls onPrevious when previous button is clicked', async () => {
    const user = userEvent.setup()
    const onPrevious = jest.fn()
    render(
      <StudentAssignmentDetailTray
        {...defaultProps}
        assignmentNavigator={{...defaultProps.assignmentNavigator, onPrevious}}
      />,
    )

    await user.click(screen.getByTestId('previous-button'))
    expect(onPrevious).toHaveBeenCalledTimes(1)
  })

  it('calls onNext when next button is clicked', async () => {
    const user = userEvent.setup()
    const onNext = jest.fn()
    render(
      <StudentAssignmentDetailTray
        {...defaultProps}
        assignmentNavigator={{...defaultProps.assignmentNavigator, onNext}}
      />,
    )

    await user.click(screen.getByTestId('next-button'))
    expect(onNext).toHaveBeenCalledTimes(1)
  })

  it('disables previous button when hasPrevious is false', () => {
    render(
      <StudentAssignmentDetailTray
        {...defaultProps}
        assignmentNavigator={{...defaultProps.assignmentNavigator, hasPrevious: false}}
      />,
    )
    expect(screen.getByTestId('previous-button')).toBeDisabled()
  })

  it('disables next button when hasNext is false', () => {
    render(
      <StudentAssignmentDetailTray
        {...defaultProps}
        assignmentNavigator={{...defaultProps.assignmentNavigator, hasNext: false}}
      />,
    )
    expect(screen.getByTestId('next-button')).toBeDisabled()
  })

  it('does not render when closed', () => {
    render(<StudentAssignmentDetailTray {...defaultProps} open={false} />)
    const tray = screen.queryByTestId('student-assignment-detail-tray')
    expect(tray).not.toBeInTheDocument()
  })
})
