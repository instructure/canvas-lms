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
import {render, act, fireEvent, cleanup} from '@testing-library/react'
import JobsIndex from '../index'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

injectGlobalAlertContainers()

// Track API calls for verification
const apiCalls = []

function createLinkHeader(path) {
  // Create HTTP Link header format that doFetchApi can parse
  const baseUrl = 'http://localhost'
  return `<${baseUrl}${path}?page=1>; rel="current", <${baseUrl}${path}?page=2>; rel="next", <${baseUrl}${path}?page=5>; rel="last"`
}

function fake_info(bucket) {
  if (bucket === 'running' || bucket === 'queued') {
    return 100.0 // number of seconds
  } else {
    return '2022-04-02T13:00:00Z' // timestamp
  }
}

const fake_job = {
  id: '3606',
  priority: 20,
  attempts: 1,
  handler: 'fake_job_list_handler_value',
  last_error: 'fake_job_list_last_error_value',
  run_at: '2022-04-02T13:01:00Z',
  locked_at: '2022-04-02T13:02:00Z',
  failed_at: '2022-04-02T13:03:00Z',
  locked_by: 'job010001039065:12438',
  tag: 'fake_job_list_tag_value',
  max_attempts: 1,
  strand: 'fake_job_list_strand_value',
  shard_id: '1',
  original_job_id: '2838533',
  singleton: 'fake_job_list_singleton_value',
}

function captureRequest(request) {
  const url = new URL(request.url)
  const params = Object.fromEntries(url.searchParams.entries())
  apiCalls.push({
    path: url.pathname,
    params,
  })
}

const server = setupServer(
  // Search endpoint - most specific first
  http.get('/api/v1/jobs2/:bucket/:group/search', ({request}) => {
    captureRequest(request)
    const json = {
      fake_group_search_value_1: 106,
      fake_group_search_value_2: 92,
    }
    return HttpResponse.json(json)
  }),

  // Grouped info endpoint
  http.get('/api/v1/jobs2/:bucket/:group', ({params, request}) => {
    captureRequest(request)
    const {bucket, group} = params
    const json = [
      {
        count: 1,
        [group.replace('by_', '')]: 'fake_job_list_group_value',
        info: fake_info(bucket),
      },
    ]
    return HttpResponse.json(json, {
      headers: {
        Link: createLinkHeader(`/api/v1/jobs2/${bucket}/${group}`),
      },
    })
  }),

  // Lookup endpoint (numeric id)
  http.get('/api/v1/jobs2/:id', ({params, request}) => {
    captureRequest(request)
    const {id} = params
    // Check if id is numeric (lookup) vs bucket name (list)
    if (/^\d+$/.test(id)) {
      const json = [
        {
          ...fake_job,
          bucket: id,
        },
      ]
      return HttpResponse.json(json)
    } else {
      // This is a list endpoint (bucket name)
      const bucket = id
      const json = [
        {
          ...fake_job,
          info: fake_info(bucket),
        },
      ]
      return HttpResponse.json(json, {
        headers: {
          Link: createLinkHeader(`/api/v1/jobs2/${bucket}`),
        },
      })
    }
  }),
)

function changeAndBlurInput(input, newValue) {
  fireEvent.change(input, {target: {value: newValue}})
  fireEvent.blur(input)
}

describe.skip('JobsIndex (flaky - hangs with timer/API interaction)', () => {
  let oldEnv

  // Helper to check if an API call was made
  const expectApiCall = matcher => {
    const matchingCall = apiCalls.find(call => {
      const pathMatches = matcher.path ? call.path === matcher.path : true
      const paramsMatch = matcher.params
        ? Object.entries(matcher.params).every(([key, value]) => call.params[key] === value)
        : true
      return pathMatches && paramsMatch
    })
    expect(matchingCall).toBeDefined()
    return matchingCall
  }

  // Helper to check the last API call
  const expectLastApiCall = matcher => {
    expect(apiCalls.length).toBeGreaterThan(0)
    const lastCall = apiCalls[apiCalls.length - 1]
    if (matcher.path) {
      expect(lastCall.path).toBe(matcher.path)
    }
    if (matcher.params) {
      Object.entries(matcher.params).forEach(([key, value]) => {
        expect(lastCall.params[key]).toBe(value)
      })
    }
  }

  beforeAll(() => {
    oldEnv = {...window.ENV}
    window.ENV = {
      TIMEZONE: 'America/Denver',
      CONTEXT_TIMEZONE: 'America/New_York',
      jobs_scope_filter: {
        jobs_server: 'jobs1',
        cluster: 'cluster74',
        shard: 'cluster74_shard_1096',
        account: 'Test Academy',
      },
    }

    server.listen()
  })

  beforeEach(() => {
    apiCalls.length = 0
    window.history.replaceState('', '', '?')
    vi.useFakeTimers()
  })

  afterAll(() => {
    window.ENV = oldEnv
    server.close()
  })

  afterEach(() => {
    cleanup()
    vi.useRealTimers()
    server.resetHandlers()
  })

  it('renders groups and jobs', async () => {
    const {getByText, getAllByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(getByText('fake_job_list_group_value')).toBeInTheDocument()
    expect(getAllByText('00:01:40')).toHaveLength(2)
    expect(getAllByText('Page 5')).toHaveLength(2)
    expect(getByText('3606')).toBeInTheDocument()
    expect(getAllByText('fake_job_list_tag_value')).toHaveLength(2)
    expect(getAllByText('fake_job_list_strand_value')).toHaveLength(2)
    expect(getAllByText('fake_job_list_singleton_value')).toHaveLength(2)
  })

  it('switches scope', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByLabelText('Scope'))
    fireEvent.click(getByText('Test Academy'))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/jobs_scope=account/)
    expectLastApiCall({params: {scope: 'account'}})
  })

  it('switches buckets', async () => {
    const {getByLabelText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByLabelText('Failed'))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/bucket=failed/)
    expectApiCall({path: '/api/v1/jobs2/failed/by_tag'})
  })

  it('switches groups', async () => {
    const {getByLabelText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByLabelText('Singleton'))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/group_type=singleton/)
    expectApiCall({path: '/api/v1/jobs2/running/by_singleton'})
  })

  it('paginates the group list', async () => {
    const {getAllByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getAllByText('Page 5')[0])
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/groups_page=5/)
    expectApiCall({
      path: '/api/v1/jobs2/running/by_tag',
      params: {page: '5'},
    })
  })

  it('paginates the job list', async () => {
    const {getAllByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getAllByText('Page 2')[1])
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/jobs_page=2/)
    expectApiCall({
      path: '/api/v1/jobs2/running',
      params: {page: '2'},
    })
  })

  it('filters the job list via the groups table', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('fake_job_list_group_value'))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/group_text=fake_job_list_group_value/)
    expectApiCall({
      path: '/api/v1/jobs2/running',
      params: {tag: 'fake_job_list_group_value'},
    })
  })

  it('filters by clicking a tag in the jobs list', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('fake_job_list_tag_value', {selector: 'button span'}))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/group_text=fake_job_list_tag_value/)
    expectApiCall({
      path: '/api/v1/jobs2/running',
      params: {tag: 'fake_job_list_tag_value'},
    })
  })

  it('filters by clicking a strand in the jobs list', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('fake_job_list_strand_value', {selector: 'button span'}))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/group_type=strand/)
    expect(window.location.search).toMatch(/group_text=fake_job_list_strand_value/)
    expectApiCall({
      path: '/api/v1/jobs2/running',
      params: {strand: 'fake_job_list_strand_value'},
    })
  })

  it('filters by clicking a singleton in the jobs list', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('fake_job_list_singleton_value', {selector: 'button span'}))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expect(window.location.search).toMatch(/group_type=singleton/)
    expect(window.location.search).toMatch(/group_text=fake_job_list_singleton_value/)
    expectApiCall({
      path: '/api/v1/jobs2/running',
      params: {singleton: 'fake_job_list_singleton_value'},
    })
  })

  it('shows job details', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('3606'))
    expect(getByText('job010001039065:12438')).toBeInTheDocument()
    expect(getByText('10.1.39.65')).toBeInTheDocument()
    expect(getByText('4/2/22, 7:02 AM')).toBeInTheDocument()
  })

  it('searches for a tag', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.change(getByLabelText('Filter running jobs by tag'), {
      target: {value: 'fake_group_search'},
    })
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('fake_group_search_value_1 (106)'))
    await act(async () => vi.runOnlyPendingTimersAsync())
    expectApiCall({
      path: '/api/v1/jobs2/running',
      params: {tag: 'fake_group_search_value_1'},
    })
  })

  it('looks up a job by id', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    fireEvent.change(getByLabelText('Job lookup'), {
      target: {value: '3606'},
    })
    await act(async () => vi.runOnlyPendingTimersAsync())
    fireEvent.click(getByText('3606', {selector: 'button'}))
    expect(getByText('job010001039065:12438')).toBeInTheDocument()
    expect(getByText('10.1.39.65')).toBeInTheDocument()
    expect(getByText('4/2/22, 7:02 AM')).toBeInTheDocument()
  })

  it.skip('performs time-zone aware date filtering (flaky)', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    fireEvent.click(getByText('Date/Time options', {selector: 'button span'}))
    changeAndBlurInput(getByLabelText('After'), '2022-04-02 09:00')
    changeAndBlurInput(getByLabelText('Before'), '2022-04-02 23:00')
    fireEvent.click(getByLabelText('View timestamps in time zone'))
    fireEvent.click(getByText('Account (America/New_York)'))
    fireEvent.click(getByText('Accept'))
    expect(window.location.search).toMatch(/time_zone=America%2FNew_York/)

    await act(async () => vi.runOnlyPendingTimersAsync())

    // these times are 9AM and 11PM EDT, converted to UTC (a four-hour difference)
    expectApiCall({
      params: {
        start_date: '2022-04-02T13:00:00.000Z',
        end_date: '2022-04-03T03:00:00.000Z',
      },
    })

    // note we saw 7:02 AM in an earlier test, but we've changed the time zone to Eastern now
    fireEvent.click(getByText('3606'))
    expect(getByText('4/2/22, 9:02 AM')).toBeInTheDocument()
  })

  it('initializes state from URL parameters', async () => {
    window.history.replaceState(
      '',
      '',
      '?bucket=failed&group_type=strand&group_order=count&jobs_order=tag&groups_page=2&jobs_page=3&scope=account&start_date=2022-04-01T01%3A00%3A00.000Z&end_date=2022-04-02T01%3A00%3A00.000Z&time_zone=UTC',
    )
    render(<JobsIndex />)
    await act(async () => vi.runOnlyPendingTimersAsync())
    expectApiCall({
      path: '/api/v1/jobs2/failed/by_strand',
      params: {
        order: 'count',
        page: '2',
        scope: 'account',
        start_date: '2022-04-01T01:00:00.000Z',
        end_date: '2022-04-02T01:00:00.000Z',
      },
    })
    expectApiCall({
      path: '/api/v1/jobs2/failed',
      params: {
        order: 'tag',
        page: '3',
        scope: 'account',
        start_date: '2022-04-01T01:00:00.000Z',
        end_date: '2022-04-02T01:00:00.000Z',
      },
    })
  })
})
