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

export interface ItemData {
  title: string
  indentation: number
}

export const prepareItemData = (
  itemData: ItemData,
): Record<string, string | number | string[] | undefined | boolean> => {
  const {title, indentation} = itemData

  const result: Record<string, string | number | string[] | undefined | boolean> = {
    'content_tag[title]': title,
    'content_tag[indent]': indentation,
    new_tab: 0,
    graded: 0,
    _method: 'PUT',
  }

  return result
}

export const submiEditItem = async (
  courseId: string,
  itemId: string,
  itemData: Record<string, string | number | string[] | undefined | boolean>,
): Promise<Record<string, any> | null> => {
  try {
    const formData = new FormData()

    Object.entries(itemData).forEach(([key, value]) => {
      if (value !== undefined) {
        formData.append(key, String(value))
      }
    })

    const response = await doFetchApi({
      path: `/courses/${courseId}/modules/items/${itemId}`,
      method: 'POST',
      body: formData,
    })

    return response.json as Record<string, any>
  } catch (_error) {
    console.error('Error submitting module item')
    return null
  }
}
