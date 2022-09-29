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
import moxios from 'moxios'

describe('apiClient', () => {
  describe('outcome_imports', () => {
    const contextRoot = '/accounts/1'
    const outcomeImportId = 1
    const learningOutcomeGroupId = 1
    const apiRouteRoot = `/api/v1${contextRoot}/outcome_imports`
    moxios.install()

    function executeTest(apiRoute, apiClientCall) {
      moxios.stubRequest(apiRoute, {
        status: 200,
        response: {},
      })

      moxios.wait(() => {
        return apiClientCall().then(() => {
          expect(moxios.request.mostRecent().url).toEqual(apiRoute)
        })
      })
    }

    it('calls the correct route for createImport without specifying a group', () => {
      executeTest(`${apiRouteRoot}?import_type=instructure_csv`, () =>
        apiClient.createImport(contextRoot, new File())
      )
    })

    it('calls the correct route for createImport within a group', () => {
      executeTest(
        `${apiRouteRoot}/group/${learningOutcomeGroupId}?import_type=instructure_csv`,
        () => apiClient.createImport(contextRoot, new File(), learningOutcomeGroupId)
      )
    })

    it('calls the correct route for queryImportStatus', () => {
      executeTest(`${apiRouteRoot}/outcome_imports/${outcomeImportId}`, () =>
        apiClient.queryImportStatus(contextRoot, outcomeImportId)
      )
    })

    it('calls the correct route for queryImportCreatedGroupIds', () => {
      executeTest(`${apiRouteRoot}/outcome_imports/${outcomeImportId}/created_group_ids`, () =>
        apiClient.queryImportCreatedGroupIds(contextRoot, outcomeImportId)
      )
    })

    moxios.uninstall()
  })
})
