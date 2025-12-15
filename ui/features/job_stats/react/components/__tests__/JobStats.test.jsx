/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, act, fireEvent, waitFor} from '@testing-library/react'
import JobStats from '../JobStats'
import fakeENV from '@canvas/test-utils/fakeENV'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

vi.useFakeTimers()

const server = setupServer()

function fakeLinkHeader(path) {
  return `<${path}?page=1>; rel="current", <${path}?page=1>; rel="last"`
}

const fakeCluster = [
  {
    id: '101',
    database_server_id: 'jobs1',
    block_stranded_shard_ids: ['2'],
    jobs_held_shard_ids: ['7', '9'],
    domain: 'jobs101.example.com',
    counts: {running: 86, queued: 7, future: 530, blocked: 9},
  },
]

const refreshedCluster = [
  {
    id: '101',
    database_server_id: 'jobs1',
    block_stranded_shard_ids: [],
    jobs_held_shard_ids: [],
    domain: 'jobs101.example.com',
    counts: {running: 1, queued: 10, future: 100, blocked: 0},
  },
]

const fakeUnstuckResult = {
  status: 'pending',
  progress: {
    id: '655',
    context_id: '1',
    context_type: 'User',
    user_id: null,
    tag: 'JobsV2Controller::run_unstucker!',
    completion: null,
    workflow_state: 'queued',
    created_at: '2022-10-14T23:12:45Z',
    updated_at: '2022-10-14T23:12:45Z',
    message: null,
    url: '/api/v1/progress/655',
  },
}

const fakeProgressResult = {
  id: '655',
  context_id: '1',
  context_type: 'User',
  user_id: null,
  tag: 'JobsV2Controller::run_unstucker!',
  completion: 100.0,
  workflow_state: 'completed',
  created_at: '2022-10-14T23:12:45Z',
  updated_at: '2022-10-14T23:12:46Z',
  message: null,
  url: '/api/v1/progress/655',
}

const fakeStuckResult = [
  {name: 'foo', count: 1},
  {name: 'baz', count: 2},
]

describe('JobStats', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup({
      manage_jobs: false,
    })
    server.resetHandlers()
  })

  afterEach(() => {
    fakeENV.teardown()
    vi.clearAllTimers()
  })

  it.skip('loads cluster info', async () => {
    server.use(
      http.get('/api/v1/jobs2/clusters', () =>
        HttpResponse.json(fakeCluster, {
          headers: {Link: fakeLinkHeader('/api/v1/jobs2/clusters')},
        }),
      ),
    )

    const {queryByText, getByText} = render(<JobStats />)
    await act(async () => vi.runOnlyPendingTimers())

    const jobs1_link = getByText('jobs1', {selector: 'a'})
    expect(jobs1_link.getAttribute('href')).toEqual('//jobs101.example.com/jobs_v2')

    expect(getByText('jobs held')).toBeInTheDocument()
    expect(getByText('block stranded')).toBeInTheDocument()

    expect(getByText('86', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('7', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('530', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('9', {selector: 'td button'})).toBeInTheDocument()

    // since ENV.manage_jobs is explicitly set to false
    await waitFor(() => {
      expect(queryByText('Unblock', {selector: 'button span'})).not.toBeInTheDocument()
    })
  })

  it.skip('refreshes cluster', async () => {
    let capturedParams = null
    server.use(
      http.get('/api/v1/jobs2/clusters', ({request}) => {
        const url = new URL(request.url)
        capturedParams = url.searchParams.get('job_shards[]')
        if (capturedParams) {
          return HttpResponse.json(refreshedCluster, {
            headers: {Link: fakeLinkHeader('/api/v1/jobs2/clusters')},
          })
        }
        return HttpResponse.json(fakeCluster, {
          headers: {Link: fakeLinkHeader('/api/v1/jobs2/clusters')},
        })
      }),
    )

    const {queryByText, getByText} = render(<JobStats />)
    await act(async () => vi.runOnlyPendingTimers())

    fireEvent.click(getByText('Refresh', {selector: 'button span'}))
    await act(async () => vi.runOnlyPendingTimers())

    expect(capturedParams).toBe('101')

    expect(queryByText('jobs held')).not.toBeInTheDocument()
    expect(queryByText('block stranded')).not.toBeInTheDocument()
    expect(queryByText('86', {selector: 'td'})).not.toBeInTheDocument()
    expect(queryByText('7', {selector: 'td'})).not.toBeInTheDocument()
    expect(queryByText('530', {selector: 'td'})).not.toBeInTheDocument()
    expect(queryByText('9', {selector: 'td button'})).not.toBeInTheDocument()

    expect(getByText('1', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('10', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('100', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('0', {selector: 'td'})).toBeInTheDocument()
  })

  it.skip('unstucks a cluster', async () => {
    // Set manage_jobs to true for this test
    fakeENV.setup({
      manage_jobs: true,
    })

    let unstuckParams = null
    let unstuckMethod = null
    let progressCalled = false
    let refreshCount = 0

    server.use(
      http.get('/api/v1/jobs2/clusters', () => {
        refreshCount++
        const data = refreshCount > 1 ? refreshedCluster : fakeCluster
        return HttpResponse.json(data, {
          headers: {Link: fakeLinkHeader('/api/v1/jobs2/clusters')},
        })
      }),
      http.put('/api/v1/jobs2/unstuck', ({request}) => {
        const url = new URL(request.url)
        unstuckParams = url.searchParams.get('job_shards[]')
        unstuckMethod = request.method
        return HttpResponse.json(fakeUnstuckResult)
      }),
      http.get('/api/v1/progress/655', () => {
        progressCalled = true
        return HttpResponse.json(fakeProgressResult)
      }),
    )

    const {getByText, queryByText} = render(<JobStats />)
    await act(async () => vi.runOnlyPendingTimers())

    fireEvent.click(getByText('Unblock', {selector: 'button span'}))
    await act(async () => vi.runOnlyPendingTimers())

    expect(
      getByText('Are you sure you want to unblock all stuck jobs in this job cluster?'),
    ).toBeInTheDocument()
    expect(
      getByText('NOTE: Jobs blocked by shard migrations will not be unblocked.'),
    ).toBeInTheDocument()

    fireEvent.click(getByText('Confirm'))
    await act(async () => vi.runOnlyPendingTimers())

    expect(getByText('Unblocking...')).toBeInTheDocument()
    expect(unstuckMethod).toBe('PUT')
    expect(unstuckParams).toBe('101')

    // Advance timers to trigger the polling interval
    await act(async () => {
      vi.advanceTimersByTime(2000)
    })

    // Wait for the async updates to complete
    await waitFor(() => {
      expect(progressCalled).toBe(true)
    })

    await waitFor(() => {
      expect(queryByText('9', {selector: 'td button'})).not.toBeInTheDocument()
      expect(getByText('0', {selector: 'td'})).toBeInTheDocument()
    })
  })

  it.skip('shows stuck strands/singletons', async () => {
    let strandsCalled = false
    let singletonsCalled = false

    server.use(
      http.get('/api/v1/jobs2/clusters', () =>
        HttpResponse.json(fakeCluster, {
          headers: {Link: fakeLinkHeader('/api/v1/jobs2/clusters')},
        }),
      ),
      http.get('/api/v1/jobs2/stuck/strands', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('job_shard') === '101') {
          strandsCalled = true
        }
        return HttpResponse.json(fakeStuckResult)
      }),
      http.get('/api/v1/jobs2/stuck/singletons', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('job_shard') === '101') {
          singletonsCalled = true
        }
        return HttpResponse.json(fakeStuckResult)
      }),
    )

    const {getByText, getAllByText} = render(<JobStats />)
    await act(async () => vi.runOnlyPendingTimers())

    fireEvent.click(getByText('9', {selector: 'td button'}))
    await act(async () => vi.runOnlyPendingTimers())

    expect(strandsCalled).toBe(true)
    expect(singletonsCalled).toBe(true)

    const ss_links = getAllByText('baz', {selector: 'td a'})
    expect(ss_links).toHaveLength(2)
    expect(ss_links.map(link => link.getAttribute('href'))).toEqual([
      '//jobs101.example.com/jobs_v2?group_type=strand&group_text=baz&bucket=queued',
      '//jobs101.example.com/jobs_v2?group_type=singleton&group_text=baz&bucket=queued',
    ])
  })
})
