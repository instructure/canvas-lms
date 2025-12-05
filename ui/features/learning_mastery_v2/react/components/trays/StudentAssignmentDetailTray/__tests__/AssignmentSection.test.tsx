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
import {AssignmentSection, AssignmentSectionProps} from '../AssignmentSection'

describe('AssignmentSection', () => {
  const defaultProps: AssignmentSectionProps = {
    courseId: '123',
    studentId: '456',
    currentAssignment: {
      id: '789',
      name: 'Test Assignment',
      htmlUrl: '/courses/123/assignments/789',
    },
    hasPrevious: true,
    hasNext: true,
    onPrevious: jest.fn(),
    onNext: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders assignment name as a link', () => {
    render(<AssignmentSection {...defaultProps} />)
    const link = screen.getByRole('link', {name: /Test Assignment/i})
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/courses/123/assignments/789')
  })

  it('opens assignment link in new tab', () => {
    render(<AssignmentSection {...defaultProps} />)
    const link = screen.getByRole('link', {name: /Test Assignment/i})
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('renders SpeedGrader button with correct props', () => {
    render(<AssignmentSection {...defaultProps} />)
    const speedGraderButton = screen.getByRole('link', {name: /SpeedGrader/i})
    expect(speedGraderButton).toBeInTheDocument()
    expect(speedGraderButton).toHaveAttribute(
      'href',
      '/courses/123/gradebook/speed_grader?assignment_id=789&student_id=456',
    )
  })

  it('renders navigator with previous and next buttons', () => {
    render(<AssignmentSection {...defaultProps} />)
    expect(screen.getByTestId('assignment-navigator')).toBeInTheDocument()
    expect(screen.getByTestId('previous-button')).toBeInTheDocument()
    expect(screen.getByTestId('next-button')).toBeInTheDocument()
  })

  it('calls onPrevious when previous button is clicked', async () => {
    const user = userEvent.setup()
    const onPrevious = jest.fn()
    render(<AssignmentSection {...defaultProps} onPrevious={onPrevious} />)

    await user.click(screen.getByTestId('previous-button'))
    expect(onPrevious).toHaveBeenCalledTimes(1)
  })

  it('calls onNext when next button is clicked', async () => {
    const user = userEvent.setup()
    const onNext = jest.fn()
    render(<AssignmentSection {...defaultProps} onNext={onNext} />)

    await user.click(screen.getByTestId('next-button'))
    expect(onNext).toHaveBeenCalledTimes(1)
  })

  it('disables previous button when hasPrevious is false', () => {
    render(<AssignmentSection {...defaultProps} hasPrevious={false} />)
    expect(screen.getByTestId('previous-button')).toBeDisabled()
  })

  it('disables next button when hasNext is false', () => {
    render(<AssignmentSection {...defaultProps} hasNext={false} />)
    expect(screen.getByTestId('next-button')).toBeDisabled()
  })

  it('uses custom labels for navigator buttons', () => {
    render(
      <AssignmentSection
        {...defaultProps}
        previousLabel="Previous Assignment"
        nextLabel="Next Assignment"
      />,
    )
    expect(screen.getByText('Previous Assignment')).toBeInTheDocument()
    expect(screen.getByText('Next Assignment')).toBeInTheDocument()
  })

  it('uses default labels when not provided', () => {
    render(<AssignmentSection {...defaultProps} />)
    expect(screen.getByText('Previous assignment')).toBeInTheDocument()
    expect(screen.getByText('Next assignment')).toBeInTheDocument()
  })

  it('truncates long assignment names', () => {
    const longAssignmentName =
      'This is a very long assignment name that should be truncated to fit in the available space'
    render(
      <AssignmentSection
        {...defaultProps}
        currentAssignment={{
          ...defaultProps.currentAssignment,
          name: longAssignmentName,
        }}
      />,
    )
    expect(screen.getByText(longAssignmentName)).toBeInTheDocument()
  })
})
