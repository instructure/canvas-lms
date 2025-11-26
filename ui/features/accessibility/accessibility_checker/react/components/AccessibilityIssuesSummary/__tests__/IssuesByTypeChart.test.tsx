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

import {render, screen} from '@testing-library/react'
import {act, renderHook} from '@testing-library/react-hooks'
import '@testing-library/jest-dom'

import {IssuesByTypeChart} from '../IssuesByTypeChart'
import {
  useAccessibilityScansStore,
  initialState,
} from '../../../../../shared/react/stores/AccessibilityScansStore'
import {mockIssuesSummary1} from '../../../../../shared/react/stores/mockData'

// Mock ResizeObserver since it's not supported in jsdom
class ResizeObserver {
  observe() {}
  disconnect() {}
  unobserve() {}
}
window.ResizeObserver = ResizeObserver

describe('IssuesByTypeChart', () => {
  const mockState = {
    ...initialState,
  }

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    useAccessibilityScansStore.setState({...mockState})
  })

  it('renders chart heading', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())

    act(() => {
      result.current.setLoadingOfSummary(false)
      result.current.setIssuesSummary(mockIssuesSummary1)
    })

    render(<IssuesByTypeChart />)
    expect(screen.getByText('Issues by type')).toBeInTheDocument()
  })

  it('renders chart region with aria-label', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())

    act(() => {
      result.current.setLoadingOfSummary(false)
      result.current.setIssuesSummary(mockIssuesSummary1)
    })

    render(<IssuesByTypeChart />)
    const chart = screen.getByTestId('issues-by-type-chart')
    expect(chart).toBeInTheDocument()
    expect(chart).toHaveAttribute('aria-label', 'Accessibility issues bar chart showing 61 issues.')
  })

  it('handles empty data gracefully', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())

    act(() => {
      result.current.setLoadingOfSummary(false)
      result.current.setIssuesSummary(null)
    })

    render(<IssuesByTypeChart />)
    const chart = screen.getByTestId('issues-by-type-chart')
    expect(chart).toBeInTheDocument()
    expect(chart).toHaveAttribute('aria-label', 'Accessibility issues bar chart showing 0 issues.')
  })

  it('renders loading state', () => {
    const {result} = renderHook(() => useAccessibilityScansStore())

    act(() => {
      result.current.setLoading(true)
    })

    render(<IssuesByTypeChart />)
    expect(screen.getByText('Loading accessibility issues')).toBeInTheDocument()
  })
})
