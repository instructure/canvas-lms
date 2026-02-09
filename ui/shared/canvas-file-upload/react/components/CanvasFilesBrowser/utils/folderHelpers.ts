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

import {CanvasFolder, CanvasFile} from '../../../types'

/**
 * Formats a raw folder object from the API into our CanvasFolder type
 */
export const formatFolderData = (folder: any): CanvasFolder => {
  return {
    ...folder,
    subFolderIDs: [],
    subFileIDs: [],
  }
}

/**
 * Updates the folder hierarchy with new folders
 */
export const updateFoldersWithNewFolders = (
  existingFolders: Record<string, CanvasFolder>,
  newFolders: any[],
): Record<string, CanvasFolder> => {
  const loadedFolders = JSON.parse(JSON.stringify(existingFolders))

  newFolders.forEach(folder => {
    folder = formatFolderData(folder)
    folder.parent_folder_id = folder.parent_folder_id || '0'

    const parent = loadedFolders.hasOwnProperty(folder.parent_folder_id)
      ? loadedFolders[folder.parent_folder_id]
      : {subFileIDs: [], subFolderIDs: []}

    if (!parent.subFolderIDs.includes(folder.id)) {
      parent.subFolderIDs.push(folder.id)
      loadedFolders[folder.parent_folder_id] = {
        ...loadedFolders[folder.parent_folder_id],
        ...parent,
      }
    }

    if (loadedFolders[folder.id]) {
      folder.subFolderIDs = loadedFolders[folder.id].subFolderIDs
    }
    loadedFolders[folder.id] = folder
  })

  return loadedFolders
}

/**
 * Updates the folder hierarchy with new files
 */
export const updateFoldersWithNewFiles = (
  existingFolders: Record<string, CanvasFolder>,
  newFiles: CanvasFile[],
): Record<string, CanvasFolder> => {
  const loadedFolders = JSON.parse(JSON.stringify(existingFolders))

  newFiles.forEach(file => {
    const parentID = file.folder_id || '0'

    const parent = loadedFolders.hasOwnProperty(parentID)
      ? loadedFolders[parentID]
      : {subFileIDs: [], subFolderIDs: []}

    if (!parent.subFileIDs.includes(file.id)) {
      parent.subFileIDs.push(file.id)
      loadedFolders[parentID] = {...loadedFolders[parentID], ...parent}
    }
  })

  return loadedFolders
}

/**
 * Builds the breadcrumb path for a given folder
 */
export const buildBreadcrumbPath = (
  folderID: string,
  folders: Record<string, CanvasFolder>,
): Array<{id: string; name: string}> => {
  const path: Array<{id: string; name: string}> = []
  let folder = folders[folderID]

  while (folder) {
    path.unshift({id: folder.id, name: folder.name})
    folder = folders[folder.parent_folder_id as string]
  }

  return path
}
