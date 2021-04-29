/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
 *
 */

import React from 'react'
import {cleanup, render} from '@testing-library/react'

import GradesSummary from '../GradesSummary'

const defaultCourse = {
  courseId: '1',
  courseName: 'Horticulture',
  currentGradingPeriodId: '1',
  enrollmentType: 'student',
  score: 90
}

describe('GradesSummary', () => {
  it('displays the score as a percentage if present and grading schemes are not used', () => {
    const {getByText} = render(<GradesSummary courses={[defaultCourse]} />)
    expect(getByText('90%')).toBeInTheDocument()
  })

  it('displays screen reader-accessible representations of percentages when grading schemes are not used', () => {
    const {getByLabelText} = render(<GradesSummary courses={[defaultCourse]} />)
    const progressBar = getByLabelText('Grade for Horticulture', {exact: false})
    expect(progressBar).toBeInTheDocument()
    expect(progressBar).toHaveAttribute('aria-valuenow', '90')
    expect(progressBar).toHaveAttribute('aria-valuemax', '100')
    expect(progressBar).toHaveAttribute('aria-valuetext', '90% of points possible')
  })

  it('displays the score as a grade if present and grading schemes are in use', () => {
    const {getByText, queryByText} = render(
      <GradesSummary courses={[{...defaultCourse, grade: 'Not Bad'}]} />
    )
    expect(getByText('Not Bad')).toBeInTheDocument()
    expect(queryByText('90%')).not.toBeInTheDocument()
  })

  it('displays "Not Graded" if no score is present', () => {
    expect(
      render(<GradesSummary courses={[{...defaultCourse, score: undefined}]} />).getByText(
        'Not Graded'
      )
    ).toBeInTheDocument()
    cleanup()

    expect(
      render(<GradesSummary courses={[{...defaultCourse, score: null}]} />).getByText('Not Graded')
    ).toBeInTheDocument()
    cleanup()

    expect(
      render(<GradesSummary courses={[{...defaultCourse, score: 0}]} />).getByText('0%')
    ).toBeInTheDocument()
  })

  it('displays "--" if a course has no current grading period', () => {
    const {getByText} = render(
      <GradesSummary
        courses={[{...defaultCourse, score: undefined, currentGradingPeriodId: undefined}]}
      />
    )
    expect(getByText('--')).toBeInTheDocument()
  })

  it('shows the course image if one is given', () => {
    const {getByTestId} = render(
      <GradesSummary courses={[{...defaultCourse, courseImage: 'http://link/to/image.jpg'}]} />
    )
    const image = getByTestId('k5-grades-course-image')
    expect(image.style.getPropertyValue('background-image')).toBe('url(http://link/to/image.jpg)')
  })

  it('shows the course color if one is given and an image is not', () => {
    const {getByTestId} = render(
      <GradesSummary courses={[{...defaultCourse, courseColor: 'red'}]} />
    )
    const image = getByTestId('k5-grades-course-image')
    expect(image.style.getPropertyValue('background-color')).toBe('red')
  })

  it('shows the default background medium color if no course color or image are given', () => {
    const {getByTestId} = render(<GradesSummary courses={[defaultCourse]} />)
    const image = getByTestId('k5-grades-course-image')
    expect(image.style.getPropertyValue('background-color')).toBe('rgb(57, 75, 88)')
  })

  it('renders a link to the gradebook if the user is enrolled as a teacher', () => {
    const {getByTestId, getByRole, queryByLabelText} = render(
      <GradesSummary courses={[{...defaultCourse, enrollmentType: 'teacher'}]} />
    )
    expect(getByTestId('k5-grades-course-image')).toBeInTheDocument()
    expect(queryByLabelText('Grade for Horticulture', {exact: false})).not.toBeInTheDocument()
    expect(getByRole('link', {name: 'View Gradebook for Horticulture'})).toBeInTheDocument()
  })

  it('does not render a link to the gradebook for students', () => {
    const {queryByRole} = render(<GradesSummary courses={[defaultCourse]} />)
    expect(queryByRole('link', {name: 'View Gradebook for Horticulture'})).not.toBeInTheDocument()
  })
})
