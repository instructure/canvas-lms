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

import {DeleteItemError} from './DeleteItemError'
import {type File, type Folder} from '../../../../interfaces/File'
import {deleteItem} from '../../../queries/deleteItem'
import {UnauthorizedError} from '../../../../utils/apiUtils'

export const deleteItems = async (items: (File | Folder)[]) => {
  const failedItems: (File | Folder)[] = []

  for (const item of items) {
    try {
      await deleteItem(item)
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        throw error
      }
      failedItems.push(item)
    }
  }

  if (failedItems.length > 0) {
    throw new DeleteItemError('Failed to delete some items', failedItems)
  }
}
