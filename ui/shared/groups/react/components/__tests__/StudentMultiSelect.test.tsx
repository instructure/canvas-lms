/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import StudentMultiSelect from '../StudentMultiSelect'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fakeENV from '@canvas/test-utils/fakeENV'

injectGlobalAlertContainers()

const mockStudents = [
  {id: '1', name: 'Student One'},
  {id: '2', name: 'Student Two'},
  {id: '3', name: 'Student Three'},
]

describe('StudentMultiSelect', () => {
  let queryClient: QueryClient

  beforeEach(() => {
    fakeENV.setup({
      course_id: '123',
      current_user_id: '999',
    })

    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    // Pre-populate the query cache with our mock data
    queryClient.setQueryData(['courses', {courseId: '123', searchText: 'Student'}], mockStudents)
  })

  afterEach(() => {
    queryClient.clear()
    fakeENV.teardown()
  })

  const renderComponent = (props = {}) => {
    const defaultProps = {
      selectedOptionIds: [],
      onSelect: jest.fn(),
    }

    return render(
      <QueryClientProvider client={queryClient}>
        <StudentMultiSelect {...defaultProps} {...props} />
      </QueryClientProvider>,
    )
  }

  it('renders the component', async () => {
    renderComponent()
    expect(screen.getByLabelText('Invite Students')).toBeInTheDocument()
  })

  it('displays students when typing in the search input', async () => {
    const user = userEvent.setup()
    renderComponent()
    const input = screen.getByPlaceholderText('Search')
    await user.type(input, 'Student')

    // Wait for the students to appear
    expect(await screen.findByText('Student One')).toBeInTheDocument()
    expect(screen.getByText('Student Two')).toBeInTheDocument()
    expect(screen.getByText('Student Three')).toBeInTheDocument()
  })

  it('calls onSelect when a student is selected', async () => {
    const user = userEvent.setup()
    const onSelectMock = jest.fn()
    renderComponent({onSelect: onSelectMock})
    const input = screen.getByPlaceholderText('Search')
    await user.type(input, 'Student')

    // Wait for the students to appear
    await screen.findByText('Student Two')
    await user.click(screen.getByText('Student Two'))

    expect(onSelectMock).toHaveBeenCalledWith(['2'])
  })
})
