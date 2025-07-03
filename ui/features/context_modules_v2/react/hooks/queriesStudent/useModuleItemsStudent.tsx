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

import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {ModuleItemsResponse, ModuleItemsGraphQLResult, ModuleItem} from '../../utils/types'
import {useQuery} from '@tanstack/react-query'
import persistedQueries from '@canvas/graphql/persistedQueries'

// use persistedQueries to make sure it loads without user session (public courses)
export const MODULE_ITEMS_STUDENT_QUERY = gql`${persistedQueries.GetModuleItemsStudentQuery.query}`

const transformItems = (items: ModuleItem[], moduleId: string) => {
  return items.map((item, index) => ({
    ...item,
    moduleId,
    index,
  }))
}

async function getModuleItemsStudent({queryKey}: {queryKey: any}): Promise<ModuleItemsResponse> {
  const [_key, moduleId] = queryKey

  const result = await executeQuery<ModuleItemsGraphQLResult>(MODULE_ITEMS_STUDENT_QUERY, {
    moduleId,
  })

  if (result.errors) {
    throw new Error(result.errors.map(err => err.message).join(', '))
  }

  const moduleItems = result.legacyNode?.moduleItems || []

  return {
    moduleItems: transformItems(moduleItems, moduleId),
  }
}

export function useModuleItemsStudent(moduleId: string, enabled: boolean = false) {
  return useQuery<ModuleItemsResponse, Error>({
    queryKey: ['moduleItemsStudent', moduleId],
    queryFn: getModuleItemsStudent,
    enabled,
    refetchOnWindowFocus: true,
    // 15 minutes, will reload on refresh because there is no persistence
    staleTime: 15 * 60 * 1000,
  })
}
