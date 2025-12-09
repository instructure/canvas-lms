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
import {StudentSection, StudentSectionProps} from '../StudentSection'
import {MOCK_STUDENTS} from '../../../../__fixtures__/rollups'

describe('StudentSection', () => {
  const defaultProps: StudentSectionProps = {
    currentStudent: MOCK_STUDENTS[0],
    masteryReportUrl: '/courses/123/outcome_rollups/456',
    hasPrevious: true,
    hasNext: true,
    onPrevious: jest.fn(),
    onNext: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders student avatar', () => {
    render(<StudentSection {...defaultProps} />)
    const avatar = screen.getByRole('img', {name: MOCK_STUDENTS[0].name})
    expect(avatar).toBeInTheDocument()
  })

  it('renders student name', () => {
    render(<StudentSection {...defaultProps} />)
    expect(screen.getByText(MOCK_STUDENTS[0].name)).toBeInTheDocument()
  })

  it('renders mastery report link', () => {
    render(<StudentSection {...defaultProps} />)
    const link = screen.getByRole('link', {name: /View Mastery Report/i})
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/courses/123/outcome_rollups/456')
  })

  it('opens mastery report link in new tab', () => {
    render(<StudentSection {...defaultProps} />)
    const link = screen.getByRole('link', {name: /View Mastery Report/i})
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('renders navigator with previous and next buttons', () => {
    render(<StudentSection {...defaultProps} />)
    expect(screen.getByTestId('student-navigator')).toBeInTheDocument()
    expect(screen.getByTestId('previous-button')).toBeInTheDocument()
    expect(screen.getByTestId('next-button')).toBeInTheDocument()
  })

  it('calls onPrevious when previous button is clicked', async () => {
    const user = userEvent.setup()
    const onPrevious = jest.fn()
    render(<StudentSection {...defaultProps} onPrevious={onPrevious} />)

    await user.click(screen.getByTestId('previous-button'))
    expect(onPrevious).toHaveBeenCalledTimes(1)
  })

  it('calls onNext when next button is clicked', async () => {
    const user = userEvent.setup()
    const onNext = jest.fn()
    render(<StudentSection {...defaultProps} onNext={onNext} />)

    await user.click(screen.getByTestId('next-button'))
    expect(onNext).toHaveBeenCalledTimes(1)
  })

  it('disables previous button when hasPrevious is false', () => {
    render(<StudentSection {...defaultProps} hasPrevious={false} />)
    expect(screen.getByTestId('previous-button')).toBeDisabled()
  })

  it('disables next button when hasNext is false', () => {
    render(<StudentSection {...defaultProps} hasNext={false} />)
    expect(screen.getByTestId('next-button')).toBeDisabled()
  })

  it('uses custom labels for navigator buttons', () => {
    render(
      <StudentSection
        {...defaultProps}
        previousLabel="Previous Student Custom"
        nextLabel="Next Student Custom"
      />,
    )
    const previousButton = screen.getByTestId('previous-button')
    const nextButton = screen.getByTestId('next-button')
    expect(previousButton).toHaveAccessibleName('Previous Student Custom')
    expect(nextButton).toHaveAccessibleName('Next Student Custom')
  })

  it('uses default labels when not provided', () => {
    render(<StudentSection {...defaultProps} />)
    const previousButton = screen.getByTestId('previous-button')
    const nextButton = screen.getByTestId('next-button')
    expect(previousButton).toHaveAccessibleName('Previous student')
    expect(nextButton).toHaveAccessibleName('Next student')
  })

  it('truncates long student names', () => {
    const longStudentName =
      'This is a very long student name that should be truncated to fit in the available space'
    render(
      <StudentSection
        {...defaultProps}
        currentStudent={{
          ...MOCK_STUDENTS[0],
          name: longStudentName,
        }}
      />,
    )
    expect(screen.getByText(longStudentName)).toBeInTheDocument()
  })

  it('renders different student when currentStudent changes', () => {
    const {rerender} = render(<StudentSection {...defaultProps} />)
    expect(screen.getByText(MOCK_STUDENTS[0].name)).toBeInTheDocument()

    rerender(<StudentSection {...defaultProps} currentStudent={MOCK_STUDENTS[1]} />)
    expect(screen.getByText(MOCK_STUDENTS[1].name)).toBeInTheDocument()
    expect(screen.queryByText(MOCK_STUDENTS[0].name)).not.toBeInTheDocument()
  })

  it('displays avatar with student avatar URL', () => {
    render(<StudentSection {...defaultProps} />)
    const avatar = screen.getByRole('img', {name: MOCK_STUDENTS[0].name})
    expect(avatar).toHaveAttribute('src', MOCK_STUDENTS[0].avatar_url)
  })
})
