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

import {queryClient} from '@canvas/query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useMutation} from '@tanstack/react-query'
import {MODULE_ITEMS, MODULES} from '../../utils/constants'

interface ReorderItemsParams {
  courseId: string
  moduleId: string
  oldModuleId: string
  order: string[]
}

export const useReorderModuleItems = () => {
  return useMutation({
    mutationFn: async ({courseId, moduleId, order}: ReorderItemsParams) => {
      const {json} = await doFetchApi({
        path: `/courses/${courseId}/modules/${moduleId}/reorder`,
        method: 'POST',
        body: `order=${order.join(',')}`,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      })
      return json
    },
    onSuccess: (_data, variables) => {
      const {moduleId, oldModuleId, courseId} = variables
      if (moduleId === oldModuleId) {
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId]})
        queryClient.invalidateQueries({queryKey: ['MODULE_ITEMS_ALL', moduleId]})
      }

      if (moduleId !== oldModuleId) {
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId]})
        queryClient.invalidateQueries({queryKey: ['MODULE_ITEMS_ALL', moduleId]})
        queryClient.invalidateQueries({queryKey: [MODULES, courseId]})
      }
    },
  })
}
