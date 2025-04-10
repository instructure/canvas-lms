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
import {InfiniteData} from '@tanstack/react-query'

export type ApiFolderItem = {id: string | number; name: string}
export type ApiFoldersResponse = ApiFolderItem[]
export type MultiPagePartialResponse = {json: ApiFoldersResponse, nextPage: string | null}
export type MultiPageResponse = InfiniteData<{json: ApiFoldersResponse, nextPage: string | null }>

export const fetchFolders = async (folderId: string, page: string | null): Promise<MultiPagePartialResponse> => {
  const params = { per_page: '25', page: page ?? '1' }

  const {json, link} = await doFetchApi<ApiFoldersResponse>({
    path: `/api/v1/folders/${folderId}/folders`,
    method: 'GET',
    params,
  })

  const nextPage = link?.next?.page ?? null
  return { json: json!, nextPage }
}
