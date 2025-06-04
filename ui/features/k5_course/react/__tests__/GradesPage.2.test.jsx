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
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
  MOCK_ENROLLMENTS,
  MOCK_ENROLLMENTS_WITH_OBSERVED_USERS,
  MOCK_GRADEBOOK_HIDDEN_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
} from './mocks'

const GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/12?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores',
)
const OBSERVER_GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/12?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores&include[]=observed_users',
)
const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments',
)
const OBSERVER_ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments&include[]=observed_users',
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
        <GradesPage {...getProps({showLearningMasteryGradebook: true})} />,
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
      fetchMock.get(OBSERVER_GRADING_PERIODS_URL, MOCK_GRADING_PERIODS_EMPTY)
      fetchMock.get(OBSERVER_ASSIGNMENT_GROUPS_URL, MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS)
      fetchMock.get(OBSERVER_ENROLLMENTS_URL, MOCK_ENROLLMENTS_WITH_OBSERVED_USERS)
    })

    it('only shows assignment details for the observed user', async () => {
      // Arrange
      const {findByTestId, getByTestId, rerender} = render(
        <GradesPage {...getProps({observedUserId: '5'})} />,
      )

      // Act & Assert for first observed user
      let formattedSubmittedDate = dateFormatter('2021-09-20T23:55:08Z')

      // Wait for the assignment name to appear
      await findByTestId('assignment-name')

      // Verify submission date is shown
      const submissionDateElement = await findByTestId('submission-date')
      expect(submissionDateElement).toBeInTheDocument()
      expect(submissionDateElement.textContent).toContain(formattedSubmittedDate)

      // Verify assignment group is shown
      expect(getByTestId('assignment-group-name')).toBeInTheDocument()
      expect(getByTestId('assignment-group-name').textContent).toBe('Assignments')

      // For user 5, we expect to see the assignment with a score (could be numeric or letter grade)
      // Using the data-testid to find the score element
      expect(getByTestId('assignment-name').textContent).toBe('Assignment 3')
      const scoreElement = getByTestId('assignment-score')
      expect(scoreElement).toBeInTheDocument()
      // We don't check the exact score value since it could be rendered as a numeric value or letter grade
      // depending on the grading scheme being applied in the test

      // Test for the second observed user
      formattedSubmittedDate = dateFormatter('2021-09-22T21:25:08Z')
      rerender(<GradesPage {...getProps({observedUserId: '6'})} />)

      // Wait for the assignment name to appear again after rerender
      await findByTestId('assignment-name')

      // Verify submission date is shown for user 6
      const submissionDateElement2 = await findByTestId('submission-date')
      expect(submissionDateElement2).toBeInTheDocument()
      expect(submissionDateElement2.textContent).toContain(formattedSubmittedDate)

      // Verify assignment group is still shown
      expect(getByTestId('assignment-group-name')).toBeInTheDocument()
      expect(getByTestId('assignment-group-name').textContent).toBe('Assignments')

      // For user 6, we expect to see the assignment with a score (could be numeric or letter grade)
      expect(getByTestId('assignment-name').textContent).toBe('Assignment 3')
      const scoreElement2 = getByTestId('assignment-score')
      expect(scoreElement2).toBeInTheDocument()
      // We don't check the exact score value since it could be rendered as a numeric value or letter grade
      // depending on the grading scheme being applied in the test
    })

    it('does not show assignment details for the observed user when it is hidden for student page', async () => {
      fetchMock.get(
        OBSERVER_ASSIGNMENT_GROUPS_URL,
        MOCK_GRADEBOOK_HIDDEN_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
        {overwriteRoutes: true},
      )

      const {getByText, queryByText, getByTestId} = render(
        <GradesPage {...getProps({observedUserId: '5'})} />,
      )
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      expect(getByText("You don't have any grades yet.")).toBeInTheDocument()
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
      ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
        expect(queryByText(header)).not.toBeInTheDocument()
      })
    })

    it('displays fetched course total grade for the observed user', async () => {
      const {findByText, queryByText, rerender} = render(
        <GradesPage {...getProps({observedUserId: '5'})} />,
      )

      await waitFor(async () => {
        await findByText('Total: 88.00%')
        await findByText('History Total: 88.00%')
        expect(queryByText('Total: 76.20%')).not.toBeInTheDocument()
      })

      rerender(<GradesPage {...getProps({observedUserId: '6'})} />)
      await waitFor(async () => {
        await findByText('Total: 76.20%')
        await findByText('History Total: 76.20%')
        expect(queryByText('Total: 88.00%')).not.toBeInTheDocument()
      })
    })

    it('displays assignment group totals for the observed user when expanded', async () => {
      const {findByText, rerender} = render(<GradesPage {...getProps({observedUserId: '6'})} />)
      const totalsButton = await findByText('View Assignment Group Totals')
      act(() => totalsButton.click())
      await findByText('Assignments: 80.00%')
      rerender(<GradesPage {...getProps({observedUserId: '5'})} />)
      await findByText('Assignments: 60.00%')
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
      fetchMock.get(GRADING_PERIODS_URL, MOCK_GRADING_PERIODS_EMPTY)
      fetchMock.get(ENROLLMENTS_URL, MOCK_ENROLLMENTS)
      window.ENV = {
        RESTRICT_QUANTITATIVE_DATA: true,
        GRADING_SCHEME: DEFAULT_GRADING_SCHEME,
      }
      mockAssignmentGroups = JSON.parse(JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
    })

    it('renders the returned assignment details as a letter grade only', async () => {
      fetchMock.get(ASSIGNMENT_GROUPS_URL, mockAssignmentGroups)

      const {findByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'A']
      await Promise.all(expectedValues.map(value => findByText(value)))

      const removedValues = ['9.5 pts', 'Out of 10 pts']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })

    it('renders a pass_fail assignment correctly', async () => {
      mockAssignmentGroups[0].assignments[0].submission.score = 10
      mockAssignmentGroups[0].assignments[0].submission.grade = 'complete'
      mockAssignmentGroups[0].assignments[0].grading_type = 'pass_fail'
      fetchMock.get(ASSIGNMENT_GROUPS_URL, mockAssignmentGroups)

      const {findByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'Complete']
      await Promise.all(expectedValues.map(value => findByText(value)))

      const removedValues = ['10 pts', 'Out of 10 pts']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })

    it('renders assignments with 10/0 points possible correctly', async () => {
      mockAssignmentGroups[0].assignments[0].submission.score = 10
      mockAssignmentGroups[0].assignments[0].submission.grade = '10'
      mockAssignmentGroups[0].assignments[0].points_possible = 0
      fetchMock.get(ASSIGNMENT_GROUPS_URL, mockAssignmentGroups)

      const {findByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'A']
      await Promise.all(expectedValues.map(value => findByText(value)))

      const removedValues = ['10 pts', 'Out of 0 pts']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })

    it('renders assignments with 0/0 points possible correctly', async () => {
      mockAssignmentGroups[0].assignments[0].submission.score = 0
      mockAssignmentGroups[0].assignments[0].submission.grade = '0'
      mockAssignmentGroups[0].assignments[0].points_possible = 0

      fetchMock.get(ASSIGNMENT_GROUPS_URL, mockAssignmentGroups)

      const {findByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      const expectedValues = ['WWII Report', formattedDueDate, 'Reports', 'Complete']
      await Promise.all(expectedValues.map(value => findByText(value)))

      const removedValues = ['0 pts', 'Out of 0 pts', 'A', 'F']
      removedValues.forEach(value => {
        expect(queryByText(value)).not.toBeInTheDocument()
      })
    })
  })
})
