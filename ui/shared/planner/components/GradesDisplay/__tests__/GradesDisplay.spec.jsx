/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import GradesDisplay from '../index'

describe('GradesDisplay', () => {
  const mockCourses = [
    {
      id: '1',
      shortName: 'Ticket to Ride 101',
      color: 'blue',
      href: '/courses/1',
      score: null,
      grade: null,
      hasGradingPeriods: true,
    },
    {
      id: '2',
      shortName: 'Ingenious 101',
      color: 'green',
      href: '/courses/2',
      score: 42.34,
      grade: 'D',
      hasGradingPeriods: false,
    },
    {
      id: '3',
      shortName: 'Settlers of Catan 201',
      color: 'red',
      href: '/courses/3',
      score: 'blahblah',
      grade: null,
      hasGradingPeriods: false,
    },
  ]

  it('renders course grades with proper heading and structure', () => {
    const {getByText, getByRole} = render(<GradesDisplay courses={mockCourses} />)

    expect(getByText('My Grades')).toBeInTheDocument()

    expect(getByRole('link', {name: 'Ticket to Ride 101'})).toHaveAttribute(
      'href',
      '/courses/1/grades',
    )
    expect(getByRole('link', {name: 'Ingenious 101'})).toHaveAttribute('href', '/courses/2/grades')
    expect(getByRole('link', {name: 'Settlers of Catan 201'})).toHaveAttribute(
      'href',
      '/courses/3/grades',
    )
  })

  it('displays proper grade scores and handles invalid scores', () => {
    const {getAllByTestId} = render(<GradesDisplay courses={mockCourses} />)

    const scoreTexts = getAllByTestId('my-grades-score')
    expect(scoreTexts).toHaveLength(3)

    expect(scoreTexts[0]).toHaveTextContent('No Grade')
    expect(scoreTexts[1]).toHaveTextContent('42.34%')
    expect(scoreTexts[2]).toHaveTextContent('No Grade')
  })

  it('renders grading period caveat when courses have grading periods', () => {
    const {getByText} = render(<GradesDisplay courses={mockCourses} />)

    expect(getByText('*Only most recent grading period shown.')).toBeInTheDocument()
  })

  it('does not render caveat if no courses have grading periods', () => {
    const coursesWithoutGradingPeriods = [
      {
        id: '1',
        shortName: 'Ticket to Ride 101',
        color: 'blue',
        href: '/courses/1',
        score: null,
        grade: null,
        hasGradingPeriods: false,
        enrollmentType: 'StudentEnrollment',
      },
    ]
    const {queryByText} = render(<GradesDisplay courses={coursesWithoutGradingPeriods} />)

    expect(queryByText('*Only most recent grading period shown.')).not.toBeInTheDocument()
  })

  it('renders a loading spinner when loading', () => {
    const {getByText, queryByText, queryByRole} = render(
      <GradesDisplay loading={true} courses={mockCourses} />,
    )

    expect(getByText('Grades are loading')).toBeInTheDocument()

    expect(queryByRole('link')).not.toBeInTheDocument()
    expect(queryByText('*Only most recent grading period shown.')).not.toBeInTheDocument()
  })

  it('renders an ErrorAlert if there is an error loading grades', () => {
    const mockCoursesSimple = [
      {id: '1', shortName: 'Ticket to Ride 101', color: 'blue', href: '/courses/1'},
    ]
    const {getByText, queryByTestId} = render(
      <GradesDisplay courses={mockCoursesSimple} loadingError="There was an error" />,
    )

    expect(getByText('Error loading grades')).toBeInTheDocument()
    expect(getByText('My Grades')).toBeInTheDocument()
    expect(queryByTestId('my-grades-score')).not.toBeInTheDocument()
  })

  it('applies course color to border styling', () => {
    const {container} = render(<GradesDisplay courses={mockCourses} />)

    const styledDivs = container.querySelectorAll('div[style*="border-bottom-color"]')

    expect(styledDivs[0]).toHaveStyle('border-bottom-color: rgb(0, 0, 255)')
    expect(styledDivs[1]).toHaveStyle('border-bottom-color: rgb(0, 128, 0)')
    expect(styledDivs[2]).toHaveStyle('border-bottom-color: rgb(255, 0, 0)')
  })
})
