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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {StudentAssignmentDetailTray} from '..'
import {MOCK_OUTCOMES, MOCK_STUDENTS} from '../../../../__fixtures__/rollups'

describe('StudentAssignmentDetailTray', () => {
  const defaultProps = {
    open: true,
    onDismiss: vi.fn(),
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
      onPrevious: vi.fn(),
      onNext: vi.fn(),
    },
    studentNavigator: {
      hasPrevious: true,
      hasNext: true,
      onPrevious: vi.fn(),
      onNext: vi.fn(),
    },
  }

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('General behavior', () => {
    it('renders when open', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByTestId('student-assignment-detail-tray')).toBeInTheDocument()
    })

    it('does not render when closed', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} open={false} />)
      const tray = screen.queryByTestId('student-assignment-detail-tray')
      expect(tray).not.toBeInTheDocument()
    })

    it('displays the outcome title', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByText(defaultProps.outcome.title)).toBeInTheDocument()
    })

    it('calls onDismiss when close button is clicked', async () => {
      const user = userEvent.setup()
      const onDismiss = vi.fn()
      render(<StudentAssignmentDetailTray {...defaultProps} onDismiss={onDismiss} />)

      const closeButton = screen.getByRole('button', {name: /close/i})
      await user.click(closeButton)

      expect(onDismiss).toHaveBeenCalledTimes(1)
    })
  })

  describe('AssignmentSection integration', () => {
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

    it('calls assignmentNavigator onPrevious when assignment previous button is clicked', async () => {
      const user = userEvent.setup()
      const onPrevious = vi.fn()
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, onPrevious}}
        />,
      )

      const assignmentNav = screen.getByTestId('assignment-navigator')
      const previousButton = assignmentNav.querySelector('[data-testid="previous-button"]')
      await user.click(previousButton!)
      expect(onPrevious).toHaveBeenCalledTimes(1)
    })

    it('calls assignmentNavigator onNext when assignment next button is clicked', async () => {
      const user = userEvent.setup()
      const onNext = vi.fn()
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, onNext}}
        />,
      )

      const assignmentNav = screen.getByTestId('assignment-navigator')
      const nextButton = assignmentNav.querySelector('[data-testid="next-button"]')
      await user.click(nextButton!)
      expect(onNext).toHaveBeenCalledTimes(1)
    })

    it('disables assignment previous button when hasPrevious is false', () => {
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, hasPrevious: false}}
        />,
      )
      const assignmentNav = screen.getByTestId('assignment-navigator')
      const previousButton = assignmentNav.querySelector('[data-testid="previous-button"]')
      expect(previousButton).toBeDisabled()
    })

    it('disables assignment next button when hasNext is false', () => {
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, hasNext: false}}
        />,
      )
      const assignmentNav = screen.getByTestId('assignment-navigator')
      const nextButton = assignmentNav.querySelector('[data-testid="next-button"]')
      expect(nextButton).toBeDisabled()
    })
  })

  describe('StudentSection integration', () => {
    it('renders student navigator', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByTestId('student-navigator')).toBeInTheDocument()
    })

    it('displays student name', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByText(MOCK_STUDENTS[0].name)).toBeInTheDocument()
    })

    it('displays student avatar', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} />)
      const avatar = screen.getByRole('img', {name: MOCK_STUDENTS[0].name})
      expect(avatar).toBeInTheDocument()
      expect(avatar).toHaveAttribute('src', MOCK_STUDENTS[0].avatar_url)
    })

    it('renders mastery report link with correct URL', () => {
      render(<StudentAssignmentDetailTray {...defaultProps} />)
      const link = screen.getByRole('link', {name: /View Mastery Report/i})
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/courses/123/grades/1#tab-outcomes')
    })

    it('calls studentNavigator onPrevious when student previous button is clicked', async () => {
      const user = userEvent.setup()
      const onPrevious = vi.fn()
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, onPrevious}}
        />,
      )

      const studentNav = screen.getByTestId('student-navigator')
      const previousButton = studentNav.querySelector('[data-testid="previous-button"]')
      await user.click(previousButton!)
      expect(onPrevious).toHaveBeenCalledTimes(1)
    })

    it('calls studentNavigator onNext when student next button is clicked', async () => {
      const user = userEvent.setup()
      const onNext = vi.fn()
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, onNext}}
        />,
      )

      const studentNav = screen.getByTestId('student-navigator')
      const nextButton = studentNav.querySelector('[data-testid="next-button"]')
      await user.click(nextButton!)
      expect(onNext).toHaveBeenCalledTimes(1)
    })

    it('disables student previous button when hasPrevious is false', () => {
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, hasPrevious: false}}
        />,
      )
      const studentNav = screen.getByTestId('student-navigator')
      const previousButton = studentNav.querySelector('[data-testid="previous-button"]')
      expect(previousButton).toBeDisabled()
    })

    it('disables student next button when hasNext is false', () => {
      render(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, hasNext: false}}
        />,
      )
      const studentNav = screen.getByTestId('student-navigator')
      const nextButton = studentNav.querySelector('[data-testid="next-button"]')
      expect(nextButton).toBeDisabled()
    })

    it('updates student information when student prop changes', () => {
      const {rerender} = render(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByText(MOCK_STUDENTS[0].name)).toBeInTheDocument()

      rerender(<StudentAssignmentDetailTray {...defaultProps} student={MOCK_STUDENTS[1]} />)
      expect(screen.getByText(MOCK_STUDENTS[1].name)).toBeInTheDocument()
      expect(screen.queryByText(MOCK_STUDENTS[0].name)).not.toBeInTheDocument()
    })
  })
})
