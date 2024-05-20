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
import {render} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import TagThrottle from '../TagThrottle'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')

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
    doFetchApi.mockImplementation(({path, params}) => {
      if (path === '/api/v1/jobs2/throttle/check') {
        if (params.shard_id) {
          return Promise.resolve({json: {matched_jobs: 21, matched_tags: 2}})
        } else {
          return Promise.resolve({json: {matched_jobs: 27, matched_tags: 3}})
        }
      } else if (path === '/api/v1/jobs2/throttle') {
        return Promise.resolve({json: {new_strand: 'tmp_strand_XXX', job_count: 27}})
      } else {
        return Promise.resolve({status: 500, json: {message: 'unexpected API call'}})
      }
    })
    jest.useFakeTimers()
  })

  beforeEach(() => {
    doFetchApi.mockClear()
  })

  it("doesn't call /throttle/check until modal opened", async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const onUpdate = jest.fn()
    const {getByText} = render(<TagThrottle tag="foobar" jobs={fakeJobs} onUpdate={onUpdate} />)
    expect(doFetchApi).not.toHaveBeenCalled()
    await user.click(getByText('Throttle tag "foobar"', {selector: 'button span'}))
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/throttle/check',
        params: {term: 'foobar', shard_id: '101'},
      })
    )
    await jest.runOnlyPendingTimers()

    expect(getByText('Matched 21 jobs with 2 tags')).toBeInTheDocument()
    expect(onUpdate).not.toHaveBeenCalled()
  })

  it('performs a throttle job', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const onUpdate = jest.fn()
    const {getByText, getByLabelText} = render(
      <TagThrottle tag="foobar" jobs={fakeJobs} onUpdate={onUpdate} />
    )
    await user.click(getByText('Throttle tag "foobar"', {selector: 'button span'}))
    await jest.runOnlyPendingTimers()

    await user.clear(getByLabelText('Tag starts with'))
    await user.type(getByLabelText('Tag starts with'), 'foo')
    await user.clear(getByLabelText('Shard ID (optional)'))
    await user.clear(getByLabelText('New Concurrency'))
    await user.type(getByLabelText('New Concurrency'), '2')
    await jest.advanceTimersByTime(1000)

    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/throttle/check',
        params: {term: 'foo', shard_id: ''},
      })
    )

    expect(getByText('Matched 27 jobs with 3 tags')).toBeInTheDocument()
    await user.click(getByText('Throttle Jobs', {selector: 'button span'}))
    await jest.runOnlyPendingTimers()

    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/jobs2/throttle',
      method: 'PUT',
      params: {term: 'foo', shard_id: '', max_concurrent: 2},
    })
    expect(onUpdate).toHaveBeenCalledWith({
      job_count: 27,
      new_strand: 'tmp_strand_XXX',
    })
  })
})
