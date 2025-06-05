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
import {ModulesResponse, GraphQLResult} from '../../utils/types.d'
import {InfiniteData} from '@tanstack/react-query'

const I18n = createI18nScope('context_modules_v2')

const MODULES_QUERY = gql`
  query GetModulesQuery($courseId: ID!, $cursor: String) {
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        modulesConnection(first: 100, after: $cursor) {
          edges {
            cursor
            node {
              id
              _id
              name
              position
              published
              unlockAt
              requirementCount
              requireSequentialProgress
              hasActiveOverrides
              prerequisites {
                id
                name
                type
              }
              completionRequirements {
                id
                type
                minScore
                minPercentage
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

async function getModules({
  queryKey,
  pageParam,
}: {queryKey: any; pageParam?: unknown}): Promise<ModulesResponse> {
  const [_key, courseId] = queryKey
  const cursor = pageParam ? String(pageParam) : null
  try {
    const result = await executeQuery<GraphQLResult>(MODULES_QUERY, {
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
        moduleItems: [], // Initialize with empty items array
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

export function useModules(courseId: string) {
  return useAllPages<ModulesResponse, Error, InfiniteData<ModulesResponse>, [string, string]>({
    queryKey: ['modules', courseId],
    queryFn: getModules,
    initialPageParam: undefined,
    getNextPageParam: (lastPage: ModulesResponse) =>
      lastPage.pageInfo.hasNextPage ? lastPage.pageInfo.endCursor : undefined,
  })
}
