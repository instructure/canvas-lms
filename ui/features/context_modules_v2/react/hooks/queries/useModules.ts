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

import {useAllPages} from '@canvas/query'
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModulesResponse, GraphQLResult} from '../../utils/types'
import {InfiniteData} from '@tanstack/react-query'
import {MODULES, MODULES_QUERY_MAP} from '../../utils/constants'

const I18n = createI18nScope('context_modules_v2')

async function getModules({
  queryKey,
  pageParam,
  view,
}: {
  queryKey: any
  pageParam?: unknown
  view: string
}): Promise<ModulesResponse> {
  const [_key, courseId] = queryKey
  const cursor = pageParam ? String(pageParam) : null

  const persistedQuery = MODULES_QUERY_MAP[view]
  const query = gql`${persistedQuery}`
  try {
    const result = await executeQuery<GraphQLResult>(query, {
      courseId,
      cursor,
    })

    if (result.errors) {
      throw new Error(result.errors.map((err: {message: string}) => err.message).join(', '))
    }

    const edges = result.legacyNode?.modulesConnection?.edges || []
    const pageInfo = result.legacyNode?.modulesConnection?.pageInfo || {
      hasNextPage: false,
      endCursor: null,
    }

    const modules = edges.map(edge => {
      const node = edge.node
      return {
        ...node,
        moduleItems: [],
        moduleItemsTotalCount: node.moduleItemsTotalCount,
      }
    })

    return {
      modules,
      pageInfo,
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load modules: %{error}', {error: errorMessage}))
    throw error
  }
}

export function useModules(courseId: string, view: string = 'teacher') {
  const queryResult = useAllPages<
    ModulesResponse,
    Error,
    InfiniteData<ModulesResponse>,
    [string, string]
  >({
    queryKey: [MODULES, courseId],
    queryFn: ({queryKey, pageParam}) => getModules({queryKey, pageParam, view}),
    initialPageParam: undefined,
    getNextPageParam: (lastPage: ModulesResponse) =>
      lastPage.pageInfo.hasNextPage ? lastPage.pageInfo.endCursor : undefined,
    refetchOnWindowFocus: true,
    staleTime: 15 * 60 * 1000,
  })

  const getModuleItemsTotalCount = (moduleId: string): number | null => {
    const allModules = queryResult.data?.pages.flatMap(page => page.modules) ?? []
    const module = allModules.find(m => m.id === moduleId || m._id === moduleId)
    return module?.moduleItemsTotalCount ?? null
  }

  return {
    ...queryResult,
    getModuleItemsTotalCount,
  }
}
