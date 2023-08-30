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
import JobsIndex from '../index'
import doFetchApi from '@canvas/do-fetch-api-effect'
import mockJobsApi from './MockJobsApi'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.mock('@canvas/do-fetch-api-effect')
jest.useFakeTimers()

function changeAndBlurInput(input, newValue) {
  fireEvent.change(input, {target: {value: newValue}})
  fireEvent.blur(input)
}

describe('JobsIndex', () => {
  let oldEnv
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

    doFetchApi.mockImplementation(mockJobsApi)
  })

  beforeEach(() => {
    doFetchApi.mockClear()
    window.history.replaceState('', '', '?')
  })

  afterAll(() => {
    window.ENV = oldEnv
  })

  it('renders groups and jobs', async () => {
    const {getByText, getAllByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    expect(getByText('fake_job_list_group_value')).toBeInTheDocument()
    expect(getAllByText('00:01:40').length).toEqual(2)
    expect(getAllByText('Page 5').length).toEqual(2)
    expect(getByText('3606')).toBeInTheDocument()
    expect(getAllByText('fake_job_list_tag_value').length).toEqual(2)
    expect(getAllByText('fake_job_list_strand_value').length).toEqual(2)
    expect(getAllByText('fake_job_list_singleton_value').length).toEqual(2)
  })

  it('switches scope', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    fireEvent.click(getByLabelText('Scope'))
    fireEvent.click(getByText('Test Academy'))
    expect(window.location.search).toMatch(/jobs_scope=account/)
    expect(doFetchApi).toHaveBeenLastCalledWith(
      expect.objectContaining({params: expect.objectContaining({scope: 'account'})})
    )
  })

  it('switches buckets', async () => {
    const {getByLabelText} = render(<JobsIndex />)
    fireEvent.click(getByLabelText('Failed'))
    expect(window.location.search).toMatch(/bucket=failed/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({path: '/api/v1/jobs2/failed/by_tag'})
    )
  })

  it('switches groups', async () => {
    const {getByLabelText} = render(<JobsIndex />)
    fireEvent.click(getByLabelText('Singleton'))
    expect(window.location.search).toMatch(/group_type=singleton/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({path: '/api/v1/jobs2/running/by_singleton'})
    )
  })

  it('paginates the group list', async () => {
    const {getAllByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Page 5')[0])
    expect(window.location.search).toMatch(/groups_page=5/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running/by_tag',
        params: expect.objectContaining({page: 5}),
      })
    )
  })

  it('paginates the job list', async () => {
    const {getAllByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Page 2')[1])
    expect(window.location.search).toMatch(/jobs_page=2/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running',
        params: expect.objectContaining({page: 2}),
      })
    )
  })

  it('filters the job list via the groups table', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('fake_job_list_group_value'))
    expect(window.location.search).toMatch(/group_text=fake_job_list_group_value/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running',
        params: expect.objectContaining({tag: 'fake_job_list_group_value'}),
      })
    )
  })

  it('filters by clicking a tag in the jobs list', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('fake_job_list_tag_value', {selector: 'button span'}))
    expect(window.location.search).toMatch(/group_text=fake_job_list_tag_value/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running',
        params: expect.objectContaining({tag: 'fake_job_list_tag_value'}),
      })
    )
  })

  it('filters by clicking a strand in the jobs list', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('fake_job_list_strand_value', {selector: 'button span'}))
    expect(window.location.search).toMatch(/group_type=strand/)
    expect(window.location.search).toMatch(/group_text=fake_job_list_strand_value/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running',
        params: expect.objectContaining({strand: 'fake_job_list_strand_value'}),
      })
    )
  })

  it('filters by clicking a singleton in the jobs list', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('fake_job_list_singleton_value', {selector: 'button span'}))
    expect(window.location.search).toMatch(/group_type=singleton/)
    expect(window.location.search).toMatch(/group_text=fake_job_list_singleton_value/)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running',
        params: expect.objectContaining({singleton: 'fake_job_list_singleton_value'}),
      })
    )
  })

  it('shows job details', async () => {
    const {getByText} = render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('3606'))
    expect(getByText('job010001039065:12438')).toBeInTheDocument()
    expect(getByText('10.1.39.65')).toBeInTheDocument()
    expect(getByText('4/2/22, 7:02 AM')).toBeInTheDocument()
  })

  it('searches for a tag', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    fireEvent.change(getByLabelText('Filter running jobs by tag'), {
      target: {value: 'fake_group_search'},
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('fake_group_search_value_1 (106)'))
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/running',
        params: expect.objectContaining({tag: 'fake_group_search_value_1'}),
      })
    )
  })

  it('looks up a job by id', async () => {
    const {getByText, getByLabelText} = render(<JobsIndex />)
    fireEvent.change(getByLabelText('Job lookup'), {
      target: {value: '3606'},
    })
    await act(async () => jest.runAllTimers())
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

    await act(async () => jest.runAllTimers())

    // these times are 9AM and 11PM EDT, converted to UTC (a four-hour difference)
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        params: expect.objectContaining({
          start_date: '2022-04-02T13:00:00.000Z',
          end_date: '2022-04-03T03:00:00.000Z',
        }),
      })
    )

    // note we saw 7:02 AM in an earlier test, but we've changed the time zone to Eastern now
    fireEvent.click(getByText('3606'))
    expect(getByText('4/2/22, 9:02 AM')).toBeInTheDocument()
  })

  it('initializes state from URL parameters', async () => {
    window.history.replaceState(
      '',
      '',
      '?bucket=failed&group_type=strand&group_order=count&jobs_order=tag&groups_page=2&jobs_page=3&scope=account&start_date=2022-04-01T01%3A00%3A00.000Z&end_date=2022-04-02T01%3A00%3A00.000Z&time_zone=UTC'
    )
    render(<JobsIndex />)
    await act(async () => jest.runAllTimers())
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/failed/by_strand',
        params: expect.objectContaining({
          order: 'count',
          page: 2,
          scope: 'account',
          start_date: '2022-04-01T01:00:00.000Z',
          end_date: '2022-04-02T01:00:00.000Z',
        }),
      })
    )
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/jobs2/failed',
        params: expect.objectContaining({
          order: 'tag',
          page: 3,
          scope: 'account',
          start_date: '2022-04-01T01:00:00.000Z',
          end_date: '2022-04-02T01:00:00.000Z',
        }),
      })
    )
  })
})
