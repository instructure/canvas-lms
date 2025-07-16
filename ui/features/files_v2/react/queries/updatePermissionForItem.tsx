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

import {type File, type Folder} from '../../interfaces/File'
import {doFetchApiWithAuthCheck} from '../../utils/apiUtils'
import {isFile} from '../../utils/fileFolderUtils'

export type UpdatePermissionBody = {
  hidden: boolean
  locked: boolean
  unlock_at: string
  lock_at: string
  visibility_level?: string
}

const updatePermissionPath = (item: File | Folder) => {
  return `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}`
}

export const updatePermissionForItem = async (item: File | Folder, body: UpdatePermissionBody) => {
  await doFetchApiWithAuthCheck<File | Folder>({
    path: updatePermissionPath(item),
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: body,
  })
}
