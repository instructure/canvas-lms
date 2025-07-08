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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {type File, type Folder} from '../../interfaces/File'
import {UnauthorizedError} from '../../utils/apiUtils'
import {isFile} from '../../utils/fileFolderUtils'

const deletePath = (item: File | Folder) => {
  const params = new URLSearchParams({force: 'true'})
  return `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}?${params}`
}

export const deleteItem = async (item: File | Folder) => {
  const {response} = await doFetchApi<File | Folder>({
    path: deletePath(item),
    method: 'DELETE',
    headers: {'Content-Type': 'application/json'},
  })

  if (response.status === 401) {
    throw new UnauthorizedError()
  }

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`Failed to delete ${item.id}: ${response.status} - ${errorText}`)
  }
}
