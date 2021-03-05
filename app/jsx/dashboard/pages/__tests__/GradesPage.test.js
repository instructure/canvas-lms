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
import {act, render, waitFor} from '@testing-library/react'

import GradesPage, {
  getGradingPeriodsFromCourses,
  overrideCourseGradingPeriods
} from 'jsx/dashboard/pages/GradesPage'

jest.mock('../../utils')
const utils = require('../../utils') // eslint-disable-line import/no-commonjs

const defaultCourses = [
  {
    courseId: '1',
    courseName: 'ECON 500',
    isHomeroom: false,
    currentGradingPeriodId: '1',
    enrollmentType: 'student',
    score: 50,
    grade: 'F',
    gradingPeriods: [
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active'
      }
    ]
  },
  {
    courseId: '2',
    courseName: 'Testing 4 Dummies',
    isHomeroom: false,
    currentGradingPeriodId: '1',
    enrollmentType: 'student',
    score: 90,
    grade: 'A-',
    gradingPeriods: [
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active'
      }
    ]
  },
  {
    courseId: '3',
    courseName: 'Invisible Homeroom',
    isHomeroom: true,
    currentGradingPeriodId: '1',
    enrollmentType: 'student',
    gradingPeriods: [
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active'
      }
    ]
  },
  {
    courseId: '4',
    courseName: 'Mastering Grading Periods',
    isHomeroom: false,
    currentGradingPeriodId: '3',
    enrollmentType: 'student',
    score: 75,
    grade: 'C',
    gradingPeriods: [
      {
        id: '2',
        title: 'The Second One',
        workflow_state: 'active'
      },
      {
        id: '3',
        title: 'A Third One!',
        workflow_state: 'active'
      }
    ]
  }
]

const defaultSpecificPeriodGrades = [
  {
    courseId: '0',
    score: 99,
    grade: 'A+'
  },
  {
    courseId: '1',
    score: 80,
    grade: 'B-'
  },
  {
    courseId: '2',
    score: null,
    grade: null
  }
]

describe('GradesPage', () => {
  it('displays a loading spinner when grades are loading', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve([]))
    const {getByText} = render(<GradesPage visible />)
    expect(getByText('Loading grades...')).toBeInTheDocument()
  })

  it('displays an error message if there was an error fetching grades', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.reject(new Error('oh no!')))
    const {getAllByText} = render(<GradesPage visible />)
    // showFlashError appears to create both a regular and a screen-reader only alert on the page
    await waitFor(() => getAllByText('Failed to load the grades tab'))
    expect(getAllByText('Failed to load the grades tab')[0]).toBeInTheDocument()
    expect(getAllByText('oh no!')[0]).toBeInTheDocument()
  })

  it('renders fetched non-homeroom courses', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve(defaultCourses))
    const {getByText, queryByText} = render(<GradesPage visible />)
    await waitFor(() => getByText('Testing 4 Dummies'))
    expect(getByText('ECON 500')).toBeInTheDocument()
    expect(queryByText('Invisible Homeroom')).not.toBeInTheDocument()
  })

  it('renders a grading period drop-down if the user has any student enrollments', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve(defaultCourses))
    const {findByText} = render(<GradesPage visible />)
    expect(await findByText('Select Grading Period')).toBeInTheDocument()
  })

  it('does not render a grading period drop-down if the user has no student enrollments', async () => {
    utils.fetchGrades.mockReturnValueOnce(
      Promise.resolve([
        {
          courseId: '99',
          courseName: 'For Teachers Only',
          isHomeroom: false,
          currentGradingPeriod: '1',
          enrollmentType: 'teacher',
          score: null,
          grade: null,
          gradingPeriods: [
            {
              id: '1',
              title: 'The Only One',
              workflow_state: 'active'
            }
          ]
        }
      ])
    )
    const {getByText, queryByText} = render(<GradesPage visible />)
    await waitFor(() => getByText('For Teachers Only'))
    expect(queryByText('Select Grading Period')).not.toBeInTheDocument()
  })

  it('updates shown courses and grades to match currently selected grading periods', async () => {
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve(defaultCourses))
    utils.fetchGradesForGradingPeriod.mockReturnValueOnce(
      Promise.resolve(defaultSpecificPeriodGrades)
    )

    const {getByRole, getByText, queryByText} = render(<GradesPage visible />)
    await waitFor(() => getByText('Testing 4 Dummies'))
    expect(getByText('F')).toBeInTheDocument()
    expect(getByText('A-')).toBeInTheDocument()
    expect(getByText('C')).toBeInTheDocument()

    await act(async () => getByRole('button', {name: 'Select Grading Period'}).click())
    await act(async () => getByText('The First One').click())

    await waitFor(() => expect(getByText('B-')).toBeInTheDocument())
    expect(queryByText('F')).not.toBeInTheDocument()
    expect(queryByText('A-')).not.toBeInTheDocument()
    expect(getByText('Not Graded')).toBeInTheDocument()
    expect(queryByText('C')).not.toBeInTheDocument()
  })

  it('displays scores if grades are not available', async () => {
    const courseWithoutGrades = {
      courseId: '99',
      courseName: 'Remedial Arithmetic',
      isHomeroom: false,
      currentGradingPeriodId: '7',
      enrollmentType: 'student',
      score: 76,
      grade: undefined,
      gradingPeriods: [
        {
          id: '7',
          title: 'Summer Make-up',
          workflow_state: 'active'
        }
      ]
    }
    utils.fetchGrades.mockReturnValueOnce(Promise.resolve([courseWithoutGrades]))
    const {getByText, queryByText} = render(<GradesPage visible />)

    await waitFor(() => expect(getByText('76%')).toBeInTheDocument())
    expect(queryByText('C')).not.toBeInTheDocument()
  })
})

describe('getGradingPeriodsFromCourse', () => {
  it('returns an array of unique grading periods based on id', () => {
    expect(getGradingPeriodsFromCourses(defaultCourses)).toEqual([
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active'
      },
      {
        id: '2',
        title: 'The Second One',
        workflow_state: 'active'
      },
      {
        id: '3',
        title: 'A Third One!',
        workflow_state: 'active'
      }
    ])
  })
})

describe('overrideCourseGradingPeriods', () => {
  const subjectCourses = defaultCourses.filter(c => !c.isHomeroom)

  it('returns all courses if no grading period is selected', () => {
    expect(overrideCourseGradingPeriods(subjectCourses, '', [])).toEqual(subjectCourses)
  })

  it("filters out courses that don't include the selected grading period", () => {
    expect(overrideCourseGradingPeriods(subjectCourses, '2', [])).toEqual([
      {
        courseId: '4',
        courseName: 'Mastering Grading Periods',
        isHomeroom: false,
        currentGradingPeriodId: '3',
        enrollmentType: 'student',
        score: 75,
        grade: 'C',
        gradingPeriods: [
          {
            id: '2',
            title: 'The Second One',
            workflow_state: 'active'
          },
          {
            id: '3',
            title: 'A Third One!',
            workflow_state: 'active'
          }
        ]
      }
    ])
  })

  it('overrides grades and scores on courses with those from specific grading periods if they exist', () => {
    expect(overrideCourseGradingPeriods(subjectCourses, '1', defaultSpecificPeriodGrades)).toEqual([
      {
        courseId: '1',
        courseName: 'ECON 500',
        isHomeroom: false,
        currentGradingPeriodId: '1',
        enrollmentType: 'student',
        score: 80,
        grade: 'B-',
        gradingPeriods: [
          {
            id: '1',
            title: 'The First One',
            workflow_state: 'active'
          }
        ]
      },
      {
        courseId: '2',
        courseName: 'Testing 4 Dummies',
        isHomeroom: false,
        currentGradingPeriodId: '1',
        enrollmentType: 'student',
        score: null,
        grade: null,
        gradingPeriods: [
          {
            id: '1',
            title: 'The First One',
            workflow_state: 'active'
          }
        ]
      }
    ])
  })
})
