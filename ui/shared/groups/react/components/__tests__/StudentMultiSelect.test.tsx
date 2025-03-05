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
import {useQuery} from '@canvas/query'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import StudentMultiSelect from '../StudentMultiSelect'

injectGlobalAlertContainers()

jest.mock('@canvas/query')

const renderComponent = (props = {}) => {
  const defaultProps = {
    selectedOptionIds: [],
    onSelect: jest.fn(),
  }

  return render(<StudentMultiSelect {...defaultProps} {...props} />)
}

describe('StudentMultiSelect', () => {
  const mockStudents = [
    {id: '1', name: 'Student One'},
    {id: '2', name: 'Student Two'},
    {id: '3', name: 'Student Three'},
  ]

  const mockUseQuery = useQuery as jest.Mock

  beforeEach(() => {
    mockUseQuery.mockReturnValue({
      data: mockStudents,
      isLoading: false,
      refetch: jest.fn(),
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the component', async () => {
    renderComponent()
    expect(screen.getByLabelText('Invite Students')).toBeInTheDocument()
  })

  it('displays students when typing in the search input', async () => {
    renderComponent()
    const input = screen.getByPlaceholderText('Search')
    await userEvent.type(input, 'Student')

    expect(screen.getByText('Student One')).toBeInTheDocument()
    expect(screen.getByText('Student Two')).toBeInTheDocument()
    expect(screen.getByText('Student Three')).toBeInTheDocument()
  })

  it('calls onSelect when a student is selected', async () => {
    const onSelectMock = jest.fn()
    renderComponent({onSelect: onSelectMock})
    const input = screen.getByPlaceholderText('Search')
    await userEvent.type(input, 'Student')

    await userEvent.click(screen.getByText('Student Two'))

    expect(onSelectMock).toHaveBeenCalledWith(['2'])
  })
})
