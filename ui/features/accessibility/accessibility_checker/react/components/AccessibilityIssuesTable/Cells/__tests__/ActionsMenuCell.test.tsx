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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ActionsMenuCell} from '../ActionsMenuCell'
import {
  AccessibilityResourceScan,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
} from '../../../../../../shared/react/types'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {useAccessibilityScansStore} from '../../../../../../shared/react/stores/AccessibilityScansStore'

const mockDoFetchApi = vi.fn()
vi.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: vi.fn((...args) => mockDoFetchApi(...args)),
}))

const mockDoFetchAccessibilityScanData = vi.fn()
const mockDoFetchAccessibilityIssuesSummary = vi.fn()
vi.mock('../../../../../../shared/react/hooks/useAccessibilityScansFetchUtils', () => ({
  useAccessibilityScansFetchUtils: vi.fn(() => ({
    doFetchAccessibilityScanData: mockDoFetchAccessibilityScanData,
    doFetchAccessibilityIssuesSummary: mockDoFetchAccessibilityIssuesSummary,
  })),
}))

vi.mock('../../../../../../shared/react/stores/AccessibilityScansStore')

const mockShowFlashAlert = vi.fn()
vi.spyOn(FlashAlert, 'showFlashAlert').mockImplementation(mockShowFlashAlert)

describe('ActionsMenuCell', () => {
  let queryClient: QueryClient

  const activeScan: AccessibilityResourceScan = {
    id: 1,
    courseId: 100,
    resourceId: 10,
    resourceType: ResourceType.WikiPage,
    resourceName: 'Test Page',
    resourceWorkflowState: ResourceWorkflowState.Published,
    resourceUpdatedAt: '2025-01-01T00:00:00Z',
    resourceUrl: '/courses/100/pages/test-page',
    workflowState: ScanWorkflowState.Completed,
    issueCount: 5,
    closedAt: null,
  }

  beforeEach(() => {
    // Enable feature flag by default for tests
    window.ENV = {FEATURES: {a11y_checker_close_issues: true}} as any
    vi.clearAllMocks()
    mockDoFetchApi.mockResolvedValue({json: {}, response: {ok: true}})
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
      },
    })
    ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
      const state = {isCloseIssuesEnabled: true}
      return selector ? selector(state) : state
    })
  })

  afterEach(() => {
    queryClient.clear()
  })

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  describe('feature flag', () => {
    it('does not render menu when feature flag is disabled', () => {
      window.ENV = {FEATURES: {a11y_checker_close_issues: false}} as any
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isCloseIssuesEnabled: false}
        return selector ? selector(state) : state
      })
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})
      expect(screen.queryByTestId('actions-menu-button')).not.toBeInTheDocument()
    })

    it('does not render menu when feature flag is missing', () => {
      window.ENV = {FEATURES: {}} as any
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isCloseIssuesEnabled: false}
        return selector ? selector(state) : state
      })
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})
      expect(screen.queryByTestId('actions-menu-button')).not.toBeInTheDocument()
    })

    it('does not render menu for closed scan when feature flag is disabled', () => {
      window.ENV = {FEATURES: {a11y_checker_close_issues: false}} as any
      ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
        const state = {isCloseIssuesEnabled: false}
        return selector ? selector(state) : state
      })
      const closedScan = {...activeScan, closedAt: '2025-01-01T00:00:00Z'}
      render(<ActionsMenuCell scan={closedScan} />, {wrapper})
      expect(screen.queryByTestId('actions-menu-button')).not.toBeInTheDocument()
    })
  })

  describe('rendering conditions', () => {
    it('renders menu for completed scan with issues', () => {
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})
      expect(screen.getByTestId('actions-menu-button')).toBeInTheDocument()
    })

    it('does not render menu for non-completed scan', () => {
      const incompleteScan = {...activeScan, workflowState: ScanWorkflowState.InProgress}
      render(<ActionsMenuCell scan={incompleteScan} />, {wrapper})
      expect(screen.queryByTestId('actions-menu-button')).not.toBeInTheDocument()
    })

    it('does not render menu for open scan with no issues', () => {
      const scanWithoutIssues = {...activeScan, issueCount: 0}
      render(<ActionsMenuCell scan={scanWithoutIssues} />, {wrapper})
      expect(screen.queryByTestId('actions-menu-button')).not.toBeInTheDocument()
    })

    it('renders menu for closed scan even with no issues', () => {
      const closedScan = {...activeScan, issueCount: 0, closedAt: '2025-01-01T00:00:00Z'}
      render(<ActionsMenuCell scan={closedScan} />, {wrapper})
      expect(screen.getByTestId('actions-menu-button')).toBeInTheDocument()
    })
  })

  describe('menu options', () => {
    it('shows "Close remediation" option for open scan', async () => {
      const user = userEvent.setup()
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      expect(screen.getByText(/close remediation/i)).toBeInTheDocument()
    })

    it('shows "Reopen remediation" option for closed scan', async () => {
      const user = userEvent.setup()
      const closedScan = {...activeScan, closedAt: '2025-01-01T00:00:00Z'}
      render(<ActionsMenuCell scan={closedScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      expect(screen.getByText(/reopen remediation/i)).toBeInTheDocument()
    })
  })

  describe('close remediation', () => {
    it('calls API and opens modal when closing remediation', async () => {
      const user = userEvent.setup()
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const closeOption = screen.getByText(/close remediation/i)
      await user.click(closeOption)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: '/courses/100/accessibility/resource_scan/1/close_issues',
          method: 'PATCH',
          body: {close: true},
        })
      })

      expect(screen.getByText(/you closed remediation/i)).toBeInTheDocument()
    })

    it('shows error flash alert when close remediation fails', async () => {
      const user = userEvent.setup()
      mockDoFetchApi.mockRejectedValueOnce(new Error('Network error'))

      render(<ActionsMenuCell scan={activeScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const closeOption = screen.getByText(/close remediation/i)
      await user.click(closeOption)

      await waitFor(() => {
        expect(mockShowFlashAlert).toHaveBeenCalledWith({
          message: 'Network error',
          type: 'error',
        })
      })
    })

    it('refetches data when modal is closed', async () => {
      const user = userEvent.setup()
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const closeOption = screen.getByText(/close remediation/i)
      await user.click(closeOption)

      await waitFor(() => {
        expect(screen.getByText(/you closed remediation/i)).toBeInTheDocument()
      })

      const okButton = screen.getByText(/^ok$/i)
      await user.click(okButton.closest('button')!)

      await waitFor(() => {
        expect(mockDoFetchAccessibilityScanData).toHaveBeenCalledWith({})
        expect(mockDoFetchAccessibilityIssuesSummary).toHaveBeenCalledWith({})
      })
    })
  })

  describe('reopen remediation', () => {
    it('calls API and refetches data when reopening remediation', async () => {
      const user = userEvent.setup()
      const closedScan = {...activeScan, closedAt: '2025-01-01T00:00:00Z'}
      render(<ActionsMenuCell scan={closedScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const reopenOption = screen.getByText(/reopen remediation/i)
      await user.click(reopenOption)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: '/courses/100/accessibility/resource_scan/1/close_issues',
          method: 'PATCH',
          body: {close: false},
        })
      })

      expect(mockShowFlashAlert).toHaveBeenCalledWith({
        message: 'Remediation reopened and resource re-scanned',
        type: 'success',
      })

      expect(mockDoFetchAccessibilityScanData).toHaveBeenCalledWith({})
      expect(mockDoFetchAccessibilityIssuesSummary).toHaveBeenCalledWith({})
    })

    it('shows error flash alert when reopen remediation fails', async () => {
      const user = userEvent.setup()
      mockDoFetchApi.mockRejectedValueOnce(new Error('Network error'))

      const closedScan = {...activeScan, closedAt: '2025-01-01T00:00:00Z'}
      render(<ActionsMenuCell scan={closedScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const reopenOption = screen.getByText(/reopen remediation/i)
      await user.click(reopenOption)

      await waitFor(() => {
        expect(mockShowFlashAlert).toHaveBeenCalledWith({
          message: 'Network error',
          type: 'error',
        })
      })
    })

    it('can reopen from the modal after closing', async () => {
      const user = userEvent.setup()
      render(<ActionsMenuCell scan={activeScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const closeOption = screen.getByText(/close remediation/i)
      await user.click(closeOption)

      await waitFor(() => {
        expect(screen.getByText(/you closed remediation/i)).toBeInTheDocument()
      })

      const reopenButton = screen.getByText(/^reopen$/i)
      await user.click(reopenButton.closest('button')!)

      await waitFor(() => {
        expect(mockDoFetchApi).toHaveBeenCalledWith({
          path: '/courses/100/accessibility/resource_scan/1/close_issues',
          method: 'PATCH',
          body: {close: false},
        })
      })
    })
  })

  describe('loading states', () => {
    it('disables menu items while loading and shows screen reader announcement', async () => {
      const user = userEvent.setup()
      let resolveRequest!: (value: {json: object; response: {ok: boolean}}) => void
      mockDoFetchApi.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveRequest = resolve
          }),
      )

      render(<ActionsMenuCell scan={activeScan} />, {wrapper})

      const menuButton = screen.getByTestId('actions-menu-button')
      await user.click(menuButton)

      const closeOption = screen.getByText(/close remediation/i)
      await user.click(closeOption)

      // Wait for the API call to be initiated
      await waitFor(() => expect(mockDoFetchApi).toHaveBeenCalled())

      // Menu button should NOT be disabled (users can still open the menu)
      expect(menuButton).not.toBeDisabled()

      // Screen reader announcement should be present
      expect(screen.getByText(/closing remediation, please wait/i)).toBeInTheDocument()

      // Menu item should be disabled
      await user.click(menuButton)
      const menuItem = screen.getByText(/close remediation/i).closest('[role="menuitem"]')
      expect(menuItem).toHaveAttribute('aria-disabled', 'true')

      // Now resolve the request
      resolveRequest({json: {}, response: {ok: true}})

      await waitFor(() => {
        expect(screen.queryByText(/closing remediation, please wait/i)).not.toBeInTheDocument()
      })
    })
  })
})
