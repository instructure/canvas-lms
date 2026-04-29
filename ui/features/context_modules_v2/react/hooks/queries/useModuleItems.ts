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
import {useScope as createI18nScope} from '@canvas/i18n'
import {useQuery} from '@tanstack/react-query'
import type {
  ModuleItem,
  PaginatedNavigationGraphQLResult,
  PaginatedNavigationResponse,
} from '../../utils/types'
import {MODULE_ITEMS, PAGE_SIZE, MODULE_ITEMS_QUERY_MAP} from '../../utils/constants'

const I18n = createI18nScope('context_modules_v2')

const transformItems = (items: ModuleItem[], moduleId: string) =>
  items.map((item, index) => ({
    ...item,
    moduleId,
    index,
  }))

export async function getModuleItems(
  moduleId: string,
  cursor: string | null,
  view: string = 'teacher',
  pageSize: number = PAGE_SIZE,
): Promise<PaginatedNavigationResponse> {
  const persistedQuery = MODULE_ITEMS_QUERY_MAP[view]
  const query = gql`${persistedQuery}`

  try {
    const initialResult = await executeQuery<PaginatedNavigationGraphQLResult>(query, {
      moduleId,
      cursor: cursor,
      first: pageSize,
    })

    if (initialResult.errors) {
      throw new Error(initialResult.errors.map(err => err.message).join(', '))
    }

    const {moduleItemsConnection} = initialResult.legacyNode || {}
    const edges = moduleItemsConnection?.edges || []
    const pageInfo = moduleItemsConnection?.pageInfo || {
      hasNextPage: false,
      endCursor: null,
    }

    return {
      moduleItems: transformItems(
        edges.map(edge => edge.node),
        moduleId,
      ),
      pageInfo,
    }
  } catch (error: any) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('Failed to load module items:', errorMessage)
    throw error
  }
}

export function useModuleItems(
  moduleId: string,
  cursor: string | null,
  enabled: boolean,
  view: string = 'teacher',
) {
  return useQuery<PaginatedNavigationResponse, Error>({
    queryKey: [MODULE_ITEMS, moduleId, cursor],
    queryFn: () => getModuleItems(moduleId, cursor, view),
    enabled,
    staleTime: 15 * 60 * 1000,
  })
}
