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

import {fireEvent, render, screen} from '@testing-library/react'
import {act, renderHook} from '@testing-library/react-hooks'

import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable'
import {useAccessibilityCheckerStore, initialState} from '../../../stores/AccessibilityCheckerStore'
import {sampleTableData} from '../../../stores/mockData'

describe('AccessibilityIssuesTable', () => {
  const mockSetLoading = jest.fn()
  const mockSetError = jest.fn()
  const mockSetTableSortState = jest.fn()
  const mockSetTableData = jest.fn()
  const mockState = {
    ...initialState,
    mockSetLoading,
    mockSetError,
    mockSetTableSortState,
    mockSetTableData,
  }

  beforeEach(() => {
    useAccessibilityCheckerStore.setState({...mockState})
  })

  it('renders empty table without crashing', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(true)
      result.current.setTableData(null)
    })

    const {rerender} = render(<AccessibilityIssuesTable />)
    expect(screen.getByTestId('accessibility-issues-table')).toBeInTheDocument()

    act(() => {
      result.current.setLoading(false)
      result.current.setTableData([])
    })

    rerender(<AccessibilityIssuesTable />)
    expect(screen.getByTestId(/^no-issues-row/)).toBeInTheDocument()
  })

  it('renders the loading state correctly', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(true)
      result.current.setTableData(null)
    })

    const {rerender} = render(<AccessibilityIssuesTable />)
    expect(screen.getByTestId('loading-row')).toBeInTheDocument()

    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
    })

    rerender(<AccessibilityIssuesTable />)
    expect(screen.queryByTestId('loading-row')).not.toBeInTheDocument()
  })

  it('renders the correct number of rows', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
    })

    render(<AccessibilityIssuesTable />)
    expect(screen.getAllByTestId(/^issue-row-/)).toHaveLength(sampleTableData.length)
  })

  it('renders the error state correctly', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    const errorMessage = 'An error occurred while fetching data'
    act(() => {
      result.current.setLoading(false)
      result.current.setError(errorMessage)
      result.current.setTableData(null)
    })

    const {rerender} = render(<AccessibilityIssuesTable />)
    expect(screen.getByTestId('error-row')).toBeInTheDocument()
    expect(screen.getByText(errorMessage)).toBeInTheDocument()

    act(() => {
      result.current.setError(null)
      result.current.setTableData(sampleTableData)
    })

    rerender(<AccessibilityIssuesTable />)
    expect(screen.queryByTestId('error-row')).not.toBeInTheDocument()
    expect(screen.queryByText(errorMessage)).not.toBeInTheDocument()
  })

  it('sets tableSortState with the proper values when a column header is clicked', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
    })

    render(<AccessibilityIssuesTable />)

    screen.getByText('Resource Type').click()

    expect(result.current.tableSortState?.sortId).toBe('resource-type-header')
    expect(result.current.tableSortState?.sortDirection).toBe('ascending')

    screen.getByText('Resource Type').click()

    expect(result.current.tableSortState?.sortId).toBe('resource-type-header')
    expect(result.current.tableSortState?.sortDirection).toBe('descending')

    screen.getByText('Resource Type').click()

    expect(result.current.tableSortState?.sortId).toBe('resource-type-header')
    expect(result.current.tableSortState?.sortDirection).toBe('none')
  })

  it('renders data and pagination correctly when there are multiple pages', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
      result.current.setPageSize(2) // Set perPage to 2 for pagination
    })

    render(<AccessibilityIssuesTable />)
    const row1 = screen.getByText('Test Wiki Page 1')
    const row2 = screen.getByText('Test Assignment 1')
    const rows = screen.getAllByTestId(/^issue-row-/)
    expect(row1).toBeInTheDocument()
    expect(row2).toBeInTheDocument()
    expect(rows).toHaveLength(2)
  })

  it('handles page change', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
      result.current.setPageSize(2)
    })

    render(<AccessibilityIssuesTable />)
    const buttons = screen.getAllByText(/2/i)
    fireEvent.click(buttons[2])
    const row3 = screen.getByText('Test Assignment 2')
    const rows = screen.getAllByTestId(/^issue-row-/)
    expect(row3).toBeInTheDocument()
    expect(rows).toHaveLength(1)
  })

  it('pagination is not rendered when not needed', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
      result.current.setPageSize(3)
    })

    render(<AccessibilityIssuesTable />)
    const row1 = screen.getByText('Test Wiki Page 1')
    const row2 = screen.getByText('Test Assignment 1')
    const row3 = screen.getByText('Test Assignment 2')
    const rows = screen.getAllByTestId(/^issue-row-/)
    expect(row1).toBeInTheDocument()
    expect(row2).toBeInTheDocument()
    expect(row3).toBeInTheDocument()
    expect(rows).toHaveLength(3)
    expect(screen.queryByTestId('accessibility-issues-table-pagination')).not.toBeInTheDocument()
  })

  it('displays the correct number of pages', () => {
    const {result} = renderHook(() => useAccessibilityCheckerStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setTableData(sampleTableData)
      result.current.setPageSize(1)
    })

    render(<AccessibilityIssuesTable />)
    const buttonPage3 = screen.getAllByText(/3/i)[1]
    expect(buttonPage3).toBeInTheDocument()
  })
})
