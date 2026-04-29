/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {AccountList} from '../AccountList'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

const accountFixture = {
  id: '1',
  name: 'acc1',
  course_count: 1,
  sub_account_count: 1,
  workflow_state: 'active',
  parent_account_id: null,
  root_account_id: null,
  uuid: '2675186350fe410fb1247a4b911deef4',
  default_storage_quota_mb: 500,
  default_user_storage_quota_mb: 50,
  default_group_storage_quota_mb: 50,
  default_time_zone: 'America/Denver',
}

describe('AccountLists', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('makes an API call when page loads', async () => {
    server.use(
      http.get('/api/v1/accounts', ({request}) => {
        const url = new URL(request.url)
        if (
          url.searchParams.get('include') === 'course_count,sub_account_count' &&
          url.searchParams.get('per_page') === '50' &&
          url.searchParams.get('page') === '1'
        ) {
          return HttpResponse.json([accountFixture])
        }
        return HttpResponse.json([])
      }),
    )
    const {queryByText} = render(
      <MockedQueryProvider>
        <AccountList />
      </MockedQueryProvider>,
    )
    await waitFor(() => expect(queryByText('acc1')).toBeTruthy())
  })

  it('renders an error message when loading accounts fails', async () => {
    server.use(
      http.get('/api/v1/accounts', () => {
        return HttpResponse.json({error: 'Internal Server Error'}, {status: 500})
      }),
    )
    const {getByText} = render(
      <MockedQueryProvider>
        <AccountList />
      </MockedQueryProvider>,
    )
    await waitFor(() =>
      expect(getByText('Help us improve by telling us what happened')).toBeInTheDocument(),
    )
  })

  it('renders when the API does not return the last page', async () => {
    server.use(
      http.get('/api/v1/accounts', ({request}) => {
        const url = new URL(request.url)
        if (
          url.searchParams.get('include') === 'course_count,sub_account_count' &&
          url.searchParams.get('per_page') === '50' &&
          url.searchParams.get('page') === '1'
        ) {
          return new HttpResponse(JSON.stringify([accountFixture]), {
            headers: {
              'Content-Type': 'application/json',
              link: '</api/v1/accounts?include=course_count,sub_account_countpage=1&per_page=50>; rel="current"',
            },
          })
        }
        return HttpResponse.json([])
      }),
    )
    const {queryByText} = render(
      <MockedQueryProvider>
        <AccountList />
      </MockedQueryProvider>,
    )
    await waitFor(() => expect(queryByText('acc1')).toBeTruthy())
  })
})
