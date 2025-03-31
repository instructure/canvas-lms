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

import doFetchApi, {type DoFetchApiResults, FetchApiError} from '@canvas/do-fetch-api-effect'
import {type Links} from '@canvas/parse-link-header'

const DEFAULT_PAGE_SIZE = 10

type ModuleId = number | string
type ModuleItems = string
type ModuleItemFetchError = {moduleId: ModuleId; error: FetchApiError}
type ModuleItemsResult = DoFetchApiResults<ModuleItems>
type ModuleItemsFetchResult = ModuleItemsResult | ModuleItemFetchError
type ModuleItemsCallback = (
  moduleId: ModuleId,
  items: string,
  link?: Links,
  error?: ModuleItemFetchError,
) => void

// Fetch a page of items for a single module
// and call the callback with the result
async function fetchItemsForModule(
  moduleId: ModuleId,
  url: string,
  callback: ModuleItemsCallback,
): Promise<ModuleItemsFetchResult> {
  try {
    const result = await doFetchApi<ModuleItems>({
      path: url,
      headers: {
        accept: 'text/html',
      },
    })
    callback(moduleId, result.text, result.link)
    return result
  } catch (error: unknown) {
    const err: ModuleItemFetchError = {moduleId, error: error as FetchApiError}
    callback(moduleId, '', undefined, err)
    return Promise.resolve(err)
  }
}

// Given a list of moduleIds, initiate a fetch for them all and let the browser
// handle concurrency. This returns a promise that resolves when all the fetches
// are complete.
async function fetchModuleItems(
  courseId: string,
  moduleIds: ModuleId[],
  callback: ModuleItemsCallback,
  per_page = DEFAULT_PAGE_SIZE,
): Promise<ModuleItemsFetchResult[]> {
  const promises: Promise<ModuleItemsFetchResult>[] = []
  for (const moduleId of moduleIds) {
    const url = `/courses/${courseId}/modules/${moduleId}/items_html?per_page=${per_page || DEFAULT_PAGE_SIZE}`
    promises.push(fetchItemsForModule(moduleId, url, callback))
  }
  return Promise.all(promises)
}

export {
  fetchItemsForModule,
  fetchModuleItems,
  type ModuleId,
  type ModuleItems,
  type ModuleItemsCallback,
  type ModuleItemFetchError,
}
