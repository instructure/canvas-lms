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
  finalGradesHidden: false,
  score: 90,
}

const DEFAULT_GRADING_SCHEME = [
  ['A', 0.94],
  ['A-', 0.9],
  ['B+', 0.87],
  ['B', 0.84],
  ['B-', 0.8],
  ['C+', 0.77],
  ['C', 0.74],
  ['C-', 0.7],
  ['D+', 0.67],
  ['D', 0.64],
  ['D-', 0.61],
  ['F', 0.0],
]

describe('GradesSummary', () => {
  beforeAll(() => {
    window.location.hash = '#grades'
  })

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

  it('hides progress bar if restrictQuantitativeData is true', () => {
    const {queryByLabelText} = render(
      <GradesSummary
        courses={[
          {...defaultCourse, restrictQuantitativeData: true, gradingScheme: DEFAULT_GRADING_SCHEME},
        ]}
      />
    )
    const progressBar = queryByLabelText('Grade for Horticulture', {exact: false})
    expect(progressBar).not.toBeInTheDocument()
  })

  it('displays Letter Grade if restrictQuantitativeData is true', () => {
    const {getByText} = render(
      <GradesSummary
        courses={[
          {
            ...defaultCourse,
            score: 87.0,
            restrictQuantitativeData: true,
            gradingScheme: DEFAULT_GRADING_SCHEME,
          },
        ]}
      />
    )
    expect(getByText('B+')).toBeInTheDocument()
  })

  it('displays F Letter Grade if score is 0 and restrictQuantitativeData is true', () => {
    const {getByText} = render(
      <GradesSummary
        courses={[
          {
            ...defaultCourse,
            score: 0,
            restrictQuantitativeData: true,
            gradingScheme: DEFAULT_GRADING_SCHEME,
          },
        ]}
      />
    )
    expect(getByText('F')).toBeInTheDocument()
  })

  it('displays "--" if a course is set to hide final grades', () => {
    const {getByText} = render(
      <GradesSummary courses={[{...defaultCourse, score: undefined, finalGradesHidden: true}]} />
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

  it('redirects to the course grades tab if the course name is clicked', () => {
    const {getByRole} = render(<GradesSummary courses={[{...defaultCourse}]} />)
    expect(getByRole('link', {name: 'Horticulture'}).href).toMatch('/courses/1#grades')
  })
})
