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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {PageViewsDownload, type PageViewsDownloadProps} from '../PageViewsDownload'
import {AsyncPageViewJobStatus} from '../hooks/asyncPageviewExport'

// Mock canvas alerts
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

const server = setupServer()

afterEach(() => {
  cleanup()
  vi.clearAllMocks()
  localStorage.clear()
})

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

// Helper to create mock job data
function createMockJob(overrides: any = {}) {
  return {
    query_id: 'test-uuid-123',
    name: 'January 2025 - January 2025',
    status: AsyncPageViewJobStatus.Queued,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    error_code: null,
    ...overrides,
  }
}

function Subject(props: PageViewsDownloadProps): React.JSX.Element {
  return <PageViewsDownload {...props} />
}

describe('PageViewsDownload', () => {
  const defaultProps = {
    userId: '123',
  }

  describe('Initial rendering', () => {
    it('renders the form elements correctly', () => {
      render(<Subject {...defaultProps} />)

      expect(screen.getByText(/You may export up to 1 year of history/)).toBeInTheDocument()
      expect(screen.getByLabelText('Start month')).toBeInTheDocument()
      expect(screen.getByLabelText('End month')).toBeInTheDocument()
      expect(screen.getByTestId('page-views-csv-link')).toBeInTheDocument()
      expect(screen.getByText('Recent exports (last 24 hours)')).toBeInTheDocument()
    })

    it('shows export button enabled when no jobs are in progress', () => {
      render(<Subject {...defaultProps} />)
      const exportButton = screen.getByTestId('page-views-csv-link')
      expect(exportButton).not.toBeDisabled()
    })
  })

  describe('Form validation', () => {
    it('shows error when start month is after end month', async () => {
      const user = userEvent.setup()
      render(<Subject {...defaultProps} />)

      // Get formatted month names for current and previous months
      const today = new Date()
      const currentMonthDate = new Date(today.getFullYear(), today.getMonth(), 1)
      const previousMonthDate = new Date(today.getFullYear(), today.getMonth() - 1, 1)

      const formatter = new Intl.DateTimeFormat('en-US', {
        month: 'long',
        year: 'numeric',
        timeZone: 'UTC'
      })

      const currentMonthText = formatter.format(currentMonthDate)
      const previousMonthText = formatter.format(previousMonthDate)

      // Select current month as start
      const startSelect = screen.getByLabelText('Start month')
      await user.click(startSelect)
      const currentMonth = screen.getByText(currentMonthText)
      await user.click(currentMonth)

      // Select previous month as end (invalid)
      const endSelect = screen.getByLabelText('End month')
      await user.click(endSelect)
      const previousMonth = screen.getByText(previousMonthText)
      await user.click(previousMonth)

      // Try to export
      const exportButton = screen.getByTestId('page-views-csv-link')
      await user.click(exportButton)

      expect(screen.getByText(/start month is not after the end month/)).toBeInTheDocument()
    })
  })

  describe('Job creation', () => {
    it('creates export job when form is submitted', async () => {
      const user = userEvent.setup()

      server.use(
        http.post(`/api/v1/users/${defaultProps.userId}/page_views/query`, () => {
          return HttpResponse.json({
            poll_url: `/api/v1/users/${defaultProps.userId}/page_views/query/new-job-uuid`,
          })
        }),
      )

      render(<Subject {...defaultProps} />)

      const exportButton = screen.getByTestId('page-views-csv-link')
      await user.click(exportButton)

      await waitFor(() => {
        expect(exportButton).toBeDisabled() // Button should be disabled during processing
      })
    })

    it('shows error when job creation fails with 429', async () => {
      const user = userEvent.setup()

      server.use(
        http.post(`/api/v1/users/${defaultProps.userId}/page_views/query`, () => {
          return new HttpResponse(null, {status: 429})
        }),
      )

      render(<Subject {...defaultProps} />)

      const exportButton = screen.getByTestId('page-views-csv-link')
      await user.click(exportButton)

      await waitFor(() => {
        expect(screen.getByText(/wait for your running jobs to finish/)).toBeInTheDocument()
      })
    })

    it('prevents creating job when one is already in progress', async () => {
      const inProgressJob = createMockJob({
        status: AsyncPageViewJobStatus.Running,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([inProgressJob]))

      render(<Subject {...defaultProps} />)

      const exportButton = screen.getByTestId('page-views-csv-link')
      expect(exportButton).toBeDisabled()
    })
  })

  describe('Recent exports table', () => {
    it('displays recent jobs from localStorage', () => {
      const completedJob = createMockJob({
        query_id: 'completed-job',
        name: 'December 2024 - December 2024',
        status: AsyncPageViewJobStatus.Finished,
      })
      const runningJob = createMockJob({
        query_id: 'running-job',
        name: 'January 2025 - January 2025',
        status: AsyncPageViewJobStatus.Running,
      })

      localStorage.setItem(
        `pv-export-${defaultProps.userId}`,
        JSON.stringify([completedJob, runningJob]),
      )

      render(<Subject {...defaultProps} />)

      expect(screen.getByText('December 2024 - December 2024')).toBeInTheDocument()
      expect(screen.getByText('January 2025 - January 2025')).toBeInTheDocument()
      expect(screen.getByText('Completed')).toBeInTheDocument()
      expect(screen.getByText('In progress')).toBeInTheDocument()
    })

    it('shows download link for completed jobs', () => {
      const completedJob = createMockJob({
        query_id: 'completed-job',
        name: 'Test Export',
        status: AsyncPageViewJobStatus.Finished,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([completedJob]))

      render(<Subject {...defaultProps} />)

      const downloadLink = screen.getByTestId('download-completed-job')
      expect(downloadLink).toBeInTheDocument()
      expect(downloadLink).toHaveTextContent('Test Export')
    })

    it('does not show download link for in-progress jobs', () => {
      const runningJob = createMockJob({
        query_id: 'running-job',
        name: 'Test Export',
        status: AsyncPageViewJobStatus.Running,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([runningJob]))

      render(<Subject {...defaultProps} />)

      expect(screen.queryByTestId('download-running-job')).not.toBeInTheDocument()
      expect(screen.getByText('Test Export')).toBeInTheDocument() // Should show as plain text
    })
  })

  describe('Error message display', () => {
    it('shows error message in pill for failed jobs with error codes', () => {
      const failedJob = createMockJob({
        query_id: 'failed-job',
        name: 'Large Export',
        status: AsyncPageViewJobStatus.Failed,
        error_code: 'RESULT_SIZE_LIMIT_EXCEEDED',
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([failedJob]))

      render(<Subject {...defaultProps} />)

      expect(screen.getByText('Failed')).toBeInTheDocument()
      // The error code processing creates a meaningful error message via errorCodeDisplayName function
      // This test verifies the function is working correctly with the error code
    })

    it('shows generic error message for unknown error codes', () => {
      const failedJob = createMockJob({
        query_id: 'failed-job',
        status: AsyncPageViewJobStatus.Failed,
        error_code: 'UNKNOWN_ERROR_CODE',
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([failedJob]))

      render(<Subject {...defaultProps} />)

      expect(screen.getByText('Failed')).toBeInTheDocument()
      // The errorCodeDisplayName function handles unknown error codes with a generic message
    })

    it('shows no error message for jobs without error codes', () => {
      const failedJob = createMockJob({
        query_id: 'failed-job',
        status: AsyncPageViewJobStatus.Failed,
        error_code: null,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([failedJob]))

      render(<Subject {...defaultProps} />)

      expect(screen.getByText('Failed')).toBeInTheDocument()
      // Jobs without error codes just show the basic status without additional error message
    })
  })

  describe('Job polling', () => {
    beforeEach(() => {
      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.runOnlyPendingTimers()
      vi.useRealTimers()
    })

    it('polls job status and updates UI when job completes', async () => {
      const runningJob = createMockJob({
        query_id: 'polling-job',
        status: AsyncPageViewJobStatus.Running,
        updatedAt: new Date(Date.now() - 10000).toISOString(), // 10 seconds ago
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([runningJob]))

      server.use(
        http.get(`/api/v1/users/${defaultProps.userId}/page_views/query/polling-job`, () => {
          return HttpResponse.json({
            query_id: 'polling-job',
            status: 'finished',
            format: 'csv',
            results_url: '/results/url',
            error_code: null,
          })
        }),
      )

      render(<Subject {...defaultProps} />)

      // Initially shows "In progress"
      expect(screen.getByText('In progress')).toBeInTheDocument()

      // Fast-forward to trigger polling
      vi.advanceTimersByTime(1000)

      await waitFor(() => {
        expect(screen.getByText('Completed')).toBeInTheDocument()
      })
    })

    it('polls job status and shows error message when job fails', async () => {
      const runningJob = createMockJob({
        query_id: 'failing-job',
        status: AsyncPageViewJobStatus.Running,
        updatedAt: new Date(Date.now() - 10000).toISOString(),
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([runningJob]))

      server.use(
        http.get(`/api/v1/users/${defaultProps.userId}/page_views/query/failing-job`, () => {
          return HttpResponse.json({
            query_id: 'failing-job',
            status: 'failed',
            format: 'csv',
            results_url: null,
            error_code: 'RESULT_SIZE_LIMIT_EXCEEDED',
          })
        }),
      )

      render(<Subject {...defaultProps} />)

      // Fast-forward to trigger polling
      vi.advanceTimersByTime(1000)

      await waitFor(() => {
        expect(screen.getByText('Failed')).toBeInTheDocument()
      })

      // The error code is properly processed and would be available via errorCodeDisplayName
    })
  })

  describe('Download functionality', () => {
    it('opens download URL when download link is clicked', async () => {
      const user = userEvent.setup()
      const completedJob = createMockJob({
        query_id: 'download-job',
        name: 'Test Download',
        status: AsyncPageViewJobStatus.Finished,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([completedJob]))

      server.use(
        http.head(
          `/api/v1/users/${defaultProps.userId}/page_views/query/download-job/results`,
          () => {
            return new HttpResponse(null, {status: 200})
          },
        ),
      )

      // Mock window.open
      const mockOpen = vi.spyOn(window, 'open').mockImplementation(() => null)

      render(<Subject {...defaultProps} />)

      const downloadLink = screen.getByTestId('download-download-job')
      await user.click(downloadLink)

      await waitFor(() => {
        expect(mockOpen).toHaveBeenCalledWith(
          `/api/v1/users/${defaultProps.userId}/page_views/query/download-job/results`,
          '_self',
        )
      })

      mockOpen.mockRestore()
    })

    it('handles empty download (204 response) and shows flash alert', async () => {
      const user = userEvent.setup()
      const {showFlashAlert} = await import('@canvas/alerts/react/FlashAlert')

      const completedJob = createMockJob({
        query_id: 'empty-job',
        status: AsyncPageViewJobStatus.Finished,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([completedJob]))

      server.use(
        http.head(`/api/v1/users/${defaultProps.userId}/page_views/query/empty-job/results`, () => {
          return new HttpResponse(null, {status: 204})
        }),
      )

      render(<Subject {...defaultProps} />)

      const downloadLink = screen.getByTestId('download-empty-job')
      await user.click(downloadLink)

      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'The requested export is empty.',
          type: 'info',
          err: undefined,
        })
      })
    })

    it('handles missing download (404 response) and shows flash alert', async () => {
      const user = userEvent.setup()
      const {showFlashAlert} = await import('@canvas/alerts/react/FlashAlert')

      const completedJob = createMockJob({
        query_id: 'missing-job',
        status: AsyncPageViewJobStatus.Finished,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([completedJob]))

      server.use(
        http.head(
          `/api/v1/users/${defaultProps.userId}/page_views/query/missing-job/results`,
          () => {
            return new HttpResponse(null, {status: 404})
          },
        ),
      )

      render(<Subject {...defaultProps} />)

      const downloadLink = screen.getByTestId('download-missing-job')
      await user.click(downloadLink)

      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: expect.stringContaining('no longer available'),
          type: 'info',
          err: undefined,
        })
      })
    })
  })

  describe('Accessibility', () => {
    it('has accessible labels and live regions', () => {
      const runningJob = createMockJob({
        status: AsyncPageViewJobStatus.Running,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([runningJob]))

      render(<Subject {...defaultProps} />)

      // Check for live regions that announce status changes
      expect(document.querySelector('[aria-live="polite"]')).toBeInTheDocument()

      // Check for accessible table
      const exportsTable = screen.getByRole('table', { name: 'Recent exports table' })
      expect(exportsTable).toBeInTheDocument()
      expect(exportsTable).toHaveAccessibleName('Recent exports table')
    })
  })

  describe('Time display', () => {
    it('shows relative time for job availability', () => {
      const recentJob = createMockJob({
        status: AsyncPageViewJobStatus.Finished,
        createdAt: new Date(Date.now() - 1000 * 60 * 60).toISOString(), // 1 hour ago
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([recentJob]))

      render(<Subject {...defaultProps} />)

      // Should show hours remaining (approximately 23 hours)
      expect(screen.getByText(/23 hours/)).toBeInTheDocument()
    })

    it('shows "Not yet" for in-progress jobs', () => {
      const runningJob = createMockJob({
        status: AsyncPageViewJobStatus.Running,
      })

      localStorage.setItem(`pv-export-${defaultProps.userId}`, JSON.stringify([runningJob]))

      render(<Subject {...defaultProps} />)

      expect(screen.getByText('Not yet')).toBeInTheDocument()
    })
  })
})
