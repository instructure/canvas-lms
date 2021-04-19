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
import {render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import tz from '@canvas/timezone'
import {GradesPage} from '../GradesPage'
import {MOCK_ASSIGNMENT_GROUPS} from './mocks'

const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/12/assignment_groups?include[]=assignments&include[]=submission'
)

describe('GradesPage', () => {
  const getProps = (overrides = {}) => ({
    courseId: '12',
    courseName: 'History',
    ...overrides
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders loading skeletons while fetching content', async () => {
    fetchMock.get(ASSIGNMENT_GROUPS_URL, MOCK_ASSIGNMENT_GROUPS)
    const {getAllByText} = render(<GradesPage {...getProps()} />)
    await waitFor(() => {
      const skeletons = getAllByText('Loading grades for History')
      expect(skeletons[0]).toBeInTheDocument()
      expect(skeletons.length).toBe(10)
    })
  })

  it('renders a flashAlert if an error happens on fetch', async () => {
    fetchMock.get(ASSIGNMENT_GROUPS_URL, 400)
    const {getAllByText} = render(<GradesPage {...getProps()} />)
    await waitFor(() =>
      expect(getAllByText('Failed to load grades for History')[0]).toBeInTheDocument()
    )
  })

  it('renders a table with 4 headers', async () => {
    fetchMock.get(ASSIGNMENT_GROUPS_URL, MOCK_ASSIGNMENT_GROUPS)
    const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
    await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
    ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
      expect(getByText(header)).toBeInTheDocument()
    })
  })

  it('does not render anything if no results are returned', async () => {
    fetchMock.get(ASSIGNMENT_GROUPS_URL, [])
    const {queryByText} = render(<GradesPage {...getProps()} />)
    await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
    ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
      expect(queryByText(header)).not.toBeInTheDocument()
    })
  })

  it('renders the returned assignment details', async () => {
    fetchMock.get(ASSIGNMENT_GROUPS_URL, MOCK_ASSIGNMENT_GROUPS)
    const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
    await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
    const formattedDueDate = tz.format('2020-04-18T05:59:59Z', 'date.formats.full_with_weekday')
    ;['WWII Report', formattedDueDate, 'Reports', '9.5 pts', 'Out of 10 pts'].forEach(header => {
      expect(getByText(header)).toBeInTheDocument()
    })
  })
})
