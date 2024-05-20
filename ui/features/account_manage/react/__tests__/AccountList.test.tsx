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
import fetchMock from 'fetch-mock'

describe('AccountLists', () => {
  const props = {onPageClick: jest.fn()}

  afterEach(() => {
    fetchMock.restore()
  })

  it('makes an API call when page loads', async () => {
    fetchMock.get('/api/v1/accounts?per_page=30&page=1', [{id: '1', name: 'acc1'}])
    const {queryAllByText} = render(<AccountList {...props} pageIndex={1} />)
    await waitFor(() => expect(queryAllByText('acc1')).toBeTruthy())
  })

  it('renders an error message when loading accounts fails', async () => {
    fetchMock.get('/api/v1/accounts?per_page=30&page=1', () => {
      throw Object.assign(new Error('error'), {code: 402})
    })
    const {queryAllByText} = render(<AccountList {...props} pageIndex={1} />)
    await waitFor(() => expect(queryAllByText('Accounts could not be found')).toBeTruthy())
  })

  it('renders when the API does not return the last page', async () => {
    fetchMock.get('/api/v1/accounts?per_page=100&page=1', {
      body: [{id: '1', name: 'acc1'}],
      headers: {
        link: '</api/v1/accounts?page=1&per_page=100>; rel="current"',
      },
    })
    const {queryAllByText} = render(<AccountList {...props} pageIndex={1} />)
    await waitFor(() => expect(queryAllByText('acc1')).toBeTruthy())
  })
})
