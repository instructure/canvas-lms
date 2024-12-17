/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import store from '../ExternalAppsStore'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('ExternalApps.ExternalAppsStore', () => {
  const tools = [
    {
      app_id: 1,
      app_type: 'ContextExternalTool',
      description:
        'Talent provides an online, interactive video platform for professional development',
      enabled: true,
      installed_locally: true,
      name: 'Talent',
      context: 'Course',
      context_id: 1,
    },
    {
      app_id: 2,
      app_type: 'Lti::ToolProxy',
      description: null,
      enabled: true,
      installed_locally: true,
      name: 'SomeTool',
      context: 'Course',
      context_id: 1,
    },
    {
      app_id: 3,
      app_type: 'Lti::ToolProxy',
      description: null,
      enabled: false,
      installed_locally: true,
      name: 'LinkedIn',
      context: 'Course',
      context_id: 1,
    },
  ]

  const accountResponse = {
    id: 1,
    name: 'root',
    workflow_state: 'active',
    parent_account_id: null,
    root_account_id: null,
    default_storage_quota_mb: 500,
    default_user_storage_quota_mb: 50,
    default_group_storage_quota_mb: 50,
    default_time_zone: 'America/Denver',
  }

  beforeEach(() => {
    fakeENV.setup({CONTEXT_BASE_URL: '/accounts/1'})
    store.reset()
    jest.spyOn($, 'ajax')
    jest.spyOn($, 'getJSON')
  })

  afterEach(() => {
    store.reset()
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  it('fetches external tools', async () => {
    $.ajax.mockImplementation(({success}) => {
      success(tools)
      return {done: () => ({})}
    })

    store.fetch()
    expect(store.getState().externalTools).toHaveLength(3)
  })

  it('handles resets and fetch responses interwoven', async () => {
    $.ajax.mockImplementation(({success}) => {
      success(tools)
      return {done: () => ({})}
    })

    store.fetch()
    store.reset()
    store.fetch()

    expect(store.getState().externalTools).toHaveLength(3)
  })

  it('updates access token', async () => {
    $.ajax.mockImplementation(({success}) => {
      success(accountResponse, 'success')
      return {done: () => ({})}
    })

    return new Promise((resolve, reject) => {
      store.updateAccessToken(
        '/accounts/1',
        '1234',
        (data, statusText) => {
          expect(statusText).toBe('success')
          resolve()
        },
        () => {
          reject(new Error('Unable to update app center access token'))
        }
      )
    })
  })

  it('fetches details for ContextExternalTool', async () => {
    const responseData = {status: 'ok'}
    $.getJSON.mockImplementation(() => Promise.resolve(responseData))

    const tool = tools[0]
    const data = await store.fetchWithDetails(tool)
    expect(data.status).toBe('ok')
  })

  it('fetches details for Lti::ToolProxy', async () => {
    const responseData = {status: 'ok'}
    $.getJSON.mockImplementation(() => Promise.resolve(responseData))

    const tool = tools[1]
    const data = await store.fetchWithDetails(tool)
    expect(data.status).toBe('ok')
  })

  describe('save functionality', () => {
    let originalGenerateParams

    beforeEach(() => {
      originalGenerateParams = store._generateParams
      store._generateParams = () => ({foo: 'bar'})
    })

    afterEach(() => {
      store._generateParams = originalGenerateParams
    })

    it('saves external tool', async () => {
      const responseData = {status: 'ok'}
      $.ajax.mockImplementation(({success}) => {
        success(responseData, 'success')
        return {done: () => ({})}
      })

      return new Promise((resolve, reject) => {
        store.save(
          'http://example.com',
          {},
          (data, statusText) => {
            expect(statusText).toBe('success')
            resolve()
          },
          () => reject(new Error('Failed to save external tool'))
        )
      })
    })
  })
})
