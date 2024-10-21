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

interface FileContext {
  asset_string: string
  contextType?: string
  contextId?: string
}

declare const ENV: {
  FILES_CONTEXTS?: FileContext[]
}

const fileContexts: FileContext[] = ENV.FILES_CONTEXTS || []

const buildContextsDictionary = (contexts: FileContext[]) => {
  return contexts.reduce((dict: Record<string, FileContext>, context) => {
    const [contextType, contextId] = splitAssetString(context.asset_string)
    context.contextType = contextType
    context.contextId = contextId
    dict[context.asset_string] = context
    return dict
  }, {})
}

const filesEnv = {
  contexts: fileContexts,
  contextsDictionary: buildContextsDictionary(fileContexts),
  showingAllContexts: !!window.location.pathname.match(/^\/files/),
  contextType: fileContexts[0]?.contextType,
  contextId: fileContexts[0]?.contextId,
  baseUrl: '',
}

filesEnv.baseUrl = filesEnv.showingAllContexts
  ? '/files'
  : `/${filesEnv.contextType}/${filesEnv.contextId}/files`

export default filesEnv
