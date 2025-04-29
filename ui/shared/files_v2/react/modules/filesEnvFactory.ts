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

import splitAssetString from '@canvas/util/splitAssetString'
import {FileContext, FilesEnv} from './filesEnvFactory.types'
import {windowPathname} from '@canvas/util/globalUtils'

declare const ENV: {
  FILES_CONTEXTS?: FileContext[]
}

const buildContextsDictionary = (contexts: FileContext[]) => {
  return contexts.reduce((dict: Record<string, FileContext>, context) => {
    const [contextType, contextId] = splitAssetString(context.asset_string) ?? ['', '']
    context.contextType = contextType
    context.contextId = contextId
    dict[[contextType, contextId].join('_')] = context
    return dict
  }, {})
}

export const createFilesEnv = (customFilesContexts?: FileContext[]): FilesEnv => {
  const showingAllContexts = !!windowPathname().match(/^\/files/)
  const fileContexts = customFilesContexts || ENV.FILES_CONTEXTS || []
  // buildContextsDictonary mutates the FileContexts, adding contexType and contextId
  const contextsDictionary = buildContextsDictionary(fileContexts)
  const baseUrl = showingAllContexts
    ? '/files'
    : `/${fileContexts[0]?.contextType}/${fileContexts[0]?.contextId}/files`

  function contextFor(folder: {contextType: string; contextId: string}) {
    const pluralAssetString = `${folder.contextType}s_${folder.contextId}`.toLowerCase()
    return contextsDictionary && contextsDictionary[pluralAssetString]
  }

  function userHasPermission(folder: {contextType: string; contextId: string}, action: string) {
    return (
      (contextFor(folder) &&
        contextFor(folder).permissions &&
        contextFor(folder).permissions[action]) ??
      false
    )
  }

  return {
    contexts: fileContexts,
    contextsDictionary: buildContextsDictionary(fileContexts),
    contextType: fileContexts[0]?.contextType || '',
    contextId: fileContexts[0]?.contextId || '',
    showingAllContexts,
    baseUrl,
    contextFor,
    userHasPermission,
  }
}
