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
 */

import React from 'react'
import {render, waitFor, act} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {GradesPage} from '../GradesPage'
import {
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_GRADING_PERIODS_NORMAL,
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
  MOCK_ENROLLMENTS,
  MOCK_ENROLLMENTS_WITH_OBSERVED_USERS,
} from './mocks'

const GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/12?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores'
)
const OBSERVER_GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/12?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores&include[]=observed_users'
)
const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments'
)
const OBSERVER_ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments&include[]=observed_users'
)
const ENROLLMENTS_URL = '/api/v1/courses/12/enrollments?user_id=1'
const OBSERVER_ENROLLMENTS_URL = '/api/v1/courses/12/enrollments?user_id=1&include=observed_users'

const dtf = new Intl.DateTimeFormat('en', {
  // MMM D, YYYY h:mma
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
  timeZone: ENV.TIMEZONE,
})

const dateFormatter = d => dtf.format(d instanceof Date ? d : new Date(d))

describe('GradesPage', () => {
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

  const getProps = (overrides = {}) => ({
    courseId: '12',
    courseName: 'History',
    userIsStudent: true,
    userIsCourseAdmin: false,
    hideFinalGrades: false,
    currentUser: {
      id: '1',
    },
    showLearningMasteryGradebook: false,
    observedUserId: null,
    ...overrides,
  })

  afterEach(() => {
    fetchMock.restore()
    localStorage.clear()
  })

  describe('without grading periods', () => {
    beforeEach(() => {
      fetchMock.get(GRADING_PERIODS_URL, JSON.stringify(MOCK_GRADING_PERIODS_EMPTY))
      fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
      fetchMock.get(ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS))
    })

    it('renders loading skeletons while fetching content', async () => {
      const {getAllByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => {
        const skeletons = getAllByText('Loading grades for History')
        expect(skeletons[0]).toBeInTheDocument()
        expect(skeletons.length).toBe(10)
      })
    })

    it('renders a flashAlert if an error happens on fetch', async () => {
      fetchMock.get(ASSIGNMENT_GROUPS_URL, 400, {overwriteRoutes: true})
      const {getAllByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() =>
        expect(getAllByText('Failed to load grade details for History')[0]).toBeInTheDocument()
      )
    })

    it('renders a table with 4 headers', async () => {
      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
        expect(getByText(header)).toBeInTheDocument()
      })
    })

    it('shows a panda and text for students with no grades', async () => {
      fetchMock.get(ASSIGNMENT_GROUPS_URL, [], {overwriteRoutes: true})
      const {getByTestId, getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      expect(getByText("You don't have any grades yet.")).toBeInTheDocument()
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
      ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
        expect(queryByText(header)).not.toBeInTheDocument()
      })
    })

    it('shows a panda and text for users who are neither a student nor instructor', async () => {
      const {getByTestId, getByText, queryByText} = render(
        <GradesPage {...getProps({userIsStudent: false})} />
      )
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      expect(getByText("You don't have any grades yet.")).toBeInTheDocument()
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
    })

    it('renders the returned assignment details', async () => {
      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')
      ;['WWII Report', formattedDueDate, 'Reports', '9.5 pts', 'Out of 10 pts'].forEach(header => {
        expect(getByText(header)).toBeInTheDocument()
      })
    })

    it('shows a panda and link to gradebook for teachers', async () => {
      const {getByText, getByTestId, getByRole, queryByText} = render(
        <GradesPage {...getProps({userIsCourseAdmin: true, userIsStudent: false})} />
      )
      await waitFor(() => expect(getByText('Students see their grades here.')).toBeInTheDocument())
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
      const gradebookButton = getByRole('link', {name: 'View History Gradebook'})
      expect(gradebookButton).toBeInTheDocument()
      expect(getByText('View Gradebook')).toBeInTheDocument()
      expect(gradebookButton.href).toContain('/courses/12/gradebook')
      expect(queryByText('Assignment')).not.toBeInTheDocument()
    })

    it('shows view feedback link', async () => {
      const {queryByText, getByRole} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const link = getByRole('link', {name: 'View feedback'})
      expect(link).toBeInTheDocument()
      expect(link.href).toBe('http://localhost/wwii-report/submissions/1')
    })

    describe('totals', () => {
      it('displays fetched course total grade', async () => {
        const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
        await waitFor(() =>
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument()
        )
        expect(getByText('Total: 89.39%')).toBeInTheDocument()
        expect(getByText('History Total: 89.39%')).toBeInTheDocument()
      })

      it('displays fetched course total Letter Grade when Restrict Quantitative Data', async () => {
        const {getByText, queryByText} = render(
          <GradesPage
            {...getProps({gradingScheme: DEFAULT_GRADING_SCHEME, restrictQuantitativeData: true})}
          />
        )
        await waitFor(() =>
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument()
        )
        expect(getByText('Total: B+')).toBeInTheDocument()
        expect(getByText('History Total: B+')).toBeInTheDocument()
      })

      it('displays button to expand assignment group totals', async () => {
        const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
        await waitFor(() =>
          expect(queryByText('Loading assignment group totals')).not.toBeInTheDocument()
        )
        expect(getByText('View Assignment Group Totals')).toBeInTheDocument()
        expect(getByText("View History's Assignment Group Totals")).toBeInTheDocument()
      })

      it('displays assignment group totals when expanded', async () => {
        const {getByText, findByText, queryByText} = render(<GradesPage {...getProps()} />)
        const totalsButton = await findByText('View Assignment Group Totals')
        expect(queryByText('Reports: 95.00%')).not.toBeInTheDocument()
        act(() => totalsButton.click())
        expect(getByText('Reports: 95.00%')).toBeInTheDocument()
      })

      it('displays assignment group totals Letter Grade when expanded and Restrict Quantitative Data', async () => {
        const {getByText, findByText, queryByText} = render(
          <GradesPage
            {...getProps({gradingScheme: DEFAULT_GRADING_SCHEME, restrictQuantitativeData: true})}
          />
        )
        const totalsButton = await findByText('View Assignment Group Totals')
        expect(queryByText('Reports: A')).not.toBeInTheDocument()
        act(() => totalsButton.click())
        expect(getByText('Reports: A')).toBeInTheDocument()
      })

      it("doesn't show any totals if hideFinalGrades is set", async () => {
        const {queryByText} = render(<GradesPage {...getProps({hideFinalGrades: true})} />)
        await waitFor(() => {
          expect(queryByText('Loading grades for History')).not.toBeInTheDocument()
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument()
        })
        expect(queryByText('Total: 89.39%')).not.toBeInTheDocument()
        expect(queryByText('Reports: 95.00%')).not.toBeInTheDocument()
      })

      it('total shows n/a if the fetched score is null', async () => {
        const enrollmentsData = [
          {
            user_id: '1',
            grades: {
              current_score: null,
            },
          },
        ]
        fetchMock.get(ENROLLMENTS_URL, enrollmentsData, {overwriteRoutes: true})
        const {findByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: n/a')).toBeInTheDocument()
      })

      it('shows the grading scheme grade next to percent if course has grading scheme', async () => {
        const enrollmentsData = [
          {
            user_id: '1',
            grades: {
              current_score: 84.6,
              current_grade: 'B',
            },
          },
        ]
        fetchMock.get(ENROLLMENTS_URL, enrollmentsData, {overwriteRoutes: true})
        const {findByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: 84.60% (B)')).toBeInTheDocument()
      })

      it('shows a message explaining how totals are calculated if totals are shown', async () => {
        const {findByText, getByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: 89.39%')).toBeInTheDocument()
        expect(
          getByText('Totals are calculated based only on graded assignments.')
        ).toBeInTheDocument()
      })
    })
  })

  describe('with grading periods', () => {
    beforeEach(() => {
      fetchMock.get(GRADING_PERIODS_URL, JSON.stringify(MOCK_GRADING_PERIODS_NORMAL))
      fetchMock.get(
        `${ASSIGNMENT_GROUPS_URL}&grading_period_id=2`,
        JSON.stringify(MOCK_ASSIGNMENT_GROUPS)
      )
      fetchMock.get(`${ENROLLMENTS_URL}&grading_period_id=2`, JSON.stringify(MOCK_ENROLLMENTS))
      fetchMock.get(ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS))
      fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
    })

    it('shows a grading period select when grading periods are returned', async () => {
      const {getByText, findByText} = render(<GradesPage {...getProps()} />)
      const select = await findByText('Select Grading Period')
      act(() => select.click())
      expect(getByText('Quarter 1')).toBeInTheDocument()
      expect(getByText('Quarter 2 (Current)')).toBeInTheDocument()
      expect(getByText('All Grading Periods')).toBeInTheDocument()
    })

    it('shows an error if fetching fails', async () => {
      fetchMock.get(GRADING_PERIODS_URL, 400, {overwriteRoutes: true})
      const {getAllByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() =>
        expect(getAllByText('Failed to load grading periods for History')[0]).toBeInTheDocument()
      )
    })

    it('shows only assignments in current grading period', async () => {
      fetchMock.get(`${ASSIGNMENT_GROUPS_URL}&grading_period_id=1`, [], {
        overwriteRoutes: true,
      })
      fetchMock.get(`${ENROLLMENTS_URL}&grading_period_id=1`, JSON.stringify(MOCK_ENROLLMENTS), {
        overwriteRoutes: true,
      })
      const {getByText, findByText, queryByText} = render(<GradesPage {...getProps()} />)
      expect(await findByText('WWII Report')).toBeInTheDocument()
      const select = getByText('Select Grading Period')
      act(() => select.click())
      act(() => getByText('Quarter 1').click())
      await waitFor(() => expect(queryByText('Loading grades for history')).not.toBeInTheDocument())
      expect(queryByText('WWII Report')).not.toBeInTheDocument()
    })

    it('hides totals on All Grading Periods if not allowed', async () => {
      const gradingPeriods = {...MOCK_GRADING_PERIODS_NORMAL}
      gradingPeriods.enrollments[0].totals_for_all_grading_periods_option = false
      fetchMock.get(GRADING_PERIODS_URL, JSON.stringify(gradingPeriods), {
        overwriteRoutes: true,
      })
      const {findByText, getByText, queryByText} = render(<GradesPage {...getProps()} />)
      const select = await findByText('Select Grading Period')
      act(() => select.click())
      act(() => getByText('All Grading Periods').click())
      await waitFor(() => expect(getByText('WWII Report')).toBeInTheDocument())
      expect(queryByText('Total: 89.39%')).not.toBeInTheDocument()
      expect(queryByText('View Assignment Group Totals')).not.toBeInTheDocument()
    })

    it('waits for grading periods to load before firing other requests', async () => {
      const {getByText, getAllByText} = render(<GradesPage {...getProps()} />)
      expect(getAllByText('Loading grades for History')[0]).toBeInTheDocument()
      expect(getByText('Loading total grade for History')).toBeInTheDocument()
      await waitFor(() => {
        expect(getByText('WWII Report')).toBeInTheDocument()
        expect(getByText('Total: 89.39%')).toBeInTheDocument()
      })
      expect(fetchMock.calls().length).toBe(3)
    })
  })

  describe('learning mastery gradebook', () => {
    it('shows no tabs if LMGB is disabled', () => {
      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      expect(getByText('Assignment')).toBeInTheDocument()
      expect(queryByText('Assignments')).not.toBeInTheDocument()
      expect(queryByText('Learning Mastery')).not.toBeInTheDocument()
    })

    it('shows tabs for both gradebooks if LMGB is enabled', () => {
      const {getByRole} = render(<GradesPage {...getProps({showLearningMasteryGradebook: true})} />)
      expect(getByRole('tab', {name: 'Assignments', selected: true})).toBeInTheDocument()
      expect(getByRole('tab', {name: 'Learning Mastery'})).toBeInTheDocument()
    })

    it('shows LMGB and hides assignments when clicking on the tab', async () => {
      const {getByRole, getByText, queryByText} = render(
        <GradesPage {...getProps({showLearningMasteryGradebook: true})} />
      )
      act(() => getByRole('tab', {name: 'Learning Mastery'}).click())
      ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
        expect(queryByText(header)).not.toBeInTheDocument()
      })
      expect(getByText('Learning outcome gradebook for History')).toBeInTheDocument()
      await waitFor(() => expect(queryByText('Loading outcome results')).not.toBeInTheDocument())
      expect(getByText('An error occurred loading outcomes data.')).toBeInTheDocument()
    })
  })

  describe('observer support', () => {
    beforeEach(() => {
      fetchMock.get(OBSERVER_GRADING_PERIODS_URL, JSON.stringify(MOCK_GRADING_PERIODS_EMPTY))
      fetchMock.get(
        OBSERVER_ASSIGNMENT_GROUPS_URL,
        JSON.stringify(MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS)
      )
      fetchMock.get(OBSERVER_ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS_WITH_OBSERVED_USERS))
    })

    it('only shows assignment details for the observed user', async () => {
      const {getByText, rerender} = render(<GradesPage {...getProps({observedUserId: '5'})} />)
      let formattedSubmittedDate = dateFormatter('2021-09-20T23:55:08Z')
      await waitFor(() => {
        ;[
          'Assignment 3',
          `Submitted ${formattedSubmittedDate}`,
          'Assignments',
          '6 pts',
          'Out of 10 pts',
        ].forEach(label => {
          expect(getByText(label)).toBeInTheDocument()
        })
      })
      formattedSubmittedDate = dateFormatter('2021-09-22T21:25:08Z')
      rerender(<GradesPage {...getProps({observedUserId: '6'})} />)
      ;[
        'Assignment 3',
        `Submitted ${formattedSubmittedDate}`,
        'Assignments',
        '8 pts',
        'Out of 10 pts',
      ].forEach(label => {
        expect(getByText(label)).toBeInTheDocument()
      })
    })

    it('displays fetched course total grade for the observed user', async () => {
      const {getByText, queryByText, rerender} = render(
        <GradesPage {...getProps({observedUserId: '5'})} />
      )

      await waitFor(() => {
        expect(getByText('Total: 88.00%')).toBeInTheDocument()
        expect(getByText('History Total: 88.00%')).toBeInTheDocument()
        expect(queryByText('Total: 76.20%')).not.toBeInTheDocument()
      })

      rerender(<GradesPage {...getProps({observedUserId: '6'})} />)
      await waitFor(() => {
        expect(getByText('Total: 76.20%')).toBeInTheDocument()
        expect(getByText('History Total: 76.20%')).toBeInTheDocument()
        expect(queryByText('Total: 88.00%')).not.toBeInTheDocument()
      })
    })

    it('displays assignment group totals for the observed user when expanded', async () => {
      const {getByText, findByText, queryByText, rerender} = render(
        <GradesPage {...getProps({observedUserId: '6'})} />
      )
      const totalsButton = await findByText('View Assignment Group Totals')
      expect(queryByText('Assignments: 80.00%')).not.toBeInTheDocument()
      act(() => totalsButton.click())
      expect(getByText('Assignments: 80.00%')).toBeInTheDocument()
      rerender(<GradesPage {...getProps({observedUserId: '5'})} />)
      expect(getByText('Assignments: 60.00%')).toBeInTheDocument()
    })

    it('routes the user to the observee submissions when the "View feedback" link is clicked', async () => {
      const {getByRole} = render(<GradesPage {...getProps({observedUserId: '5'})} />)
      await waitFor(() => {
        const link = getByRole('link', {name: 'View feedback'})
        expect(link).toBeInTheDocument()
        expect(link.href).toBe('http://localhost:3000/courses/30/assignments/9/submissions/5')
      })
    })
  })

  describe('with Restrict Quantitative Data enabled', () => {
    let mockAssignmentGroups = []
    beforeEach(() => {
      fetchMock.get(GRADING_PERIODS_URL, JSON.stringify(MOCK_GRADING_PERIODS_EMPTY))
      fetchMock.get(ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS))
      window.ENV = {
        RESTRICT_QUANTITATIVE_DATA: true,
        GRADING_SCHEME: DEFAULT_GRADING_SCHEME,
      }
      mockAssignmentGroups = JSON.parse(JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
    })

    it('renders the returned assignment details as a letter grade only', async () => {
      fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(mockAssignmentGroups))

      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'A']
      expectedValues.forEach(value => {
        expect(getByText(value)).toBeInTheDocument()
      })

      const removedValues = ['9.5 pts', 'Out of 10 pts']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })

    it('renders a pass_fail assignment correctly', async () => {
      mockAssignmentGroups[0].assignments[0].submission.score = 10
      mockAssignmentGroups[0].assignments[0].submission.grade = 'complete'
      mockAssignmentGroups[0].assignments[0].grading_type = 'pass_fail'
      fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(mockAssignmentGroups))

      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'Complete']
      expectedValues.forEach(value => {
        expect(getByText(value)).toBeInTheDocument()
      })

      const removedValues = ['10 pts', 'Out of 10 pts']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })

    it('renders assignments with 10/0 points possible correctly', async () => {
      mockAssignmentGroups[0].assignments[0].submission.score = 10
      mockAssignmentGroups[0].assignments[0].submission.grade = '10'
      mockAssignmentGroups[0].assignments[0].points_possible = 0
      fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(mockAssignmentGroups))

      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'A']
      expectedValues.forEach(value => {
        expect(getByText(value)).toBeInTheDocument()
      })

      const removedValues = ['10 pts', 'Out of 0 pts']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })

    it('renders assignments with 0/0 points possible correctly', async () => {
      mockAssignmentGroups[0].assignments[0].submission.score = 0
      mockAssignmentGroups[0].assignments[0].submission.grade = '0'
      mockAssignmentGroups[0].assignments[0].points_possible = 0

      fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(mockAssignmentGroups))

      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'Complete']
      expectedValues.forEach(value => {
        expect(getByText(value)).toBeInTheDocument()
      })

      const removedValues = ['0 pts', 'Out of 0 pts', 'A', 'F']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })
  })
})
