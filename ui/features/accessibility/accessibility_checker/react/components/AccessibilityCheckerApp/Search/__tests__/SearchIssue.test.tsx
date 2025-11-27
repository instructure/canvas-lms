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

// tests/SearchIssue.test.js
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom'
import {SearchIssue} from '../SearchIssue'

describe('SearchIssue Component', () => {
  beforeEach(() => {
    // Update window.location.search without mocking
    const url = new URL('http://localhost/?page=1&search=test')
    window.history.pushState({}, '', url)
  })

  it('should initialize the search input with the value from the URL', () => {
    const mockOnSearchChange = jest.fn()
    render(<SearchIssue onSearchChange={mockOnSearchChange} />)

    const input = screen.getByTestId('issue-search-input')
    expect(input).toHaveValue('test')
  })

  it('should call onSearchChange when the input value changes', async () => {
    const mockOnSearchChange = jest.fn()
    render(<SearchIssue onSearchChange={mockOnSearchChange} />)

    const input = screen.getByTestId('issue-search-input')
    fireEvent.change(input, {target: {value: 'new search'}})

    await waitFor(() => {
      expect(mockOnSearchChange).toHaveBeenCalledWith('new search')
    })
    expect(input).toHaveValue('new search')
  })

  it('should not show clear button when search is empty', () => {
    const mockOnSearchChange = jest.fn()
    render(<SearchIssue onSearchChange={mockOnSearchChange} />)

    const input = screen.getByTestId('issue-search-input')
    fireEvent.change(input, {target: {value: ''}})

    const clearButton = screen.queryByTestId('clear-search-button')
    expect(clearButton).not.toBeInTheDocument()
  })

  it('should show clear button when search has value', () => {
    const mockOnSearchChange = jest.fn()
    render(<SearchIssue onSearchChange={mockOnSearchChange} />)

    const input = screen.getByTestId('issue-search-input')
    fireEvent.change(input, {target: {value: 'test search'}})

    const clearButton = screen.getByTestId('clear-search-button')
    expect(clearButton).toBeInTheDocument()
  })

  it('should clear search input when clear button is clicked', async () => {
    const mockOnSearchChange = jest.fn()
    render(<SearchIssue onSearchChange={mockOnSearchChange} />)

    const input = screen.getByTestId('issue-search-input')
    fireEvent.change(input, {target: {value: 'test search'}})

    const clearButton = screen.getByTestId('clear-search-button')
    fireEvent.click(clearButton)

    expect(input).toHaveValue('')
    await waitFor(() => {
      expect(mockOnSearchChange).toHaveBeenCalledWith('')
    })
  })

  it('should hide clear button after clearing search', () => {
    const mockOnSearchChange = jest.fn()
    render(<SearchIssue onSearchChange={mockOnSearchChange} />)

    const input = screen.getByPlaceholderText('Search...')
    fireEvent.change(input, {target: {value: 'test search'}})

    const clearButton = screen.getByTestId('clear-search-button')
    fireEvent.click(clearButton)

    expect(screen.queryByTestId('clear-search-button')).not.toBeInTheDocument()
  })
})
