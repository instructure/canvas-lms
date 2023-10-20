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

import {GradesPage, getGradingPeriodsFromCourses, overrideCourseGradingPeriods} from '../GradesPage'
import fetchMock from 'fetch-mock'

jest.mock('@canvas/k5/react/utils')
const utils = require('@canvas/k5/react/utils') // eslint-disable-line import/no-commonjs

const defaultCourses = [
  {
    courseId: '1',
    courseName: 'ECON 500',
    isHomeroom: false,
    currentGradingPeriodId: '1',
    enrollmentType: 'student',
    score: 50,
    grade: 'F',
    showTotalsForAllGradingPeriods: true,
    totalScoreForAllGradingPeriods: 89,
    totalGradeForAllGradingPeriods: 'B+',
    gradingPeriods: [
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active',
      },
    ],
    enrollments: [
      {
        type: 'student',
        role: 'StudentEnrollment',
        role_id: '19',
        user_id: '1',
        enrollment_state: 'active',
      },
    ],
  },
  {
    courseId: '2',
    courseName: 'Testing 4 Dummies',
    isHomeroom: false,
    currentGradingPeriodId: '1',
    enrollmentType: 'student',
    score: 90,
    grade: 'A-',
    showTotalsForAllGradingPeriods: true,
    totalScoreForAllGradingPeriods: null,
    totalGradeForAllGradingPeriods: null,
    gradingPeriods: [
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active',
      },
    ],
    enrollments: [
      {
        type: 'student',
        role: 'StudentEnrollment',
        role_id: '19',
        user_id: '1',
        enrollment_state: 'active',
      },
    ],
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
        workflow_state: 'active',
      },
    ],
  },
  {
    courseId: '4',
    courseName: 'Mastering Grading Periods',
    isHomeroom: false,
    currentGradingPeriodId: '3',
    enrollmentType: 'student',
    score: 75,
    grade: 'C',
    showTotalsForAllGradingPeriods: false,
    totalScoreForAllGradingPeriods: null,
    totalGradeForAllGradingPeriods: null,
    gradingPeriods: [
      {
        id: '2',
        title: 'The Second One',
        workflow_state: 'active',
      },
      {
        id: '3',
        title: 'A Third One!',
        workflow_state: 'active',
      },
    ],
    enrollments: [
      {
        type: 'student',
        role: 'StudentEnrollment',
        role_id: '19',
        user_id: '1',
        enrollment_state: 'active',
      },
    ],
  },
  {
    courseId: '5',
    courseName: 'Mastering Canvas',
    isHomeroom: false,
    currentGradingPeriodId: '4',
    enrollmentType: 'observer',
    score: 75,
    grade: 'A+',
    showTotalsForAllGradingPeriods: true,
    totalScoreForAllGradingPeriods: 85,
    totalGradeForAllGradingPeriods: 'B',
    gradingPeriods: [
      {
        id: '3',
        title: 'A Third One!',
        workflow_state: 'active',
      },
    ],
    enrollments: [
      {
        type: 'observer',
        role: 'ObserverEnrollment',
        role_id: '23',
        user_id: '1',
        enrollment_state: 'active',
        associated_user_id: '4',
      },
      {
        type: 'student',
        role: 'StudentEnrollment',
        role_id: '19',
        user_id: '4',
        enrollment_state: 'active',
      },
    ],
  },
  {
    courseId: '6',
    courseName: 'Canvas from zero to hero',
    isHomeroom: false,
    currentGradingPeriodId: '4',
    enrollmentType: 'observer',
    score: 75,
    grade: 'B+',
    showTotalsForAllGradingPeriods: true,
    totalScoreForAllGradingPeriods: 85,
    totalGradeForAllGradingPeriods: 'B',
    gradingPeriods: [
      {
        id: '3',
        title: 'A Third One!',
        workflow_state: 'active',
      },
    ],
    enrollments: [
      {
        type: 'observer',
        role: 'ObserverEnrollment',
        role_id: '23',
        user_id: '1',
        enrollment_state: 'active',
        associated_user_id: '4',
      },
      {
        type: 'student',
        role: 'StudentEnrollment',
        role_id: '19',
        user_id: '4',
        enrollment_state: 'active',
      },
    ],
  },
]

const defaultSpecificPeriodGrades = [
  {
    courseId: '0',
    score: 99,
    grade: 'A+',
  },
  {
    courseId: '1',
    score: 80,
    grade: 'B-',
  },
  {
    courseId: '2',
    score: null,
    grade: null,
  },
]

const defaultProps = {
  visible: true,
  currentUserRoles: ['student', 'user'],
  currentUser: {
    id: '1',
  },
}

const BASE_GRADES_URL =
  '/api/v1/users/self/courses?enrollment_state=active&per_page=100&include[]=total_scores&include[]=current_grading_period_scores&include[]=grading_periods&include[]=course_image&include[]=grading_scheme&include[]=restrict_quantitative_data'
const GRADING_PERIODS_URL = encodeURI(BASE_GRADES_URL)
const OBSERVER_GRADING_PERIODS_URL = encodeURI(`${BASE_GRADES_URL}&include[]=observed_users`)

describe('GradesPage', () => {
  beforeEach(() => {
    utils.transformGrades.mockImplementation(data => data)
    fetchMock.get(GRADING_PERIODS_URL, JSON.stringify(defaultCourses))
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('displays loading skeletons when grades are loading', async () => {
    const {getAllByText} = render(<GradesPage {...defaultProps} />)
    expect(getAllByText('Loading grades...')[0]).toBeInTheDocument()
  })

  it('displays an error message if there was an error fetching grades', async () => {
    fetchMock.get(
      GRADING_PERIODS_URL,
      () => {
        throw new Error('oh no!')
      },
      {overwriteRoutes: true}
    )
    const {getAllByText} = render(<GradesPage {...defaultProps} />)
    // showFlashError appears to create both a regular and a screen-reader only alert on the page
    await waitFor(() => getAllByText('Failed to load the grades tab'))
    expect(getAllByText('Failed to load the grades tab')[0]).toBeInTheDocument()
    expect(getAllByText('oh no!')[0]).toBeInTheDocument()
  })

  it('renders fetched non-homeroom courses', async () => {
    const {getByText, queryByText} = render(<GradesPage {...defaultProps} />)
    await waitFor(() => getByText('Testing 4 Dummies'))
    expect(getByText('ECON 500')).toBeInTheDocument()
    expect(queryByText('Invisible Homeroom')).not.toBeInTheDocument()
  })

  it('renders a grading period drop-down if the user has student role', async () => {
    const {findByText} = render(<GradesPage {...defaultProps} />)
    expect(await findByText('Select Grading Period')).toBeInTheDocument()
  })

  it('displays a loading skeleton when the grading period drop-down is loading', () => {
    const {getByText} = render(<GradesPage {...defaultProps} />)
    expect(getByText('Loading grading periods...')).toBeInTheDocument()
  })

  it('does not render a grading period drop-down if the user does not have student role', async () => {
    fetchMock.get(
      GRADING_PERIODS_URL,
      JSON.stringify([
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
              workflow_state: 'active',
            },
          ],
        },
      ]),
      {overwriteRoutes: true}
    )
    const {getByText, queryByText} = render(<GradesPage {...defaultProps} />)
    await waitFor(() => getByText('For Teachers Only'))
    expect(queryByText('Select Grading Period')).not.toBeInTheDocument()
  })

  it('updates shown courses and grades to match currently selected grading periods', async () => {
    utils.fetchGradesForGradingPeriod.mockReturnValueOnce(
      Promise.resolve(defaultSpecificPeriodGrades)
    )

    const {getByRole, getByText, queryByText} = render(<GradesPage {...defaultProps} />)
    await waitFor(() => getByText('Testing 4 Dummies'))
    expect(getByText('F')).toBeInTheDocument()
    expect(getByText('A-')).toBeInTheDocument()
    expect(getByText('C')).toBeInTheDocument()

    await act(async () => getByRole('combobox', {name: 'Select Grading Period'}).click())
    await act(async () => getByText('The First One').click())

    await waitFor(() => expect(getByText('B-')).toBeInTheDocument())
    expect(queryByText('F')).not.toBeInTheDocument()
    expect(queryByText('A-')).not.toBeInTheDocument()
    expect(getByText('Not Graded')).toBeInTheDocument()
    expect(queryByText('C')).not.toBeInTheDocument()

    act(() => getByRole('combobox', {name: 'Select Grading Period'}).click())
    act(() => getByText('All Grading Periods').click())

    expect(getByText('B+')).toBeInTheDocument()
    expect(getByText('Not Graded')).toBeInTheDocument()
    expect(getByText('--')).toBeInTheDocument()
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
          workflow_state: 'active',
        },
      ],
    }
    fetchMock.get(GRADING_PERIODS_URL, JSON.stringify([courseWithoutGrades]), {
      overwriteRoutes: true,
    })
    const {getByText, queryByText} = render(<GradesPage {...defaultProps} />)

    await waitFor(() => expect(getByText('76%')).toBeInTheDocument())
    expect(queryByText('C')).not.toBeInTheDocument()
  })

  it('displays some text indicating how grades are calculated', () => {
    const {getByText} = render(<GradesPage {...defaultProps} />)
    expect(getByText('Totals are calculated based only on graded assignments.')).toBeInTheDocument()
  })

  describe('Parent Support', () => {
    beforeEach(() => {
      fetchMock.get(OBSERVER_GRADING_PERIODS_URL, JSON.stringify(defaultCourses))
      utils.getCourseGrades.mockImplementation(c => c)
    })

    it('only shows courses of the observed user if provided', async () => {
      const {getByText, queryByText} = render(
        <GradesPage
          {...defaultProps}
          currentUserRoles={['observer', 'user']}
          observedUserId="4"
          currentUser={{id: '1'}}
        />
      )
      await waitFor(() => {
        expect(getByText('Mastering Canvas')).toBeInTheDocument()
        expect(getByText('A+')).toBeInTheDocument()
        expect(getByText('Canvas from zero to hero')).toBeInTheDocument()
        expect(getByText('B+')).toBeInTheDocument()
        expect(queryByText('Testing 4 Dummies')).not.toBeInTheDocument()
        expect(queryByText('ECON 500')).not.toBeInTheDocument()
        expect(queryByText('Mastering Grading Periods')).not.toBeInTheDocument()
      })
    })

    it('filters out observer enrollments if the observed user is the current user', async () => {
      const {getByText, queryByText} = render(
        <GradesPage
          {...defaultProps}
          currentUserRoles={['observer', 'teacher', 'user']}
          observedUserId="1"
          currentUser={{id: '1'}}
        />
      )
      await waitFor(() => {
        expect(getByText('Testing 4 Dummies')).toBeInTheDocument()
        expect(getByText('ECON 500')).toBeInTheDocument()
        expect(getByText('Mastering Grading Periods')).toBeInTheDocument()
        expect(queryByText('Mastering Canvas')).not.toBeInTheDocument()
        expect(queryByText('A+')).not.toBeInTheDocument()
        expect(queryByText('Canvas from zero to hero')).not.toBeInTheDocument()
        expect(queryByText('B+')).not.toBeInTheDocument()
      })
    })

    it('does not filter any course if the observedUserId is null', async () => {
      const {getByText} = render(<GradesPage {...defaultProps} currentUser={{id: '1'}} />)
      await waitFor(() => {
        expect(getByText('Testing 4 Dummies')).toBeInTheDocument()
        expect(getByText('ECON 500')).toBeInTheDocument()
        expect(getByText('Mastering Grading Periods')).toBeInTheDocument()
        expect(getByText('Mastering Canvas')).toBeInTheDocument()
        expect(getByText('Canvas from zero to hero')).toBeInTheDocument()
      })
    })
  })
})

describe('getGradingPeriodsFromCourse', () => {
  it('returns an array of unique grading periods based on id', () => {
    expect(getGradingPeriodsFromCourses(defaultCourses)).toEqual([
      {
        id: '1',
        title: 'The First One',
        workflow_state: 'active',
      },
      {
        id: '2',
        title: 'The Second One',
        workflow_state: 'active',
      },
      {
        id: '3',
        title: 'A Third One!',
        workflow_state: 'active',
      },
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
        showTotalsForAllGradingPeriods: false,
        totalScoreForAllGradingPeriods: null,
        totalGradeForAllGradingPeriods: null,
        gradingPeriods: [
          {
            id: '2',
            title: 'The Second One',
            workflow_state: 'active',
          },
          {
            id: '3',
            title: 'A Third One!',
            workflow_state: 'active',
          },
        ],
        enrollments: [
          {
            type: 'student',
            role: 'StudentEnrollment',
            role_id: '19',
            user_id: '1',
            enrollment_state: 'active',
          },
        ],
      },
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
        showTotalsForAllGradingPeriods: true,
        showingAllGradingPeriods: false,
        totalScoreForAllGradingPeriods: 89,
        totalGradeForAllGradingPeriods: 'B+',
        gradingPeriods: [
          {
            id: '1',
            title: 'The First One',
            workflow_state: 'active',
          },
        ],
        enrollments: [
          {
            type: 'student',
            role: 'StudentEnrollment',
            role_id: '19',
            user_id: '1',
            enrollment_state: 'active',
          },
        ],
      },
      {
        courseId: '2',
        courseName: 'Testing 4 Dummies',
        isHomeroom: false,
        currentGradingPeriodId: '1',
        enrollmentType: 'student',
        score: null,
        grade: null,
        showTotalsForAllGradingPeriods: true,
        showingAllGradingPeriods: false,
        totalScoreForAllGradingPeriods: null,
        totalGradeForAllGradingPeriods: null,
        gradingPeriods: [
          {
            id: '1',
            title: 'The First One',
            workflow_state: 'active',
          },
        ],
        enrollments: [
          {
            type: 'student',
            role: 'StudentEnrollment',
            role_id: '19',
            user_id: '1',
            enrollment_state: 'active',
          },
        ],
      },
    ])
  })
})
