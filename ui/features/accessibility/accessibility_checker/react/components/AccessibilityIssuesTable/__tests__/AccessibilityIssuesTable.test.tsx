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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'

import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable'
import {
  useAccessibilityScansStore,
  initialState,
} from '../../../../../shared/react/stores/AccessibilityScansStore'
import {mockScanData} from '../../../../../shared/react/stores/mockData'
import {useAccessibilityScansFetchUtils} from '../../../../../shared/react/hooks/useAccessibilityScansFetchUtils'

jest.mock('../../../../../shared/react/hooks/useAccessibilityScansFetchUtils', () => ({
  useAccessibilityScansFetchUtils: jest.fn(),
}))

const mockDoFetch = jest.fn()

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('AccessibilityIssuesTable', () => {
  const mockState = {
    ...initialState,
  }

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    useAccessibilityScansStore.setState({...mockState})
    ;(useAccessibilityScansFetchUtils as jest.Mock).mockReturnValue({
      doFetchAccessibilityScanData: mockDoFetch,
    })
  })

  it('renders empty table without crashing', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())
    act(() => {
      result.current.setLoading(true)
      result.current.setAccessibilityScans(null)
    })

    const Wrapper = createWrapper()
    const {rerender} = render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
    expect(screen.getByTestId('accessibility-issues-table')).toBeInTheDocument()

    act(() => {
      result.current.setLoading(false)
      result.current.setAccessibilityScans([])
    })

    rerender(<AccessibilityIssuesTable />)
    expect(screen.getByTestId(/^no-issues-row/)).toBeInTheDocument()
  })

  it('renders the loading state correctly', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())
    act(() => {
      result.current.setLoading(true)
      result.current.setAccessibilityScans(null)
    })

    const Wrapper = createWrapper()
    const {rerender} = render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
    expect(screen.getByTestId('loading-row')).toBeInTheDocument()

    act(() => {
      result.current.setLoading(false)
      result.current.setAccessibilityScans(mockScanData)
    })

    rerender(<AccessibilityIssuesTable />)
    expect(screen.queryByTestId('loading-row')).not.toBeInTheDocument()
  })

  it('renders the correct number of rows', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())
    act(() => {
      result.current.setLoading(false)
      result.current.setAccessibilityScans(mockScanData)
    })

    const Wrapper = createWrapper()
    render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
    expect(screen.getAllByTestId(/^issue-row-/)).toHaveLength(mockScanData.length)
  })

  it('renders the error state correctly', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())
    const errorMessage = 'An error occurred while fetching data'
    act(() => {
      result.current.setLoading(false)
      result.current.setError(errorMessage)
      result.current.setAccessibilityScans(null)
    })

    const Wrapper = createWrapper()
    const {rerender} = render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
    expect(screen.getByTestId('error-row')).toBeInTheDocument()
    expect(screen.getByText(errorMessage)).toBeInTheDocument()

    act(() => {
      result.current.setError(null)
      result.current.setAccessibilityScans(mockScanData)
    })

    rerender(<AccessibilityIssuesTable />)
    expect(screen.queryByTestId('error-row')).not.toBeInTheDocument()
    expect(screen.queryByText(errorMessage)).not.toBeInTheDocument()
  })

  describe('- sorting -', () => {
    it('calls doFetchAccessibilityScanData with the proper tableSortState values when a column header is clicked', () => {
      const {result} = renderHook(() => useAccessibilityScansStore())
      const Wrapper = createWrapper()
      render(<AccessibilityIssuesTable />, {wrapper: Wrapper})

      act(() => {
        screen.getByText('Type').click()
      })

      expect(mockDoFetch).toHaveBeenCalledTimes(1)
      expect(mockDoFetch).toHaveBeenCalledWith(
        expect.objectContaining({
          tableSortState: {
            sortId: 'resource-type-header',
            sortDirection: 'ascending',
          },
        }),
      )

      act(() => {
        result.current.setTableSortState({
          sortId: 'resource-type-header',
          sortDirection: 'ascending',
        })
      })

      act(() => {
        screen.getByText('Type').click()
      })

      expect(mockDoFetch).toHaveBeenCalledTimes(2)
      expect(mockDoFetch).toHaveBeenCalledWith(
        expect.objectContaining({
          tableSortState: {
            sortId: 'resource-type-header',
            sortDirection: 'descending',
          },
        }),
      )

      act(() => {
        result.current.setTableSortState({
          sortId: 'resource-type-header',
          sortDirection: 'descending',
        })
      })

      act(() => {
        screen.getByText('Type').click()
      })

      expect(mockDoFetch).toHaveBeenCalledTimes(3)
      expect(mockDoFetch).toHaveBeenCalledWith(
        expect.objectContaining({
          tableSortState: {
            sortId: 'resource-type-header',
            sortDirection: 'ascending',
          },
        }),
      )
    })
  })

  describe('- pagination -', () => {
    it('buttons are not rendered when not needed', () => {
      const {result} = renderHook(() => useAccessibilityScansStore())
      act(() => {
        result.current.setLoading(false)
        result.current.setPage(1)
        result.current.setPageCount(1)
      })

      const Wrapper = createWrapper()
      render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
      expect(screen.queryByTestId('accessibility-issues-table-pagination')).not.toBeInTheDocument()
    })

    it('displays the correct number of pages', () => {
      const {result} = renderHook(() => useAccessibilityScansStore())
      act(() => {
        result.current.setLoading(false)
        result.current.setPage(1)
        result.current.setPageCount(5)
      })

      const Wrapper = createWrapper()
      render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
      expect(screen.getByTestId('accessibility-issues-table-pagination')).toBeInTheDocument()
      const buttonPage5 = screen.getAllByText(/5/i)[0]
      expect(buttonPage5).toBeInTheDocument()
    })

    it('handles page change', () => {
      const {result} = renderHook(() => useAccessibilityScansStore())
      act(() => {
        result.current.setLoading(false)
        result.current.setPage(1)
        result.current.setPageCount(5)
      })

      const Wrapper = createWrapper()
      render(<AccessibilityIssuesTable />, {wrapper: Wrapper})
      const buttons = screen.getAllByText(/5/i)
      fireEvent.click(buttons[0])

      expect(mockDoFetch).toHaveBeenCalledTimes(1)
      expect(mockDoFetch).toHaveBeenCalledWith(
        expect.objectContaining({
          page: 5,
        }),
      )
    })
  })
})
