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

// import doFetchApi from '@canvas/do-fetch-api-effect'
import {render, screen, waitFor} from '@testing-library/react'
import {act, renderHook} from '@testing-library/react-hooks'
import userEvent from '@testing-library/user-event'

import {
  useAccessibilityScansStore,
  initialState,
} from '../../../../../shared/react/stores/AccessibilityScansStore'
import {mockEmptyIssuesSummary, mockIssuesSummary2} from '../../../stores/mockData'
import {GroupedIssueSummary} from '../GroupedIssueSummary'

describe('GroupedIssueSummary', () => {
  const mockState = {
    ...initialState,
  }

  beforeEach(() => {
    useAccessibilityScansStore.setState({...mockState})
  })

  describe(' - main content - ', () => {
    it('renders with empty dataset', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setErrorOfSummary(null)
      })

      const {getByTestId} = render(<GroupedIssueSummary />)

      expect(getByTestId('grouped-issue-summary')).toBeInTheDocument()
    })

    it('does not show overlays when not loading or there was no error', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setErrorOfSummary(null)
      })

      const {queryByTestId} = render(<GroupedIssueSummary />)

      expect(queryByTestId('grouped-issue-summary-loading-overlay')).not.toBeInTheDocument()
      expect(queryByTestId('grouped-issue-error-loading-overlay')).not.toBeInTheDocument()
    })

    it('manages loading state correctly', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      const {rerender, queryByTestId, queryByText} = render(<GroupedIssueSummary />)

      // Shows the overlay mask and the spinner
      await act(() => {
        result.current.setLoadingOfSummary(true)
      })

      const loadingSpinner = queryByText('Loading preview...')
      expect(loadingSpinner).toBeInTheDocument()
      const overlay = queryByTestId('grouped-issue-summary-loading-overlay')
      expect(overlay).toBeInTheDocument()
      expect(overlay).toContainElement(loadingSpinner)

      // Clears loading indications
      await act(() => {
        result.current.setLoadingOfSummary(false)
      })

      rerender(<GroupedIssueSummary />)

      expect(queryByText('Loading preview...')).not.toBeInTheDocument()
      expect(queryByTestId('grouped-issue-summary-loading-overlay')).not.toBeInTheDocument()
    })

    it('manages error state correctly', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      // Shows error indications (overlay and text)
      await act(() => {
        result.current.setErrorOfSummary('Error fetching summary')
      })

      const {rerender, queryByTestId, queryByText} = render(<GroupedIssueSummary />)

      expect(queryByTestId('grouped-issue-summary-error-overlay')).toBeInTheDocument()
      expect(queryByText('Error fetching summary')).toBeInTheDocument()

      // Clears error indications (overlay and text)
      await act(() => {
        result.current.setErrorOfSummary(null)
      })

      rerender(<GroupedIssueSummary />)

      expect(queryByText('Error fetching summary')).not.toBeInTheDocument()
      expect(queryByTestId('grouped-issue-summary-error-overlay')).not.toBeInTheDocument()
    })
  })

  describe(' - rows content - ', () => {
    it('renders all issue type summary rows', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockIssuesSummary2)
      })

      render(<GroupedIssueSummary />)

      await waitFor(() => {
        expect(screen.getByTestId('issue-summary-group-headings')).toBeInTheDocument()
        expect(screen.getByTestId('issue-summary-group-links')).toBeInTheDocument()
        expect(screen.getByTestId('issue-summary-group-image-alt-text')).toBeInTheDocument()
        expect(screen.getByTestId('issue-summary-group-tables')).toBeInTheDocument()
        expect(screen.getByTestId('issue-summary-group-lists')).toBeInTheDocument()
        expect(screen.getByTestId('issue-summary-group-low-contrast')).toBeInTheDocument()
      })
    })

    it('groups issues by category correctly', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockIssuesSummary2)
      })

      render(<GroupedIssueSummary />)

      await waitFor(() => {
        // headings-sequence (3)
        const headingsRow = screen.getByTestId('issue-summary-group-headings')
        const headingsCount = headingsRow.querySelector('[data-testid="issue-count-badge"]')

        expect(headingsCount).toHaveTextContent('3')

        // link-text (4)
        const linksRow = screen.getByTestId('issue-summary-group-links')
        const linksCount = linksRow.querySelector('[data-testid="issue-count-badge"]')
        expect(linksCount).toHaveTextContent('4')

        // img-alt (5) + img-alt-length (2) = 7
        const imageAltRow = screen.getByTestId('issue-summary-group-image-alt-text')
        const imageAltCount = imageAltRow.querySelector('[data-testid="issue-count-badge"]')
        expect(imageAltCount).toHaveTextContent('7')

        // table-header (1)
        const tablesRow = screen.getByTestId('issue-summary-group-tables')
        const tablesCount = tablesRow.querySelector('[data-testid="issue-count-badge"]')
        expect(tablesCount).toHaveTextContent('1')
      })
    })
  })

  describe(' - Summary header - ', () => {
    it('displays title and total issues badge with correct count', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockIssuesSummary2)
      })

      render(<GroupedIssueSummary />)

      expect(screen.getByText('Accessibility issues summary')).toBeInTheDocument()
      const totalIssuesSummaryRow = screen.getByTestId('grouped-issue-summary-total-badge')
      expect(totalIssuesSummaryRow).toBeInTheDocument()
      const totalIssuesCount = totalIssuesSummaryRow.querySelector(
        '[data-testid="issue-count-badge"]',
      )
      expect(totalIssuesCount).toHaveTextContent('15')
    })

    it('does not show total issues badge, if there is no data', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(null)
      })

      const {queryByTestId} = render(<GroupedIssueSummary />)

      const totalIssuesSummaryRow = queryByTestId('grouped-issue-summary-total-badge')

      expect(totalIssuesSummaryRow).toBeNull()
    })

    it('does not show total issues badge, if the total count is zero', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary({total: 0, byRuleType: {}})
      })

      const {queryByTestId} = render(<GroupedIssueSummary />)

      const totalIssuesSummaryRow = queryByTestId('grouped-issue-summary-total-badge')

      expect(totalIssuesSummaryRow).toBeNull()
    })
  })

  describe(' - Summary footer - ', () => {
    const mockOnBackClick = jest.fn()
    const mockOnReviewAndFixClick = jest.fn()

    beforeEach(() => {
      jest.clearAllMocks()
      jest.restoreAllMocks()
    })

    it('the "review and fix" and "back" buttons are visible, and can be clicked', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      const {getByTestId} = render(
        <GroupedIssueSummary
          onBackClick={mockOnBackClick}
          onReviewAndFixClick={mockOnReviewAndFixClick}
        />,
      )

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockIssuesSummary2)
      })

      const user = userEvent.setup()

      const reviewAndFixButton = getByTestId('grouped-issue-summary-review-fix')
      const backButton = getByTestId('grouped-issue-summary-back')

      expect(reviewAndFixButton).toBeInTheDocument()
      expect(reviewAndFixButton).toHaveTextContent('Review and fix')
      expect(backButton).toBeInTheDocument()
      expect(backButton).toHaveTextContent('Back to accessibility checker')

      await user.click(reviewAndFixButton)
      expect(mockOnReviewAndFixClick).toHaveBeenCalledTimes(1)

      await user.click(backButton)
      expect(mockOnBackClick).toHaveBeenCalledTimes(1)
    })

    it('the "review and fix button" is disabled only when there is no data or no issues', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      const {getByTestId} = render(
        <GroupedIssueSummary
          onBackClick={mockOnBackClick}
          onReviewAndFixClick={mockOnReviewAndFixClick}
        />,
      )

      const reviewAndFixButton = getByTestId('grouped-issue-summary-review-fix')
      expect(reviewAndFixButton).toBeInTheDocument()
      expect(reviewAndFixButton).toBeDisabled()

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockIssuesSummary2)
      })

      expect(reviewAndFixButton).not.toBeDisabled()

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockEmptyIssuesSummary)
      })

      expect(reviewAndFixButton).toBeDisabled()
    })
  })

  describe('accessibility features', () => {
    it('has proper ARIA live region', async () => {
      const {result} = renderHook(() => useAccessibilityScansStore())

      await act(() => {
        result.current.setLoadingOfSummary(false)
        result.current.setIssuesSummary(mockIssuesSummary2)
      })

      const {container} = render(<GroupedIssueSummary />)

      const liveRegion = container.querySelector('[aria-live="polite"]')
      expect(liveRegion).toBeInTheDocument()
    })
  })
})
