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

import * as apiClient from '../apiClient'
import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../msw/mswServer'

const server = mswServer([])

describe('apiClient', () => {
  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('outcome_imports', () => {
    const contextRoot = '/accounts/1'
    const outcomeImportId = 1
    const learningOutcomeGroupId = 1
    const apiRouteRoot = `/api/v1${contextRoot}/outcome_imports`

    async function executeTest(apiRoute, apiClientCall) {
      let capturedUrl
      server.use(
        http.all('*', ({request}) => {
          capturedUrl = request.url
          return new HttpResponse(JSON.stringify({}), {
            status: 200,
            headers: {
              'Content-Type': 'application/json',
            },
          })
        }),
      )

      await apiClientCall()
      // Extract pathname and search from the full URL
      const url = new URL(capturedUrl)
      const fullPath = url.pathname + url.search
      expect(fullPath).toEqual(apiRoute)
    }

    it('calls the correct route for createImport without specifying a group', async () => {
      await executeTest(`${apiRouteRoot}/?import_type=instructure_csv`, () =>
        apiClient.createImport(contextRoot, new File([''], 'test.csv')),
      )
    })

    it('calls the correct route for createImport within a group', async () => {
      await executeTest(
        `${apiRouteRoot}/group/${learningOutcomeGroupId}?import_type=instructure_csv`,
        () =>
          apiClient.createImport(contextRoot, new File([''], 'test.csv'), learningOutcomeGroupId),
      )
    })

    it('calls the correct route for queryImportStatus', async () => {
      await executeTest(`${apiRouteRoot}/${outcomeImportId}`, () =>
        apiClient.queryImportStatus(contextRoot, outcomeImportId),
      )
    })

    it('calls the correct route for queryImportCreatedGroupIds', async () => {
      await executeTest(`${apiRouteRoot}/${outcomeImportId}/created_group_ids`, () =>
        apiClient.queryImportCreatedGroupIds(contextRoot, outcomeImportId),
      )
    })
  })
})
