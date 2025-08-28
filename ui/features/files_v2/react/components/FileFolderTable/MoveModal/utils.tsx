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

import {Collection} from '@instructure/ui-tree-browser/types/TreeBrowser/props'
import {ApiFolderItem, MultiPageResponse} from '../../../queries/folders'
import doFetchApi from '@canvas/do-fetch-api-effect'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {FileOptions, ResolvedName} from '../../FilesHeader/UploadButton/FileOptions'
import {showFlashSuccess, showFlashError, showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {getName, isFile} from '../../../../utils/fileFolderUtils'
import {type Folder, type File} from '../../../../interfaces/File'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('files_v2')

export type FolderCollection = Record<string, Collection>

export const addNewFoldersToCollection = (
  collection: FolderCollection,
  targetId: string,
  newCollections: FolderCollection,
) => {
  const collections = Object.keys(newCollections)
  const result = JSON.parse(JSON.stringify(collection))
  result[targetId] = {...collection[targetId], collections: [...collections]}
  return {...result, ...newCollections}
}

export const parseAllPagesResponse = (response: MultiPageResponse): FolderCollection => {
  return response.pages
    .map(page => page.json)
    .flat()
    .reduce((result: FolderCollection, item: ApiFolderItem) => ({...result, [item.id]: item}), {})
}

export const sendMoveRequests = (
  selectedFolder: Folder,
  resolveCollisions?: (nameCollisions: FileOptions[]) => void,
  selectedItems?: ResolvedName[],
) => {
  const body = {
    parent_folder_id: selectedFolder?.id,
  }
  const resolvedNames = selectedItems
    ? selectedItems
    : FileOptionsCollection.getState().resolvedNames
  const nameCollisions: FileOptions[] = []

  showFlashAlert({message: I18n.t('Starting copy operation...')})
  return Promise.all(
    resolvedNames.map(options => {
      let additionalParams
      if (options.dup === 'overwrite') {
        additionalParams = {
          on_duplicate: 'overwrite',
        }
      } else if (options.dup === 'error' || options.dup === 'rename') {
        if (options.name) {
          additionalParams = {
            display_name: options.name,
            name: options.name,
            on_duplicate: 'error',
          }
        } else {
          additionalParams = {
            on_duplicate: 'error',
          }
        }
      }
      const item = options.file as File | Folder

      return doFetchApi<File | Folder>({
        method: 'PUT',
        path: `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}`,
        body: {...body, ...additionalParams},
      })
        .then(response => response.json)
        .then((responseItem?: File | Folder) => {
          showFlashSuccess(
            I18n.t('%{name} successfully moved to %{folderName}.', {
              name: responseItem ? getName(responseItem) : '',
              folderName: selectedFolder?.name,
            }),
          )()
        })
        .catch(error => {
          console.error('Error moving item:', error)
          if (error.response.status === 409 && isFile(item)) {
            nameCollisions.push({
              ...options,
              file: options.file as globalThis.File,
              cannotOverwrite: false,
            })
          } else {
            showFlashError(
              I18n.t('Error moving %{name} to %{folderName}.', {
                name: getName(item),
                folderName: selectedFolder?.name,
              }),
            )
          }
        })
    }),
  ).then(() => {
    if (resolveCollisions) {
      resolveCollisions(nameCollisions)
    }
  })
}
