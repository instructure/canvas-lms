/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks'
import {defaultState} from '../lib/settingsReducer'
import useSettings from '../lib/useSettings'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

const CONTEXT_BASE_URL = '/accounts/5'

const subject = () => {
  return renderHook(() => useSettings())
}

describe('useGetSettings', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    server.resetHandlers()
  })

  it('renders without errors', () => {
    fakeENV.setup({CONTEXT_BASE_URL})
    server.use(http.get('/api/v1/accounts/5/settings', () => HttpResponse.json(defaultState)))
    const {result} = subject()
    expect(result.error).toBeFalsy()
  })

  it('tries to get current account settings', async () => {
    fakeENV.setup({CONTEXT_BASE_URL})
    server.use(http.get('/api/v1/accounts/5/settings', () => HttpResponse.json(defaultState)))
    const {result, waitForNextUpdate} = subject()
    await waitForNextUpdate()
    expect(result.current[0]).toStrictEqual({...defaultState, loading: false})
  })

  describe('updating state after fetch finishes', () => {
    beforeEach(() => {
      fakeENV.setup({CONTEXT_BASE_URL})
    })

    it('adds errors on failure to fetch', async () => {
      server.use(
        http.get('/api/v1/accounts/5/settings', () => new HttpResponse(null, {status: 500})),
      )
      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()
      expect(result.current[0].loading).toBeFalsy()
      expect(result.current[0].errorMessage).toBeTruthy()
    })

    it('updates the settings to the fetched settings', async () => {
      const expectedSettings = {
        ...defaultState,
        microsoft_sync_enabled: true,
        microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
        last_saved_microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
        microsoft_sync_login_attribute: 'email',
        microsoft_sync_login_attribute_suffix: '@example.com',
        microsoft_sync_remote_attribute: 'mailNickname',
        loading: false,
      }
      server.use(http.get('/api/v1/accounts/5/settings', () => HttpResponse.json(expectedSettings)))

      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()
      expect(result.current[0]).toStrictEqual(expectedSettings)
    })
  })
})
