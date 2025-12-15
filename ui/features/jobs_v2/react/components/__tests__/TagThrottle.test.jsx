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
import {render, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import TagThrottle from '../TagThrottle'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

// Mock the debounce hook to avoid timer issues
vi.mock('@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm', () => ({
  default: (initialValue) => ({
    searchTerm: initialValue,
    setSearchTerm: vi.fn(),
  }),
}))

const server = setupServer()

const fakeJobs = [
  {
    id: '1024',
    tag: 'foobar',
    shard_id: '101',
  },
  {
    id: '2048',
    tag: 'foobar',
    shard_id: '102',
  },
]

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

describe('TagThrottle', () => {
  beforeAll(() => {
    server.listen()
    server.use(
      http.get('/api/v1/jobs2/throttle/check', ({request}) => {
        const url = new URL(request.url)
        const shardId = url.searchParams.get('shard_id')
        if (shardId) {
          return HttpResponse.json({matched_jobs: 21, matched_tags: 2})
        } else {
          return HttpResponse.json({matched_jobs: 27, matched_tags: 3})
        }
      }),
      http.put('/api/v1/jobs2/throttle', () =>
        HttpResponse.json({new_strand: 'tmp_strand_XXX', job_count: 27}),
      ),
    )
  })

  afterAll(() => server.close())

  beforeEach(() => {
    server.resetHandlers()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it("doesn't call /throttle/check until modal opened", async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const onUpdate = vi.fn()
    let requestMade = false
    let requestParams = null
    server.use(
      http.get('/api/v1/jobs2/throttle/check', ({request}) => {
        requestMade = true
        const url = new URL(request.url)
        requestParams = {
          term: url.searchParams.get('term'),
          shard_id: url.searchParams.get('shard_id'),
        }
        const shardId = url.searchParams.get('shard_id')
        if (shardId) {
          return HttpResponse.json({matched_jobs: 21, matched_tags: 2})
        } else {
          return HttpResponse.json({matched_jobs: 27, matched_tags: 3})
        }
      }),
    )

    const {getByText} = render(<TagThrottle tag="foobar" jobs={fakeJobs} onUpdate={onUpdate} />)
    expect(requestMade).toBe(false)
    await user.click(getByText('Throttle tag "foobar"', {selector: 'button span'}))
    await waitFor(() => expect(requestMade).toBe(true))
    expect(requestParams).toEqual({term: 'foobar', shard_id: '101'})
    expect(getByText('Matched 21 jobs with 2 tags')).toBeInTheDocument()
    expect(onUpdate).not.toHaveBeenCalled()
  })

  it('performs a throttle job', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const onUpdate = vi.fn()
    let lastCheckRequestParams = null
    let throttleRequestParams = null
    server.use(
      http.get('/api/v1/jobs2/throttle/check', ({request}) => {
        const url = new URL(request.url)
        lastCheckRequestParams = {
          term: url.searchParams.get('term'),
          shard_id: url.searchParams.get('shard_id'),
        }
        const shardId = url.searchParams.get('shard_id')
        if (shardId) {
          return HttpResponse.json({matched_jobs: 21, matched_tags: 2})
        } else {
          return HttpResponse.json({matched_jobs: 27, matched_tags: 3})
        }
      }),
      http.put('/api/v1/jobs2/throttle', ({request}) => {
        const url = new URL(request.url)
        throttleRequestParams = {
          term: url.searchParams.get('term'),
          shard_id: url.searchParams.get('shard_id'),
          max_concurrent: url.searchParams.get('max_concurrent'),
        }
        return HttpResponse.json({new_strand: 'tmp_strand_XXX', job_count: 27})
      }),
    )

    const {getByText, getByLabelText} = render(
      <TagThrottle tag="foobar" jobs={fakeJobs} onUpdate={onUpdate} />,
    )
    await user.click(getByText('Throttle tag "foobar"', {selector: 'button span'}))

    await user.clear(getByLabelText('Tag starts with'))
    await user.type(getByLabelText('Tag starts with'), 'foo')
    await user.clear(getByLabelText('Shard ID (optional)'))
    await user.clear(getByLabelText('New Concurrency'))
    await user.type(getByLabelText('New Concurrency'), '2')

    await waitFor(() => expect(lastCheckRequestParams).toEqual({term: 'foo', shard_id: ''}))
    await waitFor(() => {
      expect(getByText('Matched 27 jobs with 3 tags')).toBeInTheDocument()
    })
    await user.click(getByText('Throttle Jobs', {selector: 'button span'}))

    await waitFor(() => expect(throttleRequestParams).toEqual({term: 'foo', shard_id: '', max_concurrent: '2'}))
    expect(onUpdate).toHaveBeenCalledWith({
      job_count: 27,
      new_strand: 'tmp_strand_XXX',
    })
  })
})
