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
import fetchMock from 'fetch-mock'

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
  beforeEach(() => {
    fetchMock.restore()
  })

  it('makes an API call when page loads', async () => {
    fetchMock.get('/api/v1/accounts?include=course_count,sub_account_count&per_page=50&page=1', [
      accountFixture,
    ])
    const {queryByText} = render(
      <MockedQueryProvider>
        <AccountList />
      </MockedQueryProvider>,
    )
    await waitFor(() => expect(queryByText('acc1')).toBeTruthy())
  })

  // FOO-4877: the mocked error is appearing in console, failing the test
  it.skip('renders an error message when loading accounts fails', async () => {
    fetchMock.get(
      '/api/v1/accounts?include=course_count,sub_account_count&per_page=50&page=1',
      () => {
        throw Object.assign(new Error('mocked error'), {code: 402})
      },
    )
    const {queryByText} = render(
      <MockedQueryProvider>
        <AccountList />
      </MockedQueryProvider>,
    )
    await waitFor(() => expect(queryByText('Accounts could not be found')).toBeTruthy())
  })

  it('renders when the API does not return the last page', async () => {
    fetchMock.get('/api/v1/accounts?include=course_count,sub_account_count&per_page=50&page=1', {
      body: [accountFixture],
      headers: {
        link: '</api/v1/accounts?include=course_count,sub_account_countpage=1&per_page=50>; rel="current"',
      },
    })
    const {queryByText} = render(
      <MockedQueryProvider>
        <AccountList />
      </MockedQueryProvider>,
    )
    await waitFor(() => expect(queryByText('acc1')).toBeTruthy())
  })
})
