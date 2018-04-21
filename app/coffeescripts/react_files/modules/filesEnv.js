/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import Folder from '../../models/Folder'
import splitAssetString from '../../str/splitAssetString'

const fileContexts = ENV.FILES_CONTEXTS || []
let newFolderTree = ENV.NEW_FOLDER_TREE
if (newFolderTree === undefined) newFolderTree = false

const filesEnv = {
  newFolderTree,
  contexts: fileContexts,
  contextsDictionary: fileContexts.reduce(function(dict, context) {
    const [contextType, contextId] = Array.from(splitAssetString(context.asset_string))
    context.contextType = contextType
    context.contextId = contextId
    dict[[contextType, contextId].join('_')] = context
    return dict
  }, {}),
  showingAllContexts: window.location.pathname.match(/^\/files/),
  contextType: fileContexts[0] != null ? fileContexts[0].contextType : undefined,
  contextId: fileContexts[0] != null ? fileContexts[0].contextId : undefined,
  rootFolders: fileContexts.map(function(contextData) {
    if (ENV.current_user_id) {
      const folder = new Folder({
        custom_name: contextData.name,
        context_type: contextData.contextType.replace(/s$/, ''),
        context_id: contextData.contextId
      })
      folder.url = `/api/v1/${contextData.contextType}/${contextData.contextId}/folders/root`
      folder.fetch()
      return folder
    }
  })
}

filesEnv.contextFor = function(folderOrFile) {
  let assetString
  if (folderOrFile.collection && folderOrFile.collection.parentFolder) {
    folderOrFile = folderOrFile.collection.parentFolder
  }
  if (folderOrFile instanceof Folder) {
    const folder = folderOrFile
    assetString = `${folder && folder.get('context_type')}s_${folder &&
      folder.get('context_id')}`.toLowerCase()
  } else if (folderOrFile.contextType && folderOrFile.contextId) {
    assetString = `${folderOrFile.contextType}_${folderOrFile.contextId}`.toLowerCase()
  }
  return filesEnv.contextsDictionary && filesEnv.contextsDictionary[assetString]
}

filesEnv.userHasPermission = function(folderOrFile, action) {
  if (!folderOrFile) return false
  return (
    filesEnv.contextFor(folderOrFile) &&
    filesEnv.contextFor(folderOrFile).permissions &&
    filesEnv.contextFor(folderOrFile).permissions[action]
  )
}

filesEnv.baseUrl = filesEnv.showingAllContexts
  ? '/files'
  : `/${filesEnv.contextType}/${filesEnv.contextId}/files`

export default filesEnv
