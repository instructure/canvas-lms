/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ModuleSequence, Result} from './types'

export async function fetchAllModules(courseId: string, searchResults: Result[]) {
  const promises = searchResults.map(async result => {
    return await fetchModule(courseId, result.content_id, result.content_type)
  })
  return await Promise.all(promises)
}

async function fetchModule(courseId: string, assetId: string, assetType: string) {
  const params = {
    asset_type: assetType,
    asset_id: assetId,
  }
  const {json} = await doFetchApi<ModuleSequence>({
    path: `/api/v1/courses/${courseId}/module_item_sequence`,
    params,
  })
  return {modules: json?.modules, assetId}
}
