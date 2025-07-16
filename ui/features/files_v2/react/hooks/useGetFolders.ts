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

import {useQuery, keepPreviousData} from '@tanstack/react-query'
import {useParams} from 'react-router-dom'
import splitAssetString from '@canvas/util/splitAssetString'
import {getFilesEnv} from '../../utils/filesEnvUtils'
import {createStubRootFolder} from '../../utils/folderUtils'
import {
  doFetchApiWithAuthCheck,
  generateFolderByPathUrl,
  NotFoundError,
  UnauthorizedError,
} from '../../utils/apiUtils'
import {Folder} from '../../interfaces/File'

function getRootFolder({
  contextId,
  pluralContextType,
  rootFolderId,
}: {
  contextId: string
  pluralContextType: string
  rootFolderId: string
}) {
  return createStubRootFolder({contextId, pluralContextType, rootFolderId})
}

async function loadFolders(pluralContextType: string, contextId: string, path?: string) {
  const url = generateFolderByPathUrl(pluralContextType, contextId, path)

  try {
    const {json} = await doFetchApiWithAuthCheck<Folder[]>({
      path: url,
    })

    if (!json || json.length === 0) {
      throw new Error()
    }

    return json
  } catch (err) {
    if (err instanceof UnauthorizedError) {
      throw err
    }
    const status = (err as any).response?.status
    if (status === 404) throw new NotFoundError(url)
    if (status && status >= 400) throw new Error(`Request failed with status ${status}`)
    throw new Error('Error fetching by_path')
  }
}

export const useGetFolders = () => {
  const filesEnv = getFilesEnv()
  const pathParams = useParams()
  const pathContext = pathParams.context
  const path = pathParams['*']
  const [contextType, contextId] = pathContext
    ? splitAssetString(pathContext)!
    : [filesEnv.contextType, filesEnv.contextId]

  const queryKey = ['folders', {path, contextType, contextId}] as const
  return useQuery<Folder[], Error, Folder[], typeof queryKey>({
    queryKey,
    staleTime: 0,
    placeholderData: keepPreviousData,
    queryFn: async ({queryKey}) => {
      const [, {path, contextType, contextId}] = queryKey
      const context = getFilesEnv().contextsDictionary[`${contextType}_${contextId}`]

      return path || !context?.root_folder_id
        ? await loadFolders(contextType, contextId, path)
        : [
            getRootFolder({
              contextId: context.contextId,
              pluralContextType: context.contextType,
              rootFolderId: context.root_folder_id,
            }),
          ]
    },
  })
}
