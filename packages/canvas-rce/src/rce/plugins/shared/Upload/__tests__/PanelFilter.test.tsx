/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import PanelFilter from '../PanelFilter'

function getSortByField() {
  return screen.getByLabelText('Sort By')
}

function selectSortBy(sortByLabel: string) {
  const sortByField = getSortByField()
  fireEvent.click(sortByField)
  fireEvent.click(screen.getByText(sortByLabel))
}

describe('PanelFilter', () => {
  const mockOnChange = jest.fn()

  const renderComponent = (props = {}) => {
    return render(
      <PanelFilter
        onChange={mockOnChange}
        sortValue="date_added"
        searchString=""
        contentType="course"
        {...props}
      />,
    )
  }

  beforeEach(() => {
    jest.useFakeTimers()
    mockOnChange.mockClear()
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  it('renders correctly', () => {
    renderComponent()
    expect(screen.getByPlaceholderText('Search')).toBeInTheDocument()
    expect(screen.getByTestId('filter-sort-by')).toBeInTheDocument()
  })

  it('has the correct initial state', () => {
    renderComponent()
    expect(screen.getByPlaceholderText('Search')).toHaveValue('')
    expect(screen.getByTestId('filter-sort-by')).toHaveValue('Date Added')
  })

  it('calls onChange with correct value when sort option is changed', async () => {
    renderComponent()
    selectSortBy('Alphabetical')
    await waitFor(() => {
      expect(mockOnChange).toHaveBeenCalledWith({sortValue: 'alphabetical'})
    })
  })

  it('updates search input state and calls doSearch after delay', async () => {
    renderComponent()
    const searchInput = screen.getByPlaceholderText('Search')
    fireEvent.change(searchInput, {target: {value: 'test'}})
    expect(searchInput).toHaveValue('test')

    jest.advanceTimersByTime(250)
    await waitFor(() => {
      expect(mockOnChange).toHaveBeenCalledWith({searchString: 'test'})
    })
  })

  it('clears search input when clear button is clicked', async () => {
    renderComponent({searchString: 'test'})
    const clearButton = screen.getByRole('button', {name: 'Clear'})
    fireEvent.click(clearButton)

    jest.advanceTimersByTime(250)
    await waitFor(() => {
      expect(mockOnChange).toHaveBeenCalledWith({searchString: ''})
    })
  })

  it('changes context to course on load', () => {
    renderComponent()
    expect(mockOnChange).toHaveBeenCalledWith({contentType: 'course'})
  })

  it('changes context to user on load', () => {
    renderComponent({contentType: 'user'})
    expect(mockOnChange).toHaveBeenCalledWith({contentType: 'user'})
  })
})
