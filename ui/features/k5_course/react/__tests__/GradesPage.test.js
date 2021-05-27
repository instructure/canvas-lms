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
import tz from '@canvas/timezone'
import {GradesPage} from '../GradesPage'
import {
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_GRADING_PERIODS_NORMAL,
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ENROLLMENTS
} from './mocks'

const GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/12?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores'
)
const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state'
)
const ENROLLMENTS_URL = '/api/v1/courses/12/enrollments'

describe('GradesPage', () => {
  const getProps = (overrides = {}) => ({
    courseId: '12',
    courseName: 'History',
    userIsStudent: true,
    userIsInstructor: false,
    hideFinalGrades: false,
    currentUser: {
      id: '1'
    },
    showLearningMasteryGradebook: false,
    ...overrides
  })

  afterEach(() => {
    fetchMock.restore()
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
      const formattedDueDate = tz.format('2020-04-18T05:59:59Z', 'date.formats.full_with_weekday')
      ;['WWII Report', formattedDueDate, 'Reports', '9.5 pts', 'Out of 10 pts'].forEach(header => {
        expect(getByText(header)).toBeInTheDocument()
      })
    })

    it('shows a panda and link to gradebook for teachers', async () => {
      const {getByText, getByTestId, getByRole, queryByText} = render(
        <GradesPage {...getProps({userIsInstructor: true, userIsStudent: false})} />
      )
      await waitFor(() => expect(getByText('Students see their grades here.')).toBeInTheDocument())
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
      const gradebookButton = getByRole('link', {name: 'View Gradebook'})
      expect(gradebookButton).toBeInTheDocument()
      expect(gradebookButton.href).toContain('/courses/12/gradebook')
      expect(queryByText('Assignment')).not.toBeInTheDocument()
    })

    describe('totals', () => {
      it('displays fetched course total grade', async () => {
        const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
        await waitFor(() =>
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument()
        )
        expect(getByText('Total: 89.39%')).toBeInTheDocument()
      })

      it('displays assignment group totals when expanded', async () => {
        const {getByText, findByText, queryByText} = render(<GradesPage {...getProps()} />)
        const totalsButton = await findByText('View Assignment Group Totals')
        expect(queryByText('Reports: 95.00%')).not.toBeInTheDocument()
        act(() => totalsButton.click())
        expect(getByText('Reports: 95.00%')).toBeInTheDocument()
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
              current_score: null
            }
          }
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
              current_grade: 'B'
            }
          }
        ]
        fetchMock.get(ENROLLMENTS_URL, enrollmentsData, {overwriteRoutes: true})
        const {findByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: 84.60% (B)')).toBeInTheDocument()
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
      fetchMock.get(`${ENROLLMENTS_URL}?grading_period_id=2`, JSON.stringify(MOCK_ENROLLMENTS))
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
        overwriteRoutes: true
      })
      fetchMock.get(`${ENROLLMENTS_URL}?grading_period_id=1`, JSON.stringify(MOCK_ENROLLMENTS), {
        overwriteRoutes: true
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
        overwriteRoutes: true
      })
      const {findByText, getByText, queryByText} = render(<GradesPage {...getProps()} />)
      const select = await findByText('Select Grading Period')
      act(() => select.click())
      act(() => getByText('All Grading Periods').click())
      await waitFor(() => expect(getByText('WWII Report')).toBeInTheDocument())
      expect(queryByText('Total: 89.39%')).not.toBeInTheDocument()
      expect(queryByText('View Assignment Group Totals')).not.toBeInTheDocument()
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
})
