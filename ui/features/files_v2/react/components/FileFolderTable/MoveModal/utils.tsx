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

export type FolderCollection = Record<string, Collection>

export const addNewFoldersToCollection = (collection: FolderCollection, targetId: string, newCollections: FolderCollection) => {
  const collections = Object.keys(newCollections)
  const result = JSON.parse(JSON.stringify(collection))
  result[targetId] = { ...collection[targetId], collections: [...collections] }
  return { ...result, ...newCollections }
}

export const parseAllPagesResponse = (response: MultiPageResponse): FolderCollection => {
  return response
          .pages
          .map(page => page.json)
          .flat()
          .reduce((result: FolderCollection, item: ApiFolderItem) => ({...result, [item.id]: item}), {})
}
