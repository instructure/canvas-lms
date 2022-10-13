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

import {
  doUpdateSettings,
  sliceSyncSettings,
  getTenantErrorMessages,
  getSuffixErrorMessages,
  SYNC_SETTINGS,
} from '../lib/settingsHelper'
import {defaultState} from '../lib/settingsReducer'
import fetchMock from 'fetch-mock'

describe('MicrosoftSyncAccountSettings settingsHelper', () => {
  describe('doUpdateSettings', () => {
    const expectedBody = {
      microsoft_sync_tenant: 'testtenant.com',
      microsoft_sync_enabled: true,
      microsoft_sync_login_attribute: 'email',
      microsoft_sync_login_attribute_suffix: '@example.com',
      microsoft_sync_remote_attribute: 'mail',
    }

    let oldEnv
    beforeAll(() => {
      oldEnv = ENV
      ENV = {
        CONTEXT_BASE_URL: 'accounts/4',
      }
      fetchMock.mock('*', 200)
    })
    beforeEach(() => {})

    afterEach(() => {
      fetchMock.resetHistory()
    })

    afterAll(() => {
      ENV = oldEnv
      fetchMock.reset()
    })

    it('calls to the correct URL', async () => {
      await doUpdateSettings(expectedBody)

      expect(fetchMock.called()).toBeTruthy()
      expect(fetchMock.lastCall()[0]).toBe(`/api/v1/${ENV.CONTEXT_BASE_URL}`)
    })

    it('calls with the correct body format', async () => {
      await doUpdateSettings({
        ...expectedBody,
      })

      expect(fetchMock.called()).toBeTruthy()
      expect(JSON.parse(fetchMock.lastCall()[1].body)).toStrictEqual({
        account: {
          settings: {
            ...expectedBody,
          },
        },
      })
    })
  })

  describe('sliceSyncSettings', () => {
    it('returns only sync settings', () => {
      expect(Object.keys(sliceSyncSettings(defaultState))).toEqual(SYNC_SETTINGS)
    })

    it('returns an empty object if no valid settings are found', () => {
      expect(Object.keys(sliceSyncSettings({foo: 'bar'}))).toHaveLength(0)
    })
  })

  describe('getTenantErrorMessages', () => {
    const createState = tenant => {
      return {
        tenantErrorMessages: [],
        microsoft_sync_tenant: tenant,
      }
    }

    it('invalidates a blank tenant', () => {
      const errors = getTenantErrorMessages(createState(''))

      expect(errors.length).toBe(1)
      expect(errors[0].text).toBe(
        'To toggle Microsoft Teams Sync you need to input a tenant domain.'
      )
    })

    it('invalidates a tenant with an invalid domain name', () => {
      const errors = getTenantErrorMessages(createState('purpleoranges.com$!'))

      expect(errors.length).toBe(1)
      expect(errors[0].text).toBe(
        'Please provide a valid tenant domain. Check your Azure Active Directory settings to find it.'
      )
    })

    it('validates a valid tenant', () => {
      const errors = getTenantErrorMessages(createState('canvastest2.onmicrosoft.com'))
      expect(errors.length).toBe(0)
    })
  })

  describe('getSuffixErrorMessages', () => {
    it('invalidates suffixes that are longer than 255 characters', () => {
      const suffix = 'a'.repeat(256)

      const errors = getSuffixErrorMessages({microsoft_sync_login_attribute_suffix: suffix})

      expect(errors.length).toBe(1)
    })

    it('invalidates suffixes that have whitespace in them', () => {
      const suffix = '\t hello there my dear friend'

      const errors = getSuffixErrorMessages({microsoft_sync_login_attribute_suffix: suffix})

      expect(errors.length).toBe(1)
    })
  })
})
