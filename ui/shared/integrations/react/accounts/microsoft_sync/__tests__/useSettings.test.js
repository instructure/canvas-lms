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
import useFetchApi from '@canvas/use-fetch-api-hook'

jest.mock('@canvas/use-fetch-api-hook')

const CONTEXT_BASE_URL = 'accounts/5'

const subject = () => {
  return renderHook(() => useSettings())
}

describe('useGetSettings', () => {
  let previousEnv
  beforeEach(() => {
    useFetchApi.mockClear()
    previousEnv = ENV
  })

  afterEach(() => {
    ENV = previousEnv
  })

  it('renders without errors', () => {
    const {result} = subject()
    expect(result.error).toBeFalsy()
  })

  it('tries to get current account settings', () => {
    ENV = {
      CONTEXT_BASE_URL,
    }
    const {result} = subject()
    const call = useFetchApi.mock.calls.pop()[0]
    expect(call.path).toMatch(`/api/v1/${CONTEXT_BASE_URL}/settings`)
    expect(result.current[0]).toStrictEqual(defaultState)
  })

  describe('updating state after fetch finishes', () => {
    it('adds errors on failure to fetch', () => {
      useFetchApi.mockImplementationOnce(({loading, error}) => {
        loading(false)
        error('error!')
      })
      const {result} = subject()
      expect(result.current[0].loading).toBeFalsy()
      expect(result.current[0].errorMessage).toBeTruthy()
    })

    it('updates the settings to the fetched settings', () => {
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
      useFetchApi.mockImplementationOnce(({success, loading}) => {
        loading(false)
        success(expectedSettings)
      })

      const {result} = subject()
      expect(result.current[0]).toStrictEqual(expectedSettings)
    })
  })
})
