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

import {doUpdateSettings, validateTenant, clearMessages} from '../lib/settingsHelper'
import fetchMock from 'fetch-mock'

describe('MicrosoftSyncAccountSettings settingsHelper', () => {
  describe('doUpdateSettings', () => {
    const enabled = true
    const tenant = 'testtenant.com'
    const loginAttr = 'oid'

    let oldEnv
    beforeAll(() => {
      oldEnv = ENV
      ENV = {
        CONTEXT_BASE_URL: 'accounts/4'
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
      await doUpdateSettings(enabled, tenant, loginAttr)

      expect(fetchMock.called()).toBeTruthy()
      expect(fetchMock.lastCall()[0]).toBe(`/api/v1/${ENV.CONTEXT_BASE_URL}`)
    })

    it('call with the correct body format', async () => {
      await doUpdateSettings(enabled, tenant, loginAttr)

      expect(fetchMock.called()).toBeTruthy()
      expect(JSON.parse(fetchMock.lastCall()[1].body)).toStrictEqual({
        account: {
          settings: {
            microsoft_sync_enabled: enabled,
            microsoft_sync_tenant: tenant,
            microsoft_sync_login_attribute: loginAttr
          }
        }
      })
    })
  })

  describe('validateTenant', () => {
    const createState = tenant => {
      return {
        tenantErrorMessages: [],
        microsoft_sync_tenant: tenant
      }
    }

    it('invalidates a blank tenant', () => {
      const result = validateTenant(createState(''))

      expect(result.tenantErrorMessages.length).toBe(1)
      expect(result.tenantErrorMessages[0].text).toBe(
        'To toggle Microsoft Teams Sync you need to input a tenant domain.'
      )
    })

    it('invalidates a tenant with an invalid domain name', () => {
      const result = validateTenant(createState('purpleoranges.com$!'))

      expect(result.tenantErrorMessages.length).toBe(1)
      expect(result.tenantErrorMessages[0].text).toBe(
        'Please provide a valid tenant domain. Check your Azure Active Directory settings to find it.'
      )
    })

    it('validates a valid tenant', () => {
      const result = validateTenant(createState('canvastest2.onmicrosoft.com'))
      expect(result.tenantErrorMessages.length).toBe(0)
    })
  })
})
