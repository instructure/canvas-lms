/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useQuery} from '@tanstack/react-query'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
import {Folder} from '../../interfaces/File'
import {pluralizeContextTypeString} from '../../utils/fileFolderUtils'

interface UseCheckDuplicateFoldersParams {
  folderId: string
  contextType: string
  contextId: string
  enabled?: boolean
}

async function fetchDuplicateFolders(
  contextType: string,
  contextId: string,
  folderId: string,
): Promise<Folder[]> {
  const pluralContextType = pluralizeContextTypeString(contextType)
  const path = `/api/v1/${pluralContextType}/${contextId}/folders/${folderId}/duplicates`

  try {
    const {json} = await doFetchApi<{duplicates: Folder[]}>({
      path,
      method: 'GET',
    })
    return json?.duplicates || []
  } catch (error) {
    if (error instanceof FetchApiError && error.response.status === 404) {
      return []
    }
    throw error
  }
}

export const useCheckDuplicateFolders = ({
  folderId,
  contextType,
  contextId,
  enabled = true,
}: UseCheckDuplicateFoldersParams) => {
  return useQuery({
    queryKey: ['duplicateFolders', {folderId, contextType, contextId}] as const,
    queryFn: async ({queryKey}) => {
      const [, {folderId, contextType, contextId}] = queryKey
      return fetchDuplicateFolders(contextType, contextId, folderId)
    },
    enabled,
    staleTime: 0,
    gcTime: 0,
    retry: false,
  })
}
