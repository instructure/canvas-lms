/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {act, screen} from '@testing-library/react'
import {start} from '../index'

const server = setupServer(
  http.get('/api/v1/accounts/1/csp_settings', () =>
    HttpResponse.json({
      enabled: false,
      inherited: false,
      effective_whitelist: [],
      current_account_whitelist: [],
      tools_whitelist: {},
    }),
  ),
)

describe('start', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  beforeEach(() => {
    window.ENV = {
      ACCOUNT: {id: '1234'},
    }
  })

  afterEach(() => {
    document.getElementById('fixtures')?.remove()
  })

  it('renders without errors', async () => {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)

    await act(async () => {
      start(fixtures, {context: 'account', contextId: '1'})
    })

    await screen.findByText(/canvas content security policy/i)
  })
})
