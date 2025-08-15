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

import {useQuery} from '@tanstack/react-query'
import type {ModuleItem, PaginatedNavigationResponse} from '../../utils/types'
import {SHOW_ALL_PAGE_SIZE} from '../../utils/constants'
import {getModuleItems} from './useModuleItems'

export async function getAllModuleItems(
  moduleId: string,
  view: string = 'teacher',
  pageSize: number = SHOW_ALL_PAGE_SIZE,
): Promise<PaginatedNavigationResponse> {
  const allItems: ModuleItem[] = []
  let currentCursor: string | null = null
  let hasMore = true

  // NOTE: getModuleItems can throw, so getAllModuleItems can
  while (hasMore) {
    const result = await getModuleItems(moduleId, currentCursor, view, pageSize)
    allItems.push(...result.moduleItems)
    hasMore = result.pageInfo.hasNextPage
    currentCursor = result.pageInfo.endCursor
  }

  return {moduleItems: allItems, pageInfo: {hasNextPage: false, endCursor: null}}
}

export function useAllModuleItems(moduleId: string, enabled: boolean, view: string = 'teacher') {
  return useQuery<PaginatedNavigationResponse, Error>({
    queryKey: ['MODULE_ITEMS_ALL', moduleId, view, SHOW_ALL_PAGE_SIZE],
    queryFn: () => getAllModuleItems(moduleId, view),
    enabled,
    staleTime: 15 * 60 * 1000,
  })
}
