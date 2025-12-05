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
import CourseProgressBar, {calculateProgressSegments} from '../CourseProgressBar'

describe('calculateProgressSegments', () => {
  it('returns no assignments segment when all counts are zero', () => {
    const segments = calculateProgressSegments(0, 0, 0, 0)

    expect(segments).toHaveLength(1)
    expect(segments[0]).toEqual({
      color: '#D8E7F3',
      percentage: 100,
      label: 'No assignments',
      testId: 'no-assignments',
    })
  })

  it('calculates correct percentages for all segment types', () => {
    const segments = calculateProgressSegments(10, 5, 3, 2)

    expect(segments).toHaveLength(4)
    expect(segments[0]).toMatchObject({
      color: '#1E9975',
      percentage: 50,
      label: 'Submitted and graded',
      testId: 'graded',
    })
    expect(segments[1]).toMatchObject({
      color: '#2573DF',
      percentage: 25,
      label: 'Submitted not graded',
      testId: 'not-graded',
    })
    expect(segments[2]).toMatchObject({
      color: '#DB6414',
      percentage: 15,
      label: 'Missing',
      testId: 'missing',
    })
    expect(segments[3]).toMatchObject({
      color: '#D8E7F3',
      percentage: 10,
      label: 'Due',
      testId: 'due',
    })
  })

  it('omits segments with zero counts', () => {
    const segments = calculateProgressSegments(8, 2, 0, 0)

    expect(segments).toHaveLength(2)
    expect(segments[0].testId).toBe('graded')
    expect(segments[1].testId).toBe('not-graded')
  })

  it('handles only graded assignments', () => {
    const segments = calculateProgressSegments(10, 0, 0, 0)

    expect(segments).toHaveLength(1)
    expect(segments[0]).toMatchObject({
      percentage: 100,
      testId: 'graded',
    })
  })

  it('handles only overdue assignments', () => {
    const segments = calculateProgressSegments(0, 0, 5, 0)

    expect(segments).toHaveLength(1)
    expect(segments[0]).toMatchObject({
      percentage: 100,
      testId: 'missing',
    })
  })

  it('calculates correct percentages with decimal results', () => {
    const segments = calculateProgressSegments(1, 1, 1, 0)

    expect(segments).toHaveLength(3)
    expect(segments[0].percentage).toBeCloseTo(33.33, 2)
    expect(segments[1].percentage).toBeCloseTo(33.33, 2)
    expect(segments[2].percentage).toBeCloseTo(33.33, 2)
  })
})

describe('CourseProgressBar', () => {
  it('renders progress bar with correct test id', () => {
    render(
      <CourseProgressBar
        submittedAndGradedCount={5}
        submittedNotGradedCount={3}
        missingSubmissionsCount={2}
        submissionsDueCount={1}
        courseId="123"
      />,
    )

    expect(screen.getByTestId('progress-bar-123')).toBeInTheDocument()
  })

  it('renders all segment types when all have counts', () => {
    render(
      <CourseProgressBar
        submittedAndGradedCount={5}
        submittedNotGradedCount={3}
        missingSubmissionsCount={2}
        submissionsDueCount={1}
        courseId="123"
      />,
    )

    expect(screen.getByTestId('progress-segment-graded-123')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-not-graded-123')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-missing-123')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-due-123')).toBeInTheDocument()
  })

  it('renders no assignments segment when all counts are zero', () => {
    render(
      <CourseProgressBar
        submittedAndGradedCount={0}
        submittedNotGradedCount={0}
        missingSubmissionsCount={0}
        submissionsDueCount={0}
        courseId="456"
      />,
    )

    expect(screen.getByTestId('progress-segment-no-assignments-456')).toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-graded-456')).not.toBeInTheDocument()
  })

  it('renders only present segments', () => {
    render(
      <CourseProgressBar
        submittedAndGradedCount={8}
        submittedNotGradedCount={2}
        missingSubmissionsCount={0}
        submissionsDueCount={0}
        courseId="789"
      />,
    )

    expect(screen.getByTestId('progress-segment-graded-789')).toBeInTheDocument()
    expect(screen.getByTestId('progress-segment-not-graded-789')).toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-missing-789')).not.toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-due-789')).not.toBeInTheDocument()
  })

  it('renders single segment when only one type exists', () => {
    render(
      <CourseProgressBar
        submittedAndGradedCount={0}
        submittedNotGradedCount={0}
        missingSubmissionsCount={5}
        submissionsDueCount={0}
        courseId="999"
      />,
    )

    expect(screen.getByTestId('progress-segment-missing-999')).toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-graded-999')).not.toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-not-graded-999')).not.toBeInTheDocument()
    expect(screen.queryByTestId('progress-segment-due-999')).not.toBeInTheDocument()
  })
})
