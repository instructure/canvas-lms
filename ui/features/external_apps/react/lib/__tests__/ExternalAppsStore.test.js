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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

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
  })

  afterEach(() => {
    store.reset()
    fakeENV.teardown()
  })

  it('fetches external tools', done => {
    server.use(
      http.get('/api/v1/accounts/1/lti_apps', () => {
        return HttpResponse.json(tools)
      }),
    )

    store.fetch()

    // Wait for the async operation to complete
    setTimeout(() => {
      expect(store.getState().externalTools).toHaveLength(3)
      done()
    }, 100)
  })

  it('handles resets and fetch responses interwoven', done => {
    server.use(
      http.get('/api/v1/accounts/1/lti_apps', () => {
        return HttpResponse.json(tools)
      }),
    )

    store.fetch()
    store.reset()
    store.fetch()

    // Wait for the async operation to complete
    setTimeout(() => {
      expect(store.getState().externalTools).toHaveLength(3)
      done()
    }, 100)
  })

  it('updates access token', async () => {
    server.use(
      http.put('/accounts/1', () => {
        return HttpResponse.json(accountResponse)
      }),
    )

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
        },
      )
    })
  })

  it('fetches details for ContextExternalTool', async () => {
    const responseData = {status: 'ok'}
    server.use(
      http.get('/api/v1/courses/1/external_tools/1', () => {
        return HttpResponse.json(responseData)
      }),
    )

    const tool = tools[0]
    const data = await store.fetchWithDetails(tool)
    expect(data.status).toBe('ok')
  })

  it('fetches details for Lti::ToolProxy', async () => {
    const responseData = {status: 'ok'}
    server.use(
      http.get('/api/v1/accounts/1/tool_proxies/2', () => {
        return HttpResponse.json(responseData)
      }),
    )

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
      server.use(
        http.post('/api/v1/accounts/1/external_tools', () => {
          return HttpResponse.json(responseData)
        }),
      )

      return new Promise((resolve, reject) => {
        store.save(
          '/api/v1/accounts/1/external_tools',
          {},
          (data, statusText) => {
            expect(statusText).toBe('success')
            resolve()
          },
          () => reject(new Error('Failed to save external tool')),
        )
      })
    })
  })
})
