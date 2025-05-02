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
import {generateFolderByPathUrl, NotFoundError, UnauthorizedError} from '../../utils/apiUtils'
import {Folder} from '../../interfaces/File'

function getRootFolder(pluralContextType: string, contextId: string) {
  return createStubRootFolder(getFilesEnv().contextsDictionary[`${pluralContextType}_${contextId}`])
}

async function loadFolders(pluralContextType: string, contextId: string, path?: string) {
  const url = generateFolderByPathUrl(pluralContextType, contextId, path)
  const resp = await fetch(url)
  if (resp.status === 401) {
    throw new UnauthorizedError()
  }

  if (resp.status === 404) {
    throw new NotFoundError(url)
  }

  if (!resp.ok) {
    throw new Error(`Request failed with status ${resp.status}`)
  }

  const folders = await resp.json()
  if (!folders || folders.length === 0) {
    throw new Error('Error fetching by_path')
  }
  return folders as Folder[]
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
      return path
        ? await loadFolders(contextType, contextId, path)
        : [getRootFolder(contextType, contextId)]
    },
  })
}
