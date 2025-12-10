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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {
  useAsyncPageviewJobs,
  notExpired,
  displayTTL,
  isInProgress,
  statusColor,
  statusDisplayName,
  AsyncPageviewJob,
  AsyncPageViewJobStatus,
} from '../hooks/asyncPageviewExport'
import {FetchApiError} from '@canvas/do-fetch-api-effect'

const server = setupServer()

describe('useAsyncPageviewJobs', () => {
  const key = 'test_jobs'
  const userid = '1'
  const job: AsyncPageviewJob = {
    query_id: 'abc123',
    name: 'Test Job',
    status: AsyncPageViewJobStatus.Queued,
    createdAt: new Date(),
    updatedAt: new Date(),
  }

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    window.localStorage.clear()
  })
  afterAll(() => server.close())

  it('initializes jobs from localStorage', () => {
    window.localStorage.setItem(key, JSON.stringify([job]))
    const {result} = renderHook(() => useAsyncPageviewJobs(key, userid))
    const [jobs] = result.current
    expect(jobs[0].query_id).toBe('abc123')
  })

  it('setJobs updates localStorage', () => {
    const {result} = renderHook(() => useAsyncPageviewJobs(key, userid))
    const [_jobs, setJobs] = result.current
    act(() => {
      setJobs([job])
    })
    expect(JSON.parse(window.localStorage.getItem(key)!)[0].query_id).toBe('abc123')
  })

  it('postJob adds a new job', async () => {
    server.use(
      http.post(`/api/v1/users/${userid}/page_views/query`, () =>
        HttpResponse.json({poll_url: 'baseurl/newid'}),
      ),
    )
    const {result} = renderHook(() => useAsyncPageviewJobs(key, userid))
    const [, , , postJob] = result.current
    await act(async () => {
      await postJob(userid, 'JobName', '2025-09-01', '2025-09-08')
    })
    const [updatedJobs] = result.current
    expect(updatedJobs[0].query_id).toBe('newid')
    expect(updatedJobs[0].name).toBe('JobName')
  })

  describe('getDownloadUrl', () => {
    it('returns correct url when status is 200', async () => {
      server.use(
        http.head(
          `/api/v1/users/${userid}/page_views/query/${job.query_id}/results`,
          () => new HttpResponse(null, {status: 200}),
        ),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(key, userid))
      const [, , , , getDownloadUrl] = result.current
      const url = await getDownloadUrl(job)
      expect(url).toContain(job.query_id)
      expect(url).toContain('/query/abc123/results')
    })

    it('throws error and updates job status on 204', async () => {
      server.use(
        http.head(
          `/api/v1/users/${userid}/page_views/query/${job.query_id}/results`,
          () => new HttpResponse(null, {status: 204}),
        ),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(key, userid))
      const [, setJobs, , , getDownloadUrl] = result.current

      // Set initial job
      act(() => {
        setJobs([job])
      })

      await expect(getDownloadUrl(job)).rejects.toThrow(FetchApiError)
      const error = await getDownloadUrl(job).catch(e => e)
      expect(error.response.status).toBe(204)
    })

    it('throws error and removes job on 404', async () => {
      server.use(
        http.head(
          `/api/v1/users/${userid}/page_views/query/${job.query_id}/results`,
          () => new HttpResponse(null, {status: 404}),
        ),
      )

      const {result} = renderHook(() => useAsyncPageviewJobs(key, userid))
      const [, setJobs, , , getDownloadUrl] = result.current

      // Set initial job
      act(() => {
        setJobs([job])
      })

      await expect(getDownloadUrl(job)).rejects.toThrow(FetchApiError)
      const error = await getDownloadUrl(job).catch(e => e)
      expect(error.response.status).toBe(404)
    })
  })
})

describe('notExpired', () => {
  it('returns true for fresh job', () => {
    const job: AsyncPageviewJob = {
      query_id: 'id',
      name: 'name',
      status: AsyncPageViewJobStatus.Finished,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    expect(notExpired(job)).toBe(true)
  })
  it('returns false for expired job', () => {
    const job: AsyncPageviewJob = {
      query_id: 'id',
      name: 'name',
      status: AsyncPageViewJobStatus.Finished,
      createdAt: new Date(Date.now() - 25 * 60 * 60 * 1000), // 25 hours ago
      updatedAt: new Date(),
    }
    expect(notExpired(job)).toBe(false)
  })
})

describe('displayTTL', () => {
  it('shows Not yet for in progress', () => {
    const job: AsyncPageviewJob = {
      query_id: 'id',
      name: 'name',
      status: AsyncPageViewJobStatus.Queued,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    expect(displayTTL(job)).toMatch(/Not yet/)
  })
  it('shows - for failed', () => {
    const job: AsyncPageviewJob = {
      query_id: 'id',
      name: 'name',
      status: AsyncPageViewJobStatus.Failed,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    expect(displayTTL(job)).toBe('-')
  })

  it('shows - for empty', () => {
    const job: AsyncPageviewJob = {
      query_id: 'id',
      name: 'name',
      status: AsyncPageViewJobStatus.Empty,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    expect(displayTTL(job)).toBe('-')
  })
  it('shows Expired for expired', () => {
    const job: AsyncPageviewJob = {
      query_id: 'id',
      name: 'name',
      status: AsyncPageViewJobStatus.Finished,
      createdAt: new Date(Date.now() - 25 * 60 * 60 * 1000),
      updatedAt: new Date(),
    }
    expect(displayTTL(job)).toBe('Expired')
  })
})

describe('isInProgress', () => {
  it('returns true for waiting/enqueued/running', () => {
    ;[AsyncPageViewJobStatus.Queued, AsyncPageViewJobStatus.Running].forEach(status => {
      const job: AsyncPageviewJob = {
        query_id: 'id',
        name: 'name',
        status: status as any,
        createdAt: new Date(),
        updatedAt: new Date(),
      }
      expect(isInProgress(job)).toBe(true)
    })
  })
  it('returns false for complete/failed/empty', () => {
    ;[
      AsyncPageViewJobStatus.Finished,
      AsyncPageViewJobStatus.Failed,
      AsyncPageViewJobStatus.Empty,
    ].forEach(status => {
      const job: AsyncPageviewJob = {
        query_id: 'id',
        name: 'name',
        status: status as any,
        createdAt: new Date(),
        updatedAt: new Date(),
      }
      expect(isInProgress(job)).toBe(false)
    })
  })
})

describe('statusColor', () => {
  it('returns correct color', () => {
    expect(statusColor({status: AsyncPageViewJobStatus.Finished} as any)).toBe('success')
    expect(statusColor({status: AsyncPageViewJobStatus.Failed} as any)).toBe('warning')
    expect(statusColor({status: AsyncPageViewJobStatus.Empty} as any)).toBe('success')
    expect(statusColor({status: AsyncPageViewJobStatus.Queued} as any)).toBe('info')
    expect(statusColor({status: AsyncPageViewJobStatus.Running} as any)).toBe('info')
  })
})

describe('statusDisplayName', () => {
  it('returns correct display name', () => {
    expect(statusDisplayName({status: AsyncPageViewJobStatus.Queued} as any)).toMatch(/In progress/)
    expect(statusDisplayName({status: AsyncPageViewJobStatus.Running} as any)).toMatch(
      /In progress/,
    )
    expect(statusDisplayName({status: AsyncPageViewJobStatus.Finished} as any)).toMatch(/Completed/)
    expect(statusDisplayName({status: AsyncPageViewJobStatus.Failed} as any)).toMatch(/Failed/)
    expect(statusDisplayName({status: AsyncPageViewJobStatus.Empty} as any)).toMatch(/Empty/)
  })
})
