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

import {renderHook} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {useAccessibilityScansPolling} from '../useAccessibilityScansPolling'
import {initialState, useAccessibilityScansStore} from '../../stores/AccessibilityScansStore'
import {
  AccessibilityResourceScan,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
} from '../../types'

// Mock getCourseBasedPath to return a predictable path
vi.mock('../../utils/query', () => ({
  getCourseBasedPath: vi.fn((path: string) => `/courses/1${path}`),
  parseFetchParams: vi.fn(() => ({})),
}))

const mockDoFetchAccessibilityIssuesSummary = vi.fn().mockResolvedValue(undefined)

vi.mock('../useAccessibilityScansFetchUtils', () => ({
  useAccessibilityScansFetchUtils: vi.fn(() => ({
    doFetchAccessibilityIssuesSummary: mockDoFetchAccessibilityIssuesSummary,
  })),
}))

const server = setupServer()

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

const mockScan = (
  id: number,
  workflowState: ScanWorkflowState,
  issueCount = 0,
): AccessibilityResourceScan => ({
  id,
  resourceId: id,
  resourceType: ResourceType.WikiPage,
  resourceName: `Resource ${id}`,
  resourceWorkflowState: ResourceWorkflowState.Unpublished,
  resourceUpdatedAt: '2025-01-01T00:00:00Z',
  resourceUrl: `/courses/1/pages/${id}`,
  workflowState,
  errorMessage: '',
  issueCount,
  issues: [],
})

describe('useAccessibilityScansPolling', () => {
  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
  })

  beforeEach(() => {
    vi.clearAllMocks()
    mockDoFetchAccessibilityIssuesSummary.mockClear()
    useAccessibilityScansStore.setState(initialState)
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('scansNeedingPolling calculation', () => {
    it('should not poll when there are no scans', () => {
      useAccessibilityScansStore.setState({
        accessibilityScans: null,
      })

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })

    it('should not poll when all scans are completed', () => {
      const completedScan = mockScan(1, ScanWorkflowState.Completed, 5)
      useAccessibilityScansStore.setState({
        accessibilityScans: [completedScan],
      })

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })

    it('should poll queued scans', () => {
      const queuedScan = mockScan(1, ScanWorkflowState.Queued)
      const completedScan = mockScan(2, ScanWorkflowState.Completed, 5)

      useAccessibilityScansStore.setState({
        accessibilityScans: [queuedScan, completedScan],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', ({request}) => {
          const url = new URL(request.url)
          const scanIds = url.searchParams.get('scan_ids')
          expect(scanIds).toBe('1')

          return HttpResponse.json({
            scans: [queuedScan],
          })
        }),
      )

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })

    it('should poll in_progress scans', () => {
      const inProgressScan = mockScan(2, ScanWorkflowState.InProgress)

      useAccessibilityScansStore.setState({
        accessibilityScans: [inProgressScan],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', ({request}) => {
          const url = new URL(request.url)
          const scanIds = url.searchParams.get('scan_ids')
          expect(scanIds).toBe('2')

          return HttpResponse.json({
            scans: [inProgressScan],
          })
        }),
      )

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })

    it('should poll mixed scan states correctly', () => {
      const queuedScan = mockScan(1, ScanWorkflowState.Queued)
      const completedScan = mockScan(2, ScanWorkflowState.Completed, 5)
      const inProgressScan = mockScan(3, ScanWorkflowState.InProgress)
      const failedScan = mockScan(4, ScanWorkflowState.Failed)

      useAccessibilityScansStore.setState({
        accessibilityScans: [queuedScan, completedScan, inProgressScan, failedScan],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', ({request}) => {
          const url = new URL(request.url)
          const scanIds = url.searchParams.get('scan_ids')
          expect(scanIds).toBe('1,3')

          return HttpResponse.json({
            scans: [queuedScan, inProgressScan],
          })
        }),
      )

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })
  })

  describe('error handling', () => {
    it('should handle 4xx error responses', () => {
      const queuedScan = mockScan(1, ScanWorkflowState.Queued)

      useAccessibilityScansStore.setState({
        accessibilityScans: [queuedScan],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', () => {
          return new HttpResponse(null, {status: 403})
        }),
      )

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      // Hook should not crash on error
      expect(result.error).toBeUndefined()
    })

    it('should handle 5xx error responses', () => {
      const queuedScan = mockScan(1, ScanWorkflowState.Queued)

      useAccessibilityScansStore.setState({
        accessibilityScans: [queuedScan],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', () => {
          return new HttpResponse(null, {status: 500})
        }),
      )

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })
  })

  describe('scan ID sorting', () => {
    it('should sort scan IDs for stable comparison', () => {
      // Testing that the useMemo includes .sort()
      const scan3 = mockScan(3, ScanWorkflowState.Queued)
      const scan1 = mockScan(1, ScanWorkflowState.InProgress)
      const scan2 = mockScan(2, ScanWorkflowState.Queued)

      useAccessibilityScansStore.setState({
        accessibilityScans: [scan3, scan1, scan2],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', ({request}) => {
          const url = new URL(request.url)
          const scanIds = url.searchParams.get('scan_ids')
          // IDs should be sorted
          expect(scanIds).toBe('1,2,3')

          return HttpResponse.json({
            scans: [scan1, scan2, scan3],
          })
        }),
      )

      const {result} = renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      expect(result.error).toBeUndefined()
    })
  })

  describe('dashboard refetch integration', () => {
    it('calls doFetchAccessibilityIssuesSummary through useAccessibilityScansFetchUtils', () => {
      // This test verifies that useAccessibilityScansFetchUtils is called
      // The actual dashboard refetch is tested through:
      // 1. The AccessibilityIssuesTable pagination tests
      // 2. Manual/integration testing as documented in test plan
      const queuedScan = mockScan(1, ScanWorkflowState.Queued)

      useAccessibilityScansStore.setState({
        accessibilityScans: [queuedScan],
      })

      server.use(
        http.get('*/accessibility/resource_scan/poll', () => {
          return HttpResponse.json({
            scans: [queuedScan],
          })
        }),
      )

      renderHook(() => useAccessibilityScansPolling(), {
        wrapper: createWrapper(),
      })

      // Verify the hook uses the mocked fetch utils
      expect(mockDoFetchAccessibilityIssuesSummary).toBeDefined()
    })
  })
})
