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
import {render, act, fireEvent} from '@testing-library/react'
import JobStats from '../JobStats'
import doFetchApi from '@canvas/do-fetch-api-effect'
import mockJobsApi from './MockJobsAPI'

jest.mock('@canvas/do-fetch-api-effect')
jest.useFakeTimers()

describe('JobStats', () => {
  let oldEnv
  beforeAll(() => {
    oldEnv = {...window.ENV}
    doFetchApi.mockImplementation(mockJobsApi)
  })

  beforeEach(() => {
    doFetchApi.mockClear()
  })

  afterAll(() => {
    window.ENV = oldEnv
  })

  it('loads cluster info', async () => {
    const {queryByText, getByText} = render(<JobStats />)
    await act(async () => jest.runAllTimers())

    const jobs1_link = getByText('jobs1', {selector: 'a'})
    expect(jobs1_link.getAttribute('href')).toEqual('//jobs101.example.com/jobs_v2')

    expect(getByText('jobs held')).toBeInTheDocument()
    expect(getByText('block stranded')).toBeInTheDocument()

    expect(getByText('86', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('7', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('530', {selector: 'td'})).toBeInTheDocument()
    expect(getByText('9', {selector: 'td button'})).toBeInTheDocument()

    // since ENV.manage_jobs isn't set
    expect(queryByText('Unblock', {selector: 'button span'})).not.toBeInTheDocument()
  })

  it('refreshes cluster', async () => {
    const {queryByText, getByText} = render(<JobStats />)
    await act(async () => jest.runAllTimers())

    fireEvent.click(getByText('Refresh', {selector: 'button span'}))
    await act(async () => jest.runAllTimers())

    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({params: {job_shards: ['101']}})
    )

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

  it('unstucks a cluster', async () => {
    ENV.manage_jobs = true

    const {getByText, queryByText} = render(<JobStats />)
    await act(async () => jest.runAllTimers())

    fireEvent.click(getByText('Unblock', {selector: 'button span'}))
    await act(async () => jest.runAllTimers())

    expect(
      getByText('Are you sure you want to unblock all stuck jobs in this job cluster?')
    ).toBeInTheDocument()
    expect(
      getByText('NOTE: Jobs blocked by shard migrations will not be unblocked.')
    ).toBeInTheDocument()

    fireEvent.click(getByText('Confirm'))
    await act(async () => jest.runAllTimers())

    expect(getByText('Unblocking...')).toBeInTheDocument()
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'PUT',
        params: {job_shards: ['101']},
        path: '/api/v1/jobs2/unstuck',
      })
    )

    await act(async () => jest.advanceTimersByTime(2000))

    expect(doFetchApi).toHaveBeenCalledWith(expect.objectContaining({path: '/api/v1/progress/655'}))
    expect(queryByText('9', {selector: 'td button'})).not.toBeInTheDocument()
    expect(getByText('0', {selector: 'td'})).toBeInTheDocument()
  })

  it('shows stuck strands/singletons', async () => {
    const {getByText, getAllByText} = render(<JobStats />)
    await act(async () => jest.runAllTimers())

    fireEvent.click(getByText('9', {selector: 'td button'}))
    await act(async () => jest.runAllTimers())

    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({params: {job_shard: '101'}, path: '/api/v1/jobs2/stuck/strands'})
    )
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({params: {job_shard: '101'}, path: '/api/v1/jobs2/stuck/singletons'})
    )

    const ss_links = getAllByText('baz', {selector: 'td a'})
    expect(ss_links.length).toEqual(2)
    expect(ss_links.map(link => link.getAttribute('href'))).toEqual([
      '//jobs101.example.com/jobs_v2?group_type=strand&group_text=baz&bucket=queued',
      '//jobs101.example.com/jobs_v2?group_type=singleton&group_text=baz&bucket=queued',
    ])
  })
})
