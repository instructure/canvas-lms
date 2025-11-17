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
import CourseWorkFilters from '../CourseWorkFilters'
import type {CourseOption} from '../../../types'

describe('CourseWorkFilters', () => {
  const mockCourses: CourseOption[] = [
    {id: 'course_1', name: 'Course 1'},
    {id: 'course_2', name: 'Course 2'},
  ]

  const defaultProps = {
    selectedCourse: 'all',
    selectedDateFilter: 'not_submitted' as const,
    onCourseChange: jest.fn(),
    onDateFilterChange: jest.fn(),
    userCourses: mockCourses,
  }

  it('renders course filter label', () => {
    render(<CourseWorkFilters {...defaultProps} />)
    expect(screen.getByText('Course filter:')).toBeInTheDocument()
    expect(screen.getByTestId('course-filter-select')).toBeInTheDocument()
  })

  it('renders submission status filter with correct label', () => {
    render(<CourseWorkFilters {...defaultProps} />)
    expect(screen.getByText('Submission status:')).toBeInTheDocument()
  })

  it('renders submission status filter options', async () => {
    const user = userEvent.setup()
    render(<CourseWorkFilters {...defaultProps} />)

    const submissionStatusSelect = screen.getByTestId('submission-status-filter-select')
    await user.click(submissionStatusSelect)

    expect(screen.getByText('Not submitted')).toBeInTheDocument()
    expect(screen.getByText('Missing')).toBeInTheDocument()
    expect(screen.getByText('Submitted')).toBeInTheDocument()
  })

  it('does not render date filter options', async () => {
    const user = userEvent.setup()
    render(<CourseWorkFilters {...defaultProps} />)

    const submissionStatusSelect = screen.getByTestId('submission-status-filter-select')
    await user.click(submissionStatusSelect)

    expect(screen.queryByText('Next 3 days')).not.toBeInTheDocument()
    expect(screen.queryByText('Next 7 days')).not.toBeInTheDocument()
    expect(screen.queryByText('Next 14 days')).not.toBeInTheDocument()
  })

  it('calls onDateFilterChange when submission status is changed', async () => {
    const user = userEvent.setup()
    const onDateFilterChange = jest.fn()

    render(<CourseWorkFilters {...defaultProps} onDateFilterChange={onDateFilterChange} />)

    const submissionStatusSelect = screen.getByTestId('submission-status-filter-select')
    await user.click(submissionStatusSelect)

    const submittedOption = screen.getByText('Submitted')
    await user.click(submittedOption)

    expect(onDateFilterChange).toHaveBeenCalled()
  })

  it('calls onCourseChange when course is changed', async () => {
    const user = userEvent.setup()
    const onCourseChange = jest.fn()

    render(<CourseWorkFilters {...defaultProps} onCourseChange={onCourseChange} />)

    const courseSelect = screen.getByTestId('course-filter-select')
    await user.click(courseSelect)

    const course1Option = screen.getByText('Course 1')
    await user.click(course1Option)

    expect(onCourseChange).toHaveBeenCalled()
  })
})
