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
import {MOCK_ASSIGNMENT_GROUPS, MOCK_ENROLLMENTS} from './mocks'

const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission'
)
const ENROLLMENTS_URL = '/api/v1/courses/12/enrollments'

describe('GradesPage', () => {
  const getProps = (overrides = {}) => ({
    courseId: '12',
    courseName: 'History',
    userIsInstructor: false,
    hideFinalGrades: false,
    currentUser: {
      id: '1'
    },
    ...overrides
  })

  beforeEach(() => {
    fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
    fetchMock.get(ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS))
  })

  afterEach(() => {
    fetchMock.restore()
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
      expect(getAllByText('Failed to load grades for History')[0]).toBeInTheDocument()
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
      <GradesPage {...getProps({userIsInstructor: true})} />
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
  })
})
