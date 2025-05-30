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
import {ModuleItem} from '../../utils/types.d'

interface ToggleCollapseParams {
  moduleId: string
  collapse: boolean
}

type ToggleCollapseResponse = {collapsed: boolean} | ModuleItem[]

export const useToggleCollapse = (courseId: string) => {
  return useMutation<ToggleCollapseResponse, Error, ToggleCollapseParams>({
    mutationFn: async ({moduleId, collapse}: ToggleCollapseParams) => {
      const {json} = await doFetchApi({
        path: `/courses/${courseId}/modules/${moduleId}/collapse`,
        method: 'POST',
        body: {collapse},
      })
      return json as ToggleCollapseResponse
    },
    onSuccess: () => {
      queryClient.invalidateQueries({queryKey: ['modules', courseId]})
    },
  })
}

export const useToggleAllCollapse = (courseId: string) => {
  return useMutation({
    mutationFn: async (collapse: boolean) => {
      const {json} = await doFetchApi({
        path: `/courses/${courseId}/collapse_all_modules`,
        method: 'POST',
        params: {
          collapse: collapse ? 1 : 0,
        },
      })
      return json
    },
    onSuccess: () => {
      queryClient.invalidateQueries({queryKey: ['modules', courseId]})
    },
  })
}
