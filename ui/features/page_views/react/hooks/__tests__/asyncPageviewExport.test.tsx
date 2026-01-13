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

import {renderHook, act} from '@testing-library/react-hooks'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {
  useAsyncPageviewJobs,
  AsyncPageViewJobStatus,
  type AsyncPageviewJob,
  notExpired,
  displayTTL,
  isInProgress,
  statusColor,
  statusDisplayName,
  errorCodeDisplayName,
} from '../asyncPageviewExport'

// MSW server setup
const server = setupServer()

// Helper to create mock jobs
function createMockJob(overrides: Partial<AsyncPageviewJob> = {}): AsyncPageviewJob {
  return {
    query_id: 'test-uuid-123',
    name: 'Test Export',
    status: AsyncPageViewJobStatus.Queued,
    createdAt: new Date(),
    updatedAt: new Date(),
    error_code: null,
    ...overrides,
  }
}

beforeAll(() => {
  server.listen()
})

beforeEach(() => {
  vi.clearAllMocks()
  // Clear localStorage
  window.localStorage.clear()
  // Mock console methods to avoid noise in tests
  vi.spyOn(console, 'warn').mockImplementation(() => {})
  server.resetHandlers()
})

afterEach(() => {
  vi.restoreAllMocks()
})

afterAll(() => {
  server.close()
})

describe('useAsyncPageviewJobs', () => {
  const defaultUserId = '123'
  const defaultKey = 'test-key'

  describe('initialization', () => {
    it('should initialize with empty jobs when localStorage is empty', () => {
      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [jobs] = result.current

      expect(jobs).toEqual([])
    })

    it('should load jobs from localStorage and filter expired ones', () => {
      const now = new Date()
      const validJob = createMockJob({
        query_id: 'valid-job',
        createdAt: new Date(now.getTime() - 1000 * 60 * 60), // 1 hour ago
      })
      const expiredJob = createMockJob({
        query_id: 'expired-job',
        createdAt: new Date(now.getTime() - 1000 * 60 * 60 * 25), // 25 hours ago
      })

      localStorage.setItem(defaultKey, JSON.stringify([validJob, expiredJob]))

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [jobs] = result.current

      expect(jobs).toHaveLength(1)
      expect(jobs[0].query_id).toBe('valid-job')
    })
  })

  describe('postJob', () => {
    it('should create new job and add to list', async () => {
      server.use(
        http.post('/api/v1/users/123/page_views/query', async ({request}) => {
          const body = await request.json()
          expect(body).toEqual({
            user: '123',
            start_date: '2023-01-01',
            end_date: '2023-02-01',
            results_format: 'csv',
          })

          return HttpResponse.json(
            {poll_url: '/api/v1/users/123/page_views/query/new-uuid-456'},
            {status: 201},
          )
        }),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , , postJob] = result.current

      await act(async () => {
        await postJob('123', 'New Export', '2023-01-01', '2023-02-01')
      })

      const [jobs] = result.current
      expect(jobs).toHaveLength(1)
      expect(jobs[0]).toMatchObject({
        query_id: 'new-uuid-456',
        name: 'New Export',
        status: AsyncPageViewJobStatus.Queued,
        error_code: null,
      })
    })

    it('should not duplicate existing jobs', async () => {
      const existingJob = createMockJob({query_id: 'existing-uuid'})
      localStorage.setItem(defaultKey, JSON.stringify([existingJob]))

      server.use(
        http.post('/api/v1/users/123/page_views/query', () => {
          return HttpResponse.json(
            {poll_url: '/api/v1/users/123/page_views/query/existing-uuid'},
            {status: 201},
          )
        }),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , , postJob] = result.current

      await act(async () => {
        await postJob('123', 'Duplicate Export', '2023-01-01', '2023-02-01')
      })

      const [jobs] = result.current
      expect(jobs).toHaveLength(1) // Should still have only one job
    })
  })

  describe('pollJobs', () => {
    it('should return false when no jobs are in progress', async () => {
      const completedJob = createMockJob({status: AsyncPageViewJobStatus.Finished})
      localStorage.setItem(defaultKey, JSON.stringify([completedJob]))

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , pollJobs] = result.current

      const shouldContinue = await pollJobs()
      expect(shouldContinue).toBe(false)
      // No API call should be made since no jobs are in progress
    })

    it('should update job status and error_code when polling', async () => {
      const runningJob = createMockJob({
        query_id: 'running-job',
        status: AsyncPageViewJobStatus.Running,
        updatedAt: new Date(Date.now() - 10000), // 10 seconds ago to avoid freshness check
      })
      localStorage.setItem(defaultKey, JSON.stringify([runningJob]))

      server.use(
        http.get('/api/v1/users/123/page_views/query/running-job', () => {
          return HttpResponse.json({
            status: 'failed',
            error_code: 'RESULT_SIZE_LIMIT_EXCEEDED',
          })
        }),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , pollJobs] = result.current

      await act(async () => {
        const shouldContinue = await pollJobs()
        expect(shouldContinue).toBe(false)
      })

      const [jobs] = result.current
      expect(jobs[0]).toMatchObject({
        query_id: 'running-job',
        status: 'failed',
        error_code: 'RESULT_SIZE_LIMIT_EXCEEDED',
      })
    })

    it('should remove job when polling returns 404', async () => {
      const runningJob = createMockJob({
        query_id: 'test-uuid-123',
        status: AsyncPageViewJobStatus.Running,
        updatedAt: new Date(Date.now() - 10000),
      })
      localStorage.setItem(defaultKey, JSON.stringify([runningJob]))

      server.use(
        http.get('/api/v1/users/123/page_views/query/test-uuid-123', () => {
          return new HttpResponse(null, {status: 404})
        }),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , pollJobs] = result.current

      await act(async () => {
        const shouldContinue = await pollJobs()
        expect(shouldContinue).toBe(false)
      })

      const [jobs] = result.current
      expect(jobs).toHaveLength(0) // Job should be removed
    })

    it('should continue polling on other errors', async () => {
      const runningJob = createMockJob({
        query_id: 'test-uuid-123',
        status: AsyncPageViewJobStatus.Running,
        updatedAt: new Date(Date.now() - 10000),
      })
      localStorage.setItem(defaultKey, JSON.stringify([runningJob]))

      server.use(
        http.get('/api/v1/users/123/page_views/query/test-uuid-123', () => {
          return new HttpResponse(null, {status: 500})
        }),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , pollJobs] = result.current

      const shouldContinue = await pollJobs()
      expect(shouldContinue).toBe(true) // Should continue polling on server errors
    })

    it('should skip polling if job was updated recently', async () => {
      const recentJob = createMockJob({
        status: AsyncPageViewJobStatus.Running,
        updatedAt: new Date(), // Just updated
      })
      localStorage.setItem(defaultKey, JSON.stringify([recentJob]))

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , pollJobs] = result.current

      const shouldContinue = await pollJobs()
      expect(shouldContinue).toBe(true)
      // Should skip API call due to freshness check
    })
  })

  describe('getDownloadUrl', () => {
    it('should return path for successful HEAD request', async () => {
      server.use(
        http.head('/api/v1/users/123/page_views/query/download-job/results', () => {
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , , , getDownloadUrl] = result.current

      const job = createMockJob({query_id: 'download-job'})
      const url = await getDownloadUrl(job)

      expect(url).toBe('/api/v1/users/123/page_views/query/download-job/results')
    })

    it('should mark job as empty and throw error for 204 response', async () => {
      server.use(
        http.head('/api/v1/users/123/page_views/query/empty-job/results', () => {
          return new HttpResponse(null, {status: 204})
        }),
      )

      const job = createMockJob({query_id: 'empty-job'})
      localStorage.setItem(defaultKey, JSON.stringify([job]))

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , , , getDownloadUrl] = result.current

      await expect(getDownloadUrl(job)).rejects.toThrow('No content available for download')

      const [jobs] = result.current
      expect(jobs[0].status).toBe(AsyncPageViewJobStatus.Empty)
    })

    it('should remove job and throw error for 404 response', async () => {
      server.use(
        http.head('/api/v1/users/123/page_views/query/missing-job/results', () => {
          return new HttpResponse(null, {status: 404})
        }),
      )

      const job = createMockJob({query_id: 'missing-job'})
      localStorage.setItem(defaultKey, JSON.stringify([job]))

      const {result} = renderHook(() => useAsyncPageviewJobs(defaultKey, defaultUserId))
      const [, , , , getDownloadUrl] = result.current

      await expect(getDownloadUrl(job)).rejects.toThrow('doFetchApi received a bad response: 404')

      const [jobs] = result.current
      expect(jobs).toHaveLength(0) // Job should be removed
    })
  })
})

describe('Utility functions', () => {
  describe('notExpired', () => {
    it('should return true for recent jobs', () => {
      const recentJob = createMockJob({
        createdAt: new Date(Date.now() - 1000 * 60 * 60), // 1 hour ago
      })
      expect(notExpired(recentJob)).toBe(true)
    })

    it('should return false for old jobs', () => {
      const oldJob = createMockJob({
        createdAt: new Date(Date.now() - 1000 * 60 * 60 * 25), // 25 hours ago
      })
      expect(notExpired(oldJob)).toBe(false)
    })
  })

  describe('isInProgress', () => {
    it('should return true for queued and running jobs', () => {
      expect(isInProgress(createMockJob({status: AsyncPageViewJobStatus.Queued}))).toBe(true)
      expect(isInProgress(createMockJob({status: AsyncPageViewJobStatus.Running}))).toBe(true)
    })

    it('should return false for completed states', () => {
      expect(isInProgress(createMockJob({status: AsyncPageViewJobStatus.Finished}))).toBe(false)
      expect(isInProgress(createMockJob({status: AsyncPageViewJobStatus.Failed}))).toBe(false)
      expect(isInProgress(createMockJob({status: AsyncPageViewJobStatus.Empty}))).toBe(false)
    })
  })

  describe('statusColor', () => {
    it('should return correct colors for each status', () => {
      expect(statusColor(createMockJob({status: AsyncPageViewJobStatus.Finished}))).toBe('success')
      expect(statusColor(createMockJob({status: AsyncPageViewJobStatus.Failed}))).toBe('warning')
      expect(statusColor(createMockJob({status: AsyncPageViewJobStatus.Empty}))).toBe('success')
      expect(statusColor(createMockJob({status: AsyncPageViewJobStatus.Queued}))).toBe('info')
      expect(statusColor(createMockJob({status: AsyncPageViewJobStatus.Running}))).toBe('info')
    })
  })

  describe('statusDisplayName', () => {
    it('should return correct display names for each status', () => {
      expect(statusDisplayName(createMockJob({status: AsyncPageViewJobStatus.Queued}))).toBe(
        'In progress',
      )
      expect(statusDisplayName(createMockJob({status: AsyncPageViewJobStatus.Running}))).toBe(
        'In progress',
      )
      expect(statusDisplayName(createMockJob({status: AsyncPageViewJobStatus.Finished}))).toBe(
        'Completed',
      )
      expect(statusDisplayName(createMockJob({status: AsyncPageViewJobStatus.Failed}))).toBe(
        'Failed',
      )
      expect(statusDisplayName(createMockJob({status: AsyncPageViewJobStatus.Empty}))).toBe('Empty')
    })
  })

  describe('errorCodeDisplayName', () => {
    it('should return generic message when no error code', () => {
      expect(
        errorCodeDisplayName(
          createMockJob({error_code: null, status: AsyncPageViewJobStatus.Finished}),
        ),
      ).toBe('Query failed. Please try again later.')
      expect(
        errorCodeDisplayName(
          createMockJob({error_code: undefined as any, status: AsyncPageViewJobStatus.Running}),
        ),
      ).toBe('Query failed. Please try again later.')
      expect(
        errorCodeDisplayName(
          createMockJob({error_code: null, status: AsyncPageViewJobStatus.Failed}),
        ),
      ).toBe('Query failed. Please try again later.')
      expect(
        errorCodeDisplayName(
          createMockJob({error_code: undefined as any, status: AsyncPageViewJobStatus.Failed}),
        ),
      ).toBe('Query failed. Please try again later.')
    })

    it('should return specific message for RESULT_SIZE_LIMIT_EXCEEDED', () => {
      const job = createMockJob({error_code: 'RESULT_SIZE_LIMIT_EXCEEDED'})
      expect(errorCodeDisplayName(job)).toContain('export result size limit was exceeded')
    })

    it('should return specific message for USER_FILTERED', () => {
      const job = createMockJob({error_code: 'USER_FILTERED'})
      expect(errorCodeDisplayName(job)).toContain('not available for export')
    })

    it('should return generic message for unknown error codes', () => {
      const job = createMockJob({error_code: 'UNKNOWN_ERROR_CODE'})
      expect(errorCodeDisplayName(job)).toBe('Query failed. Please try again later.')
    })
  })

  describe('displayTTL', () => {
    it('should return "Not yet" for in-progress jobs', () => {
      expect(displayTTL(createMockJob({status: AsyncPageViewJobStatus.Queued}))).toBe('Not yet')
      expect(displayTTL(createMockJob({status: AsyncPageViewJobStatus.Running}))).toBe('Not yet')
    })

    it('should return "-" for failed and empty jobs', () => {
      expect(displayTTL(createMockJob({status: AsyncPageViewJobStatus.Failed}))).toBe('-')
      expect(displayTTL(createMockJob({status: AsyncPageViewJobStatus.Empty}))).toBe('-')
    })

    it('should return time remaining for finished jobs', () => {
      const recentJob = createMockJob({
        status: AsyncPageViewJobStatus.Finished,
        createdAt: new Date(Date.now() - 1000 * 60 * 60), // 1 hour ago
      })
      const result = displayTTL(recentJob)
      expect(result).toContain('23') // Should show ~23 hours remaining
    })

    it('should return "Expired" for old finished jobs', () => {
      const expiredJob = createMockJob({
        status: AsyncPageViewJobStatus.Finished,
        createdAt: new Date(Date.now() - 1000 * 60 * 60 * 25), // 25 hours ago
      })
      expect(displayTTL(expiredJob)).toBe('Expired')
    })
  })
})
