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
import CourseProgressItem from '../CourseProgressItem'
import type {CourseProgress} from '../../../../hooks/useProgressOverview'

const mockCourse: CourseProgress = {
  courseId: '1',
  courseName: 'Environmental Science',
  courseCode: 'ENVS150',
  submittedAndGradedCount: 8,
  submittedNotGradedCount: 2,
  missingSubmissionsCount: 1,
  submissionsDueCount: 3,
}

describe('CourseProgressItem', () => {
  it('renders course link with correct href', () => {
    render(<CourseProgressItem course={mockCourse} />)

    const link = screen.getByTestId('course-link-1')
    expect(link).toHaveAttribute('href', '/courses/1')
  })

  it('renders progress bar with course data', () => {
    render(<CourseProgressItem course={mockCourse} />)

    expect(screen.getByTestId('progress-bar-1')).toBeInTheDocument()
  })

  it('renders with correct test id for container', () => {
    render(<CourseProgressItem course={mockCourse} />)

    expect(screen.getByTestId('course-progress-item-1')).toBeInTheDocument()
  })

  it('renders all progress segments when all counts are present', () => {
    render(<CourseProgressItem course={mockCourse} />)

    expect(screen.getByTestId('progress-segment-graded-1')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-not-graded-1')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-missing-1')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-due-1')).toBeInTheDocument()
  })

  it('renders course with no assignments', () => {
    const courseNoAssignments: CourseProgress = {
      courseId: '2',
      courseName: 'Empty Course',
      courseCode: 'EMPTY101',
      submittedAndGradedCount: 0,
      submittedNotGradedCount: 0,
      missingSubmissionsCount: 0,
      submissionsDueCount: 0,
    }

    render(<CourseProgressItem course={courseNoAssignments} />)

    expect(screen.getByTestId('progress-segment-no-assignments-2')).toBeInTheDocument()
  })

  it('renders course with only overdue assignments', () => {
    const courseWithMissing: CourseProgress = {
      courseId: '3',
      courseName: 'Missing Course',
      courseCode: 'OVER202',
      submittedAndGradedCount: 0,
      submittedNotGradedCount: 0,
      missingSubmissionsCount: 5,
      submissionsDueCount: 0,
    }

    render(<CourseProgressItem course={courseWithMissing} />)

    expect(screen.getByTestId('progress-segment-missing-3')).toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-graded-3')).not.toBeInTheDocument()
  })

  it('has accessible link with aria-label', () => {
    render(<CourseProgressItem course={mockCourse} />)

    const link = screen.getByTestId('course-link-1')
    expect(link).toHaveAttribute('aria-label', 'Go to Environmental Science')
  })

  it('renders course with different id correctly', () => {
    const differentCourse: CourseProgress = {
      courseId: '999',
      courseName: 'Mathematics',
      courseCode: 'MATH300',
      submittedAndGradedCount: 5,
      submittedNotGradedCount: 1,
      missingSubmissionsCount: 0,
      submissionsDueCount: 2,
    }

    render(<CourseProgressItem course={differentCourse} />)

    expect(screen.getByTestId('course-progress-item-999')).toBeInTheDocument()
    expect(screen.getByTestId('course-link-999')).toHaveAttribute('href', '/courses/999')
  })
})
